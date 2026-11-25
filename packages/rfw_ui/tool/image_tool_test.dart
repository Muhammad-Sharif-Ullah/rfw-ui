// Reads a design image the way a person with a colour picker would: its
// palette, the colour at given points, and how far a render is from it.
//
//   cd packages/rfw_ui
//   RFW_IMAGE=/abs/design.png flutter test tool/image_tool_test.dart
//       the image's size, and its main colours with how much of it each covers
//   RFW_IMAGE=/abs/design.png RFW_POINTS="40,120 200,880" flutter test tool/image_tool_test.dart
//       the colour at each point, in the image's own pixels
//   RFW_IMAGE=/abs/design.png RFW_COMPARE=/abs/render.png RFW_OUT=/abs/side.png flutter test tool/image_tool_test.dart
//       one picture of the design, the render and their difference side by
//       side, scaled to the same width, and how different each band is
//
// PNG and JPEG both read. A test only because a test is how Flutter decodes
// an image without a device; it is in tool/, so `flutter test` never runs it.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, String> env = Platform.environment;

  testWidgets('image', (WidgetTester tester) async {
    final String? path = env['RFW_IMAGE'];
    if (path == null) {
      fail('Set RFW_IMAGE to the design image.');
    }
    await tester.runAsync(() async {
      final ui.Image design = await _decode(path);
      final Uint8List pixels = await _rgba(design);
      _say('IMAGE $path ${design.width}x${design.height}');
      _say('  at @3x that is ${(design.width / 3).round()}x${(design.height / 3).round()} logical; '
          'at @2x ${(design.width / 2).round()}x${(design.height / 2).round()}');

      final String? points = env['RFW_POINTS'];
      final String? compare = env['RFW_COMPARE'];
      if (points != null) {
        for (final String p in points.split(RegExp(r'\s+')).where((String s) => s.isNotEmpty)) {
          final List<int> xy = p.split(',').map(int.parse).toList();
          final int x = xy[0].clamp(0, design.width - 1);
          final int y = xy[1].clamp(0, design.height - 1);
          _say('POINT $x,$y ${_hex(_at(pixels, design.width, x, y))}');
        }
      } else if (compare != null) {
        final String out = env['RFW_OUT'] ?? '${compare.replaceAll(RegExp(r'\.png$'), '')}-compare.png';
        await _compare(design, pixels, await _decode(compare), out);
      } else {
        _palette(pixels, design.width, design.height);
      }
      design.dispose();
    });
  });
}

void _say(String line) => stdout.writeln(line);

Future<ui.Image> _decode(String path) async {
  final ui.Codec codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final ui.FrameInfo frame = await codec.getNextFrame();
  return frame.image;
}

Future<Uint8List> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

int _at(Uint8List rgba, int width, int x, int y) {
  final int i = (y * width + x) * 4;
  return (rgba[i + 3] << 24) | (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2];
}

