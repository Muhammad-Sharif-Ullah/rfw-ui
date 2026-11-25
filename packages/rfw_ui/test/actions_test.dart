import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart' hide Switch;
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

/// A remote file on screen under a [UiRemoteWidget], with every app-level
/// event it fires recorded.
class _Harness {
  _Harness(this.store, this.events);

  final UiStore store;
  final List<(String, DynamicMap)> events;
}

Future<_Harness> _pump(WidgetTester tester, String source, {UiThemeController? theme}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  final DynamicContent data = DynamicContent();
  final UiStore store = UiStore(data);
  final List<(String, DynamicMap)> events = <(String, DynamicMap)>[];
  final Widget screen = MaterialApp(
    home: Scaffold(
      body: UiRemoteWidget(
        runtime: runtime,
        data: data,
        store: store,
        widget: const FullyQualifiedWidgetName(_main, 'root'),
        onEvent: (String name, DynamicMap args) => events.add((name, args)),
      ),
    ),
  );
  await tester.pumpWidget(theme == null ? screen : UiTheme(controller: theme, child: screen));
  await tester.pump();
  return _Harness(store, events);
}

void main() {
  testWidgets('ui.set binds a text field to the data a Text reads', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = Column(children: [
        TextField(onChanged: event "ui.set" { key: "form.email" }),
        Text(text: ["You typed: ", data.form.email]),
      ]);
    ''');
    await tester.enterText(find.byType(TextField), 'ada@example.com');
    await tester.pump();
    expect(find.text('You typed: ada@example.com'), findsOneWidget);
    expect(h.store.get('form.email'), 'ada@example.com');
    expect(h.events, isEmpty, reason: 'ui.* events are the kit\'s, not the app\'s');
  });

  testWidgets('a switch bound with ui.set moves, and what it says is in the data', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = Column(children: [
        Switch(value: data.wifi, onChanged: event "ui.set" { key: "wifi" }),
        Text(text: switch data.wifi { true: "on", default: "off" }),
      ]);
    ''');
    expect(find.text('off'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('on'), findsOneWidget);
    expect(h.store.get('wifi'), true);
  });

  testWidgets('ui.toggle flips a value', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = TextButton(child: "flip", onPressed: event "ui.toggle" { key: "open" });
    ''');
    await tester.tap(find.text('flip'));
    expect(h.store.get('open'), true);
    await tester.tap(find.text('flip'));
    expect(h.store.get('open'), false);
  });

  testWidgets('ui.dialog shows a widget of the file with args, and ui.pop answers it', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget Confirm = AlertDialog(
        title: args.title,
        actions: [
          TextButton(child: "No", onPressed: event "ui.pop" {}),
          FilledButton(child: "Yes", onPressed: event "ui.pop" { result: "yes" }),
        ],
      );
      widget root = FilledButton(
        child: "Open",
        onPressed: event "ui.dialog" { widget: "Confirm", args: { title: "Delete it?" }, key: "answer", onResult: "answered" },
      );
    ''');
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete it?'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Delete it?'), findsNothing);
    expect(h.store.get('answer'), 'yes');
    expect(h.events, hasLength(1));
    expect(h.events.single.$1, 'answered');
    expect(h.events.single.$2['value'], 'yes');
  });

  testWidgets('a dismissed dialog answers nothing', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget Confirm = AlertDialog(title: "Sure?", actions: [TextButton(child: "No", onPressed: event "ui.pop" {})]);
      widget root = FilledButton(child: "Open", onPressed: event "ui.dialog" { widget: "Confirm", onResult: "answered" });
    ''');
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(h.events, isEmpty);
  });

  testWidgets('a dialog sees the same data, and can open a sheet of its own', (WidgetTester tester) async {
    await _pump(tester, '''
      widget Sheet = Padding(padding: "lg", child: Text(text: ["Sheet for ", data.user]));
      widget Dialog1 = AlertDialog(
        title: data.user,
        actions: [TextButton(child: "More", onPressed: event "ui.bottomSheet" { widget: "Sheet" })],
      );
      widget root = Column(children: [
        TextButton(child: "Name", onPressed: event "ui.set" { key: "user", value: "Ada" }),
        TextButton(child: "Open", onPressed: event "ui.dialog" { widget: "Dialog1" }),
      ]);
    ''');
    await tester.tap(find.text('Name'));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet for Ada'), findsOneWidget);
  });

  testWidgets('ui.bottomSheet slides a widget up', (WidgetTester tester) async {
    await _pump(tester, '''
      widget Share = Column(mainAxisSize: "min", children: [ListTile(title: "Copy link", leading: "link")]);
      widget root = TextButton(child: "Share", onPressed: event "ui.bottomSheet" { widget: "Share", showDragHandle: true });
    ''');
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('ui.cupertinoModal and ui.cupertinoDialog show iOS surfaces', (WidgetTester tester) async {
    await _pump(tester, '''
      widget Sheet = CupertinoActionSheet(title: "Share", actions: [CupertinoActionSheetAction(child: "Mail", onPressed: event "ui.pop" {})]);
      widget Alert = CupertinoAlertDialog(title: "Allow?", actions: [CupertinoDialogAction(child: "OK", onPressed: event "ui.pop" {})]);
      widget root = Column(children: [
        TextButton(child: "sheet", onPressed: event "ui.cupertinoModal" { widget: "Sheet" }),
        TextButton(child: "alert", onPressed: event "ui.cupertinoDialog" { widget: "Alert" }),
      ]);
    ''');
    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Mail'), findsOneWidget);
    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('alert'));
    await tester.pumpAndSettle();
    expect(find.text('Allow?'), findsOneWidget);
  });

  testWidgets('every modal is in the theme of what opened it, Cupertino ones too', (WidgetTester tester) async {
    // Material's dialog and sheet carry the opener's themes into their route;
    // the Cupertino ones do not, and would show in the app's theme instead.
    final ThemeData page = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)));
    final Runtime runtime = createUiRuntime()
      ..update(uiLibraryName, createUiWidgets())
      ..update(_main, parseLibraryFile('''
        import ui;
        widget Sheet = CupertinoActionSheet(title: "Share", actions: [CupertinoActionSheetAction(child: "Mail", onPressed: event "ui.pop" {})]);
        widget Alert = CupertinoAlertDialog(title: "Allow?", actions: [CupertinoDialogAction(child: "OK", onPressed: event "ui.pop" {})]);
        widget root = Column(children: [
          TextButton(child: "sheet", onPressed: event "ui.cupertinoModal" { widget: "Sheet" }),
          TextButton(child: "alert", onPressed: event "ui.cupertinoDialog" { widget: "Alert" }),
        ]);
      '''));
    addTearDown(runtime.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8BFF3C), brightness: Brightness.dark)),
        home: Scaffold(
          body: ScopedTheme(
            data: page,
            child: UiRemoteWidget(
              runtime: runtime,
              data: DynamicContent(),
              widget: const FullyQualifiedWidgetName(_main, 'root'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(CupertinoTheme.of(tester.element(find.text('Mail'))).primaryColor, page.colorScheme.primary);
    expect(CupertinoTheme.brightnessOf(tester.element(find.text('Mail'))), Brightness.light);
    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('alert'));
    await tester.pumpAndSettle();
    expect(CupertinoTheme.of(tester.element(find.text('OK'))).primaryColor, page.colorScheme.primary);
  });

  testWidgets('ui.snackBar shows a message whose action fires an event', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = TextButton(child: "Archive", onPressed: event "ui.snackBar" {
        message: "Archived", actionLabel: "Undo", onAction: "unarchive", actionArgs: { id: 7 },
      });
    ''');
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(h.events.single.$1, 'unarchive');
    expect(h.events.single.$2['id'], 7);
  });

  testWidgets('ui.pickDate writes the chosen date as YYYY-MM-DD', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = TextButton(child: "Pick", onPressed: event "ui.pickDate" {
        initial: "2026-10-23", first: "2026-01-01", last: "2026-12-31", key: "when",
      });
    ''');
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(h.store.get('when'), '2026-10-23');
  });

  testWidgets('ui.pickTime writes HH:mm', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = TextButton(child: "Pick", onPressed: event "ui.pickTime" { initial: "09:05", key: "at" });
    ''');
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(h.store.get('at'), '09:05');
  });

  testWidgets('ui.themeMode toggles the controller above the app', (WidgetTester tester) async {
    final UiThemeController theme = UiThemeController(mode: ThemeMode.light);
    await _pump(tester, '''
      widget root = TextButton(child: "Dark", onPressed: event "ui.themeMode" { mode: "toggle" });
    ''', theme: theme);
    await tester.tap(find.text('Dark'));
    expect(theme.mode, ThemeMode.dark);
  });

  testWidgets('every other event reaches the app as rfw would deliver it', (WidgetTester tester) async {
    final _Harness h = await _pump(tester, '''
      widget root = Column(children: [
        TextButton(child: "Go", onPressed: event "login" { method: "email" }),
        TextButton(child: "Future", onPressed: event "ui.somethingNew" { x: 1 }),
      ]);
    ''');
    await tester.tap(find.text('Go'));
    await tester.tap(find.text('Future'));
    expect(h.events.map(((String, DynamicMap) e) => e.$1), <String>['login', 'ui.somethingNew']);
    expect(h.events.first.$2['method'], 'email');
  });

  testWidgets('ui.haptic calls the platform channel', (WidgetTester tester) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(tester, '''
      widget root = Row(children: [
        TextButton(child: "Tap", onPressed: event "ui.haptic" { }),
        TextButton(child: "Buzz", onPressed: event "ui.haptic" { type: "vibrate" }),
        TextButton(child: "Pick", onPressed: event "ui.haptic" { type: "selection" }),
      ]);
    ''');
    await tester.tap(find.text('Tap'));
    await tester.tap(find.text('Buzz'));
    await tester.tap(find.text('Pick'));
    await tester.pump();
    expect(
      calls.where((MethodCall c) => c.method.startsWith('HapticFeedback')).map((MethodCall c) => '${c.method}:${c.arguments}'),
      <String>[
        'HapticFeedback.vibrate:HapticFeedbackType.lightImpact',
        'HapticFeedback.vibrate:null',
        'HapticFeedback.vibrate:HapticFeedbackType.selectionClick',
      ],
    );
  });

  test('the store writes nested paths and removes on null', () {
    final UiStore store = UiStore(DynamicContent());
    store.set('form.email', 'a@b.c');
    store.set('form.name', 'Ada');
    expect(store.get('form.email'), 'a@b.c');
    expect(store.get('form'), <String, Object?>{'email': 'a@b.c', 'name': 'Ada'});
    store.set('items', <Object?>[<String, Object?>{'done': false}]);
    store.set('items.0.done', true);
    expect(store.get('items.0.done'), true);
    store.set('form.email', null);
    expect(store.get('form'), <String, Object?>{'name': 'Ada'});
    store.set('form', null);
    expect(store.get('form'), isNull);
  });

  test('every action is documented', () {
    final Set<String> names = <String>{};
    for (final UiAction action in uiActions) {
      expect(action.name, startsWith('ui.'));
      expect(names.add(action.name), isTrue, reason: '${action.name} twice');
      expect(action.doc.trim(), isNotEmpty);
    }
  });
}
