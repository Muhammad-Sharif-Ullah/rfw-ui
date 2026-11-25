import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import '../decode/decoder.dart';
import '../decode/resolver.dart';
import 'theme_data_decoder.dart';

/// The schema revision [uiThemeSchema] describes. The theme console stores
/// it beside every version it saves, and migrates older ones forward.
const int uiThemeSchemaVersion = 2;

/// The JSON Schema (2020-12) of one brightness of a theme -- the map
/// [decodeThemeData] reads -- for an editor to draw a form from and a server
/// to check documents against.
///
/// Generated, not written: each component theme's keys and the kind of value
/// each one takes come from running that component's own decoder with a
/// probe that notes which reader each key goes through (`color`,
/// `textStyle`, `buttonStyle`, ...). So the schema says what the app reads,
/// and cannot drift from it. `theme.schema.json` beside this package is this,
/// kept current by `test/theme_schema_test.dart`.
///
/// The decoder is more forgiving than the schema. It takes a text style by
/// name (`"titleLarge"`), padding as one number, a shape as `"stadium"`. The
/// schema takes each in one form, the map form, which is the one a form can
/// draw fields for; every document it accepts, the decoder reads.
///
/// Besides JSON Schema it uses the theme console's extensions: `x-order` on
/// every object, the key order; `x-format: "color"` on every colour, an
/// ARGB number or a token string; `x-group` on each top-level key, the
/// section an editor files it under; `x-schemaVersion` at the root, and
/// `x-reshape`, which says this version's documents are rewritten from the
/// last version's rather than extended.
Map<String, Object?> uiThemeSchema() {
  final Map<String, Object?> properties = <String, Object?>{
    'name': <String, Object?>{'type': 'string', 'description': 'What the theme is called.', 'x-group': 'General'},
    'brightness': <String, Object?>{
      'type': 'string',
      'enum': <String>['light', 'dark'],
      'description': 'Which side of the theme this document is.',
      'x-group': 'General',
    },
    'colorScheme': _ref('ColorScheme', group: 'Colour scheme'),
    'textTheme': _ref('TextTheme', group: 'Text'),
    'primaryTextTheme': _ref('TextTheme', group: 'Text'),
    'fontFamily': <String, Object?>{'type': 'string', 'description': 'The font every style uses unless it names another.', 'x-group': 'Text'},
    'fontFamilyFallback': <String, Object?>{..._strings, 'x-group': 'Text'},
    'tokens': _ref('Tokens', group: 'Tokens'),
    'useMaterial3': <String, Object?>{'type': 'boolean', 'x-group': 'General'},
    'visualDensity': <String, Object?>{..._visualDensity, 'x-group': 'General'},
    'materialTapTargetSize': <String, Object?>{..._enum(MaterialTapTargetSize.values), 'x-group': 'General'},
    'splashFactory': <String, Object?>{..._oneOf(<String>['ripple', 'sparkle', 'splash', 'none']), 'x-group': 'General'},
    'applyElevationOverlayColor': <String, Object?>{'type': 'boolean', 'x-group': 'General'},
    'platform': <String, Object?>{..._enum(TargetPlatform.values), 'x-group': 'General'},
    'pageTransitionsTheme': <String, Object?>{
      ..._oneOf(<String>['zoom', 'fadeForwards', 'fadeUpwards', 'openUpwards', 'cupertino', 'predictiveBack']),
      'description': 'One page transition, for every platform.',
      'x-group': 'General',
    },
    for (final String name in _themeColors) name: _ref('Color', group: 'Colours'),
    'iconTheme': _ref('IconThemeData', group: 'Colours'),
    'primaryIconTheme': _ref('IconThemeData', group: 'Colours'),
    // Components by the section an editor files them under, then by name,
    // so the sections read in the order of _groupOrder.
    for (final String name in themeComponents.keys.toList()..sort(_bySection))
      name: <String, Object?>{..._component(name, themeComponents[name]!), 'x-group': _groupOf(name)},
  };
  return <String, Object?>{
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': 'Theme',
    'description': 'One brightness of a theme: the arguments of Flutter\'s ThemeData, as data.',
    'type': 'object',
    'additionalProperties': false,
    'required': <String>['name', 'brightness'],
    'x-order': properties.keys.toList(),
    'x-schemaVersion': uiThemeSchemaVersion,
    // Version 2 is not version 1 plus new keys: the server rewrites a
    // version-1 document into this shape (backend/.../schema/reshape.go).
    'x-reshape': true,
    'properties': properties,
    r'$defs': _defs,
  };
}

