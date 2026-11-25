import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

List<Object?> _items(int count) => <Object?>[
  for (int i = 0; i < count; i += 1) <String, Object?>{'title': 'Item $i'},
];

Future<DynamicContent> _pump(
  WidgetTester tester,
  String source, {
  required int count,
  List<String>? events,
}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  final DynamicContent content = DynamicContent(<String, Object?>{'items': _items(count)});
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: content,
          widget: const FullyQualifiedWidgetName(_main, 'root'),
          onEvent: (String name, DynamicMap arguments) => events?.add(name),
        ),
      ),
    ),
  );
  await tester.pump();
  return content;
}

Finder get _scrollable => find.byType(Scrollable).first;

void main() {
  testWidgets('a long list shows any row it is scrolled to', (WidgetTester tester) async {
    await _pump(tester, 'widget root = ListView(children: [...for item in data.items: Text(text: item.title)]);', count: 1000);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 500'), findsNothing);
    await tester.scrollUntilVisible(find.text('Item 500'), 2000, scrollable: _scrollable);
    expect(find.text('Item 500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a list that shrinks while scrolled deep shows its new rows', (WidgetTester tester) async {
    final DynamicContent data = await _pump(
      tester,
      'widget root = ListView(children: [...for item in data.items: SizedBox(height: 40, child: Text(text: item.title))]);',
      count: 1000,
    );
    await tester.scrollUntilVisible(find.text('Item 500'), 2000, scrollable: _scrollable);
    data.update('items', _items(10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Item 500'), findsNothing);
    expect(find.text('Item 9'), findsOneWidget);
  });

  testWidgets('a separator goes between rows, not after the last', (WidgetTester tester) async {
    await _pump(
      tester,
      'widget root = ListView(separator: Divider(height: 1), children: [...for item in data.items: Text(text: item.title)]);',
      count: 3,
    );
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('onEndReached fires once when the end is reached, and again once the list has grown', (WidgetTester tester) async {
    final List<String> events = <String>[];
    final DynamicContent data = await _pump(
      tester,
      'widget root = ListView(onEndReached: event "more" { }, children: [...for item in data.items: SizedBox(height: 50, child: Text(text: item.title))]);',
      count: 40,
      events: events,
    );
    expect(events, isEmpty);

    await tester.scrollUntilVisible(find.text('Item 39'), 500, scrollable: _scrollable);
    await tester.pumpAndSettle();
    expect(events, <String>['more']);

    // Still at the end: more frames, and more dragging, ask for nothing more.
    await tester.drag(_scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(events, <String>['more']);

    data.update('items', _items(80));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Item 79'), 500, scrollable: _scrollable);
    await tester.pumpAndSettle();
    expect(events, <String>['more', 'more']);
  });

  testWidgets('a grid shows any cell it is scrolled to', (WidgetTester tester) async {
    await _pump(
      tester,
      'widget root = GridView(gridDelegate: { crossAxisCount: 2 }, children: [...for item in data.items: Text(text: item.title)]);',
      count: 400,
    );
    await tester.scrollUntilVisible(find.text('Item 300'), 2000, scrollable: _scrollable);
    expect(find.text('Item 300'), findsOneWidget);
  });

  testWidgets('a sliver list shows any row it is scrolled to', (WidgetTester tester) async {
    await _pump(
      tester,
      'widget root = CustomScrollView(slivers: [SliverList(children: [...for item in data.items: Text(text: item.title)])]);',
      count: 400,
    );
    await tester.scrollUntilVisible(find.text('Item 300'), 2000, scrollable: _scrollable);
    expect(find.text('Item 300'), findsOneWidget);
  });
}
