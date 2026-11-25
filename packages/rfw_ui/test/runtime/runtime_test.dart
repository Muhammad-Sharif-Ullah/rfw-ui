import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);
const LibraryName _core = LibraryName(<String>['core']);
const LibraryName _test = LibraryName(<String>['test']);

/// How many times each `Count(id: ...)` has built.
final Map<String, int> _builds = <String, int>{};

/// Test widgets: `Count`, a text that counts its builds, and `Tap`, a box
/// whose handler a test calls with extra arguments.
LocalWidgetLibrary _testWidgets(List<VoidCallback> taps) => LocalWidgetLibrary(<String, LocalWidgetBuilder>{
  'Count': (BuildContext context, DataSource source) {
    final String id = source.v<String>(<Object>['id']) ?? '';
    _builds[id] = (_builds[id] ?? 0) + 1;
    return Text(source.v<String>(<Object>['text']) ?? '', textDirection: TextDirection.ltr);
  },
  'Tap': (BuildContext context, DataSource source) {
    final VoidCallback? onTap = source.voidHandler(<Object>['onTap'], <String, Object?>{'n': 9});
    if (onTap != null) {
      taps.add(onTap);
    }
    return const SizedBox.shrink();
  },
});

/// Mounts `root` of [source] on [runtime], with the core, kit and test
/// widgets, and returns the events it fires.
Future<List<(String, DynamicMap)>> _mount(
  WidgetTester tester,
  Runtime runtime,
  String source, {
  DynamicContent? data,
  List<VoidCallback>? taps,
}) async {
  runtime
    ..update(_core, createCoreWidgets())
    ..update(uiLibraryName, createUiWidgets())
    ..update(_test, _testWidgets(taps ?? <VoidCallback>[]))
    ..update(_main, parseLibraryFile(source));
  final List<(String, DynamicMap)> events = <(String, DynamicMap)>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RemoteWidget(
          runtime: runtime,
          data: data ?? DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
          onEvent: (String name, DynamicMap args) => events.add((name, args)),
        ),
      ),
    ),
  );
  return events;
}

List<String?> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((Text t) => t.data ?? t.textSpan?.toPlainText()).toList();

void main() {
  setUp(_builds.clear);

  test('createUiRuntime makes a UiRuntime, unless built with RFW_RUNTIME=rfw', () {
    final Runtime runtime = createUiRuntime();
    addTearDown(runtime.dispose);
    const bool rfw = String.fromEnvironment('RFW_RUNTIME') == 'rfw';
    expect(runtime, rfw ? isNot(isA<UiRuntime>()) : isA<UiRuntime>());
  });

  testWidgets('a screen of kit and remote widgets shows what it shows on rfw\'s Runtime', (WidgetTester tester) async {
    const String source = '''
      import ui;
      widget root = Column(children: [
        Text(text: "Title", style: .titleLarge),
        ...for item in data.items: Row(item: item),
        Card(child: ListTile(title: "Tile", subtitle: args.missing)),
      ]);
      widget Row = Padding(padding: .md, child: Text(text: args.item.name, style: { base: .bodySmall, color: .onSurfaceVariant }));
    ''';
    DynamicContent data() => DynamicContent(<String, Object?>{
      'items': <Object?>[<String, Object?>{'name': 'a'}, <String, Object?>{'name': 'b'}],
    });
    final Runtime rfw = Runtime();
    addTearDown(rfw.dispose);
    await _mount(tester, rfw, source, data: data());
    final List<String?> expected = _texts(tester);
    final List<TextStyle?> styles = tester.widgetList<Text>(find.byType(Text)).map((Text t) => t.style).toList();
    final UiRuntime ours = UiRuntime();
    addTearDown(ours.dispose);
    await _mount(tester, ours, source, data: data());
    expect(_texts(tester), expected);
    expect(tester.widgetList<Text>(find.byType(Text)).map((Text t) => t.style).toList(), styles);
    expect(expected, containsAll(<String>['Title', 'a', 'b', 'Tile']));
  });

  testWidgets('a data change rebuilds only the widget that read it', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    final DynamicContent data = DynamicContent(<String, Object?>{'a': 'one', 'b': 'two'});
    await _mount(tester, runtime, '''
      import core; import test;
      widget root = Column(children: [Count(id: "a", text: data.a), Count(id: "b", text: data.b), Count(id: "c", text: "fixed")]);
    ''', data: data);
    expect(_builds, <String, int>{'a': 1, 'b': 1, 'c': 1});
    data.update('a', 'uno');
    await tester.pump();
    expect(find.text('uno'), findsOneWidget);
    expect(_builds, <String, int>{'a': 2, 'b': 1, 'c': 1});
  });

  testWidgets('an event\'s arguments arrive as plain values, the extra ones over the written', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    final List<VoidCallback> taps = <VoidCallback>[];
    final List<(String, DynamicMap)> events = await _mount(tester, runtime, '''
      import core; import test;
      widget root = Column(children: [
        ...for item in data.items: Tap(onTap: event "x" { user: { id: item.id }, tags: [...for t in item.tags: t], n: 1, total: data.total }),
      ]);
    ''', data: DynamicContent(<String, Object?>{
      'total': 2,
      'items': <Object?>[<String, Object?>{'id': 'i1', 'tags': <Object?>['a', 'b']}],
    }), taps: taps);
    taps.single();
    expect(events, hasLength(1));
    expect(events.single.$1, 'x');
    expect(events.single.$2, <String, Object?>{
      'user': <String, Object?>{'id': 'i1'},
      'tags': <Object?>['a', 'b'],
      'n': 9,
      'total': 2,
    });
  });

  testWidgets('a list of handlers fires each, in order', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    final List<VoidCallback> taps = <VoidCallback>[];
    final List<(String, DynamicMap)> events = await _mount(tester, runtime, '''
      import core; import test;
      widget root = Tap(onTap: [event "a" { }, event "b" { k: 1 }]);
    ''', taps: taps);
    taps.single();
    expect(events.map(((String, DynamicMap) e) => e.$1), <String>['a', 'b']);
  });

  testWidgets('a widget that calls itself is an error, not a crash', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    await _mount(tester, runtime, 'import core; widget root = A(); widget A = B(); widget B = A();');
    expect(tester.takeException().toString(), contains('Widget loop: Tried to call main:A constructor reentrantly.'));
  });

  testWidgets('a missing widget gives rfw\'s message', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    await _mount(tester, runtime, 'import core; widget root = Nope();');
    expect(tester.takeException().toString(), 'Could not find remote widget named Nope in main.');
  });

  testWidgets('updating the library swaps what is mounted', (WidgetTester tester) async {
    final UiRuntime runtime = UiRuntime();
    addTearDown(runtime.dispose);
    await _mount(tester, runtime, 'import core; widget root = Text(text: "before", textDirection: "ltr");');
    expect(find.text('before'), findsOneWidget);
    runtime.update(_main, parseLibraryFile('import core; widget root = Text(text: "after", textDirection: "ltr");'));
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
    expect(find.text('before'), findsNothing);
  });
}
