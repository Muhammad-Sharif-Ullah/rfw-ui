import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../decode/decoder.dart';
import '../decode/map_source.dart';
import '../decode/resolver.dart';
import 'tokens.dart';

/// A [ThemeData] from a map that mirrors its constructor.
///
/// The keys are `ThemeData`'s own names -- `colorScheme`, `textTheme`,
/// `appBarTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, ... -- and so
/// are the keys inside each component theme, so the Flutter documentation is
/// the documentation for this format too. Every value reads through
/// [UiDecoder], which is what lets a component theme name a role of the very
/// colour scheme it sits beside: `appBarTheme: { backgroundColor:
/// "surfaceContainer" }`.
///
/// Anything left out is ThemeData's own default for the brightness, so a
/// document need only say what differs.
ThemeData decodeThemeData(Map<String, Object?> map, {Brightness? brightness}) {
  final MapSource source = MapSource(map);

  // 1. The colour scheme, from a seed or Material's baseline, then overrides.
  final Brightness b = brightness ??
      switch (source.v<String>(<Object>['colorScheme', 'brightness']) ?? source.v<String>(<Object>['brightness'])) {
        'dark' => Brightness.dark,
        _ => Brightness.light,
      };
  final ColorScheme scheme = _colorScheme(source, b);

  // 2. ThemeData's own defaults for that scheme, which is where the text
  // theme every override starts from comes from.
  final UiDecoder early = UiDecoder(source, UiResolver(colorScheme: scheme, textTheme: const TextTheme()));
  final String? fontFamily = early.string(<Object>['fontFamily']);
  final ThemeData base = ThemeData(
    brightness: b,
    colorScheme: scheme,
    fontFamily: fontFamily,
    fontFamilyFallback: early.strings(<Object>['fontFamilyFallback']),
    useMaterial3: early.boolean(<Object>['useMaterial3']) ?? true,
  );
  final TextTheme textTheme = _textTheme(source, scheme, base.textTheme, <Object>['textTheme']);

  // 3. Tokens, whose text styles may start from the text theme.
  final UiTokens tokens = _tokens(source, scheme, textTheme);

  // 4. Everything else, with every token resolvable.
  final UiDecoder d = UiDecoder(
    source,
    UiResolver(colorScheme: scheme, textTheme: textTheme, tokens: tokens, theme: base, fontFamily: fontFamily),
  );
  List<Object> k(String name) => <Object>[name];
  T? component<T>(String name) => themeComponents[name]!.build(d, k(name)) as T?;

  return ThemeData(
    brightness: b,
    colorScheme: scheme,
    useMaterial3: d.boolean(k('useMaterial3')) ?? true,
    fontFamily: fontFamily,
    fontFamilyFallback: d.strings(k('fontFamilyFallback')),
    textTheme: textTheme,
    primaryTextTheme: _textTheme(source, scheme, base.primaryTextTheme, k('primaryTextTheme')),
    visualDensity: d.visualDensity(k('visualDensity')),
    materialTapTargetSize: d.enumValue(MaterialTapTargetSize.values, k('materialTapTargetSize')),
    splashFactory: _splashFactory(d.string(k('splashFactory'))),
    applyElevationOverlayColor: d.boolean(k('applyElevationOverlayColor')),
    platform: d.enumValue(TargetPlatform.values, k('platform')),
    pageTransitionsTheme: _pageTransitions(d.string(k('pageTransitionsTheme'))),
    canvasColor: d.color(k('canvasColor')),
    cardColor: d.color(k('cardColor')),
    disabledColor: d.color(k('disabledColor')),
    dividerColor: d.color(k('dividerColor')),
    focusColor: d.color(k('focusColor')),
    highlightColor: d.color(k('highlightColor')),
    hintColor: d.color(k('hintColor')),
    hoverColor: d.color(k('hoverColor')),
    primaryColor: d.color(k('primaryColor')),
    scaffoldBackgroundColor: d.color(k('scaffoldBackgroundColor')),
    secondaryHeaderColor: d.color(k('secondaryHeaderColor')),
    shadowColor: d.color(k('shadowColor')),
    splashColor: d.color(k('splashColor')),
    unselectedWidgetColor: d.color(k('unselectedWidgetColor')),
    iconTheme: d.iconThemeData(k('iconTheme')),
    primaryIconTheme: d.iconThemeData(k('primaryIconTheme')),
    appBarTheme: component<AppBarThemeData>('appBarTheme'),
    badgeTheme: component<BadgeThemeData>('badgeTheme'),
    bottomAppBarTheme: component<BottomAppBarThemeData>('bottomAppBarTheme'),
    bottomNavigationBarTheme: component<BottomNavigationBarThemeData>('bottomNavigationBarTheme'),
    bottomSheetTheme: component<BottomSheetThemeData>('bottomSheetTheme'),
    cardTheme: component<CardThemeData>('cardTheme'),
    checkboxTheme: component<CheckboxThemeData>('checkboxTheme'),
    chipTheme: component<ChipThemeData>('chipTheme'),
    cupertinoOverrideTheme: component<NoDefaultCupertinoThemeData>('cupertinoOverrideTheme'),
    datePickerTheme: component<DatePickerThemeData>('datePickerTheme'),
    dialogTheme: component<DialogThemeData>('dialogTheme'),
    dividerTheme: component<DividerThemeData>('dividerTheme'),
    drawerTheme: component<DrawerThemeData>('drawerTheme'),
    dropdownMenuTheme: component<DropdownMenuThemeData>('dropdownMenuTheme'),
    elevatedButtonTheme: component<ElevatedButtonThemeData>('elevatedButtonTheme'),
    expansionTileTheme: component<ExpansionTileThemeData>('expansionTileTheme'),
    filledButtonTheme: component<FilledButtonThemeData>('filledButtonTheme'),
    floatingActionButtonTheme: component<FloatingActionButtonThemeData>('floatingActionButtonTheme'),
    iconButtonTheme: component<IconButtonThemeData>('iconButtonTheme'),
    inputDecorationTheme: component<InputDecorationThemeData>('inputDecorationTheme'),
    listTileTheme: component<ListTileThemeData>('listTileTheme'),
    navigationBarTheme: component<NavigationBarThemeData>('navigationBarTheme'),
    navigationDrawerTheme: component<NavigationDrawerThemeData>('navigationDrawerTheme'),
    navigationRailTheme: component<NavigationRailThemeData>('navigationRailTheme'),
    outlinedButtonTheme: component<OutlinedButtonThemeData>('outlinedButtonTheme'),
    popupMenuTheme: component<PopupMenuThemeData>('popupMenuTheme'),
    progressIndicatorTheme: component<ProgressIndicatorThemeData>('progressIndicatorTheme'),
    radioTheme: component<RadioThemeData>('radioTheme'),
    scrollbarTheme: component<ScrollbarThemeData>('scrollbarTheme'),
    searchBarTheme: component<SearchBarThemeData>('searchBarTheme'),
    segmentedButtonTheme: component<SegmentedButtonThemeData>('segmentedButtonTheme'),
    sliderTheme: component<SliderThemeData>('sliderTheme'),
    snackBarTheme: component<SnackBarThemeData>('snackBarTheme'),
    switchTheme: component<SwitchThemeData>('switchTheme'),
    tabBarTheme: component<TabBarThemeData>('tabBarTheme'),
    textButtonTheme: component<TextButtonThemeData>('textButtonTheme'),
    textSelectionTheme: component<TextSelectionThemeData>('textSelectionTheme'),
    timePickerTheme: component<TimePickerThemeData>('timePickerTheme'),
    tooltipTheme: component<TooltipThemeData>('tooltipTheme'),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}

/// The top-level keys [decodeThemeData] reads besides the component themes.
const List<String> themeDataKeys = <String>[
  'brightness', 'colorScheme', 'useMaterial3', 'fontFamily', 'fontFamilyFallback', 'textTheme', 'primaryTextTheme',
  'tokens', 'visualDensity', 'materialTapTargetSize', 'splashFactory', 'applyElevationOverlayColor', 'platform',
  'pageTransitionsTheme', 'canvasColor', 'cardColor', 'disabledColor', 'dividerColor', 'focusColor', 'highlightColor',
  'hintColor', 'hoverColor', 'primaryColor', 'scaffoldBackgroundColor', 'secondaryHeaderColor', 'shadowColor',
  'splashColor', 'unselectedWidgetColor', 'iconTheme', 'primaryIconTheme',
];

ColorScheme _colorScheme(MapSource source, Brightness b) {
  const List<Object> key = <Object>['colorScheme'];
  final UiDecoder seedReader = UiDecoder(source, UiResolver(colorScheme: ColorScheme.fromSeed(seedColor: _baseline), textTheme: const TextTheme()));
  final Color seed = seedReader.color(<Object>[...key, 'seed']) ?? _baseline;
  final ColorScheme fromSeed = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: b,
    dynamicSchemeVariant: seedReader.enumValue(DynamicSchemeVariant.values, <Object>[...key, 'variant']) ?? DynamicSchemeVariant.tonalSpot,
    contrastLevel: (seedReader.number(<Object>[...key, 'contrastLevel']) ?? 0).clamp(-1, 1),
  );
  // Two passes, so a role may name another role of this same document:
  // `surfaceTint: "primary"` is the primary the document sets, not the
  // seed's. First the roles given as colours; then the ones given as names,
  // read against the scheme the first pass made.
  bool named(String name) {
    final String? token = source.v<String>(<Object>[...key, name]);
    return token != null && !token.startsWith('#');
  }

  final UiDecoder first = UiDecoder(source, UiResolver(colorScheme: fromSeed, textTheme: const TextTheme()));
  final ColorScheme given = _withRoles(fromSeed, (String name) => named(name) ? null : first.color(<Object>[...key, name]));
  final UiDecoder second = UiDecoder(source, UiResolver(colorScheme: given, textTheme: const TextTheme()));
  return _withRoles(given, (String name) => named(name) ? second.color(<Object>[...key, name]) : null);
}