const List<String> _themeColors = <String>[
  'canvasColor', 'cardColor', 'disabledColor', 'dividerColor', 'focusColor', 'highlightColor', 'hintColor',
  'hoverColor', 'primaryColor', 'scaffoldBackgroundColor', 'secondaryHeaderColor', 'shadowColor', 'splashColor',
  'unselectedWidgetColor',
];

/// The sections an editor shows, in order.
const List<String> _groupOrder = <String>[
  'Buttons', 'Inputs', 'Navigation', 'Surfaces', 'Feedback', 'Pickers', 'Cupertino', 'Components',
];

int _bySection(String a, String b) {
  final int bySection = _groupOrder.indexOf(_groupOf(a)).compareTo(_groupOrder.indexOf(_groupOf(b)));
  return bySection != 0 ? bySection : a.compareTo(b);
}

/// Where an editor files each component theme.
String _groupOf(String component) {
  const Map<String, List<String>> groups = <String, List<String>>{
    'Buttons': <String>[
      'elevatedButtonTheme', 'filledButtonTheme', 'outlinedButtonTheme', 'textButtonTheme', 'iconButtonTheme',
      'floatingActionButtonTheme', 'segmentedButtonTheme', 'toggleButtonsTheme',
    ],
    'Inputs': <String>[
      'inputDecorationTheme', 'checkboxTheme', 'radioTheme', 'switchTheme', 'sliderTheme', 'chipTheme',
      'dropdownMenuTheme', 'searchBarTheme', 'textSelectionTheme',
    ],
    'Navigation': <String>[
      'appBarTheme', 'bottomAppBarTheme', 'bottomNavigationBarTheme', 'navigationBarTheme', 'navigationRailTheme',
      'navigationDrawerTheme', 'drawerTheme', 'tabBarTheme',
    ],
    'Surfaces': <String>[
      'cardTheme', 'dialogTheme', 'bottomSheetTheme', 'listTileTheme', 'expansionTileTheme', 'dividerTheme',
      'popupMenuTheme', 'scrollbarTheme',
    ],
    'Feedback': <String>['snackBarTheme', 'tooltipTheme', 'badgeTheme', 'progressIndicatorTheme'],
    'Pickers': <String>['datePickerTheme', 'timePickerTheme'],
    'Cupertino': <String>['cupertinoOverrideTheme'],
  };
  for (final MapEntry<String, List<String>> group in groups.entries) {
    if (group.value.contains(component)) {
      return group.key;
    }
  }
  return 'Components';
}

Map<String, Object?> _ref(String name, {String? group}) => <String, Object?>{
  r'$ref': '#/\$defs/$name',
  'x-group': ?group,
};

Map<String, Object?> _enum<T extends Enum>(List<T> values) => _oneOf(<String>[for (final T v in values) v.name]);

Map<String, Object?> _oneOf(List<String> values) => <String, Object?>{'type': 'string', 'enum': values};

const Map<String, Object?> _number = <String, Object?>{'type': 'number'};

const Map<String, Object?> _strings = <String, Object?>{
  'type': 'array',
  'items': <String, Object?>{'type': 'string'},
};

const Map<String, Object?> _visualDensity = <String, Object?>{
  'type': 'string',
  'enum': <String>['standard', 'compact', 'comfortable', 'adaptivePlatformDensity'],
};

