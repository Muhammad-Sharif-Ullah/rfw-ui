# The theme: one format from the console to the app

A theme is ThemeData's own arguments, as data. The same document is:

- **what the console edits.** Its form has a tab per group (General, Colour
  scheme, Text, Tokens, Colours, Buttons, Inputs, Navigation, Surfaces,
  Feedback, Pickers, Cupertino), a section per component, and a search across
  all 3,664 settings.
- **what the server validates and serves**, against `schema/theme.schema.json`.
- **what the app decodes**, with `decodeThemeData` (one side) or
  `UiThemeDocument.decode` (`{ shared, light, dark }`).

## One source for all three

`uiThemeSchema()` (`lib/src/theme/theme_schema.dart`) writes the schema from
the decoder itself. It runs each component theme's decoder with a probe that
notes which reader each key goes through (`color`, `textStyle`,
`buttonStyle`), so the schema cannot list a key the app does not read, or
miss one it does. `test/theme_schema_test.dart` holds it to that, both ways.
`make catalog` copies it to `schema/`, where the Go server and the panel read
it.

| What the schema has | What it is |
|---|---|
| `$defs` | the value types: Color, TextStyle, EdgeInsets, Shape, BorderSide, InputBorder, IconThemeData, ButtonStyle, StateColor, ... |
| `x-format: "color"` | a value that is an ARGB number or a colour's name |
| `x-suggest`, `x-names-from` | the names a colour or text style may take: the scheme's roles, plus the document's own `tokens.colors` / `tokens.textStyles`. The server refuses any other. |
| `x-group` | the tab of the form a top-level key is filed under |
| `x-reshape` | version 2 is not version 1 plus new keys; the server rewrites a version-1 document with `reshape.go` |

## What the server refuses, and why

The decoder forgives anything. An unknown key is ignored, and a value it
cannot read is the default. That is right for an app that must never fail to
load, and wrong for an editor, where it means a typo saves, publishes and
silently does nothing. So the server refuses, by path:

- **a key the app never reads:** `theme.appBarTheme.backgroundColour: not a theme key`
- **a value of the wrong kind:** `theme.colorScheme.onPrimary: expected a colour: an ARGB number, a role such as "primary", or "#RRGGBB"`
- **a colour or style name that names nothing:** `theme.appBarTheme.backgroundColor: "primry" is not a colour: ...`
- **a colour written as a float**, which Dart would read as no colour: `theme.colorScheme.primary: expected an integer`
- **a font weight between the hundreds:** `must be a multiple of 100`

## Fonts in component themes

`fontFamily` at the top of a document is "the font every style uses unless it
names another". In ThemeData that holds only for the text theme. A button's
`textStyle: { fontSize: 16 }` would otherwise fall back to the platform's
font. The decoder gives such a style the theme's font
(`test/theme_test.dart`). A button style written on a widget gets the
theme's button font in the same way (`test/decoder_test.dart`).

## Old versions

Versions saved at schema version 1 stay as they were stored. The server
reshapes them at render, and `rfw-checking/test/theme_migration_test.dart`
compares the ThemeData rfw_theme built from one with the ThemeData the kit
decodes from its reshape. Every colour role, text style, button state,
border and shape is compared. A changed value fails the test; that was
checked by changing one.
