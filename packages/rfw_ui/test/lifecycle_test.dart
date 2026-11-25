import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

/// What the kit creates for a remote screen, and that it all goes away again.
///
/// These run under the leak tracker (test/flutter_test_config.dart): a focus
/// node, text controller, page or scroll controller left undisposed by any
/// of them fails the test. What they check besides is that nothing the kit
/// keeps grows with use.
void main() {
  // Every widget that owns something disposable, on one screen.
  const String everything = '''
    widget root = Column(children: [
      TextField(key: "a", decoration: { labelText: "a" }),
      CupertinoTextField(key: "b", placeholder: "b"),
      CupertinoSearchTextField(placeholder: "c"),
      SearchBar(key: "d", hintText: "d"),
      Switch(value: data.on, onChanged: event "ui.set" { key: "on" }),
      SizedBox(height: 80, child: PageView(children: [Text(text: "1"), Text(text: "2")])),
      SizedBox(height: 120, child: CupertinoPicker(itemExtent: 32, children: [Text(text: "x"), Text(text: "y")])),
      TextButton(child: "open", onPressed: event "ui.dialog" { widget: "Nested", args: { depth: 1 } }),
    ]);
    widget Nested = AlertDialog(
      content: TextField(key: "a", decoration: { labelText: ["in dialog ", args.depth] }),
      actions: [
        TextButton(child: "deeper", onPressed: event "ui.dialog" { widget: "Nested", args: { depth: 2 } }),
        TextButton(child: "close", onPressed: event "ui.pop" { }),
      ],
    );
  ''';

  Runtime runtimeFor(String source) {
    final Runtime runtime = createUiRuntime()
      ..update(uiLibraryName, createUiWidgets())
      ..update(_main, parseLibraryFile('import ui;\n$source'));
    addTearDown(runtime.dispose);
    return runtime;
  }

  Widget screen(Runtime runtime, DynamicContent data) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: UiRemoteWidget(runtime: runtime, data: data, widget: const FullyQualifiedWidgetName(_main, 'root')),
      ),
    ),
  );

  testWidgets('a screen mounted and taken down twenty times leaves nothing behind', (WidgetTester tester) async {
    final Runtime runtime = runtimeFor(everything);
    for (int i = 0; i < 20; i += 1) {
      await tester.pumpWidget(screen(runtime, DynamicContent()));
      await tester.enterText(find.widgetWithText(TextField, 'a'), 'typed $i');
      await tester.pumpWidget(const SizedBox());
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('fifty dialogs, opened and closed, never touch the screen\'s runtime', (WidgetTester tester) async {
    final Runtime runtime = runtimeFor(everything);
    await tester.pumpWidget(screen(runtime, DynamicContent()));
    final int before = runtime.libraries.length;
    int notified = 0;
    void heard() => notified += 1;
    runtime.addListener(heard);
    addTearDown(() => runtime.removeListener(heard));
    for (int i = 0; i < 50; i += 1) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('deeper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
    }
    // A notification is a rebuild of every remote widget on the screen,
    // behind the dialog. Modals are registered on a runtime of their own.
    expect(notified, 0);
    expect(runtime.libraries.length, before);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an edit to the screen\'s library reaches a dialog that is open', (WidgetTester tester) async {
    final Runtime runtime = runtimeFor('''
      widget root = TextButton(child: "open", onPressed: event "ui.dialog" { widget: "Note" });
      widget Note = AlertDialog(content: Text(text: "first"));
    ''');
    await tester.pumpWidget(screen(runtime, DynamicContent()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
    runtime.update(_main, parseLibraryFile('''
      import ui;
      widget root = TextButton(child: "open", onPressed: event "ui.dialog" { widget: "Note" });
      widget Note = AlertDialog(content: Text(text: "second"));
    '''));
    await tester.pump();
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('a thousand writes to one key keep one value', (WidgetTester tester) async {
    final Runtime runtime = runtimeFor('widget root = Text(text: data.form.name);');
    final DynamicContent data = DynamicContent();
    final UiStore store = UiStore(data);
    await tester.pumpWidget(
      MaterialApp(
        home: UiRemoteWidget(runtime: runtime, data: data, store: store, widget: const FullyQualifiedWidgetName(_main, 'root')),
      ),
    );
    for (int i = 0; i < 1000; i += 1) {
      store.set('form.name', 'name $i');
    }
    await tester.pump();
    expect(find.text('name 999'), findsOneWidget);
    expect(store.get('form'), <String, Object?>{'name': 'name 999'});
  });

  // The one thing that does grow, and is documented as growing: the store
  // keeps a copy of everything it has written until the screen goes.
  test('the store keeps every distinct key it is given', () {
    final UiStore store = UiStore(DynamicContent());
    for (int i = 0; i < 1000; i += 1) {
      store.set('rows.$i', i);
    }
    expect((store.get('rows')! as Map<String, Object?>).length, 1000);
    store.set('rows', null);
    expect(store.get('rows'), isNull);
  });

  group('what rebuilds', () {
    // Counted by a widget whose builder notes each build.
    int builds = 0;
    const LibraryName probe = LibraryName(<String>['probe']);
    Runtime counted(String source) {
      final Runtime runtime = createUiRuntime()
        ..update(uiLibraryName, createUiWidgets())
        ..update(probe, LocalWidgetLibrary(<String, LocalWidgetBuilder>{
          'Counted': (BuildContext context, DataSource source) {
            builds += 1;
            return const SizedBox(height: 10);
          },
        }))
        ..update(_main, parseLibraryFile('import ui;\nimport probe;\n$source'));
      addTearDown(runtime.dispose);
      return runtime;
    }

    const String rows = '''
      widget root = Column(children: [
        ...for item in data.items: FeedRow(title: item.title),
      ]);
      widget FeedRow { liked: false } = Column(children: [
        Counted(),
        TextButton(
          child: Text(text: switch state.liked { true: ["liked ", args.title], default: ["like ", args.title] }),
          onPressed: set state.liked = true,
        ),
      ]);
    ''';

    List<Object?> items(String tag) => <Object?>[
      for (int i = 0; i < 20; i += 1) <String, Object?>{'title': 'row $i$tag'},
    ];

    testWidgets('a row\'s own state rebuilds that row alone', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'items': items('')});
      await tester.pumpWidget(MaterialApp(
        home: SingleChildScrollView(
          child: UiRemoteWidget(runtime: counted(rows), data: data, widget: const FullyQualifiedWidgetName(_main, 'root')),
        ),
      ));
      builds = 0;
      await tester.tap(find.text('like row 3'));
      await tester.pump();
      expect(find.text('liked row 3'), findsOneWidget);
      expect(builds, lessThanOrEqualTo(1));
    });

    // rfw's Runtime copies every row again when the list changes. UiRuntime
    // keeps each row whose item is unchanged, and Counted(), which reads
    // nothing that changes, is built once: no row's Counted builds again.
    testWidgets('a change to one item of the list rebuilds every row on rfw\'s Runtime, none on UiRuntime', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'items': items('')});
      await tester.pumpWidget(MaterialApp(
        home: SingleChildScrollView(
          child: UiRemoteWidget(runtime: counted(rows), data: data, widget: const FullyQualifiedWidgetName(_main, 'root')),
        ),
      ));
      builds = 0;
      data.update('items', <Object?>[<String, Object?>{'title': 'row 0 changed'}, ...items('').skip(1)]);
      await tester.pump();
      expect(find.text('like row 0 changed'), findsOneWidget);
      expect(builds, const String.fromEnvironment('RFW_RUNTIME') == 'rfw' ? 20 : 0);
    });
  });
}