/// [s] with each role [role] gives replaced, and the rest as they are.
ColorScheme _withRoles(ColorScheme s, Color? Function(String name) role) {
  return s.copyWith(
    primary: role('primary'),
    onPrimary: role('onPrimary'),
    primaryContainer: role('primaryContainer'),
    onPrimaryContainer: role('onPrimaryContainer'),
    primaryFixed: role('primaryFixed'),
    primaryFixedDim: role('primaryFixedDim'),
    onPrimaryFixed: role('onPrimaryFixed'),
    onPrimaryFixedVariant: role('onPrimaryFixedVariant'),
    secondary: role('secondary'),
    onSecondary: role('onSecondary'),
    secondaryContainer: role('secondaryContainer'),
    onSecondaryContainer: role('onSecondaryContainer'),
    secondaryFixed: role('secondaryFixed'),
    secondaryFixedDim: role('secondaryFixedDim'),
    onSecondaryFixed: role('onSecondaryFixed'),
    onSecondaryFixedVariant: role('onSecondaryFixedVariant'),
    tertiary: role('tertiary'),
    onTertiary: role('onTertiary'),
    tertiaryContainer: role('tertiaryContainer'),
    onTertiaryContainer: role('onTertiaryContainer'),
    tertiaryFixed: role('tertiaryFixed'),
    tertiaryFixedDim: role('tertiaryFixedDim'),
    onTertiaryFixed: role('onTertiaryFixed'),
    onTertiaryFixedVariant: role('onTertiaryFixedVariant'),
    error: role('error'),
    onError: role('onError'),
    errorContainer: role('errorContainer'),
    onErrorContainer: role('onErrorContainer'),
    surface: role('surface'),
    onSurface: role('onSurface'),
    surfaceDim: role('surfaceDim'),
    surfaceBright: role('surfaceBright'),
    surfaceContainerLowest: role('surfaceContainerLowest'),
    surfaceContainerLow: role('surfaceContainerLow'),
    surfaceContainer: role('surfaceContainer'),
    surfaceContainerHigh: role('surfaceContainerHigh'),
    surfaceContainerHighest: role('surfaceContainerHighest'),
    onSurfaceVariant: role('onSurfaceVariant'),
    outline: role('outline'),
    outlineVariant: role('outlineVariant'),
    shadow: role('shadow'),
    scrim: role('scrim'),
    inverseSurface: role('inverseSurface'),
    onInverseSurface: role('onInverseSurface'),
    inversePrimary: role('inversePrimary'),
    surfaceTint: role('surfaceTint'),
  );
}

/// Material 3's baseline purple: what a scheme with no seed grows from, and
/// what `ThemeData()` itself uses.
const Color _baseline = Color(0xFF6750A4);