String _hex(int argb) => '0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// The colours that cover the most of the image, grouped where they are close
/// enough to be one colour drawn with anti-aliasing, each with where it sits.
void _palette(Uint8List rgba, int width, int height) {
  final Map<int, List<int>> buckets = <int, List<int>>{}; // key -> [count, sumR, sumG, sumB, sumX, sumY]
  final int step = math.max(1, (width * height / 400000).sqrt().floor());
  int seen = 0;
  for (int y = 0; y < height; y += step) {
    for (int x = 0; x < width; x += step) {
      final int i = (y * width + x) * 4;
      final int r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      final int key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      final List<int> bucket = buckets[key] ??= <int>[0, 0, 0, 0, 0, 0];
      bucket[0] += 1;
      bucket[1] += r;
      bucket[2] += g;
      bucket[3] += b;
      bucket[4] += x;
      bucket[5] += y;
      seen += 1;
    }
  }
  final List<List<int>> sorted = buckets.values.toList()..sort((List<int> a, List<int> b) => b[0].compareTo(a[0]));
  final List<List<int>> kept = <List<int>>[];
  for (final List<int> b in sorted) {
    final int r = b[1] ~/ b[0], g = b[2] ~/ b[0], bl = b[3] ~/ b[0];
    final List<int>? near = kept.where((List<int> k) {
      final int kr = k[1] ~/ k[0], kg = k[2] ~/ k[0], kb = k[3] ~/ k[0];
      return (kr - r).abs() + (kg - g).abs() + (kb - bl).abs() < 24;
    }).firstOrNull;
    if (near != null) {
      for (int i = 0; i < 6; i += 1) {
        near[i] += b[i];
      }
    } else {
      kept.add(List<int>.of(b));
    }
  }
  kept.sort((List<int> a, List<int> b) => b[0].compareTo(a[0]));
  _say('PALETTE the colours covering the most of the image, and the middle of where each is:');
  for (final List<int> k in kept.take(14)) {
    final double share = k[0] * 100 / seen;
    if (share < 0.2) {
      break;
    }
    final int argb = 0xFF000000 | ((k[1] ~/ k[0]) << 16) | ((k[2] ~/ k[0]) << 8) | (k[3] ~/ k[0]);
    _say('  ${_hex(argb)}  ${share.toStringAsFixed(1).padLeft(5)}%  around ${k[4] ~/ k[0]},${k[5] ~/ k[0]}');
  }
}

/// Design | render | difference, each [w] wide, and the difference per band.
Future<void> _compare(ui.Image design, Uint8List designPixels, ui.Image render, String out) async {
  const int w = 360;
  final int h = (design.height * w / design.width).round();
  final ui.Image a = await _scaled(design, w, h);
  final ui.Image b = await _scaled(render, w, h);
  final Uint8List pa = await _rgba(a);
  final Uint8List pb = await _rgba(b);
  final Uint8List diff = Uint8List(w * h * 4);
  const int bands = 8;
  final List<double> band = List<double>.filled(bands, 0);
  for (int i = 0; i < w * h; i += 1) {
    final int o = i * 4;
    final int d = ((pa[o] - pb[o]).abs() + (pa[o + 1] - pb[o + 1]).abs() + (pa[o + 2] - pb[o + 2]).abs()) ~/ 3;
    // Red where they differ, the design faintly where they agree.
    final int grey = (pa[o] + pa[o + 1] + pa[o + 2]) ~/ 3;
    diff[o] = math.min(255, grey ~/ 4 + d * 3);
    diff[o + 1] = grey ~/ 4;
    diff[o + 2] = grey ~/ 4;
    diff[o + 3] = 255;
    band[(i ~/ w) * bands ~/ h] += d;
  }
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(diff);
  final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final ui.FrameInfo frame = await (await descriptor.instantiateCodec()).getNextFrame();
  final ui.Image d = frame.image;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  const double gap = 12;
  canvas.drawRect(Rect.fromLTWH(0, 0, w * 3 + gap * 2, h.toDouble()), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  canvas.drawImage(a, Offset.zero, ui.Paint());
  canvas.drawImage(b, const Offset(w + gap, 0), ui.Paint());
  canvas.drawImage(d, const Offset((w + gap) * 2, 0), ui.Paint());
  final ui.Image side = await recorder.endRecording().toImage((w * 3 + gap * 2).toInt(), h);
  File(out).writeAsBytesSync((await side.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
  _say('COMPARED design | render | difference -> $out');
  final double perBand = (w * h / bands).toDouble();
  for (int i = 0; i < bands; i += 1) {
    final double score = band[i] / perBand;
    _say('  band ${i + 1}/$bands (rows ${i * h ~/ bands}-${(i + 1) * h ~/ bands}): '
        'mean difference ${score.toStringAsFixed(1).padLeft(5)} of 255${score > 20 ? '  <- look here' : ''}');
  }
  for (final ui.Image i in <ui.Image>[a, b, d, side, render]) {
    i.dispose();
  }
}

Future<ui.Image> _scaled(ui.Image image, int w, int h) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  return recorder.endRecording().toImage(w, h);
}

extension on num {
  double sqrt() => math.sqrt(this);
}
