import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The parts of a design system `ThemeData` has no slot for.
///
/// A spacing scale, a radius scale, brand colours beyond the colour scheme's
/// roles, and named text styles. Registered as a [ThemeExtension], so it
/// travels with the theme, lerps with it and is read from the same
/// `Theme.of(context)` as everything else -- which is what lets a remote file
/// write `padding: "md"` or `style: "hero"` and mean whatever the current
/// theme says those are.
///
/// A theme without one still resolves the default scales, so a token never
/// silently becomes zero just because the app built its ThemeData by hand.
@immutable
class UiTokens extends ThemeExtension<UiTokens> {
  const UiTokens({
    this.spacing = defaultSpacing,
    this.radius = defaultRadius,
    this.colors = const <String, Color>{},
    this.textStyles = const <String, TextStyle>{},
    this.textStyleBases = const <String, String>{},
  });

  /// `padding: "md"`, `SizedBox(height: "lg")`, `Row(spacing: "sm")`.
  final Map<String, double> spacing;

  /// `borderRadius: "md"`, `shape: { type: "rounded", borderRadius: "lg" }`.
  final Map<String, double> radius;

  /// Colours by name beyond the colour scheme: `color: "success"`.
  final Map<String, Color> colors;

  /// Named text styles: `style: "hero"` or `{ base: "hero", ... }`. Each
  /// is what its definition says over its base, if [textStyleBases] names one.
  final Map<String, TextStyle> textStyles;

  /// The style each of [textStyles] starts from, by name (`"displaySmall"`).
  ///
  /// Kept as a name and not merged in at decode time, because a text theme
  /// has no sizes until it is used: `ThemeData.textTheme` holds colours and
  /// fonts, and `Theme` merges in the sizes and line heights for the locale.
  /// So `hero: { base: "displaySmall" }` is resolved against the text theme
  /// in scope, where displaySmall is 36 points -- see `UiResolver.textStyle`.
  final Map<String, String> textStyleBases;

  /// A 4-point scale, the same steps `rfw_theme`'s `AppSpacing` falls back to.
  static const Map<String, double> defaultSpacing = <String, double>{
    'none': 0,
    'xxs': 2,
    'xs': 4,
    'sm': 8,
    'md': 16,
    'lg': 24,
    'xl': 32,
    'xxl': 48,
  };

  /// The corners `rfw_theme`'s `AppShape` falls back to (4, 8, 16), widened at
  /// both ends, with `full` for pills and circles.
  static const Map<String, double> defaultRadius = <String, double>{
    'none': 0,
    'xs': 2,
    'sm': 4,
    'md': 8,
    'lg': 16,
    'xl': 28,
    'full': 9999,
  };

  static const UiTokens fallback = UiTokens();

  /// The tokens of the theme in scope, or the defaults.
  static UiTokens of(BuildContext context) => Theme.of(context).extension<UiTokens>() ?? fallback;

  @override
  UiTokens copyWith({
    Map<String, double>? spacing,
    Map<String, double>? radius,
    Map<String, Color>? colors,
    Map<String, TextStyle>? textStyles,
    Map<String, String>? textStyleBases,
  }) {
    return UiTokens(
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      colors: colors ?? this.colors,
      textStyles: textStyles ?? this.textStyles,
      textStyleBases: textStyleBases ?? this.textStyleBases,
    );
  }

  @override
  UiTokens lerp(UiTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return UiTokens(
      spacing: _lerpMap(spacing, other.spacing, t, (double a, double b) => lerpDouble(a, b, t)!),
      radius: _lerpMap(radius, other.radius, t, (double a, double b) => lerpDouble(a, b, t)!),
      colors: _lerpMap(colors, other.colors, t, (Color a, Color b) => Color.lerp(a, b, t)!),
      textStyles: _lerpMap(textStyles, other.textStyles, t, (TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!),
      // A name cannot be halfway between two names.
      textStyleBases: t < 0.5 ? textStyleBases : other.textStyleBases,
    );
  }

  /// Keys in both lerp; a key in only one side snaps at the midpoint, which is
  /// what Flutter does for every other value that cannot be interpolated.
  static Map<String, V> _lerpMap<V>(Map<String, V> a, Map<String, V> b, double t, V Function(V, V) lerp) {
    final Map<String, V> out = <String, V>{};
    for (final String key in <String>{...a.keys, ...b.keys}) {
      final V? x = a[key];
      final V? y = b[key];
      if (x != null && y != null) {
        out[key] = lerp(x, y);
      } else {
        final V? pick = t < 0.5 ? x : y;
        if (pick != null) {
          out[key] = pick;
        }
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is UiTokens &&
      _mapEquals(spacing, other.spacing) &&
      _mapEquals(radius, other.radius) &&
      _mapEquals(colors, other.colors) &&
      _mapEquals(textStyles, other.textStyles) &&
      _mapEquals(textStyleBases, other.textStyleBases);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(spacing.entries.map((MapEntry<String, double> e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(radius.entries.map((MapEntry<String, double> e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(colors.entries.map((MapEntry<String, Color> e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(textStyles.entries.map((MapEntry<String, TextStyle> e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(textStyleBases.entries.map((MapEntry<String, String> e) => Object.hash(e.key, e.value))),
  );

  static bool _mapEquals<V>(Map<String, V> a, Map<String, V> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, V> entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// Shorthands for a widget written in Dart under a theme with [UiTokens]:
/// `context.spacing.md`, `context.radius.lg`, `context.text.titleLarge`,
/// `context.colors.primary`. The same tokens a remote file reaches as
/// `padding: "md"`, so a Dart screen and a remote one cannot drift apart.
extension UiThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  UiTokens get tokens => UiTokens.of(this);

  /// The spacing scale: `context.spacing.md`, `context.spacing['gutter']`.
  UiScale get spacing => UiScale(UiTokens.of(this).spacing);

  /// The radius scale: `context.radius.lg`.
  UiScale get radius => UiScale(UiTokens.of(this).radius);
}

/// One of a theme's scales, read by name.
@immutable
class UiScale {
  const UiScale(this.values);

  final Map<String, double> values;

  /// The step called [name], or 0 when the theme has none by that name.
  double operator [](String name) => values[name] ?? 0;

  double get none => this['none'];
  double get xxs => this['xxs'];
  double get xs => this['xs'];
  double get sm => this['sm'];
  double get md => this['md'];
  double get lg => this['lg'];
  double get xl => this['xl'];
  double get xxl => this['xxl'];
  double get full => this['full'];
}
