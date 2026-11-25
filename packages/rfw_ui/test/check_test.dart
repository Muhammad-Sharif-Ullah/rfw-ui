import 'package:flutter/material.dart' hide Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw_ui/rfw_ui.dart';

List<String> _check(String source, {ThemeData? theme}) =>
    checkUiLibrary(parseLibraryFile(source, sourceIdentifier: 'test'), source, theme: theme);

void main() {
  // A checker that cries wolf is one nobody reads.
  test('every example in the catalog is clean', () {
    final List<String> noisy = <String>[
      for (final UiWidget w in uiWidgets.where((UiWidget w) => w.example != null))
        for (final String problem in _check('import ui;\nwidget root = ${w.example};')) '${w.name}: $problem',
      for (final UiAction a in uiActions.where((UiAction a) => a.example != null))
        for (final String problem in _check('import ui;\nwidget root = ${a.example};')) '${a.name}: $problem',
    ];
    expect(noisy, isEmpty, reason: noisy.join('\n'));
  });

  test('names each mistake rfw would pass over in silence, with its line', () {
    final List<String> problems = _check('''
import ui;
widget root = Column(children: [
  Txt(text: "typo widget"),
  Text(text: "x", style: { base: "titleLarg", color: "primry" }),
  Icon(icon: "favourite"),
  Padding(padding: "huge", child: Text(text: "x")),
  Card(elevaton: 2, child: Container(borderRadius: "enormous")),
  Mine(),
]);
widget Mine = Text(text: "a widget of the file's own is fine");
''');
    expect(problems, <String>[
      'line 3:3 Txt is not a widget in the kit or this file',
      'line 4:3 Text.style.base: "titleLarg" is not a text style (titleLarge, bodyMedium, ... or one the theme names)',
      'line 4:3 Text.style.color: "primry" is not a colour role, theme colour, named colour or #RRGGBB',
      'line 5:3 Icon.icon: "favourite" is not an icon name (Material names like "favorite_border", Cupertino ones as "cupertino.heart")',
      'line 6:3 Padding.padding: "huge" is not a spacing token (none, xxs, xs, sm, md, lg, xl, xxl)',
      'line 7:3 Card.elevaton is not an argument of Card',
      'line 7:28 Container.borderRadius is not an argument of Container',
    ]);
  });

  test('a token the theme defines is not a problem', () {
    final ThemeData theme = decodeThemeData(<String, Object?>{
      'tokens': <String, Object?>{
        'colors': <String, Object?>{'success': 0xFF00AA00},
        'textStyles': <String, Object?>{
          'hero': <String, Object?>{'base': 'displaySmall'},
        },
        'spacing': <String, Object?>{'gutter': 20},
      },
    });
    const String source = '''
import ui;
widget root = Padding(padding: "gutter", child: Text(text: "x", style: { base: "hero", color: "success/50" }));
''';
    expect(_check(source, theme: theme), isEmpty);
    expect(_check(source), hasLength(3));
  });

  test('a value written with a dot is checked as its quoted form is, at the same place', () {
    expect(
      _check('import ui;\nwidget root = Text(text: "x", style: { base: .titleLarg, color: .primry });'),
      _check('import ui;\nwidget root = Text(text: "x", style: { base: "titleLarg", color: "primry" });'),
    );
    expect(
      _check('import ui;\nwidget root = Text(text: "x", textAlign: .center, style: { base: .titleLarge, color: .primary });'),
      isEmpty,
    );
  });

  test('a file that does not import the kit is told so', () {
    expect(_check('import core.widgets;\nwidget root = Text(text: ["x"]);').first, contains('import ui;'));
  });
}
