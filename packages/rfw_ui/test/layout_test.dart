import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The layout widgets added for screens that are not flat.
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
          onEvent: (String name, DynamicMap args) => _events.add((name, args)),
        ),
      ),
    ),
  );
}

Finder _inScreen(Type type) => find.descendant(of: find.byType(UiRemoteWidget), matching: find.byType(type));

final List<(String, DynamicMap)> _events = <(String, DynamicMap)>[];

List<String> get _names => _events.map(((String, DynamicMap) e) => e.$1).toList();

void main() {
  setUp(_events.clear);

  group('Transform', () {
    testWidgets('rotateY and perspective tilt the child away from the screen', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Transform(rotateY: 0.4, perspective: 0.001, child: Text(text: "x"));');
      final Matrix4 matrix = tester.widget<Transform>(_inScreen(Transform)).transform;
      // rotateY post-multiplies, so the perspective entry comes out as
      // p * cos(angle) -- what Flutter's own tilt idiom produces.
      expect(matrix.entry(3, 2), closeTo(0.001 * math.cos(0.4), 1e-9), reason: 'the perspective row is set');
      expect(matrix.entry(3, 0), closeTo(-0.001 * math.sin(0.4), 1e-9));
      expect(matrix.entry(0, 0), closeTo(math.cos(0.4), 0.0001));
      expect(matrix.entry(2, 0), closeTo(-math.sin(0.4), 0.0001));
    });

    testWidgets('rotateX tilts it the other way', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Transform(rotateX: 0.3, child: Text(text: "x"));');
      final Matrix4 matrix = tester.widget<Transform>(_inScreen(Transform)).transform;
      expect(matrix.entry(1, 1), closeTo(math.cos(0.3), 0.0001));
    });

    testWidgets('a flat Transform is what it always was', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Transform(rotate: 0.5, scale: 2, child: Text(text: "x"));');
      final Matrix4 matrix = tester.widget<Transform>(_inScreen(Transform)).transform;
      final Matrix4 expected = Matrix4.identity()
        ..rotateZ(0.5)
        ..scaleByDouble(2, 2, 1, 1);
      expect(matrix.entry(3, 2), 0);
      for (int row = 0; row < 4; row += 1) {
        for (int column = 0; column < 4; column += 1) {
          expect(matrix.entry(row, column), closeTo(expected.entry(row, column), 0.0001));
        }
      }
    });
  });

  group('the layout gaps', () {
    testWidgets('IndexedStack shows the one at index and keeps the others', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'i': 0});
      await _mount(
        tester,
        'widget root = IndexedStack(index: data.i, children: [Text(text: "A"), Text(text: "B")]);',
        data: data,
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B', skipOffstage: false), findsOneWidget, reason: 'built, but not shown');
      expect(find.text('B'), findsNothing, reason: 'kept, with its state, off the screen');
      expect(tester.widget<IndexedStack>(_inScreen(IndexedStack)).index, 0);
      data.update('i', 1);
      await tester.pump();
      expect(tester.widget<IndexedStack>(_inScreen(IndexedStack)).index, 1);
    });

    testWidgets('OverflowBox lets its child be bigger than the space it was given', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = SizedBox(width: 50, height: 50, child: OverflowBox(maxWidth: 200, maxHeight: 200, '
        'child: Placeholder()));',
      );
      expect(tester.getSize(_inScreen(Placeholder)).width, 200);
    });

    testWidgets('UnconstrainedBox drops the constraints entirely', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = SizedBox(width: 40, child: UnconstrainedBox(clipBehavior: .hardEdge, '
        'child: SizedBox(width: 160, height: 20, child: Placeholder())));',
      );
      expect(tester.getSize(_inScreen(Placeholder)).width, 160);
    });

    testWidgets('FractionalTranslation moves by a fraction of the child', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Align(alignment: .topLeft, child: FractionalTranslation(translation: { x: 0.5, y: 0 }, '
        'child: SizedBox(width: 80, height: 20, child: Placeholder())));',
      );
      expect(tester.getTopLeft(_inScreen(Placeholder)).dx, 40);
    });

    testWidgets('Table lays its cells out in columns', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = Table(
          border: { color: .outline, width: 1 },
          rows: [
            { cells: [Text(text: "a1"), Text(text: "a2")] },
            { cells: [Text(text: "b1"), Text(text: "b2")] },
          ],
        );
      ''');
      expect(find.text('a1'), findsOneWidget);
      expect(find.text('b2'), findsOneWidget);
      expect(tester.getTopLeft(find.text('a2')).dx, greaterThan(tester.getTopLeft(find.text('a1')).dx));
      expect(tester.getTopLeft(find.text('b1')).dy, greaterThan(tester.getTopLeft(find.text('a1')).dy));
    });

    testWidgets('Table takes column widths', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = Table(
          columnWidths: [{ type: .fixed, width: 100 }, { type: .flex }],
          rows: [{ cells: [SizedBox(height: 20, child: Placeholder()), Text(text: "wide")] }],
        );
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).width, 100);
    });

    testWidgets('ListWheelScrollView curves its children and reports the one in the middle', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = ListWheelScrollView(
          itemExtent: 40,
          onSelectedItemChanged: event "picked" { },
          children: [...for n in data.items: SizedBox(height: 40, child: Center(child: Text(text: n)))],
        );
      ''', data: DynamicContent(<String, Object?>{'items': <Object?>['one', 'two', 'three', 'four', 'five']}));
      expect(find.text('one'), findsOneWidget);
      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(_names, contains('picked'));
    });

    testWidgets('Scrollbar draws over a scroll view', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Scrollbar(thumbVisibility: true, child: ListView(children: [...for n in data.items: '
        'SizedBox(height: 120, child: Text(text: n))]));',
        data: DynamicContent(<String, Object?>{'items': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']}),
      );
      expect(_inScreen(Scrollbar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
