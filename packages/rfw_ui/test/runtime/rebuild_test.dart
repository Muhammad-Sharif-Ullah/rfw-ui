import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// What UiRuntime keeps from one build to the next -- rows whose item is
/// unchanged, subtrees that read nothing that changes -- and that what it
/// keeps is never stale.
const LibraryName _main = LibraryName(<String>['main']);
const LibraryName _test = LibraryName(<String>['test']);

/// How many times each `Count(id: ...)` has built.
final Map<String, int> _builds = <String, int>{};

final LocalWidgetLibrary _testWidgets = LocalWidgetLibrary(<String, LocalWidgetBuilder>{
  'Count': (BuildContext context, DataSource source) {
    final String id = source.v<String>(<Object>['id']) ?? '';
    _builds[id] = (_builds[id] ?? 0) + 1;
    return Text(source.v<String>(<Object>['text']) ?? '');
  },
  // Not a kit widget: puts its child under a theme of its own.
  'Themed': (BuildContext context, DataSource source) => Theme(
    data: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF0000))),
    child: source.child(<Object>['child']),
  ),
});

Future<UiRuntime> _mount(WidgetTester tester, String source, {DynamicContent? data, ThemeData? theme}) async {
  final UiRuntime runtime = UiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_test, _testWidgets)
    ..update(_main, parseLibraryFile('import ui; import test;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: UiRemoteWidget(runtime: runtime, data: data ?? DynamicContent(), widget: const FullyQualifiedWidgetName(_main, 'root')),
      ),
    ),
  );
  return runtime;
}

List<Object?> _items(int n, {int? changed, String tag = ''}) => <Object?>[
  for (int i = 0; i < n; i += 1)
    <String, Object?>{
      'id': 'r$i',
      'title': i == changed ? 'Changed' : 'Item $i$tag',
      'user': <String, Object?>{'name': 'someone', 'tags': <Object?>['a', 'b']},
    },
];

final ThemeData _blue = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0000FF)));
final ThemeData _green = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00FF00)));

void main() {
  setUp(_builds.clear);

  testWidgets('changing one item rebuilds that row only, nested maps and all', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(5)});
    await _mount(tester, 'widget root = Column(children: [...for i in data.items: Count(id: i.id, text: i.title)]);', data: data);
    expect(_builds.values, everyElement(1));
    data.update('items', _items(5, changed: 2));
    await tester.pump();
    expect(find.text('Changed'), findsOneWidget);
    expect(_builds, <String, int>{'r0': 1, 'r1': 1, 'r2': 2, 'r3': 1, 'r4': 1});
  });

  testWidgets('a kept row still shows a change to data outside its item', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(3), 'selected': 'none'});
    await _mount(tester, 'widget root = Column(children: [...for i in data.items: Count(id: i.id, text: data.selected)]);', data: data);
    data.update('items', _items(3, changed: 1));
    await tester.pump();
    data.update('selected', 'r1');
    await tester.pump();
    expect(find.text('r1'), findsNWidgets(3));
    expect(find.text('none'), findsNothing);
  });

  testWidgets('two copies of one widget keep their own rows', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(3)});
    await _mount(tester, '''
      widget root = Column(children: [Rows(tag: "x"), Rows(tag: "y")]);
      widget Rows = Column(children: [...for i in data.items: Text(text: args.tag)]);
    ''', data: data);
    data.update('items', _items(3, changed: 0));
    await tester.pump();
    data.update('items', _items(3, changed: 1));
    await tester.pump();
    expect(find.text('x'), findsNWidgets(3));
    expect(find.text('y'), findsNWidgets(3));
  });

  testWidgets('a row whose widget comes from a switch on data is not kept past that data', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(2), 'mode': 'a'});
    await _mount(tester, '''
      widget root = Column(children: [...for i in data.items: switch data.mode { "a": Text(text: "A"), "b": Text(text: "B") }]);
    ''', data: data);
    expect(find.text('A'), findsNWidgets(2));
    data.update('mode', 'b');
    await tester.pump();
    expect(find.text('B'), findsNWidgets(2));
  });

  testWidgets('a subtree that reads nothing that changes is built once', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(2)});
    await _mount(tester, '''
      widget root = Column(children: [Count(id: "fixed", text: "fixed"), ...for i in data.items: Count(id: i.id, text: i.title)]);
    ''', data: data);
    for (int n = 3; n <= 5; n += 1) {
      data.update('items', _items(n));
      await tester.pump();
    }
    expect(_builds['fixed'], 1);
    expect(find.text('Item 4'), findsOneWidget);
  });

  testWidgets('a new theme reaches kept rows and kept subtrees', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': _items(2)});
    const String source = '''
      widget root = Column(children: [
        Text(text: "fixed", style: { color: .primary }),
        ...for i in data.items: Text(text: i.title, style: { color: .primary }),
      ]);
    ''';
    await _mount(tester, source, data: data, theme: _blue);
    Color? color(String text) => tester.widget<Text>(find.text(text)).style?.color;
    expect(color('fixed'), _blue.colorScheme.primary);
    await _mount(tester, source, data: data, theme: _green);
    await tester.pumpAndSettle();
    expect(color('fixed'), _green.colorScheme.primary);
    expect(color('Item 1'), _green.colorScheme.primary);
  });

  testWidgets('a kit widget under a local widget\'s own theme reads that theme', (WidgetTester tester) async {
    await _mount(tester, 'widget root = Themed(child: Text(text: "inside", style: { color: .primary }));', theme: _blue);
    final ThemeData red = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF0000)));
    expect(tester.widget<Text>(find.text('inside')).style?.color, red.colorScheme.primary);
  });

  testWidgets('updating the library drops what was kept', (WidgetTester tester) async {
    final UiRuntime runtime = await _mount(tester, 'widget root = Column(children: [Count(id: "c", text: "one")]);');
    runtime.update(_main, parseLibraryFile('import ui; import test;\nwidget root = Column(children: [Count(id: "c", text: "two")]);'));
    await tester.pump();
    expect(find.text('two'), findsOneWidget);
  });
}
