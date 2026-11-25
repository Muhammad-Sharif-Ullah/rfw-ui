import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// `theme.schema.json` is what the theme console validates documents against
/// and draws its form from. It is generated, and it is only worth having if
/// everything it accepts is something the app reads.
///
///     UPDATE_CATALOG=1 flutter test test/theme_schema_test.dart
void main() {
  final Map<String, Object?> schema = uiThemeSchema();
  final Map<String, Object?> defs = schema[r'$defs']! as Map<String, Object?>;
  final Map<String, Object?> properties = schema['properties']! as Map<String, Object?>;

  test('theme.schema.json is current', () {
    final String expected = '${const JsonEncoder.withIndent('  ').convert(schema)}\n';
    final File file = File('theme.schema.json');
    if (Platform.environment['UPDATE_CATALOG'] == '1') {
      file.writeAsStringSync(expected);
      return;
    }
    expect(file.readAsStringSync(), expected, reason: 'theme.schema.json is stale; run with UPDATE_CATALOG=1');
  });

  test('every top-level key is one decodeThemeData reads', () {
    final Set<String> read = <String>{'name', ...themeDataKeys, ...themeComponents.keys};
    expect(properties.keys.toSet().difference(read), isEmpty);
    expect(read.difference(properties.keys.toSet()), isEmpty);
  });

  test('every object lists its keys in x-order, and every reference resolves', () {
    final List<String> wrong = <String>[];
    void walk(Object? node, String path) {
      if (node is! Map) {
        return;
      }
      final Object? ref = node[r'$ref'];
      if (ref is String && !defs.containsKey(ref.split('/').last)) {
        wrong.add('$path refers to $ref, which is not defined');
      }
      final Object? props = node['properties'];
      if (props is Map) {
        final List<Object?> order = node['x-order']! as List<Object?>;
        if (!const ListEquality().equals(order.toList(), props.keys.toList())) {
          wrong.add('$path: x-order is not its properties in order');
        }
        props.forEach((Object? k, Object? v) => walk(v, '$path.$k'));
      }
      walk(node['items'], '$path[]');
      walk(node['additionalProperties'], '$path.*');
    }

    walk(schema, 'theme');
    defs.forEach((String k, Object? v) => walk(v, r'$defs.' '$k'));
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  // A key the schema allows that the decoder never reads would save, publish
  // and then do nothing at all.
  test('every key a value type allows is one its decoder reads', () {
    final Map<String, void Function(UiDecoder d, List<Object> key)> readers = <String, void Function(UiDecoder, List<Object>)>{
      'TextStyle': (UiDecoder d, List<Object> k) => d.textStyle(k),
      'EdgeInsets': (UiDecoder d, List<Object> k) => d.edgeInsets(k),
      'BorderSide': (UiDecoder d, List<Object> k) => d.borderSide(k),
      'Shape': (UiDecoder d, List<Object> k) => d.shape(k),
      'InputBorder': (UiDecoder d, List<Object> k) => d.inputBorder(k),
      'IconThemeData': (UiDecoder d, List<Object> k) => d.iconThemeData(k),
      'Size': (UiDecoder d, List<Object> k) => d.size(k),
      'Offset': (UiDecoder d, List<Object> k) => d.offset(k),
      'BoxConstraints': (UiDecoder d, List<Object> k) => d.boxConstraints(k),
      'BoxDecoration': (UiDecoder d, List<Object> k) => d.decoration(k),
      'ButtonStyle': (UiDecoder d, List<Object> k) => d.buttonStyle(k),
      'StateColor': (UiDecoder d, List<Object> k) => d.stateColor(k),
    };
    final List<String> wrong = <String>[];
    for (final MapEntry<String, void Function(UiDecoder, List<Object>)> entry in readers.entries) {
      final _Reads reads = _Reads();
      entry.value(
        UiDecoder(reads, const UiResolver(colorScheme: ColorScheme.light(), textTheme: TextTheme())),
        <Object>[_Reads.at],
      );
      final Map<String, Object?> def = defs[entry.key]! as Map<String, Object?>;
      final Set<String> allowed = (def['properties']! as Map<String, Object?>).keys.toSet();
      final Set<String> unread = allowed.difference(reads.read);
      if (unread.isNotEmpty) {
        wrong.add('${entry.key} allows ${unread.join(', ')}, which its decoder never reads');
      }
    }
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('every colour role, text style and token the schema allows reaches the theme', () {
    final Map<String, Object?> scheme = (defs['ColorScheme']! as Map<String, Object?>)['properties']! as Map<String, Object?>;
    final Map<String, Object?> styles = (defs['TextTheme']! as Map<String, Object?>)['properties']! as Map<String, Object?>;
    final List<String> roles = scheme.keys.where(colorRoles.contains).toList();
    final List<String> names = styles.keys.where(textThemeNames.contains).toList();
    expect(roles, hasLength(colorRoles.length));
    expect(names, hasLength(textThemeNames.length));
    final ThemeData theme = decodeThemeData(<String, Object?>{
      'colorScheme': <String, Object?>{for (int i = 0; i < roles.length; i += 1) roles[i]: 0xFF000000 + i + 1},
      'textTheme': <String, Object?>{
        for (int i = 0; i < names.length; i += 1) names[i]: <String, Object?>{'fontSize': 10 + i},
      },
      'tokens': <String, Object?>{
        'spacing': <String, Object?>{'gutter': 13},
        'radius': <String, Object?>{'pill': 99},
        'colors': <String, Object?>{'success': 0xFF00AA00},
        'textStyles': <String, Object?>{'hero': <String, Object?>{'base': 'displaySmall'}},
      },
    }, brightness: Brightness.light);
    for (int i = 0; i < roles.length; i += 1) {
      expect(colorRole(theme.colorScheme, roles[i]), Color(0xFF000000 + i + 1), reason: roles[i]);
    }
    for (int i = 0; i < names.length; i += 1) {
      expect(textThemeStyle(theme.textTheme, names[i])!.fontSize, 10 + i, reason: names[i]);
    }
    final UiTokens tokens = theme.extension<UiTokens>()!;
    expect(tokens.spacing['gutter'], 13);
    expect(tokens.radius['pill'], 99);
    expect(tokens.colors['success'], const Color(0xFF00AA00));
    expect(tokens.textStyleBases['hero'], 'displaySmall');
  });

  test('a document in the schema\'s own form decodes to what it says', () {
    final ThemeData theme = decodeThemeData(<String, Object?>{
      'name': 'Test',
      'brightness': 'light',
      'colorScheme': <String, Object?>{'seed': 0xFF2F6BFF, 'primary': 0xFF102030},
      'textTheme': <String, Object?>{
        'titleLarge': <String, Object?>{'fontSize': 30, 'fontWeight': 700},
      },
      'appBarTheme': <String, Object?>{
        'backgroundColor': 'surfaceContainer',
        'titleTextStyle': <String, Object?>{'base': 'titleLarge', 'color': 'primary'},
        'shape': <String, Object?>{'type': 'rounded', 'borderRadius': 12, 'side': <String, Object?>{'color': 0xFF000000, 'width': 2}},
      },
      'filledButtonTheme': <String, Object?>{
        'style': <String, Object?>{
          'backgroundColor': <String, Object?>{'default': 'primary', 'disabled': 'primary/38'},
          'padding': <String, Object?>{'horizontal': 24, 'vertical': 12},
          'minimumSize': <String, Object?>{'width': 0, 'height': 48},
        },
      },
    }, brightness: Brightness.light);
    expect(theme.colorScheme.primary, const Color(0xFF102030));
    expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w700);
    expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surfaceContainer);
    expect(theme.appBarTheme.titleTextStyle!.color, theme.colorScheme.primary);
    final RoundedRectangleBorder shape = theme.appBarTheme.shape! as RoundedRectangleBorder;
    expect(shape.side.width, 2);
    final ButtonStyle style = theme.filledButtonTheme.style!;
    expect(style.backgroundColor!.resolve(<WidgetState>{}), const Color(0xFF102030));
    expect(style.backgroundColor!.resolve(<WidgetState>{WidgetState.disabled})!.a, closeTo(0.38, 0.01));
    expect(style.padding!.resolve(<WidgetState>{}), const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 12));
    expect(style.minimumSize!.resolve(<WidgetState>{}), const Size(0, 48));
  });
}

/// A source with an empty map at [at], that notes every key asked for one
/// level under it.
class _Reads extends MapSource {
  _Reads() : super(<String, Object?>{at: <String, Object?>{}});

  static const String at = 'x';

  final Set<String> read = <String>{};

  void _note(List<Object> key) {
    if (key.length > 1 && key.first == at && key[1] is String) {
      read.add(key[1] as String);
    }
  }

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    _note(argsKey);
    return super.v<T>(argsKey);
  }

  @override
  bool isMap(List<Object> argsKey) {
    _note(argsKey);
    return super.isMap(argsKey);
  }

  @override
  bool isList(List<Object> argsKey) {
    _note(argsKey);
    return super.isList(argsKey);
  }

  // Says nothing of which keys are written, so a decoder asks after every
  // key it knows: those are what this records.
  @override
  Iterable<String>? keysAt(List<Object> key) => null;
}

/// Equality of two lists, element by element.
class ListEquality {
  const ListEquality();

  bool equals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
