import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The `.builder` widgets hand `itemBuilder` each row's item, which rfw's
/// Runtime cannot do: these need UiRuntime, and say so on rfw's.
const bool _onRfw = String.fromEnvironment('RFW_RUNTIME') == 'rfw';
const LibraryName _main = LibraryName(<String>['main']);

Future<List<String>> _mount(WidgetTester tester, String source, {DynamicContent? data}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  final List<String> events = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: data ?? DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
          onEvent: (String name, DynamicMap args) => events.add(name),
        ),
      ),
    ),
  );
  await tester.pump();
  return events;
}

const String _ab = 'items: [{ n: "a" }, { n: "b" }], itemBuilder: (m) => Text(text: m.n)';

void main() {
  group('on UiRuntime', () {
    final Map<String, String> each = <String, String>{
      'ListView.builder': 'widget root = ListView.builder($_ab);',
      'ListView.separated': 'widget root = ListView.separated($_ab, separatorBuilder: (m) => Divider());',
      'GridView.builder': 'widget root = GridView.builder($_ab);',
      'PageView.builder': 'widget root = PageView.builder($_ab, viewportFraction: 0.5, padEnds: false);',
      'SliverList.builder': 'widget root = CustomScrollView(slivers: [SliverList.builder($_ab)]);',
      'SliverList.separated': 'widget root = CustomScrollView(slivers: [SliverList.separated($_ab, separatorBuilder: (m) => Divider())]);',
      'SliverGrid.builder': 'widget root = CustomScrollView(slivers: [SliverGrid.builder($_ab)]);',
    };
    for (final MapEntry<String, String> e in each.entries) {
      testWidgets('${e.key} builds each item through itemBuilder', (WidgetTester tester) async {
        await _mount(tester, e.value);
        expect(tester.takeException(), isNull);
        expect(find.text('a'), findsOneWidget);
        expect(find.text('b'), findsOneWidget);
      });
    }

    testWidgets('an item that is a string is read whole', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView.builder(items: ["x", "y"], itemBuilder: (s) => Text(text: s));');
      expect(find.text('x'), findsOneWidget);
      expect(find.text('y'), findsOneWidget);
    });

    testWidgets('itemCount alone gives each row its index', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = ListView.builder(itemCount: 3, itemBuilder: (i) => Text(text: switch i { 0: "zero", 1: "one", 2: "two" }));
      ''');
      expect(find.text('zero'), findsOneWidget);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('itemCount caps the items', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView.builder(items: ["p", "q", "r"], itemCount: 2, itemBuilder: (s) => Text(text: s));');
      expect(find.text('p'), findsOneWidget);
      expect(find.text('q'), findsOneWidget);
      expect(find.text('r'), findsNothing);
    });

    testWidgets('items that are not a list give no rows', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView.builder(items: "x", itemBuilder: (s) => Text(text: "row"));');
      expect(tester.takeException(), isNull);
      expect(find.text('row'), findsNothing);
    });

    testWidgets('separatorBuilder gets the row above it', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = ListView.separated(items: ["a", "b"], itemBuilder: (s) => Text(text: s), separatorBuilder: (s) => Text(text: ["after ", s]));
      ''');
      expect(find.text('after a'), findsOneWidget);
      expect(find.text('after b'), findsNothing);
    });

    testWidgets('ten thousand items build only the rows on screen', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = ListView.builder(items: data.items, itemBuilder: (s) => SizedBox(height: 50, child: Text(text: s)));',
        data: DynamicContent(<String, Object?>{'items': <Object?>[for (int i = 0; i < 10000; i += 1) 'row $i']}),
      );
      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('row 9999'), findsNothing);
      expect(tester.widgetList(find.byType(Text)).length, lessThan(30));
    });

    testWidgets('the list may shrink and grow while scrolled', (WidgetTester tester) async {
      List<Object?> rows(int n) => <Object?>[for (int i = 0; i < n; i += 1) 'row $i'];
      final DynamicContent data = DynamicContent(<String, Object?>{'items': rows(100)});
      await _mount(tester, 'widget root = ListView.builder(items: data.items, itemBuilder: (s) => SizedBox(height: 50, child: Text(text: s)));', data: data);
      await tester.drag(find.byType(Scrollable), const Offset(0, -4000));
      await tester.pumpAndSettle();
      data.update('items', rows(10));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('row 9'), findsOneWidget);
      data.update('items', rows(200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('onEndReached fires once for each length of list', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'items': <Object?>['a', 'b']});
      final List<String> events = await _mount(
        tester,
        'widget root = ListView.builder(items: data.items, itemBuilder: (s) => Text(text: s), onEndReached: event "more" { });',
        data: data,
      );
      await tester.pump();
      expect(events, <String>['more']);
      data.update('items', <Object?>['a', 'b', 'c']);
      await tester.pump();
      await tester.pump();
      expect(events, <String>['more', 'more']);
    });

    testWidgets('itemBuilder reads args and data too', (WidgetTester tester) async {
      await _mount(
        tester,
        '''
          widget root = Rows(tag: "T");
          widget Rows = ListView.builder(items: data.items, itemBuilder: (s) => Text(text: [args.tag, s, data.suffix]));
        ''',
        data: DynamicContent(<String, Object?>{'items': <Object?>['a'], 'suffix': '!'}),
      );
      expect(find.text('Ta!'), findsOneWidget);
    });

    testWidgets('PageView.builder swipes to the next item', (WidgetTester tester) async {
      await _mount(tester, 'widget root = PageView.builder(items: ["first", "second"], itemBuilder: (s) => Center(child: Text(text: s)));');
      expect(find.text('first'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
    });
  }, skip: _onRfw);

  testWidgets('PageView with children shows its pages, swiping to the last', (WidgetTester tester) async {
    await _mount(tester, 'widget root = PageView(children: [Center(child: Text(text: "p1")), Center(child: Text(text: "p2"))]);');
    expect(find.text('p1'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('p2'), findsOneWidget);
  });

  testWidgets('on rfw\'s Runtime, a .builder widget says it needs UiRuntime', (WidgetTester tester) async {
    await _mount(tester, 'widget root = ListView.builder($_ab);');
    expect(tester.takeException().toString(), contains('ListView.builder needs UiRuntime'));
  }, skip: !_onRfw);
}
