import 'actions/actions.dart';
import 'decode/decoder.dart' show curveNames;
import 'decode/icons.g.dart';
import 'decode/resolver.dart';
import 'library.dart';
import 'theme/theme_data_decoder.dart';
import 'theme/tokens.dart';
import 'widgets/spec.dart';

/// Everything an editor needs to know about the `ui` library, as JSON: each
/// widget's parameters and documentation, each action's, what every
/// parameter type accepts, and the token names a theme resolves.
///
/// `catalog.json` beside this package is this, written by
/// `UPDATE_CATALOG=1 flutter test test/catalog_export_test.dart` and checked
/// by the same test, so the file the studio reads cannot fall behind the code.
Map<String, Object?> uiCatalog() => <String, Object?>{
  'library': uiLibraryName.toString(),
  'version': 1,
  'widgets': <Map<String, Object?>>[for (final UiWidget w in uiWidgets) w.toJson()],
  'actions': <Map<String, Object?>>[for (final UiAction a in uiActions) a.toJson()],
  'types': uiTypes,
  'tokens': <String, Object?>{
    'colors': <String>[...colorRoles, ...themeColorNames, 'transparent', 'black', 'white'],
    'textStyles': textThemeNames,
    'spacing': UiTokens.defaultSpacing,
    'radius': UiTokens.defaultRadius,
    'curves': curveNames.toList(),
  },
  'theme': <String, Object?>{
    'keys': themeDataKeys,
    'components': <String, Object?>{
      for (final MapEntry<String, ThemeComponent> e in themeComponents.entries) e.key: e.value.keys,
    },
  },
};

/// Every icon name a remote file may use, Material first.
List<String> uiIconNames() => <String>[
  ...materialIcons.keys,
  for (final String name in cupertinoIcons.keys) 'cupertino.$name',
];
