import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// What a token in remote data stands for: the colour scheme, the text theme
/// and the [UiTokens] of one theme.
///
/// Inside a widget that is the theme in scope ([UiResolver.of]). While a theme
/// document is being decoded it is the scheme and text theme decoded so far,
/// which is how `appBarTheme: { backgroundColor: "surfaceContainer" }` can name
/// a role of the very theme it is part of.
@immutable
class UiResolver {
  const UiResolver({
    required this.colorScheme,
    required this.textTheme,
    this.tokens = UiTokens.fallback,
    this.theme,
    this.fontFamily,
  });

  factory UiResolver.of(BuildContext context) => UiResolver.fromTheme(Theme.of(context));

  /// Resolves against [theme], looked up already.
  factory UiResolver.fromTheme(ThemeData theme) => UiResolver(
    colorScheme: theme.colorScheme,
    textTheme: theme.textTheme,
    tokens: theme.extension<UiTokens>() ?? UiTokens.fallback,
    theme: theme,
  );

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final UiTokens tokens;

  /// The whole theme, when there is one; the theme-level colours
  /// (`scaffoldBackground`, `divider`, ...) resolve only through it.
  final ThemeData? theme;

  /// While a theme document is decoded: its `fontFamily`, which a component
  /// theme's text style that names no font of its own takes. Flutter applies
  /// `ThemeData(fontFamily:)` to the text theme only, so a button's
  /// `textStyle: { fontSize: 16 }` would otherwise be drawn in the platform's
  /// font whatever the theme says -- not what "the font every style uses"
  /// means. Null for widgets, whose styles inherit from the text around them.
  final String? fontFamily;

  /// A colour by token: a scheme role (`primary`), a theme colour
  /// (`scaffoldBackground`), a custom colour from [UiTokens.colors]
  /// (`success`), `#RRGGBB` / `#AARRGGBB`, or any of those with `/NN` for an
  /// opacity in percent (`onSurface/60`).
  Color? color(String token) {
    final int slash = token.lastIndexOf('/');
    if (slash > 0) {
      final Color? base = color(token.substring(0, slash));
      final double? percent = double.tryParse(token.substring(slash + 1));
      if (base == null || percent == null || percent < 0 || percent > 100) {
        return null;
      }
      return base.withValues(alpha: base.a * percent / 100);
    }
    if (token.startsWith('#')) {
      return _hex(token.substring(1));
    }
    return colorRole(colorScheme, token) ?? _themeColor(token) ?? tokens.colors[token] ?? _named[token];
  }

  /// A style by name: one the theme document named in [UiTokens.textStyles]
  /// -- over its base, resolved here, against this text theme -- else one of
  /// the fifteen [TextTheme] styles.
  TextStyle? textStyle(String name) => _textStyle(name, 0);

  TextStyle? _textStyle(String name, int depth) {
    final TextStyle? own = tokens.textStyles[name];
    if (own == null) {
      return textThemeStyle(textTheme, name);
    }
    final String? base = tokens.textStyleBases[name];
    // A named style may start from another named one; a chain that loops, or
    // runs absurdly long, stops at the text theme.
    final TextStyle? under = base == null
        ? null
        : (base == name || depth > 8 ? textThemeStyle(textTheme, base) : _textStyle(base, depth + 1));
    return under == null ? own : under.merge(own);
  }

  double? spacing(String name) => tokens.spacing[name];

  double? radius(String name) => tokens.radius[name];

  Color? _themeColor(String name) {
    final ThemeData? t = theme;
    if (t == null) {
      return null;
    }
    return switch (name) {
      'scaffoldBackground' => t.scaffoldBackgroundColor,
      'canvas' => t.canvasColor,
      'card' => t.cardColor,
      'divider' => t.dividerColor,
      'disabled' => t.disabledColor,
      'hint' => t.hintColor,
      'highlight' => t.highlightColor,
      'splash' => t.splashColor,
      'hover' => t.hoverColor,
      'focus' => t.focusColor,
      _ => null,
    };
  }

  static Color? _hex(String digits) {
    if (digits.length != 6 && digits.length != 8) {
      return null;
    }
    final int? value = int.tryParse(digits, radix: 16);
    if (value == null) {
      return null;
    }
    return Color(digits.length == 6 ? 0xFF000000 | value : value);
  }

  static const Map<String, Color> _named = <String, Color>{
    'transparent': Color(0x00000000),
    'black': Color(0xFF000000),
    'white': Color(0xFFFFFFFF),
  };
}

