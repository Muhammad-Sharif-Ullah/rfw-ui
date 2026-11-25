import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// UiRuntime must build what rfw's Runtime builds. Every catalog example and
/// every skill recipe is rendered on both, and the render trees -- every
/// render object with its size, offset, constraints and paint properties --
/// must be the same. Only what names the widgets that made them (the
/// `creator:` chains) and object ids may differ.
const LibraryName _main = LibraryName(<String>['main']);

Future<String> _render(WidgetTester tester, Runtime runtime, String source, Map<String, Object?> data) async {
  runtime
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile(source));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    // A new key, so nothing of the other runtime's tree is kept.
    KeyedSubtree(
      key: UniqueKey(),
      child: MaterialApp(
        home: Scaffold(
          body: UiRemoteWidget(runtime: runtime, data: DynamicContent(data), widget: const FullyQualifiedWidgetName(_main, 'root')),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
  return tester.binding.rootElement!.renderObject!
      .toStringDeep()
      .split('\n')
      .where((String line) => !line.contains('creator:') && !line.contains('←') && !line.trimRight().endsWith('⋯'))
      .map((String line) => line.replaceAll(RegExp(r'#[0-9a-f]{5}\b'), '#').replaceAll(RegExp(r'SemanticsNode#\d+'), 'SemanticsNode#'))
      .join('\n');
}

Future<void> _same(WidgetTester tester, String source, [Map<String, Object?> data = const <String, Object?>{}]) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final String rfw = await _render(tester, Runtime(), source, data);
  final String ours = await _render(tester, UiRuntime(), source, data);
  expect(ours, rfw);
}

void main() {
  // A widget that needs UiRuntime has no rfw rendering to be compared with.
  for (final UiWidget w in uiWidgets.where((UiWidget w) => w.example != null && !w.needsUiRuntime)) {
    testWidgets('${w.name}: the example renders the same on both runtimes', (WidgetTester tester) async {
      await _same(tester, 'import ui;\nwidget root = ${w.example};');
    });
  }

  final Directory recipes = Directory('../../skills/rfw-ui-from-image/references/recipes');
  for (final File screen in recipes.listSync().whereType<File>().where(
    (File f) => f.path.endsWith('.rfwtxt') && !f.path.endsWith('.theme.rfwtxt'),
  )) {
    final String name = screen.uri.pathSegments.last.replaceAll('.rfwtxt', '');
    final File dataFile = File('${recipes.path}/$name.data.json');
    testWidgets('$name: the recipe renders the same on both runtimes', (WidgetTester tester) async {
      await _same(
        tester,
        screen.readAsStringSync(),
        dataFile.existsSync() ? jsonDecode(dataFile.readAsStringSync()) as Map<String, Object?> : const <String, Object?>{},
      );
    });
  }
}