/// The theme's fifteen styles, each `base` the default of the same name (or
/// the named one), with the document's keys over it. `bodyColor` and
/// `displayColor` recolour the lot, as `TextTheme.apply` does.
TextTheme _textTheme(MapSource source, ColorScheme scheme, TextTheme defaults, List<Object> key) {
  if (!source.isMap(key)) {
    return defaults;
  }
  final UiDecoder reader = UiDecoder(source, UiResolver(colorScheme: scheme, textTheme: defaults));
  final TextTheme recoloured = defaults.apply(
    bodyColor: reader.color(<Object>[...key, 'bodyColor']),
    displayColor: reader.color(<Object>[...key, 'displayColor']),
    fontFamily: reader.string(<Object>[...key, 'fontFamily']),
  );
  // ThemeData's text theme has no sizes -- Theme merges those in per locale
  // -- so a style that is its own default changed stays size-less and gets
  // its locale's size when used. One that names a different base needs that
  // base's size and line height now, or it would get its own name's instead;
  // those come from Material's English-like geometry.
  final UiDecoder colours = UiDecoder(
    source,
    UiResolver(colorScheme: scheme, textTheme: Typography.material2021().englishLike.merge(recoloured)),
  );
  TextStyle? style(String name) {
    final List<Object> at = <Object>[...key, name];
    final TextStyle? own = textThemeStyle(recoloured, name);
    if (!source.isMap(at) && source.v<String>(at) == null) {
      return own;
    }
    // A style with no `base` starts from its own default, not from nothing:
    // `titleLarge: { fontWeight: "bold" }` is titleLarge made bold. Naming
    // itself as its base is the same thing.
    final String? base = colours.textStyleBase(at);
    if (base == null || base == name) {
      final TextStyle? decoded = colours.textStyleOverrides(at);
      return own?.merge(decoded) ?? decoded;
    }
    return colours.textStyle(at);
  }

  return TextTheme(
    displayLarge: style('displayLarge'),
    displayMedium: style('displayMedium'),
    displaySmall: style('displaySmall'),
    headlineLarge: style('headlineLarge'),
    headlineMedium: style('headlineMedium'),
    headlineSmall: style('headlineSmall'),
    titleLarge: style('titleLarge'),
    titleMedium: style('titleMedium'),
    titleSmall: style('titleSmall'),
    bodyLarge: style('bodyLarge'),
    bodyMedium: style('bodyMedium'),
    bodySmall: style('bodySmall'),
    labelLarge: style('labelLarge'),
    labelMedium: style('labelMedium'),
    labelSmall: style('labelSmall'),
  );
}

/// `tokens: { spacing, radius, colors, textStyles }`. Scales are merged over
/// the defaults, so a document can change `md` without restating `xs`.
UiTokens _tokens(MapSource source, ColorScheme scheme, TextTheme textTheme) {
  const List<Object> key = <Object>['tokens'];
  final Map<String, Object?> root = source.root;
  final Object? raw = root['tokens'];
  if (raw is! Map) {
    return UiTokens.fallback;
  }
  final UiDecoder d = UiDecoder(source, UiResolver(colorScheme: scheme, textTheme: textTheme));
  Map<String, V> read<V>(String group, V? Function(List<Object> k) decode) {
    final Object? entries = raw[group];
    if (entries is! Map) {
      return <String, V>{};
    }
    return <String, V>{
      for (final Object? name in entries.keys)
        if (name is String && decode(<Object>[...key, group, name]) != null) name: decode(<Object>[...key, group, name]) as V,
    };
  }

  return UiTokens(
    spacing: <String, double>{...UiTokens.defaultSpacing, ...read<double>('spacing', d.number)},
    radius: <String, double>{...UiTokens.defaultRadius, ...read<double>('radius', d.number)},
    colors: read<Color>('colors', d.color),
    // A named style's base stays a name, resolved where the style is used:
    // only there does the text theme have the locale's sizes in it.
    textStyles: read<TextStyle>('textStyles', d.textStyleOverrides),
    textStyleBases: read<String>('textStyles', d.textStyleBase),
  );
}

InteractiveInkFeatureFactory? _splashFactory(String? name) => switch (name) {
  'ripple' => InkRipple.splashFactory,
  'sparkle' => InkSparkle.splashFactory,
  'splash' => InkSplash.splashFactory,
  'none' => NoSplash.splashFactory,
  _ => null,
};

/// One transition for every platform: `"zoom"`, `"fadeForwards"`,
/// `"fadeUpwards"`, `"openUpwards"`, `"cupertino"` or `"predictiveBack"`.
PageTransitionsTheme? _pageTransitions(String? name) {
  final PageTransitionsBuilder? builder = switch (name) {
    'zoom' => const ZoomPageTransitionsBuilder(),
    'fadeForwards' => const FadeForwardsPageTransitionsBuilder(),
    'fadeUpwards' => const FadeUpwardsPageTransitionsBuilder(),
    'openUpwards' => const OpenUpwardsPageTransitionsBuilder(),
    'cupertino' => const CupertinoPageTransitionsBuilder(),
    'predictiveBack' => const PredictiveBackPageTransitionsBuilder(),
    _ => null,
  };
  if (builder == null) {
    return null;
  }
  return PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{for (final TargetPlatform p in TargetPlatform.values) p: builder},
  );
}

/// One component theme: the keys it reads, and how.
class ThemeComponent {
  const ThemeComponent(this.keys, this.build);

  final List<String> keys;
  final Object? Function(UiDecoder d, List<Object> key) build;
}