/// An object whose keys are [props], in that order, and nothing else.
Map<String, Object?> _object(Map<String, Object?> props, {String? description}) => <String, Object?>{
  'type': 'object',
  'description': ?description,
  'additionalProperties': false,
  'x-order': props.keys.toList(),
  'properties': props,
};

/// An object of any keys, each a [value]: a token scale, a set of named colours.
Map<String, Object?> _map(Map<String, Object?> value, {String? description}) => <String, Object?>{
  'type': 'object',
  'description': ?description,
  'additionalProperties': value,
  'x-order': const <String>[],
  'properties': const <String, Object?>{},
};

/// A component theme: its keys, from its own decoder.
Map<String, Object?> _component(String name, ThemeComponent component) {
  final _Probe probe = _Probe(<Object>[name]);
  final Object? built = component.build(probe, <Object>[name]);
  final Map<String, Object?> props = <String, Object?>{
    for (final String key in component.keys) key: _read(probe.found, key) ?? (throw StateError('$name.$key was never read')),
  };
  return _object(props, description: '${built.runtimeType}: what ${_widgetOf(name)} looks like, everywhere in the app.');
}

/// What was read at [path]: a value, or -- for a theme nested in a theme,
/// `dropdownMenuTheme.inputDecorationTheme` -- an object of what was read
/// under it, in the order it was read.
Map<String, Object?>? _read(Map<String, Map<String, Object?>> found, String path) {
  final Map<String, Object?>? here = found[path];
  if (here != null) {
    return here;
  }
  final String prefix = '$path.';
  final Map<String, Object?> props = <String, Object?>{};
  for (final String key in found.keys) {
    if (key.startsWith(prefix)) {
      final String child = key.substring(prefix.length).split('.').first;
      props[child] ??= _read(found, '$prefix$child');
    }
  }
  return props.isEmpty ? null : _object(props);
}

String _widgetOf(String component) {
  final String bare = component.substring(0, component.length - 'Theme'.length);
  final String widget = '${bare[0].toUpperCase()}${bare.substring(1)}';
  return switch (component) {
    'cupertinoOverrideTheme' => 'every Cupertino widget',
    'textSelectionTheme' => 'selected text and the cursor',
    'inputDecorationTheme' => 'every text field\'s decoration',
    _ => 'every $widget',
  };
}

/// The colour state a state map may name, in the order the decoder checks
/// them. `default` is the rest.
final List<String> _states = UiDecoder.stateOrder;

Map<String, Object?> _stateOf(String valueDef, String description) => _object(
  <String, Object?>{for (final String s in _states) s: _ref(valueDef)},
  description: description,
);

