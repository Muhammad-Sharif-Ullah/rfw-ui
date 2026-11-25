import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The compositing effects, and the care each one needs.
///
/// `BackdropFilter` is the most expensive widget in Flutter and the easiest
/// to get wrong: unclipped it blurs its whole layer, which is usually the
/// screen. The kit's clips to its own bounds unless told not to, and a
/// `borderRadius` makes that clip a rounded one.
const LibraryName _main = LibraryName(<String>['main']);

Future<void> _mount(WidgetTester tester, String source, {DynamicContent? data}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: data ?? DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
        ),
      ),
    ),
  );
}

Finder _inScreen(Type type) => find.descendant(of: find.byType(UiRemoteWidget), matching: find.byType(type));

void main() {
  group('BackdropFilter', () {
    testWidgets('a borderRadius puts the clip that bounds the cost there itself', (WidgetTester tester) async {
      await _mount(tester, 'widget root = BackdropFilter(blur: 20, borderRadius: 24, child: SizedBox(width: 100, height: 100));');
      expect(
        find.ancestor(of: _inScreen(BackdropFilter), matching: find.byType(ClipRRect)),
        findsOneWidget,
      );
    });

    testWidgets('without one it still clips to its own bounds, so a bar blurs a bar', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = Stack(children: [
          SizedBox(width: 400, height: 400, child: ColoredBox(color: .primary)),
          Positioned(top: 0, left: 0, right: 0, child: BackdropFilter(blur: 20, child: SizedBox(height: 48))),
        ]);
      ''');
      final Finder clip = find.ancestor(of: _inScreen(BackdropFilter), matching: find.byType(ClipRect));
      expect(clip, findsOneWidget);
      expect(tester.getSize(clip).height, 48, reason: 'the blur is bounded by the bar, not by the screen');
    });

    testWidgets('clip: false gives Flutter\'s own whole-layer blur back', (WidgetTester tester) async {
      await _mount(tester, 'widget root = BackdropFilter(blur: 20, clip: false, child: SizedBox(width: 100, height: 100));');
      expect(_inScreen(BackdropFilter), findsOneWidget);
      expect(find.ancestor(of: _inScreen(BackdropFilter), matching: find.byType(ClipRect)), findsNothing);
    });

    testWidgets('a blur of nothing is switched off rather than drawn', (WidgetTester tester) async {
      await _mount(tester, 'widget root = BackdropFilter(child: SizedBox(width: 100, height: 100));');
      expect(tester.widget<BackdropFilter>(_inScreen(BackdropFilter)).enabled, isFalse);
    });

    testWidgets('blurX and blurY override the one blur', (WidgetTester tester) async {
      await _mount(tester, 'widget root = BackdropFilter(blur: 4, blurX: 12, child: SizedBox(width: 100, height: 100));');
      expect(
        tester.widget<BackdropFilter>(_inScreen(BackdropFilter)).filter,
        ui.ImageFilter.blur(sigmaX: 12, sigmaY: 4, tileMode: TileMode.clamp),
      );
    });

    testWidgets('a BackdropGroup lets its filters share one read of the backdrop', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = BackdropGroup(child: Column(children: [
          BackdropFilter(blur: 8, grouped: true, child: SizedBox(width: 50, height: 50)),
          BackdropFilter(blur: 8, grouped: true, child: SizedBox(width: 50, height: 50)),
        ]));
      ''');
      expect(_inScreen(BackdropGroup), findsOneWidget);
      expect(_inScreen(BackdropFilter), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('ImageFiltered and RepaintBoundary', () {
    testWidgets('ImageFiltered blurs the child itself', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ImageFiltered(blur: 6, child: Text(text: "glow"));');
      expect(
        tester.widget<ImageFiltered>(_inScreen(ImageFiltered)).imageFilter,
        ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6, tileMode: TileMode.decal),
      );
    });

    testWidgets('ImageFiltered with no blur is switched off', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ImageFiltered(child: Text(text: "plain"));');
      expect(tester.widget<ImageFiltered>(_inScreen(ImageFiltered)).enabled, isFalse);
      expect(find.text('plain'), findsOneWidget);
    });

    testWidgets('RepaintBoundary renders its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = RepaintBoundary(child: Text(text: "own layer"));');
      expect(_inScreen(RepaintBoundary), findsWidgets);
      expect(find.text('own layer'), findsOneWidget);
    });
  });

  group('ShaderMask, ColorFiltered and ClipPath', () {
    testWidgets('ShaderMask paints its child through a gradient', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = ShaderMask(gradient: { type: .linear, colors: ["#FF0000", "#0000FF"] }, '
        'child: Text(text: "gradient"));',
      );
      expect(_inScreen(ShaderMask), findsOneWidget);
      expect(tester.widget<ShaderMask>(_inScreen(ShaderMask)).blendMode, BlendMode.srcIn);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShaderMask with no gradient is its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ShaderMask(child: Text(text: "plain"));');
      expect(_inScreen(ShaderMask), findsNothing);
      expect(find.text('plain'), findsOneWidget);
    });

    testWidgets('ColorFiltered with saturation 0 greys its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ColorFiltered(saturation: 0, child: Text(text: "grey"));');
      expect(_inScreen(ColorFiltered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ColorFiltered takes a colour and a blend mode', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ColorFiltered(color: .primary, blendMode: .multiply, child: Text(text: "x"));');
      final Color primary = Theme.of(tester.element(find.text('x'))).colorScheme.primary;
      expect(
        tester.widget<ColorFiltered>(_inScreen(ColorFiltered)).colorFilter,
        ColorFilter.mode(primary, BlendMode.multiply),
      );
    });

    testWidgets('ColorFiltered with neither is its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ColorFiltered(child: Text(text: "plain"));');
      expect(_inScreen(ColorFiltered), findsNothing);
      expect(find.text('plain'), findsOneWidget);
    });

    testWidgets('ClipPath takes a ShapeBorder', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ClipPath(shape: .stadium, child: SizedBox(width: 100, height: 40));');
      expect(_inScreen(ClipPath), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClipPath takes SVG path data in a viewBox', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = ClipPath(path: "M50 0 L100 100 L0 100 Z", viewBox: [0, 0, 100, 100], '
        'child: SizedBox(width: 120, height: 120));',
      );
      expect(_inScreen(ClipPath), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClipPath with neither is its child, unclipped', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ClipPath(child: Text(text: "plain"));');
      expect(_inScreen(ClipPath), findsNothing);
      expect(find.text('plain'), findsOneWidget);
    });
  });
}