/// Every component theme [decodeThemeData] reads, by its ThemeData name.
/// `test/theme_test.dart` holds each to its key list, as the widget catalog
/// is held to its parameters.
final Map<String, ThemeComponent> themeComponents = <String, ThemeComponent>{
  'appBarTheme': ThemeComponent(
    <String>['backgroundColor', 'foregroundColor', 'elevation', 'scrolledUnderElevation', 'shadowColor', 'surfaceTintColor',
      'shape', 'iconTheme', 'actionsIconTheme', 'centerTitle', 'titleSpacing', 'leadingWidth', 'toolbarHeight',
      'toolbarTextStyle', 'titleTextStyle', 'actionsPadding'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => AppBarThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      foregroundColor: d.color(k('foregroundColor')),
      elevation: d.number(k('elevation')),
      scrolledUnderElevation: d.number(k('scrolledUnderElevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      shape: d.shape(k('shape')),
      iconTheme: d.iconThemeData(k('iconTheme')),
      actionsIconTheme: d.iconThemeData(k('actionsIconTheme')),
      centerTitle: d.boolean(k('centerTitle')),
      titleSpacing: d.spacing(k('titleSpacing')),
      leadingWidth: d.number(k('leadingWidth')),
      toolbarHeight: d.number(k('toolbarHeight')),
      toolbarTextStyle: d.textStyle(k('toolbarTextStyle')),
      titleTextStyle: d.textStyle(k('titleTextStyle')),
      actionsPadding: d.edgeInsets(k('actionsPadding')),
    )),
  ),
  'badgeTheme': ThemeComponent(
    <String>['backgroundColor', 'textColor', 'smallSize', 'largeSize', 'textStyle', 'padding', 'alignment', 'offset'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => BadgeThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      textColor: d.color(k('textColor')),
      smallSize: d.number(k('smallSize')),
      largeSize: d.number(k('largeSize')),
      textStyle: d.textStyle(k('textStyle')),
      padding: d.edgeInsets(k('padding')),
      alignment: d.alignment(k('alignment')),
      offset: d.offset(k('offset')),
    )),
  ),
  'bottomAppBarTheme': ThemeComponent(
    <String>['color', 'elevation', 'height', 'surfaceTintColor', 'shadowColor', 'padding'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => BottomAppBarThemeData(
      color: d.color(k('color')),
      elevation: d.number(k('elevation')),
      height: d.number(k('height')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      shadowColor: d.color(k('shadowColor')),
      padding: d.edgeInsets(k('padding')),
    )),
  ),
  'bottomNavigationBarTheme': ThemeComponent(
    <String>['backgroundColor', 'elevation', 'selectedIconTheme', 'unselectedIconTheme', 'selectedItemColor',
      'unselectedItemColor', 'selectedLabelStyle', 'unselectedLabelStyle', 'showSelectedLabels', 'showUnselectedLabels',
      'type', 'landscapeLayout'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => BottomNavigationBarThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      selectedIconTheme: d.iconThemeData(k('selectedIconTheme')),
      unselectedIconTheme: d.iconThemeData(k('unselectedIconTheme')),
      selectedItemColor: d.color(k('selectedItemColor')),
      unselectedItemColor: d.color(k('unselectedItemColor')),
      selectedLabelStyle: d.textStyle(k('selectedLabelStyle')),
      unselectedLabelStyle: d.textStyle(k('unselectedLabelStyle')),
      showSelectedLabels: d.boolean(k('showSelectedLabels')),
      showUnselectedLabels: d.boolean(k('showUnselectedLabels')),
      type: d.enumValue(BottomNavigationBarType.values, k('type')),
      landscapeLayout: d.enumValue(BottomNavigationBarLandscapeLayout.values, k('landscapeLayout')),
    )),
  ),
  'bottomSheetTheme': ThemeComponent(
    <String>['backgroundColor', 'surfaceTintColor', 'elevation', 'modalBackgroundColor', 'modalBarrierColor', 'shadowColor',
      'modalElevation', 'shape', 'showDragHandle', 'dragHandleColor', 'dragHandleSize', 'clipBehavior', 'constraints'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => BottomSheetThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      elevation: d.number(k('elevation')),
      modalBackgroundColor: d.color(k('modalBackgroundColor')),
      modalBarrierColor: d.color(k('modalBarrierColor')),
      shadowColor: d.color(k('shadowColor')),
      modalElevation: d.number(k('modalElevation')),
      shape: d.shape(k('shape')),
      showDragHandle: d.boolean(k('showDragHandle')),
      dragHandleColor: d.color(k('dragHandleColor')),
      dragHandleSize: d.size(k('dragHandleSize')),
      clipBehavior: d.enumValue(Clip.values, k('clipBehavior')),
      constraints: d.boxConstraints(k('constraints')),
    )),
  ),
  'cardTheme': ThemeComponent(
    <String>['clipBehavior', 'color', 'shadowColor', 'surfaceTintColor', 'elevation', 'margin', 'shape'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => CardThemeData(
      clipBehavior: d.enumValue(Clip.values, k('clipBehavior')),
      color: d.color(k('color')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      elevation: d.number(k('elevation')),
      margin: d.edgeInsets(k('margin')),
      shape: d.shape(k('shape')),
    )),
  ),
  'checkboxTheme': ThemeComponent(
    <String>['fillColor', 'checkColor', 'overlayColor', 'splashRadius', 'materialTapTargetSize', 'visualDensity', 'shape', 'side'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => CheckboxThemeData(
      fillColor: d.stateColor(k('fillColor')),
      checkColor: d.stateColor(k('checkColor')),
      overlayColor: d.stateColor(k('overlayColor')),
      splashRadius: d.number(k('splashRadius')),
      materialTapTargetSize: d.enumValue(MaterialTapTargetSize.values, k('materialTapTargetSize')),
      visualDensity: d.visualDensity(k('visualDensity')),
      shape: d.shape(k('shape')),
      side: d.borderSide(k('side')),
    )),
  ),
  'chipTheme': ThemeComponent(
    <String>['color', 'backgroundColor', 'deleteIconColor', 'disabledColor', 'selectedColor', 'secondarySelectedColor',
      'shadowColor', 'surfaceTintColor', 'selectedShadowColor', 'showCheckmark', 'checkmarkColor', 'labelPadding', 'padding',
      'side', 'shape', 'labelStyle', 'secondaryLabelStyle', 'brightness', 'elevation', 'pressElevation', 'iconTheme'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => ChipThemeData(
      color: d.stateColor(k('color')),
      backgroundColor: d.color(k('backgroundColor')),
      deleteIconColor: d.color(k('deleteIconColor')),
      disabledColor: d.color(k('disabledColor')),
      selectedColor: d.color(k('selectedColor')),
      secondarySelectedColor: d.color(k('secondarySelectedColor')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      selectedShadowColor: d.color(k('selectedShadowColor')),
      showCheckmark: d.boolean(k('showCheckmark')),
      checkmarkColor: d.color(k('checkmarkColor')),
      labelPadding: d.edgeInsets(k('labelPadding')),
      padding: d.edgeInsets(k('padding')),
      side: d.borderSide(k('side')),
      shape: d.shape(k('shape')),
      labelStyle: d.textStyle(k('labelStyle')),
      secondaryLabelStyle: d.textStyle(k('secondaryLabelStyle')),
      brightness: d.enumValue(Brightness.values, k('brightness')),
      elevation: d.number(k('elevation')),
      pressElevation: d.number(k('pressElevation')),
      iconTheme: d.iconThemeData(k('iconTheme')),
    )),
  ),
  'cupertinoOverrideTheme': ThemeComponent(
    <String>['brightness', 'primaryColor', 'primaryContrastingColor', 'barBackgroundColor', 'scaffoldBackgroundColor', 'applyThemeToAll'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => NoDefaultCupertinoThemeData(
      brightness: d.enumValue(Brightness.values, k('brightness')),
      primaryColor: d.color(k('primaryColor')),
      primaryContrastingColor: d.color(k('primaryContrastingColor')),
      barBackgroundColor: d.color(k('barBackgroundColor')),
      scaffoldBackgroundColor: d.color(k('scaffoldBackgroundColor')),
      applyThemeToAll: d.boolean(k('applyThemeToAll')),
    )),
  ),
  'datePickerTheme': ThemeComponent(
    <String>['backgroundColor', 'elevation', 'shadowColor', 'surfaceTintColor', 'shape', 'headerBackgroundColor',
      'headerForegroundColor', 'headerHeadlineStyle', 'headerHelpStyle', 'weekdayStyle', 'dayStyle', 'dayForegroundColor',
      'dayBackgroundColor', 'todayForegroundColor', 'todayBackgroundColor', 'yearStyle', 'rangeSelectionBackgroundColor',
      'dividerColor', 'cancelButtonStyle', 'confirmButtonStyle'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => DatePickerThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      shape: d.shape(k('shape')),
      headerBackgroundColor: d.color(k('headerBackgroundColor')),
      headerForegroundColor: d.color(k('headerForegroundColor')),
      headerHeadlineStyle: d.textStyle(k('headerHeadlineStyle')),
      headerHelpStyle: d.textStyle(k('headerHelpStyle')),
      weekdayStyle: d.textStyle(k('weekdayStyle')),
      dayStyle: d.textStyle(k('dayStyle')),
      dayForegroundColor: d.stateColor(k('dayForegroundColor')),
      dayBackgroundColor: d.stateColor(k('dayBackgroundColor')),
      todayForegroundColor: d.stateColor(k('todayForegroundColor')),
      todayBackgroundColor: d.stateColor(k('todayBackgroundColor')),
      yearStyle: d.textStyle(k('yearStyle')),
      rangeSelectionBackgroundColor: d.color(k('rangeSelectionBackgroundColor')),
      dividerColor: d.color(k('dividerColor')),
      cancelButtonStyle: d.buttonStyle(k('cancelButtonStyle')),
      confirmButtonStyle: d.buttonStyle(k('confirmButtonStyle')),
    )),
  ),
  'dialogTheme': ThemeComponent(
    <String>['backgroundColor', 'elevation', 'shadowColor', 'surfaceTintColor', 'shape', 'alignment', 'iconColor',
      'titleTextStyle', 'contentTextStyle', 'actionsPadding', 'barrierColor', 'insetPadding', 'clipBehavior'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => DialogThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      shape: d.shape(k('shape')),
      alignment: d.alignment(k('alignment')),
      iconColor: d.color(k('iconColor')),
      titleTextStyle: d.textStyle(k('titleTextStyle')),
      contentTextStyle: d.textStyle(k('contentTextStyle')),
      actionsPadding: d.edgeInsets(k('actionsPadding')),
      barrierColor: d.color(k('barrierColor')),
      insetPadding: d.edgeInsets(k('insetPadding'))?.resolve(TextDirection.ltr),
      clipBehavior: d.enumValue(Clip.values, k('clipBehavior')),
    )),
  ),
  'dividerTheme': ThemeComponent(
    <String>['color', 'space', 'thickness', 'indent', 'endIndent'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => DividerThemeData(
      color: d.color(k('color')),
      space: d.number(k('space')),
      thickness: d.number(k('thickness')),
      indent: d.spacing(k('indent')),
      endIndent: d.spacing(k('endIndent')),
    )),
  ),
  'drawerTheme': ThemeComponent(
    <String>['backgroundColor', 'scrimColor', 'elevation', 'shadowColor', 'surfaceTintColor', 'shape', 'endShape', 'width', 'clipBehavior'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => DrawerThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      scrimColor: d.color(k('scrimColor')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      shape: d.shape(k('shape')),
      endShape: d.shape(k('endShape')),
      width: d.number(k('width')),
      clipBehavior: d.enumValue(Clip.values, k('clipBehavior')),
    )),
  ),
  'dropdownMenuTheme': ThemeComponent(
    <String>['textStyle', 'inputDecorationTheme'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => DropdownMenuThemeData(
      textStyle: d.textStyle(k('textStyle')),
      inputDecorationTheme: _inputDecorationTheme(d, k('inputDecorationTheme')),
    )),
  ),
  'elevatedButtonTheme': _buttonTheme((ButtonStyle? s) => ElevatedButtonThemeData(style: s)),
  'expansionTileTheme': ThemeComponent(
    <String>['backgroundColor', 'collapsedBackgroundColor', 'tilePadding', 'expandedAlignment', 'childrenPadding', 'iconColor',
      'collapsedIconColor', 'textColor', 'collapsedTextColor', 'shape', 'collapsedShape', 'clipBehavior'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => ExpansionTileThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      collapsedBackgroundColor: d.color(k('collapsedBackgroundColor')),
      tilePadding: d.edgeInsets(k('tilePadding')),
      expandedAlignment: d.alignment(k('expandedAlignment')),
      childrenPadding: d.edgeInsets(k('childrenPadding')),
      iconColor: d.color(k('iconColor')),
      collapsedIconColor: d.color(k('collapsedIconColor')),
      textColor: d.color(k('textColor')),
      collapsedTextColor: d.color(k('collapsedTextColor')),
      shape: d.shape(k('shape')),
      collapsedShape: d.shape(k('collapsedShape')),
      clipBehavior: d.enumValue(Clip.values, k('clipBehavior')),
    )),
  ),
  'filledButtonTheme': _buttonTheme((ButtonStyle? s) => FilledButtonThemeData(style: s)),
  'floatingActionButtonTheme': ThemeComponent(
    <String>['foregroundColor', 'backgroundColor', 'focusColor', 'hoverColor', 'splashColor', 'elevation', 'focusElevation',
      'hoverElevation', 'disabledElevation', 'highlightElevation', 'shape', 'iconSize', 'extendedIconLabelSpacing',
      'extendedPadding', 'extendedTextStyle'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => FloatingActionButtonThemeData(
      foregroundColor: d.color(k('foregroundColor')),
      backgroundColor: d.color(k('backgroundColor')),
      focusColor: d.color(k('focusColor')),
      hoverColor: d.color(k('hoverColor')),
      splashColor: d.color(k('splashColor')),
      elevation: d.number(k('elevation')),
      focusElevation: d.number(k('focusElevation')),
      hoverElevation: d.number(k('hoverElevation')),
      disabledElevation: d.number(k('disabledElevation')),
      highlightElevation: d.number(k('highlightElevation')),
      shape: d.shape(k('shape')),
      iconSize: d.number(k('iconSize')),
      extendedIconLabelSpacing: d.spacing(k('extendedIconLabelSpacing')),
      extendedPadding: d.edgeInsets(k('extendedPadding')),
      extendedTextStyle: d.textStyle(k('extendedTextStyle')),
    )),
  ),
  'iconButtonTheme': _buttonTheme((ButtonStyle? s) => IconButtonThemeData(style: s)),
  'inputDecorationTheme': ThemeComponent(_inputDecorationKeys, _inputDecorationTheme),
  'listTileTheme': ThemeComponent(
    <String>['dense', 'shape', 'style', 'selectedColor', 'iconColor', 'textColor', 'titleTextStyle', 'subtitleTextStyle',
      'leadingAndTrailingTextStyle', 'contentPadding', 'tileColor', 'selectedTileColor', 'horizontalTitleGap',
      'minVerticalPadding', 'minLeadingWidth', 'minTileHeight', 'enableFeedback', 'visualDensity', 'titleAlignment'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => ListTileThemeData(
      dense: d.boolean(k('dense')),
      shape: d.shape(k('shape')),
      style: d.enumValue(ListTileStyle.values, k('style')),
      selectedColor: d.color(k('selectedColor')),
      iconColor: d.color(k('iconColor')),
      textColor: d.color(k('textColor')),
      titleTextStyle: d.textStyle(k('titleTextStyle')),
      subtitleTextStyle: d.textStyle(k('subtitleTextStyle')),
      leadingAndTrailingTextStyle: d.textStyle(k('leadingAndTrailingTextStyle')),
      contentPadding: d.edgeInsets(k('contentPadding')),
      tileColor: d.color(k('tileColor')),
      selectedTileColor: d.color(k('selectedTileColor')),
      horizontalTitleGap: d.spacing(k('horizontalTitleGap')),
      minVerticalPadding: d.spacing(k('minVerticalPadding')),
      minLeadingWidth: d.number(k('minLeadingWidth')),
      minTileHeight: d.number(k('minTileHeight')),
      enableFeedback: d.boolean(k('enableFeedback')),
      visualDensity: d.visualDensity(k('visualDensity')),
      titleAlignment: d.enumValue(ListTileTitleAlignment.values, k('titleAlignment')),
    )),
  ),
  'navigationBarTheme': ThemeComponent(
    <String>['height', 'backgroundColor', 'elevation', 'shadowColor', 'surfaceTintColor', 'indicatorColor', 'indicatorShape',
      'labelTextStyle', 'iconTheme', 'labelBehavior', 'overlayColor', 'labelPadding'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => NavigationBarThemeData(
      height: d.number(k('height')),
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      indicatorColor: d.color(k('indicatorColor')),
      indicatorShape: d.shape(k('indicatorShape')),
      labelTextStyle: d.state<TextStyle>(k('labelTextStyle'), d.textStyle),
      iconTheme: d.state<IconThemeData>(k('iconTheme'), d.iconThemeData),
      labelBehavior: d.enumValue(NavigationDestinationLabelBehavior.values, k('labelBehavior')),
      overlayColor: d.stateColor(k('overlayColor')),
      labelPadding: d.edgeInsets(k('labelPadding')),
    )),
  ),
  'navigationDrawerTheme': ThemeComponent(
    <String>['tileHeight', 'backgroundColor', 'elevation', 'shadowColor', 'surfaceTintColor', 'indicatorColor', 'indicatorShape',
      'indicatorSize', 'labelTextStyle', 'iconTheme'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => NavigationDrawerThemeData(
      tileHeight: d.number(k('tileHeight')),
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      indicatorColor: d.color(k('indicatorColor')),
      indicatorShape: d.shape(k('indicatorShape')),
      indicatorSize: d.size(k('indicatorSize')),
      labelTextStyle: d.state<TextStyle>(k('labelTextStyle'), d.textStyle),
      iconTheme: d.state<IconThemeData>(k('iconTheme'), d.iconThemeData),
    )),
  ),
  'navigationRailTheme': ThemeComponent(
    <String>['backgroundColor', 'elevation', 'unselectedLabelTextStyle', 'selectedLabelTextStyle', 'unselectedIconTheme',
      'selectedIconTheme', 'groupAlignment', 'labelType', 'useIndicator', 'indicatorColor', 'indicatorShape', 'minWidth',
      'minExtendedWidth'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => NavigationRailThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      unselectedLabelTextStyle: d.textStyle(k('unselectedLabelTextStyle')),
      selectedLabelTextStyle: d.textStyle(k('selectedLabelTextStyle')),
      unselectedIconTheme: d.iconThemeData(k('unselectedIconTheme')),
      selectedIconTheme: d.iconThemeData(k('selectedIconTheme')),
      groupAlignment: d.number(k('groupAlignment')),
      labelType: d.enumValue(NavigationRailLabelType.values, k('labelType')),
      useIndicator: d.boolean(k('useIndicator')),
      indicatorColor: d.color(k('indicatorColor')),
      indicatorShape: d.shape(k('indicatorShape')),
      minWidth: d.number(k('minWidth')),
      minExtendedWidth: d.number(k('minExtendedWidth')),
    )),
  ),
  'outlinedButtonTheme': _buttonTheme((ButtonStyle? s) => OutlinedButtonThemeData(style: s)),
  'popupMenuTheme': ThemeComponent(
    <String>['color', 'shape', 'menuPadding', 'elevation', 'shadowColor', 'surfaceTintColor', 'textStyle', 'labelTextStyle',
      'enableFeedback', 'position', 'iconColor', 'iconSize'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => PopupMenuThemeData(
      color: d.color(k('color')),
      shape: d.shape(k('shape')),
      menuPadding: d.edgeInsets(k('menuPadding')),
      elevation: d.number(k('elevation')),
      shadowColor: d.color(k('shadowColor')),
      surfaceTintColor: d.color(k('surfaceTintColor')),
      textStyle: d.textStyle(k('textStyle')),
      labelTextStyle: d.state<TextStyle>(k('labelTextStyle'), d.textStyle),
      enableFeedback: d.boolean(k('enableFeedback')),
      position: d.enumValue(PopupMenuPosition.values, k('position')),
      iconColor: d.color(k('iconColor')),
      iconSize: d.number(k('iconSize')),
    )),
  ),
  'progressIndicatorTheme': ThemeComponent(
    <String>['color', 'linearTrackColor', 'linearMinHeight', 'circularTrackColor', 'refreshBackgroundColor', 'borderRadius',
      'stopIndicatorColor', 'stopIndicatorRadius', 'strokeWidth', 'strokeAlign', 'strokeCap', 'trackGap'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => ProgressIndicatorThemeData(
      color: d.color(k('color')),
      linearTrackColor: d.color(k('linearTrackColor')),
      linearMinHeight: d.number(k('linearMinHeight')),
      circularTrackColor: d.color(k('circularTrackColor')),
      refreshBackgroundColor: d.color(k('refreshBackgroundColor')),
      borderRadius: d.borderRadius(k('borderRadius')),
      stopIndicatorColor: d.color(k('stopIndicatorColor')),
      stopIndicatorRadius: d.number(k('stopIndicatorRadius')),
      strokeWidth: d.number(k('strokeWidth')),
      strokeAlign: d.number(k('strokeAlign')),
      strokeCap: d.enumValue(StrokeCap.values, k('strokeCap')),
      trackGap: d.number(k('trackGap')),
    )),
  ),
  'radioTheme': ThemeComponent(
    <String>['fillColor', 'overlayColor', 'splashRadius', 'materialTapTargetSize', 'visualDensity'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => RadioThemeData(
      fillColor: d.stateColor(k('fillColor')),
      overlayColor: d.stateColor(k('overlayColor')),
      splashRadius: d.number(k('splashRadius')),
      materialTapTargetSize: d.enumValue(MaterialTapTargetSize.values, k('materialTapTargetSize')),
      visualDensity: d.visualDensity(k('visualDensity')),
    )),
  ),
  'scrollbarTheme': ThemeComponent(
    <String>['thickness', 'thumbVisibility', 'trackVisibility', 'radius', 'thumbColor', 'trackColor', 'trackBorderColor',
      'crossAxisMargin', 'mainAxisMargin', 'minThumbLength', 'interactive'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => ScrollbarThemeData(
      thickness: d.state<double>(k('thickness'), d.number),
      thumbVisibility: d.state<bool>(k('thumbVisibility'), d.boolean),
      trackVisibility: d.state<bool>(k('trackVisibility'), d.boolean),
      radius: d.radius(k('radius')),
      thumbColor: d.stateColor(k('thumbColor')),
      trackColor: d.stateColor(k('trackColor')),
      trackBorderColor: d.stateColor(k('trackBorderColor')),
      crossAxisMargin: d.number(k('crossAxisMargin')),
      mainAxisMargin: d.number(k('mainAxisMargin')),
      minThumbLength: d.number(k('minThumbLength')),
      interactive: d.boolean(k('interactive')),
    )),
  ),
  'searchBarTheme': ThemeComponent(
    <String>['elevation', 'backgroundColor', 'shadowColor', 'surfaceTintColor', 'overlayColor', 'side', 'shape', 'padding',
      'textStyle', 'hintStyle', 'constraints', 'textCapitalization'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => SearchBarThemeData(
      elevation: d.state<double>(k('elevation'), d.number),
      backgroundColor: d.stateColor(k('backgroundColor')),
      shadowColor: d.stateColor(k('shadowColor')),
      surfaceTintColor: d.stateColor(k('surfaceTintColor')),
      overlayColor: d.stateColor(k('overlayColor')),
      side: d.state<BorderSide>(k('side'), d.borderSide),
      shape: d.state<OutlinedBorder>(k('shape'), d.shape),
      padding: d.state<EdgeInsetsGeometry>(k('padding'), d.edgeInsets),
      textStyle: d.state<TextStyle>(k('textStyle'), d.textStyle),
      hintStyle: d.state<TextStyle>(k('hintStyle'), d.textStyle),
      constraints: d.boxConstraints(k('constraints')),
      textCapitalization: d.enumValue(TextCapitalization.values, k('textCapitalization')),
    )),
  ),
  'segmentedButtonTheme': _buttonTheme((ButtonStyle? s) => SegmentedButtonThemeData(style: s)),
  'sliderTheme': ThemeComponent(
    <String>['trackHeight', 'activeTrackColor', 'inactiveTrackColor', 'secondaryActiveTrackColor', 'disabledActiveTrackColor',
      'disabledInactiveTrackColor', 'activeTickMarkColor', 'inactiveTickMarkColor', 'thumbColor', 'disabledThumbColor',
      'overlayColor', 'valueIndicatorColor', 'valueIndicatorTextStyle', 'showValueIndicator', 'minThumbSeparation'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => SliderThemeData(
      trackHeight: d.number(k('trackHeight')),
      activeTrackColor: d.color(k('activeTrackColor')),
      inactiveTrackColor: d.color(k('inactiveTrackColor')),
      secondaryActiveTrackColor: d.color(k('secondaryActiveTrackColor')),
      disabledActiveTrackColor: d.color(k('disabledActiveTrackColor')),
      disabledInactiveTrackColor: d.color(k('disabledInactiveTrackColor')),
      activeTickMarkColor: d.color(k('activeTickMarkColor')),
      inactiveTickMarkColor: d.color(k('inactiveTickMarkColor')),
      thumbColor: d.color(k('thumbColor')),
      disabledThumbColor: d.color(k('disabledThumbColor')),
      overlayColor: d.color(k('overlayColor')),
      valueIndicatorColor: d.color(k('valueIndicatorColor')),
      valueIndicatorTextStyle: d.textStyle(k('valueIndicatorTextStyle')),
      showValueIndicator: d.enumValue(ShowValueIndicator.values, k('showValueIndicator')),
      minThumbSeparation: d.number(k('minThumbSeparation')),
    )),
  ),
  'snackBarTheme': ThemeComponent(
    <String>['backgroundColor', 'actionTextColor', 'disabledActionTextColor', 'contentTextStyle', 'elevation', 'shape',
      'behavior', 'width', 'insetPadding', 'showCloseIcon', 'closeIconColor', 'actionBackgroundColor'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => SnackBarThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      actionTextColor: d.color(k('actionTextColor')),
      disabledActionTextColor: d.color(k('disabledActionTextColor')),
      contentTextStyle: d.textStyle(k('contentTextStyle')),
      elevation: d.number(k('elevation')),
      shape: d.shape(k('shape')),
      behavior: d.enumValue(SnackBarBehavior.values, k('behavior')),
      width: d.number(k('width')),
      insetPadding: d.edgeInsets(k('insetPadding'))?.resolve(TextDirection.ltr),
      showCloseIcon: d.boolean(k('showCloseIcon')),
      closeIconColor: d.color(k('closeIconColor')),
      actionBackgroundColor: d.color(k('actionBackgroundColor')),
    )),
  ),
  'switchTheme': ThemeComponent(
    <String>['thumbColor', 'trackColor', 'trackOutlineColor', 'trackOutlineWidth', 'materialTapTargetSize', 'overlayColor',
      'splashRadius', 'thumbIcon', 'padding'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => SwitchThemeData(
      thumbColor: d.stateColor(k('thumbColor')),
      trackColor: d.stateColor(k('trackColor')),
      trackOutlineColor: d.stateColor(k('trackOutlineColor')),
      trackOutlineWidth: d.state<double>(k('trackOutlineWidth'), d.number),
      materialTapTargetSize: d.enumValue(MaterialTapTargetSize.values, k('materialTapTargetSize')),
      overlayColor: d.stateColor(k('overlayColor')),
      splashRadius: d.number(k('splashRadius')),
      thumbIcon: d.state<Icon>(k('thumbIcon'), (List<Object> at) {
        final IconData? data = d.icon(at);
        return data == null ? null : Icon(data);
      }),
      padding: d.edgeInsets(k('padding')),
    )),
  ),
  'tabBarTheme': ThemeComponent(
    <String>['indicator', 'indicatorColor', 'indicatorSize', 'dividerColor', 'dividerHeight', 'labelColor', 'labelPadding',
      'labelStyle', 'unselectedLabelColor', 'unselectedLabelStyle', 'overlayColor', 'tabAlignment'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => TabBarThemeData(
      indicator: d.decoration(k('indicator')),
      indicatorColor: d.color(k('indicatorColor')),
      indicatorSize: d.enumValue(TabBarIndicatorSize.values, k('indicatorSize')),
      dividerColor: d.color(k('dividerColor')),
      dividerHeight: d.number(k('dividerHeight')),
      labelColor: d.color(k('labelColor')),
      labelPadding: d.edgeInsets(k('labelPadding')),
      labelStyle: d.textStyle(k('labelStyle')),
      unselectedLabelColor: d.color(k('unselectedLabelColor')),
      unselectedLabelStyle: d.textStyle(k('unselectedLabelStyle')),
      overlayColor: d.stateColor(k('overlayColor')),
      tabAlignment: d.enumValue(TabAlignment.values, k('tabAlignment')),
    )),
  ),
  'textButtonTheme': _buttonTheme((ButtonStyle? s) => TextButtonThemeData(style: s)),
  'textSelectionTheme': ThemeComponent(
    <String>['cursorColor', 'selectionColor', 'selectionHandleColor'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => TextSelectionThemeData(
      cursorColor: d.color(k('cursorColor')),
      selectionColor: d.color(k('selectionColor')),
      selectionHandleColor: d.color(k('selectionHandleColor')),
    )),
  ),
  'timePickerTheme': ThemeComponent(
    <String>['backgroundColor', 'elevation', 'shape', 'dialBackgroundColor', 'dialHandColor', 'dialTextColor',
      'hourMinuteColor', 'hourMinuteTextColor', 'dayPeriodColor', 'dayPeriodTextColor', 'entryModeIconColor',
      'helpTextStyle', 'cancelButtonStyle', 'confirmButtonStyle'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => TimePickerThemeData(
      backgroundColor: d.color(k('backgroundColor')),
      elevation: d.number(k('elevation')),
      shape: d.shape(k('shape')),
      dialBackgroundColor: d.color(k('dialBackgroundColor')),
      dialHandColor: d.color(k('dialHandColor')),
      dialTextColor: d.color(k('dialTextColor')),
      hourMinuteColor: d.color(k('hourMinuteColor')),
      hourMinuteTextColor: d.color(k('hourMinuteTextColor')),
      dayPeriodColor: d.color(k('dayPeriodColor')),
      dayPeriodTextColor: d.color(k('dayPeriodTextColor')),
      entryModeIconColor: d.color(k('entryModeIconColor')),
      helpTextStyle: d.textStyle(k('helpTextStyle')),
      cancelButtonStyle: d.buttonStyle(k('cancelButtonStyle')),
      confirmButtonStyle: d.buttonStyle(k('confirmButtonStyle')),
    )),
  ),
  'tooltipTheme': ThemeComponent(
    <String>['padding', 'margin', 'verticalOffset', 'preferBelow', 'excludeFromSemantics', 'decoration', 'textStyle',
      'textAlign', 'waitDuration', 'showDuration', 'triggerMode', 'enableFeedback'],
    (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => TooltipThemeData(
      padding: d.edgeInsets(k('padding')),
      margin: d.edgeInsets(k('margin')),
      verticalOffset: d.number(k('verticalOffset')),
      preferBelow: d.boolean(k('preferBelow')),
      excludeFromSemantics: d.boolean(k('excludeFromSemantics')),
      decoration: d.decoration(k('decoration')),
      textStyle: d.textStyle(k('textStyle')),
      textAlign: d.enumValue(TextAlign.values, k('textAlign')),
      waitDuration: d.duration(k('waitDuration')),
      showDuration: d.duration(k('showDuration')),
      triggerMode: d.enumValue(TooltipTriggerMode.values, k('triggerMode')),
      enableFeedback: d.boolean(k('enableFeedback')),
    )),
  ),
};

