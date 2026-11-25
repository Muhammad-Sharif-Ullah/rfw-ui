import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The Material widgets a complex screen asks for by name.
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

void main() {
  setUp(_events.clear);

  testWidgets('ToggleButtons reports the index pressed', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = ToggleButtons(
        isSelected: [true, false, false],
        borderRadius: 8,
        onPressed: event "picked" { },
        children: [Text(text: "Day"), Text(text: "Week"), Text(text: "Month")],
      );
    ''');
    expect(_inScreen(ToggleButtons), findsOneWidget);
    expect(tester.widget<ToggleButtons>(_inScreen(ToggleButtons)).isSelected, <bool>[true, false, false]);
    await tester.tap(find.text('Week'));
    expect(_names, <String>['picked']);
    expect(_events.single.$2['value'], 1);
  });

  testWidgets('CarouselView lays its children out along the scroll axis', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = SizedBox(height: 200, child: CarouselView(
        itemExtent: 180,
        itemSnapping: true,
        onTap: event "opened" { },
        children: [...for n in data.items: ColoredBox(color: .primary, child: Center(child: Text(text: n)))],
      ));
    ''', data: DynamicContent(<String, Object?>{'items': <Object?>['one', 'two', 'three', 'four']}));
    expect(_inScreen(CarouselView), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(
      tester.getSize(find.ancestor(of: find.text('one'), matching: _inScreen(ColoredBox)).first).width,
      180 - 8,
      reason: 'the item extent, less Material\'s 4 either side',
    );
    expect(tester.getTopLeft(find.text('two')).dx, greaterThan(tester.getTopLeft(find.text('one')).dx));
    await tester.tap(find.ancestor(of: find.text('one'), matching: _inScreen(ColoredBox)).first);
    await tester.pumpAndSettle();
    expect(_names, <String>['opened']);
    expect(_events.single.$2['value'], 0);
  });

  testWidgets('CarouselView.weighted gives each visible child its share', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = SizedBox(height: 200, child: CarouselView(
        flexWeights: [3, 1],
        children: [...for n in data.items: Center(child: Text(text: n))],
      ));
    ''', data: DynamicContent(<String, Object?>{'items': <Object?>['one', 'two', 'three']}));
    final double width = tester.getSize(_inScreen(CarouselView)).width;
    expect(tester.getSize(find.ancestor(of: find.text('one'), matching: find.byType(Center)).first).width,
        closeTo(width * 3 / 4 - 8, 1));
  });

  testWidgets('MaterialBanner shows its content and actions', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = MaterialBanner(
        leading: Icon(icon: "warning"),
        content: Text(text: "You are offline"),
        actions: [TextButton(child: "Retry", onPressed: event "retry" { })],
      );
    ''');
    expect(find.text('You are offline'), findsOneWidget);
    expect(_inScreen(Icon), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(_names, <String>['retry']);
  });
}
