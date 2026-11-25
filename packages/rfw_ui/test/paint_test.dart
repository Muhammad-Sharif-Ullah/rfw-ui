import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';
import 'package:rfw_ui/src/decode/svg_path.dart';
import 'package:rfw_ui/src/widgets/paint.dart';

const LibraryName _main = LibraryName(<String>['main']);
final ThemeData _theme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)));

/// Mounts `CustomPaint(key: "art", <args>)` and returns its data.
Future<DynamicContent> _paint(WidgetTester tester, String args, {Map<String, Object?> data = const <String, Object?>{}}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\nwidget root = Center(child: CustomPaint(key: "art", $args));'));
  addTearDown(runtime.dispose);
  final DynamicContent content = DynamicContent(data);
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      home: UiRemoteWidget(runtime: runtime, data: content, widget: const FullyQualifiedWidgetName(_main, 'root')),
    ),
  );
  await tester.pump();
  return content;
}

RenderObject _art(WidgetTester tester) => tester.renderObject(
  find.descendant(of: find.byWidgetPredicate((Widget w) => UiKey.matches(w.key, 'art')), matching: find.byType(CustomPaint)).first,
);

void main() {
  testWidgets('a circle is filled in the colour it names', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .circle, center: [50, 50], radius: 40, color: .primary }]');
    expect(_art(tester), paints..circle(x: 50, y: 50, radius: 40, color: _theme.colorScheme.primary, style: PaintingStyle.fill));
  });

  testWidgets('a stroke width draws the outline instead', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .rect, rect: [10, 10, 80, 40], color: "#FF0000", stroke: 2 }]');
    expect(
      _art(tester),
      paints..rect(rect: const Rect.fromLTWH(10, 10, 80, 40), color: const Color(0xFFFF0000), strokeWidth: 2, style: PaintingStyle.stroke),
    );
  });

  testWidgets('a rect with a radius is rounded', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .rect, rect: [0, 0, 100, 50], radius: 8, color: "#00FF00" }]');
    expect(_art(tester), paints..rrect(rrect: RRect.fromLTRBR(0, 0, 100, 50, const Radius.circular(8)), color: const Color(0xFF00FF00)));
  });

  testWidgets('a line goes from one point to the other', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .line, from: [0, 0], to: [100, 50], stroke: 3, color: "#000000" }]');
    expect(_art(tester), paints..line(p1: Offset.zero, p2: const Offset(100, 50), strokeWidth: 3));
  });

  testWidgets('an arc takes its angles in degrees, clockwise from three o\'clock', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .arc, center: [50, 50], radius: 40, start: -90, sweep: 90, stroke: 8, cap: .round }]');
    expect(
      _art(tester),
      paints..arc(
        rect: Rect.fromCircle(center: const Offset(50, 50), radius: 40),
        startAngle: -math.pi / 2,
        sweepAngle: math.pi / 2,
        strokeWidth: 8,
        strokeCap: StrokeCap.round,
        style: PaintingStyle.stroke,
      ),
    );
  });

  testWidgets('a path is SVG path data', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .path, d: "M0 0 L10 0 L10 10 Z", color: "#000000" }]');
    expect(_art(tester), paints..path(includes: <Offset>[const Offset(8, 2)], excludes: <Offset>[const Offset(2, 8)]));
  });

  testWidgets('text is drawn where it says', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .text, text: "Hi", at: [10, 20], style: { fontSize: 12 } }]');
    expect(_art(tester), paints..paragraph(offset: const Offset(10, 20)));
  });

  testWidgets('a gradient fills the shape', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, shapes: [{ shape: .rect, rect: [0, 0, 100, 100], gradient: { type: .linear, colors: [.primary, .secondary] } }]');
    expect(
      _art(tester),
      paints..something((Symbol method, List<dynamic> arguments) => method == #drawRect && (arguments[1] as Paint).shader != null),
    );
  });

  testWidgets('a view box scales its coordinates to the painted size', (WidgetTester tester) async {
    await _paint(tester, 'width: 100, height: 100, viewBox: [0, 0, 10, 10], shapes: [{ shape: .circle, center: [5, 5], radius: 4 }]');
    expect(_art(tester), paints..scale(x: 10, y: 10)..circle(x: 5, y: 5, radius: 4));
  });

  testWidgets('a colour from data repaints when the data changes', (WidgetTester tester) async {
    final DynamicContent data = await _paint(
      tester,
      'width: 100, height: 100, shapes: [{ shape: .circle, center: [50, 50], radius: 40, color: data.c }]',
      data: <String, Object?>{'c': '#FF0000'},
    );
    expect(_art(tester), paints..circle(color: const Color(0xFFFF0000)));
    data.update('c', '#0000FF');
    await tester.pump();
    expect(_art(tester), paints..circle(color: const Color(0xFF0000FF)));
  });

  testWidgets('text takes its style\'s colour, unless the shape names one', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(theme: _theme, home: Builder(builder: (BuildContext c) => SizedBox(key: ObjectKey(context = c)))));
    List<UiShape> decode(Map<String, Object?> shape) =>
        shapes(UiArgs(context, MapSource(<String, Object?>{'shapes': <Object?>[shape]})), <Object>['shapes']);
    final ColorScheme scheme = _theme.colorScheme;

    final UiTextShape styled = decode(<String, Object?>{'shape': 'text', 'text': 'a', 'at': <Object?>[0, 0], 'style': <String, Object?>{'color': 'primary'}}).single as UiTextShape;
    expect(styled.style.color, scheme.primary);
    final UiTextShape named = decode(<String, Object?>{'shape': 'text', 'text': 'a', 'at': <Object?>[0, 0], 'color': 'tertiary', 'style': <String, Object?>{'color': 'primary'}}).single as UiTextShape;
    expect(named.style.color, scheme.tertiary);
    final UiTextShape plain = decode(<String, Object?>{'shape': 'text', 'text': 'a', 'at': <Object?>[0, 0]}).single as UiTextShape;
    expect(plain.style.color, scheme.onSurface);
  });

  group('parseSvgPath', () {
    test('reads lines, curves and closes, absolute and relative', () {
      final Path path = parseSvgPath('M 10 10 h 80 v 80 H 10 Z m 20 20 c 10 0 20 10 20 20 q 10 10 20 0 l 10 0 z')!;
      expect(path.getBounds(), const Rect.fromLTRB(10, 10, 90, 90));
    });

    test('says null for what it does not read, such as arcs', () {
      expect(parseSvgPath('M0 0 A 1 1 0 0 0 2 2'), isNull);
      expect(parseSvgPath('M0 0 L x 1'), isNull);
    });
  });
}