typedef _K = List<Object> Function(String name);

/// [build] with a key helper, or null when there is no map at [key].
T? _ifMap<T>(UiDecoder d, List<Object> key, T Function(_K k) build) {
  if (!d.source.isMap(key)) {
    return null;
  }
  return build((String name) => <Object>[...key, name]);
}

/// The five ButtonStyle themes: `{ style: { ...ButtonStyle } }`.
ThemeComponent _buttonTheme(Object Function(ButtonStyle? style) make) => ThemeComponent(
  const <String>['style'],
  (UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => make(d.buttonStyle(k('style')))),
);

const List<String> _inputDecorationKeys = <String>[
  'labelStyle', 'floatingLabelStyle', 'helperStyle', 'helperMaxLines', 'hintStyle', 'hintMaxLines', 'errorStyle',
  'errorMaxLines', 'floatingLabelBehavior', 'isDense', 'contentPadding', 'isCollapsed', 'iconColor', 'prefixStyle',
  'prefixIconColor', 'prefixIconConstraints', 'suffixStyle', 'suffixIconColor', 'suffixIconConstraints', 'counterStyle',
  'filled', 'fillColor', 'focusColor', 'hoverColor', 'errorBorder', 'focusedBorder', 'focusedErrorBorder', 'disabledBorder',
  'enabledBorder', 'border', 'alignLabelWithHint', 'constraints', 'visualDensity',
];