/// The value types a theme is made of, each in the one form the schema takes.
final Map<String, Object?> _defs = <String, Object?>{
  'Color': <String, Object?>{
    'type': <String>['integer', 'string'],
    'minimum': 0,
    'maximum': 0xFFFFFFFF,
    // A scheme role, a theme colour or a named one, optionally `/NN` for an
    // opacity in percent; or #RRGGBB / #AARRGGBB.
    'pattern': r'^(#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})|[A-Za-z][A-Za-z0-9]*)(/(100|[1-9]?[0-9]))?$',
    'x-format': 'color',
    'x-suggest': <String>[...colorRoles, ...themeColorNames, 'transparent', 'black', 'white'],
    // And the theme's own named colours. The server refuses any other name,
    // which the decoder would quietly read as no colour at all.
    'x-names-from': 'tokens.colors',
    'description': 'An ARGB number (0xFF6750A4), a colour-scheme role ("primary"), a theme colour ("divider"), '
        'a named colour from tokens.colors, or any of them with an opacity in percent ("onSurface/60").',
  },
  'TextStyle': _object(<String, Object?>{
    'base': <String, Object?>{
      'type': 'string',
      'x-suggest': textThemeNames,
      'x-names-from': 'tokens.textStyles',
      'description': 'The style this one starts from: a text-theme name, or one tokens.textStyles names. '
          'The other keys change it, as copyWith would.',
    },
    'color': _ref('Color'),
    'backgroundColor': _ref('Color'),
    'fontFamily': <String, Object?>{'type': 'string'},
    'fontFamilyFallback': _strings,
    'fontSize': _number,
    'fontWeight': <String, Object?>{'type': 'integer', 'minimum': 100, 'maximum': 900, 'multipleOf': 100},
    'fontStyle': _enum(FontStyle.values),
    'letterSpacing': _number,
    'wordSpacing': _number,
    'height': <String, Object?>{'type': 'number', 'description': 'Line height, as a multiple of the font size.'},
    'leadingDistribution': _enum(TextLeadingDistribution.values),
    'textBaseline': _enum(TextBaseline.values),
    'decoration': _oneOf(<String>['none', 'underline', 'lineThrough', 'overline']),
    'decorationColor': _ref('Color'),
    'decorationStyle': _enum(TextDecorationStyle.values),
    'decorationThickness': _number,
    'overflow': _enum(TextOverflow.values),
  }, description: 'A text style.'),
  'EdgeInsets': _object(<String, Object?>{
    'all': _number,
    'horizontal': _number,
    'vertical': _number,
    'top': _number,
    'bottom': _number,
    'start': _number,
    'end': _number,
  }, description: 'Padding. A side not named takes `horizontal` or `vertical`, which take `all`.'),
  'BorderSide': _object(<String, Object?>{
    'color': _ref('Color'),
    'width': _number,
    'style': _enum(BorderStyle.values),
    'strokeAlign': <String, Object?>{'type': 'number', 'minimum': -1, 'maximum': 1},
  }, description: 'One edge of a border.'),
  'Shape': _object(<String, Object?>{
    'type': _oneOf(<String>['rounded', 'stadium', 'circle', 'beveled', 'continuous', 'superellipse']),
    'borderRadius': _number,
    'side': _ref('BorderSide'),
  }, description: 'An outline: a rounded rectangle unless `type` says otherwise.'),
  'InputBorder': _object(<String, Object?>{
    'type': _oneOf(<String>['outline', 'underline', 'none']),
    'borderRadius': _number,
    'color': _ref('Color'),
    'width': _number,
    'gapPadding': _number,
  }, description: 'A text field\'s border.'),
  'IconThemeData': _object(<String, Object?>{
    'color': _ref('Color'),
    'size': _number,
    'opacity': <String, Object?>{'type': 'number', 'minimum': 0, 'maximum': 1},
    'fill': <String, Object?>{'type': 'number', 'minimum': 0, 'maximum': 1},
    'weight': _number,
    'grade': _number,
    'opticalSize': _number,
  }, description: 'How icons are drawn.'),
  'Size': _object(<String, Object?>{'width': _number, 'height': _number}),
  'Offset': _object(<String, Object?>{'x': _number, 'y': _number}),
  'BoxConstraints': _object(<String, Object?>{
    'minWidth': _number,
    'maxWidth': _number,
    'minHeight': _number,
    'maxHeight': _number,
  }),
  'BoxDecoration': _object(<String, Object?>{
    'color': _ref('Color'),
    'borderRadius': _number,
    'border': _ref('BorderSide'),
    'shape': _enum(BoxShape.values),
  }, description: 'A box: its colour, corners and border.'),
  'StateColor': _stateOf('Color', 'A colour per state: `default`, and any of the states that change it.'),
  'StateNumber': _stateOf('Number', 'A number per state: `default`, and any of the states that change it.'),
  'StateBool': _stateOf('Bool', 'A flag per state: `default`, and any of the states that change it.'),
  'Number': _number,
  'Bool': const <String, Object?>{'type': 'boolean'},
  'ButtonStyle': _object(<String, Object?>{
    'textStyle': _ref('TextStyle'),
    'backgroundColor': _ref('StateColor'),
    'foregroundColor': _ref('StateColor'),
    'overlayColor': _ref('StateColor'),
    'shadowColor': _ref('StateColor'),
    'surfaceTintColor': _ref('StateColor'),
    'iconColor': _ref('StateColor'),
    'elevation': _ref('StateNumber'),
    'padding': _ref('EdgeInsets'),
    'minimumSize': _ref('Size'),
    'fixedSize': _ref('Size'),
    'maximumSize': _ref('Size'),
    'iconSize': _ref('StateNumber'),
    'side': _ref('BorderSide'),
    'shape': _ref('Shape'),
    'visualDensity': _visualDensity,
    'tapTargetSize': _enum(MaterialTapTargetSize.values),
    'alignment': _alignment,
    'enableFeedback': const <String, Object?>{'type': 'boolean'},
  }, description: 'How a button looks.'),
  'ColorScheme': _object(<String, Object?>{
    'seed': <String, Object?>{
      r'$ref': '#/\$defs/Color',
      'description': 'The colour every role is grown from. A role named here is used as it is instead.',
    },
    'variant': _enum(DynamicSchemeVariant.values),
    'contrastLevel': <String, Object?>{'type': 'number', 'minimum': -1, 'maximum': 1},
    for (final String role in colorRoles) role: _ref('Color'),
  }, description: 'The 46 colour roles every Material widget reads. Grown from `seed`; any role may be set.'),
  'TextTheme': _object(<String, Object?>{
    'fontFamily': <String, Object?>{'type': 'string'},
    'bodyColor': _ref('Color'),
    'displayColor': _ref('Color'),
    for (final String style in textThemeNames) style: _ref('TextStyle'),
  }, description: 'The fifteen text styles. A style changes its own default; with `base` it starts from another.'),
  'Tokens': _object(<String, Object?>{
    'spacing': _map(_number, description: 'Spacing by name: `padding: "md"`. Merged over xs 4, sm 8, md 16, lg 24, xl 32.'),
    'radius': _map(_number, description: 'Corner radii by name: `borderRadius: "lg"`.'),
    'colors': _map(<String, Object?>{r'$ref': '#/\$defs/Color'}, description: 'Colours by name, beyond the scheme: `color: "success"`.'),
    'textStyles': _map(<String, Object?>{r'$ref': '#/\$defs/TextStyle'}, description: 'Text styles by name: `style: "hero"`.'),
  }, description: 'What a design system has that ThemeData has no slot for.'),
};

