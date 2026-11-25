import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseDataFile, parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The rfw-ui-from-image skill (skills/rfw-ui-from-image) hands its recipes
/// to whoever turns a design into a screen, as screens to start from. A
/// recipe that no longer parses, that names a widget or argument the kit has
/// lost, or that throws as it builds would teach the wrong thing -- so each
/// one is held to what the skill says of it here.
void main() {
  final Directory recipes = Directory(
    '../../skills/rfw-ui-from-image/references/recipes',
  );
  final List<File> screens =
      recipes
          .listSync()
          .whereType<File>()
          .where(
            (File f) =>
                f.path.endsWith('.rfwtxt') && !f.path.endsWith('.theme.rfwtxt'),
          )
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  test(
    'there are recipes to check',
    () => expect(screens.length, greaterThanOrEqualTo(4)),
  );

  for (final File screen in screens) {
    final String name = screen.uri.pathSegments.last.replaceAll('.rfwtxt', '');
    final File themeFile = File('${recipes.path}/$name.theme.rfwtxt');
    final File dataFile = File('${recipes.path}/$name.data.json');

    ThemeData themeFor(Brightness brightness) {
      if (!themeFile.existsSync()) {
        return ThemeData(brightness: brightness);
      }
      return UiThemeDocument.decode(parseDataFile(themeFile.readAsStringSync()))
          .of(brightness);
    }

    test('$name: the catalog finds nothing wrong in it', () {
      final String text = screen.readAsStringSync();
      final List<String> problems = checkUiLibrary(
        parseLibraryFile(text, sourceIdentifier: name),
        text,
        theme: themeFor(Brightness.dark),
      );
      expect(problems, isEmpty, reason: problems.join('\n'));
      if (themeFile.existsSync()) {
        expect(
          UiThemeDocument.problems(parseDataFile(themeFile.readAsStringSync())),
          isEmpty,
        );
      }
    });

    testWidgets('$name: builds on a phone-sized screen without an error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      const LibraryName main = LibraryName(<String>['recipe']);
      final Runtime runtime = createUiRuntime()
        ..update(uiLibraryName, createUiWidgets())
        ..update(main, parseLibraryFile(screen.readAsStringSync()));
      addTearDown(runtime.dispose);
      final DynamicContent data = DynamicContent(
        dataFile.existsSync()
            ? (jsonDecode(dataFile.readAsStringSync()) as Map<String, Object?>)
            : const <String, Object?>{},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor(Brightness.light),
          darkTheme: themeFor(Brightness.dark),
          themeMode: themeFile.existsSync() ? ThemeMode.dark : ThemeMode.light,
          home: Material(
            child: UiRemoteWidget(
              runtime: runtime,
              data: data,
              widget: const FullyQualifiedWidgetName(main, 'root'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });
  }
}
