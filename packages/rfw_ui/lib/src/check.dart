import 'package:flutter/material.dart' hide Switch;
import 'package:rfw/rfw.dart';

import 'decode/decoder.dart' show iconNamed;
import 'decode/resolver.dart';
import 'library.dart';
import 'theme/tokens.dart';
import 'widgets/spec.dart';

/// What the catalog can tell about a remote file without running it: widgets
/// and arguments the kit does not have, icons that are not icons, and
/// colours, text styles, spacing and radius tokens that name nothing in
/// [theme] (Flutter's default theme when none is given). One line per
/// problem, with its line and column in [text] when [library] was parsed
/// with a `sourceIdentifier`.
///
/// rfw itself says nothing of any of these until the widget is built, and
/// then only that a widget is missing: an argument it does not know is
/// ignored, and a token that names nothing is the default. So a typo is a
/// screen that looks slightly wrong, with no message anywhere. This is the
/// message. The studio's render tool prints it; an editor can show it.
List<String> checkUiLibrary(RemoteWidgetLibrary library, String text, {ThemeData? theme}) {
  final ThemeData t = theme ?? ThemeData();
  final List<String> problems = <String>[];
  final Map<String, UiWidget> kit = <String, UiWidget>{for (final UiWidget w in uiWidgets) w.name: w};
  final Set<String> own = <String>{for (final WidgetDeclaration w in library.widgets) w.name};
  final bool importsUi = library.imports.any((Import i) => i.name == uiLibraryName);
  if (!importsUi) {
    problems.add('the file does not `import ui;`, so none of the kit is in reach');
  }
  final UiResolver resolve = UiResolver(
    colorScheme: t.colorScheme,
    textTheme: t.textTheme,
    tokens: t.extension<UiTokens>() ?? UiTokens.fallback,
    theme: t,
  );

  String at(BlobNode node) {
    final SourceRange? range = node.source;
    if (range == null) {
      return '';
    }
    final String before = text.substring(0, range.start.offset.clamp(0, text.length));
    final int line = '\n'.allMatches(before).length + 1;
    final int column = before.length - before.lastIndexOf('\n');
    return 'line $line:$column ';
  }

  void value(Object? v, String type, String where, BlobNode near) {
    if (v is! String) {
      return;
    }
    switch (type) {
      case 'IconData':
      case 'Widget|Icon':
        if (iconNamed(v) == null) {
          problems.add('${at(near)}$where: "$v" is not an icon name (Material names like "favorite_border", Cupertino ones as "cupertino.heart")');
        }
      case 'Color':
        if (resolve.color(v) == null) {
          problems.add('${at(near)}$where: "$v" is not a colour role, theme colour, named colour or #RRGGBB');
        }
      case 'TextStyle':
        if (resolve.textStyle(v) == null) {
          problems.add('${at(near)}$where: "$v" is not a text style (titleLarge, bodyMedium, ... or one the theme names)');
        }
      case 'Spacing':
      case 'EdgeInsets':
        if (resolve.spacing(v) == null) {
          problems.add('${at(near)}$where: "$v" is not a spacing token (${resolve.tokens.spacing.keys.join(', ')})');
        }
      case 'BorderRadius':
        if (resolve.radius(v) == null) {
          problems.add('${at(near)}$where: "$v" is not a radius token (${resolve.tokens.radius.keys.join(', ')})');
        }
    }
  }

  void walk(Object? node, String where) {
    if (node is ConstructorCall) {
      final UiWidget? widget = own.contains(node.name) ? null : kit[node.name];
      if (widget == null && !own.contains(node.name)) {
        problems.add('${at(node)}${node.name} is not a widget in the kit or this file');
      }
      if (widget != null) {
        final Map<String, UiParam> params = <String, UiParam>{for (final UiParam p in widget.params) p.name: p, 'key': keyParam};
        for (final MapEntry<String, Object?> arg in node.arguments.entries) {
          final UiParam? param = params[arg.key];
          if (param == null) {
            problems.add('${at(node)}${node.name}.${arg.key} is not an argument of ${node.name}');
            continue;
          }
          value(arg.value, param.type, '${node.name}.${arg.key}', node);
          // A text style map's base, and its colour.
          if (param.type == 'TextStyle' && arg.value is Map) {
            final Map<Object?, Object?> style = arg.value! as Map<Object?, Object?>;
            value(style['base'], 'TextStyle', '${node.name}.${arg.key}.base', node);
            value(style['color'], 'Color', '${node.name}.${arg.key}.color', node);
          }
        }
      }
      for (final MapEntry<String, Object?> arg in node.arguments.entries) {
        walk(arg.value, '${node.name}.${arg.key}');
      }
    } else if (node is Map) {
      node.forEach((Object? k, Object? v) => walk(v, '$where.$k'));
    } else if (node is List) {
      for (final Object? v in node) {
        walk(v, where);
      }
    } else if (node is Loop) {
      walk(node.output, where);
    } else if (node is Switch) {
      for (final Object v in node.outputs.values) {
        walk(v, where);
      }
    } else if (node is WidgetBuilderDeclaration) {
      walk(node.widget, where);
    }
  }

  for (final WidgetDeclaration declaration in library.widgets) {
    walk(declaration.root, declaration.name);
  }
  return problems;
}