final Map<String, Object?> _alignment = _oneOf(const <String>[
  'topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter',
  'bottomRight', 'topStart', 'topEnd', 'centerStart', 'centerEnd', 'bottomStart', 'bottomEnd',
]);

/// A decoder that decodes nothing, and notes which reader each key one level
/// under the component was read through.
class _Probe extends UiDecoder {
  _Probe(this.base) : super(_Everywhere(), const UiResolver(colorScheme: ColorScheme.light(), textTheme: TextTheme()));

  /// The component's own key; what is found is noted by its path under it.
  final List<Object> base;

  final Map<String, Map<String, Object?>> found = <String, Map<String, Object?>>{};

  static const String _inner = '\u0000value';

  void _note(List<Object> key, Map<String, Object?> schema) {
    found[key.sublist(base.length).join('.')] = schema;
  }

  @override
  Color? color(List<Object> key) => _null(key, _ref('Color'));

  @override
  double? number(List<Object> key) => _null(key, _number);

  @override
  int? integer(List<Object> key) => _null(key, const <String, Object?>{'type': 'integer'});

  @override
  double? spacing(List<Object> key) => _null(key, _number);

  @override
  double? radiusValue(List<Object> key) => _null(key, _number);

  @override
  bool? boolean(List<Object> key) => _null(key, const <String, Object?>{'type': 'boolean'});

  @override
  String? string(List<Object> key) => _null(key, const <String, Object?>{'type': 'string'});

  @override
  List<String>? strings(List<Object> key) => _null(key, _strings);

  @override
  T? enumValue<T extends Enum>(List<T> values, List<Object> key) => _null(key, _enum<T>(values));

