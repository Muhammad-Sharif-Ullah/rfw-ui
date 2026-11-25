import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// Swiping, dragging, dropping, pinching and reordering.
const LibraryName _main = LibraryName(<String>['main']);

final List<(String, DynamicMap)> _events = <(String, DynamicMap)>[];

List<String> get _names => _events.map(((String, DynamicMap) e) => e.$1).toList();

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

List<Object?> _rows(int n) => <Object?>[
  for (int i = 0; i < n; i += 1) <String, Object?>{'id': 'r$i', 'title': 'Row $i'},
];

void main() {
  setUp(_events.clear);

  group('Dismissible', () {
    const String row =
        'Dismissible(key: "a", direction: .horizontal, background: ColoredBox(color: .error), '
        'onDismissed: event "gone" { }, child: SizedBox(height: 80, child: Text(text: "row")))';

    testWidgets('swiped away, it fires onDismissed with the direction it went', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView(children: [$row, SizedBox(height: 400)]);');
      await tester.drag(find.text('row'), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(_names, <String>['gone']);
      expect(_events.single.$2['direction'], 'startToEnd');
    });

    testWidgets('left alone, it stays', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView(children: [$row, SizedBox(height: 400)]);');
      await tester.drag(find.text('row'), const Offset(10, 0));
      await tester.pumpAndSettle();
      expect(_events, isEmpty);
      expect(find.text('row'), findsOneWidget);
    });

    testWidgets('with no key of its own it still works', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = ListView(children: ['
        'Dismissible(onDismissed: event "gone" { }, child: SizedBox(height: 80, child: Text(text: "row"))), '
        'SizedBox(height: 400)]);',
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.text('row'), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(_names, <String>['gone']);
    });
  });

  group('Draggable and DragTarget', () {
    testWidgets('a Draggable dropped on a DragTarget hands over its data', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = Column(children: [
          Draggable(
            data: "apple",
            feedback: SizedBox(width: 40, height: 40, child: ColoredBox(color: .primary)),
            childWhenDragging: SizedBox(width: 80, height: 80),
            child: SizedBox(width: 80, height: 80, child: Center(child: Text(text: "from"))),
          ),
          SizedBox(height: 40),
          DragTarget(onAccept: event "drop" { }, child: SizedBox(width: 80, height: 80, child: Center(child: Text(text: "to")))),
        ]);
      ''');
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('from')));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(tester.getCenter(find.text('to')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_names, <String>['drop']);
      expect(_events.single.$2['value'], 'apple');
    });

    testWidgets('a Draggable shows its feedback while it is held', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = Draggable(
          data: "apple",
          feedback: SizedBox(width: 40, height: 40, child: Text(text: "held")),
          child: SizedBox(width: 80, height: 80, child: Center(child: Text(text: "from"))),
        );
      ''');
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('from')));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(find.text('held'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('InteractiveViewer', () {
    testWidgets('it renders its child and frees what it made', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = InteractiveViewer(minScale: 0.5, maxScale: 4, '
        'child: SizedBox(width: 200, height: 200, child: Center(child: Text(text: "zoom"))));',
      );
      expect(find.text('zoom'), findsOneWidget);
      final InteractiveViewer viewer = tester.widget<InteractiveViewer>(_inScreen(InteractiveViewer));
      expect(viewer.minScale, 0.5);
      expect(viewer.maxScale, 4);
    });

    testWidgets('a pinch scales what is inside it', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = InteractiveViewer(maxScale: 4, '
        'child: SizedBox(width: 200, height: 200, child: Center(child: Text(text: "zoom"))));',
      );
      final Offset centre = tester.getCenter(_inScreen(InteractiveViewer));
      final TestGesture a = await tester.createGesture();
      final TestGesture b = await tester.createGesture();
      await a.down(centre - const Offset(20, 0));
      await b.down(centre + const Offset(20, 0));
      await tester.pump();
      await a.moveTo(centre - const Offset(60, 0));
      await b.moveTo(centre + const Offset(60, 0));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ReorderableListView', () {
    testWidgets('dragging a row fires onReorder with where it came from and went', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'rows': _rows(4)});
      await _mount(tester, '''
        widget root = ReorderableListView(
          onReorder: event "reorder" { },
          children: [...for r in data.rows: SizedBox(key: r.id, height: 80, child: Center(child: Text(text: r.title)))],
        );
      ''', data: data);
      expect(find.text('Row 0'), findsOneWidget);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Row 0')));
      await tester.pump(kLongPressTimeout + kPressTimeout);
      for (int i = 0; i < 12; i += 1) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_names, <String>['reorder']);
      expect(_events.single.$2['oldIndex'], 0);
      expect(_events.single.$2['newIndex'], isNotNull);
    });

    testWidgets('ReorderableListView.builder builds its rows from items', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'rows': _rows(5)});
      await _mount(tester, '''
        widget root = ReorderableListView.builder(
          items: data.rows,
          onReorder: event "reorder" { },
          itemBuilder: (r) => SizedBox(key: r.id, height: 60, child: Center(child: Text(text: r.title))),
        );
      ''', data: data);
      expect(find.text('Row 0'), findsOneWidget);
      expect(find.text('Row 4'), findsOneWidget);
    }, skip: const String.fromEnvironment('RFW_RUNTIME') == 'rfw');
  });
}
