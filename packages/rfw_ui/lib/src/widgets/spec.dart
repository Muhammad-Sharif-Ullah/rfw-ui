import 'package:flutter/widgets.dart';

import 'args.dart';

/// Builds one widget from its remote arguments.
typedef UiBuilder = Widget Function(UiArgs args);

/// One widget of the `ui` library: its builder and its documentation, side by
/// side, so the catalog the studio shows on hover cannot drift from what the
/// builder reads. `test/catalog_test.dart` holds them to that -- every key a
/// builder reads must be a declared parameter, and every declared parameter
/// must be read.
@immutable
class UiWidget {
  const UiWidget(
    this.name, {
    required this.group,
    required this.doc,
    required this.params,
    required this.build,
    this.example,
    this.needsUiRuntime = false,
  });

  /// What a remote file calls it: `TextField(...)`.
  final String name;

  /// Where the catalog files it.
  final UiGroup group;

  /// A sentence or two: what it is and anything rfw-specific about using it.
  final String doc;

  final List<UiParam> params;

  final UiBuilder build;

  /// A complete widget expression in rfw text. `test/catalog_test.dart`
  /// renders every one, so an example is also a test that the widget works.
  final String? example;

  /// Whether it works only on UiRuntime: the `.builder` widgets, which hand
  /// their builder an item, as rfw's Runtime cannot.
  final bool needsUiRuntime;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'group': group.name,
    'doc': doc,
    'params': <Map<String, Object?>>[keyParam.toJson(), for (final UiParam p in params) p.toJson()],
    if (example != null) 'example': example,
    if (needsUiRuntime) 'needsUiRuntime': true,
  };
}

enum UiGroup { layout, text, material, input, navigation, dialog, cupertino, sliver, builder, paint, motion, effect, gesture }

/// One argument a widget reads.
///
/// [type] is the Dart-ish name the hover shows (`Color`, `EdgeInsets`,
/// `List<Widget>`); what each type accepts in rfw text is described once, in
/// [uiTypes], rather than on every parameter.
@immutable
class UiParam {
  const UiParam(this.name, this.type, {this.doc, this.defaultValue, this.values});

  final String name;
  final String type;
  final String? doc;
  final String? defaultValue;

  /// For an enum, its value names, so the editor can offer them.
  final List<String>? values;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'type': type,
    if (doc != null) 'doc': doc,
    if (defaultValue != null) 'default': defaultValue,
    if (values != null) 'values': values,
  };
}

/// The parameter every widget has besides its own. The library reads it for
/// all of them alike, so no builder declares it.
const UiParam keyParam = UiParam(
  'key',
  'Key',
  doc: 'Names this widget within its screen or dialog. In a list, its state moves with its item when the list '
      'reorders; a new key is a fresh widget; `ui.focus` and `ui.scrollTo` find a widget by it.',
);

/// Shorthand for declaring a parameter.
UiParam p(String name, String type, [String? doc, String? defaultValue]) =>
    UiParam(name, type, doc: doc, defaultValue: defaultValue);

/// Shorthand for an enum parameter: its type name and values come from the enum.
UiParam e<T extends Enum>(String name, List<T> values, [String? doc, String? defaultValue]) => UiParam(
  name,
  T.toString(),
  doc: doc,
  defaultValue: defaultValue,
  values: <String>[for (final T v in values) v.name],
);

/// Shorthand for a parameter with a fixed set of string values that is not a
/// Dart enum (`variant: "filled"`).
UiParam oneOf(String name, List<String> values, [String? doc, String? defaultValue]) =>
    UiParam(name, 'String', doc: doc, defaultValue: defaultValue, values: values);

/// The parameters a `.builder` widget adds to its plain form's: where its rows
/// come from, and what builds them.
List<UiParam> itemBuilderParams({bool separated = false}) => <UiParam>[
  p('items', 'List<Object>', "Each row's item: `data.messages`, or a list written out."),
  p('itemCount', 'int', 'At most this many rows. Alone, with no `items`, this many rows, each given its index.'),
  p('itemBuilder', 'ItemBuilder', 'Builds a row from its item: `(m) => ListTile(title: m.name)`.'),
  if (separated) p('separatorBuilder', 'ItemBuilder', "Builds what goes after each row but the last, from that row's item."),
];