/// Every role of [ColorScheme] a token may name, in the order Material lists
/// them. Also the keys a theme document's `colorScheme` accepts.
const List<String> colorRoles = <String>[
  'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
  'primaryFixed', 'primaryFixedDim', 'onPrimaryFixed', 'onPrimaryFixedVariant',
  'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
  'secondaryFixed', 'secondaryFixedDim', 'onSecondaryFixed', 'onSecondaryFixedVariant',
  'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
  'tertiaryFixed', 'tertiaryFixedDim', 'onTertiaryFixed', 'onTertiaryFixedVariant',
  'error', 'onError', 'errorContainer', 'onErrorContainer',
  'surface', 'onSurface', 'surfaceDim', 'surfaceBright',
  'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer',
  'surfaceContainerHigh', 'surfaceContainerHighest', 'onSurfaceVariant',
  'outline', 'outlineVariant', 'shadow', 'scrim',
  'inverseSurface', 'onInverseSurface', 'inversePrimary', 'surfaceTint',
];

/// The theme-level colours a token may name besides the scheme's roles.
const List<String> themeColorNames = <String>[
  'scaffoldBackground', 'canvas', 'card', 'divider', 'disabled',
  'hint', 'highlight', 'splash', 'hover', 'focus',
];

/// The fifteen styles of a [TextTheme], by name.
const List<String> textThemeNames = <String>[
  'displayLarge', 'displayMedium', 'displaySmall',
  'headlineLarge', 'headlineMedium', 'headlineSmall',
  'titleLarge', 'titleMedium', 'titleSmall',
  'bodyLarge', 'bodyMedium', 'bodySmall',
  'labelLarge', 'labelMedium', 'labelSmall',
];

Color? colorRole(ColorScheme s, String name) => switch (name) {
  'primary' => s.primary,
  'onPrimary' => s.onPrimary,
  'primaryContainer' => s.primaryContainer,
  'onPrimaryContainer' => s.onPrimaryContainer,
  'primaryFixed' => s.primaryFixed,
  'primaryFixedDim' => s.primaryFixedDim,
  'onPrimaryFixed' => s.onPrimaryFixed,
  'onPrimaryFixedVariant' => s.onPrimaryFixedVariant,
  'secondary' => s.secondary,
  'onSecondary' => s.onSecondary,
  'secondaryContainer' => s.secondaryContainer,
  'onSecondaryContainer' => s.onSecondaryContainer,
  'secondaryFixed' => s.secondaryFixed,
  'secondaryFixedDim' => s.secondaryFixedDim,
  'onSecondaryFixed' => s.onSecondaryFixed,
  'onSecondaryFixedVariant' => s.onSecondaryFixedVariant,
  'tertiary' => s.tertiary,
  'onTertiary' => s.onTertiary,
  'tertiaryContainer' => s.tertiaryContainer,
  'onTertiaryContainer' => s.onTertiaryContainer,
  'tertiaryFixed' => s.tertiaryFixed,
  'tertiaryFixedDim' => s.tertiaryFixedDim,
  'onTertiaryFixed' => s.onTertiaryFixed,
  'onTertiaryFixedVariant' => s.onTertiaryFixedVariant,
  'error' => s.error,
  'onError' => s.onError,
  'errorContainer' => s.errorContainer,
  'onErrorContainer' => s.onErrorContainer,
  'surface' => s.surface,
  'onSurface' => s.onSurface,
  'surfaceDim' => s.surfaceDim,
  'surfaceBright' => s.surfaceBright,
  'surfaceContainerLowest' => s.surfaceContainerLowest,
  'surfaceContainerLow' => s.surfaceContainerLow,
  'surfaceContainer' => s.surfaceContainer,
  'surfaceContainerHigh' => s.surfaceContainerHigh,
  'surfaceContainerHighest' => s.surfaceContainerHighest,
  'onSurfaceVariant' => s.onSurfaceVariant,
  'outline' => s.outline,
  'outlineVariant' => s.outlineVariant,
  'shadow' => s.shadow,
  'scrim' => s.scrim,
  'inverseSurface' => s.inverseSurface,
  'onInverseSurface' => s.onInverseSurface,
  'inversePrimary' => s.inversePrimary,
  'surfaceTint' => s.surfaceTint,
  _ => null,
};

TextStyle? textThemeStyle(TextTheme t, String name) => switch (name) {
  'displayLarge' => t.displayLarge,
  'displayMedium' => t.displayMedium,
  'displaySmall' => t.displaySmall,
  'headlineLarge' => t.headlineLarge,
  'headlineMedium' => t.headlineMedium,
  'headlineSmall' => t.headlineSmall,
  'titleLarge' => t.titleLarge,
  'titleMedium' => t.titleMedium,
  'titleSmall' => t.titleSmall,
  'bodyLarge' => t.bodyLarge,
  'bodyMedium' => t.bodyMedium,
  'bodySmall' => t.bodySmall,
  'labelLarge' => t.labelLarge,
  'labelMedium' => t.labelMedium,
  'labelSmall' => t.labelSmall,
  _ => null,
};
