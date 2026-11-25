import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

Future<DynamicContent> _pump(WidgetTester tester, String source, {Map<String, Object?> data = const <String, Object?>{}}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  final DynamicContent content = DynamicContent(data);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(runtime: runtime, data: content, widget: const FullyQualifiedWidgetName(_main, 'root')),
      ),
    ),
  );
  await tester.pump();
  return content;
}

/// The text in the field labelled [label].
String _text(WidgetTester tester, String label) =>
    tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

FocusNode _focusOf(WidgetTester tester, String label) =>
    tester.widget<TextField>(find.widgetWithText(TextField, label)).focusNode!;

void main() {
  group('key', () {
    const String rows = '''
      widget root = Column(children: [
        ...for item in data.items:
          TextField(KEY decoration: { labelText: item.id }),
      ]);
    ''';
    const Map<String, Object?> ab = <String, Object?>{
      'items': <Object?>[
        <String, Object?>{'id': 'a'},
        <String, Object?>{'id': 'b'},
      ],
    };
    const List<Object?> ba = <Object?>[
      <String, Object?>{'id': 'b'},
      <String, Object?>{'id': 'a'},
    ];

    testWidgets('moves a row\'s state with its item when the list reorders', (WidgetTester tester) async {
      final DynamicContent data = await _pump(tester, rows.replaceFirst('KEY', 'key: item.id,'), data: ab);
      await tester.enterText(find.widgetWithText(TextField, 'a'), 'typed into a');
      data.update('items', ba);
      await tester.pump();
      expect(_text(tester, 'a'), 'typed into a');
      expect(_text(tester, 'b'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without one, the state stays where it was -- which is why keys exist', (WidgetTester tester) async {
      final DynamicContent data = await _pump(tester, rows.replaceFirst('KEY', ''), data: ab);
      await tester.enterText(find.widgetWithText(TextField, 'a'), 'typed into a');
      data.update('items', ba);
      await tester.pump();
      expect(_text(tester, 'b'), 'typed into a');
    });

    testWidgets('a new key is a fresh widget', (WidgetTester tester) async {
      final DynamicContent data = await _pump(
        tester,
        'widget root = TextField(key: data.form, decoration: { labelText: "name" });',
        data: <String, Object?>{'form': 'first'},
      );
      await tester.enterText(find.byType(TextField), 'Ada');
      data.update('form', 'second');
      await tester.pump();
      expect(_text(tester, 'name'), isEmpty);
    });

    testWidgets('a list key is joined, and a test can find it', (WidgetTester tester) async {
      await _pump(tester, 'widget root = Text(key: ["row-", data.id], text: "x");', data: <String, Object?>{'id': 7});
      expect(find.byWidgetPredicate((Widget w) => UiKey.matches(w.key, 'row-7')), findsOneWidget);
    });

    testWidgets('a dialog may reuse a name the screen under it uses', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextField(key: "name"),
          TextButton(child: "open", onPressed: event "ui.dialog" { widget: "Ask" }),
        ]);
        widget Ask = AlertDialog(content: TextField(key: "name"));
      ''');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('focus', () {
    testWidgets('"next" on the keyboard moves to the next field by itself', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextField(decoration: { labelText: "email" }, textInputAction: "next"),
          TextField(decoration: { labelText: "password" }),
        ]);
      ''');
      await tester.tap(find.widgetWithText(TextField, 'email'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focusOf(tester, 'password').hasFocus, isTrue);
    });

    testWidgets('ui.focus sends "next" to the field it names', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextField(decoration: { labelText: "email" }, textInputAction: "next",
            onSubmitted: event "ui.focus" { key: "code" }),
          TextField(decoration: { labelText: "name" }),
          TextField(key: "code", decoration: { labelText: "code" }),
        ]);
      ''');
      await tester.tap(find.widgetWithText(TextField, 'email'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focusOf(tester, 'code').hasFocus, isTrue);
      expect(_focusOf(tester, 'name').hasFocus, isFalse);
    });

    testWidgets('ui.focus reaches a widget that is not a field', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextButton(child: "go", onPressed: event "ui.focus" { key: "save" }),
          FilledButton(key: "save", child: "Save", onPressed: event "save" { }),
        ]);
      ''');
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(Focus.of(tester.element(find.text('Save'))).hasFocus, isTrue);
    });

    testWidgets('ui.unfocus takes the focus away', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextField(decoration: { labelText: "email" }, textInputAction: "done", onSubmitted: event "ui.unfocus" { }),
        ]);
      ''');
      await tester.tap(find.widgetWithText(TextField, 'email'));
      await tester.pump();
      expect(_focusOf(tester, 'email').hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(_focusOf(tester, 'email').hasFocus, isFalse);
    });

    testWidgets('ui.focusNext and ui.focusPrevious walk the order', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = Column(children: [
          TextField(key: "a", decoration: { labelText: "a" }),
          TextField(key: "b", decoration: { labelText: "b" }),
          TextButton(child: "next", onPressed: event "ui.focusNext" { }),
          TextButton(child: "previous", onPressed: event "ui.focusPrevious" { }),
        ]);
      ''');
      await tester.tap(find.widgetWithText(TextField, 'a'));
      await tester.pump();
      // A tap on a button does not take the focus from a field on a phone,
      // so the action works from what has it.
      await tester.tap(find.text('next'));
      await tester.pump();
      expect(_focusOf(tester, 'b').hasFocus, isTrue);
      await tester.tap(find.text('previous'));
      await tester.pump();
      expect(_focusOf(tester, 'a').hasFocus, isTrue);
    });

    testWidgets('an ordered group follows its order, not the layout', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = FocusTraversalGroup(policy: "ordered", child: Column(children: [
          FocusTraversalOrder(order: 1, child: TextField(decoration: { labelText: "first" }, textInputAction: "next")),
          FocusTraversalOrder(order: 3, child: TextField(decoration: { labelText: "third" })),
          FocusTraversalOrder(order: 2, child: TextField(decoration: { labelText: "second" })),
        ]));
      ''');
      await tester.tap(find.widgetWithText(TextField, 'first'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focusOf(tester, 'second').hasFocus, isTrue);
    });
  });

  testWidgets('ui.scrollTo brings a keyed widget into view', (WidgetTester tester) async {
    await _pump(tester, '''
      widget root = Column(children: [
        TextButton(child: "jump", onPressed: event "ui.scrollTo" { key: "row-39" }),
        Expanded(child: SingleChildScrollView(child: Column(children: [
          ...for item in data.items:
            SizedBox(key: ["row-", item], height: 100, child: Text(text: ["row ", item])),
        ]))),
      ]);
    ''', data: <String, Object?>{'items': <Object?>[for (int i = 0; i < 40; i += 1) '$i']});
    final Rect screen = Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(screen.contains(tester.getCenter(find.text('row 39'))), isFalse);
    await tester.tap(find.text('jump'));
    await tester.pumpAndSettle();
    expect(screen.contains(tester.getCenter(find.text('row 39'))), isTrue);
  });
}
