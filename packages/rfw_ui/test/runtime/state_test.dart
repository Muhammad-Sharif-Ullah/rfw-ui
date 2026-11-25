import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart' show forceGC;
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

Future<UiRuntime> _mount(WidgetTester tester, String source, {DynamicContent? data}) async {
  final UiRuntime runtime = UiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RemoteWidget(runtime: runtime, data: data ?? DynamicContent(), widget: const FullyQualifiedWidgetName(_main, 'root')),
      ),
    ),
  );
  return runtime;
}

void main() {
  testWidgets('set state changes what reads it', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root { on: false } = GestureDetector(onTap: set state.on = true, child: Text(text: switch state.on { true: "on", false: "off" }));
    ''');
    expect(find.text('off'), findsOneWidget);
    await tester.tap(find.text('off'));
    await tester.pump();
    expect(find.text('on'), findsOneWidget);
  });

  testWidgets('set state in a widget without state reaches the nearest one that has it', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root { n: 0 } = Column(children: [Button(), Text(text: switch state.n { 0: "zero", 1: "one" })]);
      widget Button = GestureDetector(onTap: set state.n = 1, child: Text(text: "tap"));
    ''');
    await tester.tap(find.text('tap'));
    await tester.pump();
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('set state works inside a builder', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root { n: 0 } = LayoutBuilder(builder: (size) => GestureDetector(
        onTap: set state.n = 1,
        child: Text(text: switch state.n { 0: "zero", 1: "one" }),
      ));
    ''');
    await tester.tap(find.text('zero'));
    await tester.pump();
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('a list row keeps its state through a data change that keeps the row', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'items': <Object?>['a', 'b']});
    await _mount(tester, '''
      widget root = Column(children: [...for i in data.items: Cell(label: i)]);
      widget Cell { open: false } = GestureDetector(onTap: set state.open = true, child: Text(text: switch state.open { true: "open", false: args.label }));
    ''', data: data);
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(find.text('open'), findsOneWidget);
    data.update('items', <Object?>['a', 'b', 'c']);
    await tester.pump();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('state starts afresh when the library is updated', (WidgetTester tester) async {
    const String source = '''
      widget root { on: false } = GestureDetector(onTap: set state.on = true, child: Text(text: switch state.on { true: "on", false: "off" }));
    ''';
    final UiRuntime runtime = await _mount(tester, source);
    await tester.tap(find.text('off'));
    await tester.pump();
    expect(find.text('on'), findsOneWidget);
    runtime.update(_main, parseLibraryFile('import ui;\n$source'));
    await tester.pump();
    expect(find.text('off'), findsOneWidget);
  });

  testWidgets('setting state that does not exist is rfw\'s error', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root { on: false } = GestureDetector(onTap: set state.nope = true, child: Text(text: "tap"));
    ''');
    await tester.tap(find.text('tap'));
    await tester.pump();
    expect(tester.takeException(), isA<RemoteFlutterWidgetsException>().having((RemoteFlutterWidgetsException e) => e.message, 'message', 'nope does not identify existing state.'));
  });

  testWidgets('a widget with state that has gone is let go of, though it read data', (WidgetTester tester) async {
    final DynamicContent data = DynamicContent(<String, Object?>{'show': true, 'label': 'x'});
    await _mount(tester, '''
      widget root = Column(children: [switch data.show { true: Cell(), false: Text(text: "gone") }]);
      widget Cell { open: false } = switch data.label { "x": Text(text: "x"), default: Text(text: "?") };
    ''', data: data);
    expect(find.text('x'), findsOneWidget);
    final WeakReference<State<StatefulWidget>> cell = _stateOf(tester, 'Cell');
    data.update('show', false);
    await tester.pump();
    expect(find.text('gone'), findsOneWidget);
    await tester.runAsync(() => forceGC(fullGcCycles: 3));
    expect(cell.target, isNull);
  });
}

/// The state of the widget with state named [name], held weakly.
WeakReference<State<StatefulWidget>> _stateOf(WidgetTester tester, String name) {
  final StatefulElement element = tester.element(find.byElementPredicate((Element e) => e.widget.toStringShort() == name)) as StatefulElement;
  return WeakReference<State<StatefulWidget>>(element.state);
}
