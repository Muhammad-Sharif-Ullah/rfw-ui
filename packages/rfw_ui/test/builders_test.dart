import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

Future<void> _pump(WidgetTester tester, String source, {Size size = const Size(400, 800), ThemeData? theme}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('LayoutBuilder', () {
    const String byWidth = '''
      widget root = LayoutBuilder(builder: (size) => switch size.breakpoint {
        .compact: Text(text: "phone"),
        .medium: Text(text: "tablet"),
        default: Text(text: "wide"),
      });
    ''';

    testWidgets('names the width it is given: compact on a phone', (WidgetTester tester) async {
      await _pump(tester, byWidth, size: const Size(400, 800));
      expect(find.text('phone'), findsOneWidget);
    });

    testWidgets('names the width it is given: medium at 700, expanded at 1000', (WidgetTester tester) async {
      await _pump(tester, byWidth, size: const Size(700, 800));
      expect(find.text('tablet'), findsOneWidget);
      await _pump(tester, byWidth, size: const Size(1000, 800));
      expect(find.text('wide'), findsOneWidget);
    });

    testWidgets('says landscape when wider than tall', (WidgetTester tester) async {
      await _pump(tester, 'widget root = LayoutBuilder(builder: (size) => Text(text: size.orientation));', size: const Size(1000, 400));
      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('passes the numbers on, and -1 for a side with no limit', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = ListView(children: [
          LayoutBuilder(builder: (size) => Column(children: [
            SizedBox(width: size.maxWidth, height: 10, child: Text(text: "measured")),
            switch size.maxHeight { -1: Text(text: "unbounded"), default: Text(text: "bounded") },
            Text(text: size.breakpoint),
          ])),
        ]);
      ''', size: const Size(400, 800));
      expect(find.text('unbounded'), findsOneWidget);
      expect(find.text('compact'), findsOneWidget);
      expect(tester.getSize(find.ancestor(of: find.text('measured'), matching: find.byType(SizedBox)).first).width, 400);
    });
  });

  group('ScreenBuilder', () {
    testWidgets('reads the screen, not the space it is given', (WidgetTester tester) async {
      await _pump(tester, '''
        widget root = SizedBox(width: 100, child: ScreenBuilder(builder: (screen) => Column(children: [
          Text(text: screen.breakpoint),
          Text(text: screen.orientation),
        ])));
      ''', size: const Size(1000, 800));
      expect(find.text('expanded'), findsOneWidget);
      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('says which brightness the theme is', (WidgetTester tester) async {
      await _pump(tester, 'widget root = ScreenBuilder(builder: (screen) => Text(text: screen.brightness));', theme: ThemeData.dark());
      expect(find.text('dark'), findsOneWidget);
    });

    testWidgets('says which platform it is on', (WidgetTester tester) async {
      await _pump(tester, 'widget root = ScreenBuilder(builder: (screen) => Text(text: screen.platform));');
      expect(find.text(defaultTargetPlatform.name), findsOneWidget);
    });
  });
}