/// What each parameter type accepts in rfw text. Shown on hover over a
/// parameter, so a type is explained where it is used and written down once.
const Map<String, String> uiTypes = <String, String>{
  'Widget': 'A widget: `Text(text: "Hi")`.',
  'Widget|String': 'A widget, or a string as shorthand for `Text(text: ...)`.',
  'Widget|Icon': 'A widget, or an icon name as shorthand for `Icon(icon: ...)`.',
  'List<Widget>': 'A list of widgets: `[ Text(text: "a"), Text(text: "b") ]`, `...for item in data.items: ...` included.',
  'String': 'A string: `"hello"`. A name may be written with a dot instead of quotes: `.center` is `"center"`.',
  'Key': 'A string or number: `"email"`, `item.id`, or a list joined into one: `["row-", item.id]`.',
  'bool': '`true` or `false`.',
  'int': 'A whole number: `3`.',
  'double': 'A number: `16` or `16.5`.',
  'value': 'Any rfw value -- a string, number or bool -- compared by equality.',
  'Spacing': 'A number, or a spacing token from the theme: `"xs"`, `"sm"`, `"md"` (or `.md`), `"lg"`, `"xl"`.',
  'Color': 'An ARGB int (`0xFF6750A4`), a colour-scheme role (`"primary"`, or with a dot, `.onSurfaceVariant`), '
      'a theme colour (`"divider"`), a custom token (`"success"`), `"#RRGGBB"`, '
      'or any of those with an opacity in percent: `"onSurface/60"`.',
  'TextStyle': 'A text-theme name (`"titleLarge"` or `.titleLarge`, or a style the theme names), or a map. '
      '`{ base: "titleLarge", fontWeight: "bold", color: "primary" }` is `titleLarge.copyWith(...)`; '
      'keys: fontSize, fontWeight (`"bold"`, `600`), fontStyle, letterSpacing, wordSpacing, height, '
      'color, backgroundColor, decoration, decorationColor, decorationStyle, fontFamily, shadows, overflow.',
  'EdgeInsets': 'A number or spacing token for every side, `[start, top, end, bottom]`, '
      'or `{ all, horizontal, vertical, top, bottom, start, end, left, right }`.',
  'BorderRadius': 'A number or radius token (`"md"`, `"full"`) for every corner, '
      'or `{ all, top, bottom, start, end, topStart, topEnd, bottomStart, bottomEnd }`.',
  'Alignment': '`"center"` (or `.center`), `"topLeft"`, `"bottomEnd"`, ... or `{ x, y }` from -1 to 1.',
  'Decoration': '`{ color, borderRadius, border, boxShadow, gradient, image, shape }`; '
      '`type: "shape"` takes `shape` as an outline instead.',
  'ShapeBorder': '`"stadium"`, `"circle"`, a number (a rounded rectangle of that radius), '
      'or `{ type: "rounded" | "stadium" | "circle" | "beveled" | "continuous" | "superellipse", borderRadius, side }`.',
  'BorderSide': '`{ color, width, style, strokeAlign }`, or `"none"`.',
  'Border': 'One side for all four (`{ color, width }`) or `{ top, bottom, left, right }` / `{ start, end }`.',
  'BoxShadow': '`{ color, offset: { x, y }, blurRadius, spreadRadius }`.',
  'Gradient': '`{ type: "linear" | "radial" | "sweep", colors: [...], stops, begin, end, center, radius }`.',
  'ButtonStyle': '`{ backgroundColor, foregroundColor, overlayColor, iconColor, elevation, padding, '
      'minimumSize, fixedSize, side, shape, textStyle, ... }` -- each a value, or a map by state: '
      '`{ default: "primary", pressed: "primaryContainer", disabled: "outline" }`.',
  'InputDecoration': '`{ labelText, hintText, helperText, errorText, prefixIcon, suffixIcon, prefixText, '
      'suffixText, filled, fillColor, border, enabledBorder, focusedBorder, contentPadding, isDense, ... }`; '
      'icons may be names, borders `"outline"`, `"underline"`, `"none"` or `{ type, borderRadius, color, width }`.',
  'IconData': 'A Material icon name (`"home"`, `.favorite_border`) or a Cupertino one with a prefix '
      '(`"cupertino.heart_fill"`, `.cupertino.heart_fill`).',
  'Size': '`{ width, height }`, `[width, height]`, or one number for a square.',
  'BoxConstraints': '`{ minWidth, maxWidth, minHeight, maxHeight }`, or `width` / `height` to pin an axis.',
  'Duration': 'Milliseconds: `250`.',
  'Curve': '`"easeInOut"` (or `.easeInOut`), `"fastOutSlowIn"`, `"easeOutBack"`, ...',
  'Offset': '`{ x, y }` or `[x, y]`.',
  'GridDelegate': '`{ crossAxisCount, mainAxisSpacing, crossAxisSpacing, childAspectRatio, mainAxisExtent }`, '
      'or `maxCrossAxisExtent` in place of `crossAxisCount`.',
  'Image': 'A URL (`"https://..."`) or an asset name.',
  'Date': 'An ISO-8601 date: `"2026-10-23"` or `"2026-10-23T14:30:00"`.',
  'Shape': '`{ shape, ...its own keys, color, gradient, stroke, cap, join }`. shape: `.rect` (`rect: [x, y, w, h]`, `radius`), '
      '`.circle` (`center: [x, y]`, `radius`), `.line` (`from`, `to`), `.arc` (`center`, `radius`, `start` and `sweep` in degrees '
      'clockwise from three o\'clock), `.path` (`d`: SVG path data, M L H V C S Q T Z; not arcs), `.text` (`text`, `at`, `style`). '
      'Filled unless it has a `stroke` width.',
  'Effect': '`{ effect, from, to, ...its own keys }`. effect: `.fade` (`from`, `to`: opacity), `.scale` '
      '(`from`, `to`, `alignment`), `.slide` (`from`, `to`: `{ x, y }` as fractions of the child\'s own size), '
      '`.rotate` (`from`, `to` in turns, `alignment`), `.blur` (`from`, `to`: sigma, `tileMode`), '
      '`.tint` (`from`, `to`: colours, `blendMode`), `.shimmer` (`color`, `width`, `angle` in turns). '
      'An effect nobody knows is left out.',
  'Builder': 'A widget builder: `(size) => Text(text: size.breakpoint)`. The name is yours; '
      '`name.x` reads what the widget passes, which its own docs list.',
  'ItemBuilder': 'Builds one row from its item: `(m) => ListTile(title: m.name)`. The name is yours; `m` is the '
      'item -- a map (`m.name`), a string or a number -- or, with `itemCount` and no `items`, the row\'s index. '
      '`args.*`, `data.*` and `state.*` still read as they do around it.',
  'event': 'A handler: `event "name" { ... }` or `set state.x = ...`.',
  'event<bool>': 'A handler; an event receives `{ value: true | false }` merged into its arguments.',
  'event<int>': 'A handler; an event receives `{ value: <int> }`.',
  'event<double>': 'A handler; an event receives `{ value: <double> }`.',
  'event<String>': 'A handler; an event receives `{ value: "<text>" }`.',
  'event<value>': 'A handler; an event receives `{ value: <the selected value> }`.',
  'event<Date>': 'A handler; an event receives `{ value: "<ISO date>" }`.',
  'event<Range>': 'A handler; an event receives `{ start, end }`.',
  'List<Map>': 'A list of maps; the parameter says which keys each takes.',
  'Map': 'A map; the parameter says which keys it takes.',
};