InputDecorationThemeData? _inputDecorationTheme(UiDecoder d, List<Object> key) => _ifMap(d, key, (_K k) => InputDecorationThemeData(
  labelStyle: d.textStyle(k('labelStyle')),
  floatingLabelStyle: d.textStyle(k('floatingLabelStyle')),
  helperStyle: d.textStyle(k('helperStyle')),
  helperMaxLines: d.integer(k('helperMaxLines')),
  hintStyle: d.textStyle(k('hintStyle')),
  hintMaxLines: d.integer(k('hintMaxLines')),
  errorStyle: d.textStyle(k('errorStyle')),
  errorMaxLines: d.integer(k('errorMaxLines')),
  floatingLabelBehavior: d.enumValue(FloatingLabelBehavior.values, k('floatingLabelBehavior')) ?? FloatingLabelBehavior.auto,
  isDense: d.boolean(k('isDense')) ?? false,
  contentPadding: d.edgeInsets(k('contentPadding')),
  isCollapsed: d.boolean(k('isCollapsed')) ?? false,
  iconColor: d.color(k('iconColor')),
  prefixStyle: d.textStyle(k('prefixStyle')),
  prefixIconColor: d.color(k('prefixIconColor')),
  prefixIconConstraints: d.boxConstraints(k('prefixIconConstraints')),
  suffixStyle: d.textStyle(k('suffixStyle')),
  suffixIconColor: d.color(k('suffixIconColor')),
  suffixIconConstraints: d.boxConstraints(k('suffixIconConstraints')),
  counterStyle: d.textStyle(k('counterStyle')),
  filled: d.boolean(k('filled')) ?? false,
  fillColor: d.color(k('fillColor')),
  focusColor: d.color(k('focusColor')),
  hoverColor: d.color(k('hoverColor')),
  errorBorder: d.inputBorder(k('errorBorder')),
  focusedBorder: d.inputBorder(k('focusedBorder')),
  focusedErrorBorder: d.inputBorder(k('focusedErrorBorder')),
  disabledBorder: d.inputBorder(k('disabledBorder')),
  enabledBorder: d.inputBorder(k('enabledBorder')),
  border: d.inputBorder(k('border')),
  alignLabelWithHint: d.boolean(k('alignLabelWithHint')) ?? false,
  constraints: d.boxConstraints(k('constraints')),
  visualDensity: d.visualDensity(k('visualDensity')),
));
