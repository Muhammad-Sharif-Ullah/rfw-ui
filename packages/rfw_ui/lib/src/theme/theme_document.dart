import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme_data_decoder.dart';

/// A whole theme -- light, dark, and which one to show -- as one document.
///
///     {
///       name: "Acme",
///       mode: "system",                                  // light | dark | system
///       shared: {                                        // both brightnesses
///         fontFamily: "Inter",
///         textTheme: { displaySmall: { fontWeight: "bold", letterSpacing: -1 } },
///         tokens: { spacing: { md: 16 }, textStyles: { hero: { base: "displaySmall" } } },
///         filledButtonTheme: { style: { shape: "stadium", padding: { horizontal: "lg", vertical: "md" } } },
///       },
///       light: { colorScheme: { seed: 0xFF2F6BFF } },
///       dark:  { colorScheme: { seed: 0xFF2F6BFF }, scaffoldBackgroundColor: "#0A0A0C" },
///     }
///
/// `shared` is merged under each of `light` and `dark` (maps merge, anything
/// else in the brightness wins), and each result is a map in ThemeData's own
/// shape -- see [decodeThemeData]. A document with neither `light` nor `dark`
/// is the same theme in both brightnesses, its colour scheme grown from the
/// same seed for each.
///
/// The map is what `parseDataFile`, `decodeDataBlob` or `jsonDecode` give, so
/// a theme travels as `.rfwtxt`, `.rfw` or JSON alike.
@immutable
class UiThemeDocument {
  const UiThemeDocument({required this.name, required this.light, required this.dark, this.mode = ThemeMode.system});

  factory UiThemeDocument.decode(Map<String, Object?> document) {
    final Map<String, Object?> shared = <String, Object?>{
      ..._map(document['shared']),
      // A document with no brightness sections is all shared.
      if (!document.containsKey('light') && !document.containsKey('dark'))
        for (final MapEntry<String, Object?> e in document.entries)
          if (!_documentKeys.contains(e.key)) e.key: e.value,
    };
    return UiThemeDocument(
      name: document['name'] is String ? document['name']! as String : '',
      light: decodeThemeData(_merge(shared, _map(document['light'])), brightness: Brightness.light),
      dark: decodeThemeData(_merge(shared, _map(document['dark'])), brightness: Brightness.dark),
      mode: switch (document['mode']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );
  }

  final String name;
  final ThemeData light;
  final ThemeData dark;

  /// Which brightness the document asks to be shown in.
  final ThemeMode mode;

  ThemeData of(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  /// Keys the decoder does not know, as `"light.appBarTheme.backgroundColour"`.
  ///
  /// Decoding ignores them -- a theme must never fail to load over a typo --
  /// so this is how an editor finds them.
  static List<String> problems(Map<String, Object?> document) {
    final List<String> found = <String>[];
    final bool sectioned = document.containsKey('light') || document.containsKey('dark');
    for (final String key in document.keys) {
      if (!_documentKeys.contains(key) && sectioned) {
        found.add(key);
      }
    }
    void theme(String prefix, Map<String, Object?> map) {
      for (final MapEntry<String, Object?> entry in map.entries) {
        final String path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        final ThemeComponent? component = themeComponents[entry.key];
        if (component != null) {
          for (final String inner in _map(entry.value).keys) {
            if (!component.keys.contains(inner)) {
              found.add('$path.$inner');
            }
          }
        } else if (!themeDataKeys.contains(entry.key) && !_documentKeys.contains(entry.key)) {
          found.add(path);
        }
      }
    }

    if (sectioned) {
      for (final String section in <String>['shared', 'light', 'dark']) {
        theme(section, _map(document[section]));
      }
    } else {
      theme('', document);
    }
    return found;
  }

  static const Set<String> _documentKeys = <String>{'name', 'mode', 'shared', 'light', 'dark'};

  static Map<String, Object?> _map(Object? value) =>
      value is Map ? <String, Object?>{for (final MapEntry<Object?, Object?> e in value.entries) '${e.key}': e.value} : <String, Object?>{};

  /// [over] on top of [under]: maps merge key by key, anything else replaces.
  static Map<String, Object?> _merge(Map<String, Object?> under, Map<String, Object?> over) {
    final Map<String, Object?> out = Map<String, Object?>.of(under);
    for (final MapEntry<String, Object?> entry in over.entries) {
      final Object? below = out[entry.key];
      out[entry.key] = below is Map && entry.value is Map ? _merge(_map(below), _map(entry.value)) : entry.value;
    }
    return out;
  }
}

/// The theme an app shows, and which brightness, as something that can change.
///
/// Put a [UiTheme] above the MaterialApp and build the app from this:
///
///     ListenableBuilder(
///       listenable: controller,
///       builder: (context, _) => UiTheme(
///         controller: controller,
///         child: MaterialApp(theme: controller.light, darkTheme: controller.dark, themeMode: controller.mode),
///       ),
///     )
///
/// and a remote file can switch it: `event "ui.themeMode" { mode: "toggle" }`.
class UiThemeController extends ChangeNotifier {
  UiThemeController({UiThemeDocument? document, ThemeMode? mode})
    : _document = document,
      _mode = mode ?? document?.mode ?? ThemeMode.system;

  UiThemeDocument? _document;
  ThemeMode _mode;

  UiThemeDocument? get document => _document;

  /// Replaces the document. The mode stays what it is -- someone who chose
  /// dark should not be put back in the light because the theme was edited --
  /// unless [adoptMode] says to take the document's.
  void load(UiThemeDocument? document, {bool adoptMode = false}) {
    _document = document;
    if (adoptMode && document != null) {
      _mode = document.mode;
    }
    notifyListeners();
  }

  ThemeMode get mode => _mode;

  set mode(ThemeMode value) {
    if (value == _mode) {
      return;
    }
    _mode = value;
    notifyListeners();
  }

  /// Flips between light and dark, starting from what is on screen now.
  void toggle(Brightness current) => mode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;

  ThemeData get light => _document?.light ?? ThemeData(brightness: Brightness.light);

  ThemeData get dark => _document?.dark ?? ThemeData(brightness: Brightness.dark);
}

/// Makes a [UiThemeController] reachable from below, for `ui.themeMode`.
class UiTheme extends InheritedNotifier<UiThemeController> {
  const UiTheme({super.key, required UiThemeController controller, required super.child}) : super(notifier: controller);

  static UiThemeController? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<UiTheme>()?.notifier;
}

/// A [Theme] for part of an app -- a remote screen in a theme of its own --
/// that Cupertino widgets follow as well as Material ones.
///
/// Flutter's Theme builds its CupertinoTheme from the Material theme only
/// when there is no CupertinoTheme above it already; under a MaterialApp
/// there always is, so a nested Theme alone leaves every Cupertino widget in
/// the app's colours and brightness. This sets both.
class ScopedTheme extends StatelessWidget {
  const ScopedTheme({super.key, required this.data, required this.child});

  final ThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: MaterialBasedCupertinoThemeData(materialTheme: data),
      child: Theme(data: data, child: child),
    );
  }
}