  @override
  Duration? duration(List<Object> key) =>
      _null(key, const <String, Object?>{'type': 'integer', 'minimum': 0, 'description': 'Milliseconds.'});

  @override
  TextStyle? textStyle(List<Object> key) => _null(key, _ref('TextStyle'));

  @override
  EdgeInsetsGeometry? edgeInsets(List<Object> key) => _null(key, _ref('EdgeInsets'));

  @override
  OutlinedBorder? shape(List<Object> key) => _null(key, _ref('Shape'));

  @override
  BorderSide? borderSide(List<Object> key) => _null(key, _ref('BorderSide'));

  @override
  InputBorder? inputBorder(List<Object> key) => _null(key, _ref('InputBorder'));

  @override
  IconThemeData? iconThemeData(List<Object> key) => _null(key, _ref('IconThemeData'));

  @override
  Size? size(List<Object> key) => _null(key, _ref('Size'));

  @override
  Offset? offset(List<Object> key) => _null(key, _ref('Offset'));

  @override
  BoxConstraints? boxConstraints(List<Object> key) => _null(key, _ref('BoxConstraints'));

  @override
  AlignmentGeometry? alignment(List<Object> key) => _null(key, _alignment);

  @override
  VisualDensity? visualDensity(List<Object> key) => _null(key, _visualDensity);

  @override
  Decoration? decoration(List<Object> key) => _null(key, _ref('BoxDecoration'));

  @override
  Radius? radius(List<Object> key) => _null(key, _number);

  @override
  BorderRadiusGeometry? borderRadius(List<Object> key) => _null(key, _number);

  @override
  IconData? icon(List<Object> key) =>
      _null(key, const <String, Object?>{'type': 'string', 'description': 'A Material icon name: "close".'});

  @override
  ButtonStyle? buttonStyle(List<Object> key) => _null(key, _ref('ButtonStyle'));

  @override
  WidgetStateProperty<Color?>? stateColor(List<Object> key) => _null(key, _ref('StateColor'));

  /// A colour, number or flag per state takes the state map; anything bigger
  /// -- a text style, padding, a shape -- takes one value for every state,
  /// which the decoder reads as well, and which keeps the form to a size a
  /// person can fill in.
  @override
  WidgetStateProperty<T?>? state<T>(List<Object> key, T? Function(List<Object> key) decode) {
    decode(<Object>[...key, _inner]);
    final Map<String, Object?> value = found.remove(<Object>[...key, _inner].sublist(base.length).join('.'))!;
    final Object? ref = value[r'$ref'];
    final String? type = value['type'] as String?;
    _note(key, switch ((ref, type)) {
      ('#/\$defs/Color', _) => _ref('StateColor'),
      (null, 'number') => _ref('StateNumber'),
      (null, 'boolean') => _ref('StateBool'),
      _ => value,
    });
    return null;
  }

  T? _null<T>(List<Object> key, Map<String, Object?> schema) {
    _note(key, schema);
    return null;
  }
}

/// A source in which there is a map at every key, and nothing else, so every
/// component decoder runs to the end.
class _Everywhere implements DataSource {
  @override
  T? v<T extends Object>(List<Object> argsKey) => null;

  @override
  bool isList(List<Object> argsKey) => false;

  @override
  int length(List<Object> argsKey) => 0;

  @override
  bool isMap(List<Object> argsKey) => true;

  @override
  Widget child(List<Object> argsKey) => const SizedBox.shrink();

  @override
  Widget? optionalChild(List<Object> argsKey) => null;

  @override
  List<Widget> childList(List<Object> argsKey) => const <Widget>[];

  @override
  Widget builder(List<Object> argsKey, DynamicMap builderArg) => const SizedBox.shrink();

  @override
  Widget? optionalBuilder(List<Object> argsKey, DynamicMap builderArg) => null;

  @override
  VoidCallback? voidHandler(List<Object> argsKey, [DynamicMap? extraArguments]) => null;

  @override
  T? handler<T extends Function>(List<Object> argsKey, HandlerGenerator<T> generator) => null;
}
