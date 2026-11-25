import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';
import 'state.dart';

/// Material surfaces, buttons, lists, chips and feedback.
///
/// Every colour and style argument takes theme tokens, and every widget left
/// unstyled is styled by the theme -- a remote file only says what differs.
final List<UiWidget> materialWidgets = <UiWidget>[
  // ---------------------------------------------------------------- buttons
  _button('ElevatedButton', 'A raised button.', ElevatedButton.new, ElevatedButton.icon),
  _button('FilledButton', 'The strongest call to action.', FilledButton.new, FilledButton.icon),
  _button('FilledTonalButton', 'A filled button in the secondary container colour (FilledButton.tonal).', FilledButton.tonal, FilledButton.tonalIcon),
  _button('OutlinedButton', 'A button with an outline and no fill.', OutlinedButton.new, OutlinedButton.icon),
  _button('TextButton', 'A button that is only its label.', TextButton.new, TextButton.icon),
  UiWidget(
    'IconButton',
    group: UiGroup.material,
    doc: 'An icon you can press. `variant` picks the Material 3 style; `isSelected` and `selectedIcon` make it a toggle.',
    params: <UiParam>[
      p('icon', 'Widget|Icon'),
      p('onPressed', 'event'),
      p('onLongPress', 'event'),
      oneOf('variant', <String>['standard', 'filled', 'filledTonal', 'outlined'], null, 'standard'),
      p('tooltip', 'String'),
      p('iconSize', 'double'),
      p('color', 'Color'),
      p('isSelected', 'bool'),
      p('selectedIcon', 'Widget|Icon'),
      p('padding', 'EdgeInsets'),
      p('alignment', 'Alignment'),
      p('constraints', 'BoxConstraints'),
      p('visualDensity', 'String'),
      p('style', 'ButtonStyle'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final Widget icon = a.iconOrChild(const ['icon']) ?? const SizedBox.square(dimension: 24);
      final VoidCallback? onPressed = a.onTap(const ['onPressed']);
      final VoidCallback? onLongPress = a.onTap(const ['onLongPress']);
      final String variant = a.string(const ['variant']) ?? 'standard';
      final String? tooltip = a.string(const ['tooltip']);
      final double? iconSize = a.number(const ['iconSize']);
      final Color? color = a.color(const ['color']);
      final bool? isSelected = a.boolean(const ['isSelected']);
      final Widget? selectedIcon = a.iconOrChild(const ['selectedIcon']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final AlignmentGeometry? alignment = a.alignment(const ['alignment']);
      final BoxConstraints? constraints = a.boxConstraints(const ['constraints']);
      final VisualDensity? visualDensity = a.visualDensity(const ['visualDensity']);
      final ButtonStyle? style = a.buttonStyle(const ['style']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      final IconButton Function({
        required Widget icon,
        required VoidCallback? onPressed,
        VoidCallback? onLongPress,
        String? tooltip,
        double? iconSize,
        Color? color,
        bool? isSelected,
        Widget? selectedIcon,
        EdgeInsetsGeometry? padding,
        AlignmentGeometry? alignment,
        BoxConstraints? constraints,
        VisualDensity? visualDensity,
        ButtonStyle? style,
        bool autofocus,
      }) make = switch (variant) {
        'filled' => IconButton.filled,
        'filledTonal' => IconButton.filledTonal,
        'outlined' => IconButton.outlined,
        _ => IconButton.new,
      };
      return make(
        icon: icon,
        onPressed: onPressed,
        onLongPress: onLongPress,
        tooltip: tooltip,
        iconSize: iconSize,
        color: color,
        isSelected: isSelected,
        selectedIcon: selectedIcon,
        padding: padding,
        alignment: alignment,
        constraints: constraints,
        visualDensity: visualDensity,
        style: style,
        autofocus: autofocus,
      );
    },
    example: 'Row(children: [IconButton(icon: "favorite_border", selectedIcon: "favorite", isSelected: true, onPressed: event "like" {}), '
        'IconButton(icon: "add", variant: "filled", onPressed: event "add" {})])',
  ),
  UiWidget(
    'FloatingActionButton',
    group: UiGroup.material,
    doc: 'The screen\'s primary action. Give `label` for the extended form; `size` picks small, regular or large.',
    params: <UiParam>[
      p('child', 'Widget|Icon', 'Usually an icon name.'),
      p('label', 'Widget|String', 'Makes it an extended FAB, with `child` as its icon.'),
      p('onPressed', 'event'),
      oneOf('size', <String>['small', 'regular', 'large'], null, 'regular'),
      p('tooltip', 'String'),
      p('foregroundColor', 'Color'),
      p('backgroundColor', 'Color'),
      p('focusColor', 'Color'),
      p('hoverColor', 'Color'),
      p('splashColor', 'Color'),
      p('elevation', 'double'),
      p('focusElevation', 'double'),
      p('hoverElevation', 'double'),
      p('highlightElevation', 'double'),
      p('shape', 'ShapeBorder'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('autofocus', 'bool', null, 'false'),
      p('heroTag', 'String', 'Two FABs on one screen need different tags.'),
    ],
    build: (UiArgs a) {
      final Widget? child = a.iconOrChild(const ['child']);
      final Widget? label = a.label(const ['label']);
      final VoidCallback? onPressed = a.onTap(const ['onPressed']);
      final String size = a.string(const ['size']) ?? 'regular';
      final String? tooltip = a.string(const ['tooltip']);
      final Color? foregroundColor = a.color(const ['foregroundColor']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? focusColor = a.color(const ['focusColor']);
      final Color? hoverColor = a.color(const ['hoverColor']);
      final Color? splashColor = a.color(const ['splashColor']);
      final double? elevation = a.number(const ['elevation']);
      final double? focusElevation = a.number(const ['focusElevation']);
      final double? hoverElevation = a.number(const ['hoverElevation']);
      final double? highlightElevation = a.number(const ['highlightElevation']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none;
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      final Object heroTag = a.string(const ['heroTag']) ?? const _DefaultHeroTag();
      if (label != null) {
        return FloatingActionButton.extended(
          onPressed: onPressed,
          icon: child,
          label: label,
          tooltip: tooltip,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          focusColor: focusColor,
          hoverColor: hoverColor,
          splashColor: splashColor,
          elevation: elevation,
          focusElevation: focusElevation,
          hoverElevation: hoverElevation,
          highlightElevation: highlightElevation,
          shape: shape,
          clipBehavior: clip,
          autofocus: autofocus,
          heroTag: heroTag,
        );
      }
      final FloatingActionButton Function({
        Widget? child,
        String? tooltip,
        Color? foregroundColor,
        Color? backgroundColor,
        Color? focusColor,
        Color? hoverColor,
        Color? splashColor,
        Object? heroTag,
        double? elevation,
        double? focusElevation,
        double? hoverElevation,
        double? highlightElevation,
        required VoidCallback? onPressed,
        ShapeBorder? shape,
        Clip clipBehavior,
        bool autofocus,
      }) make = switch (size) {
        'small' => FloatingActionButton.small,
        'large' => FloatingActionButton.large,
        _ => FloatingActionButton.new,
      };
      return make(
        onPressed: onPressed,
        tooltip: tooltip,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        splashColor: splashColor,
        elevation: elevation,
        focusElevation: focusElevation,
        hoverElevation: hoverElevation,
        highlightElevation: highlightElevation,
        shape: shape,
        clipBehavior: clip,
        autofocus: autofocus,
        heroTag: heroTag,
        child: child,
      );
    },
    example: 'FloatingActionButton(child: "edit", label: "Compose", onPressed: event "compose" {})',
  ),
  UiWidget(
    'InkWell',
    group: UiGroup.material,
    doc: 'Makes its child tappable, with an ink splash. Needs a Material ancestor (Scaffold, Card, Material).',
    params: <UiParam>[
      p('onTap', 'event'),
      p('onDoubleTap', 'event'),
      p('onLongPress', 'event'),
      p('onTapDown', 'event'),
      p('onTapCancel', 'event'),
      p('onHover', 'event<bool>'),
      p('borderRadius', 'BorderRadius'),
      p('customBorder', 'ShapeBorder'),
      p('splashColor', 'Color'),
      p('highlightColor', 'Color'),
      p('hoverColor', 'Color'),
      p('focusColor', 'Color'),
      p('overlayColor', 'Color'),
      p('radius', 'double'),
      p('enableFeedback', 'bool', null, 'true'),
      p('excludeFromSemantics', 'bool', null, 'false'),
      p('canRequestFocus', 'bool', null, 'true'),
      p('autofocus', 'bool', null, 'false'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => _ink(a, circle: false),
    example: 'Material(child: InkWell(onTap: event "open" {}, borderRadius: "md", child: Padding(padding: "md", child: Text(text: "Tap me"))))',
  ),
  UiWidget(
    'InkResponse',
    group: UiGroup.material,
    doc: 'Like InkWell, but the splash is a circle that may spill outside the child -- for icon-sized targets.',
    params: <UiParam>[
      p('onTap', 'event'),
      p('onDoubleTap', 'event'),
      p('onLongPress', 'event'),
      p('onTapDown', 'event'),
      p('onTapCancel', 'event'),
      p('onHover', 'event<bool>'),
      p('borderRadius', 'BorderRadius'),
      p('customBorder', 'ShapeBorder'),
      p('splashColor', 'Color'),
      p('highlightColor', 'Color'),
      p('hoverColor', 'Color'),
      p('focusColor', 'Color'),
      p('overlayColor', 'Color'),
      p('radius', 'double'),
      p('enableFeedback', 'bool', null, 'true'),
      p('excludeFromSemantics', 'bool', null, 'false'),
      p('canRequestFocus', 'bool', null, 'true'),
      p('autofocus', 'bool', null, 'false'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => _ink(a, circle: true),
  ),

  // --------------------------------------------------------------- surfaces
  UiWidget(
    'Material',
    group: UiGroup.material,
    doc: 'A piece of Material: the surface ink, elevation and clipping need.',
    params: <UiParam>[
      e('type', MaterialType.values, null, 'canvas'),
      p('elevation', 'double', null, '0'),
      p('color', 'Color'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('textStyle', 'TextStyle'),
      p('borderRadius', 'BorderRadius'),
      p('shape', 'ShapeBorder'),
      p('borderOnForeground', 'bool', null, 'true'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('animationDuration', 'Duration'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final ShapeBorder? shape = a.shape(const ['shape']);
      final BorderRadiusGeometry? radius = a.borderRadius(const ['borderRadius']);
      return Material(
        type: a.enumValue(MaterialType.values, const ['type']) ?? MaterialType.canvas,
        elevation: a.number(const ['elevation']) ?? 0,
        color: a.color(const ['color']),
        shadowColor: a.color(const ['shadowColor']),
        surfaceTintColor: a.color(const ['surfaceTintColor']),
        textStyle: a.textStyle(const ['textStyle']),
        // Flutter asserts on both; the shape is the more specific ask.
        borderRadius: shape == null ? radius : null,
        shape: shape,
        borderOnForeground: a.boolean(const ['borderOnForeground']) ?? true,
        clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
        animationDuration: a.duration(const ['animationDuration']) ?? kThemeChangeDuration,
        child: a.optionalChild(const ['child']),
      );
    },
  ),
  UiWidget(
    'Card',
    group: UiGroup.material,
    doc: 'A surface for one piece of content. `variant` picks the Material 3 elevated, filled or outlined card.',
    params: <UiParam>[
      oneOf('variant', <String>['elevated', 'filled', 'outlined'], null, 'elevated'),
      p('color', 'Color'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('elevation', 'double'),
      p('shape', 'ShapeBorder'),
      p('borderOnForeground', 'bool', null, 'true'),
      p('margin', 'EdgeInsets'),
      e('clipBehavior', Clip.values),
      p('semanticContainer', 'bool', null, 'true'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final String variant = a.string(const ['variant']) ?? 'elevated';
      final Color? color = a.color(const ['color']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final double? elevation = a.number(const ['elevation']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final bool borderOnForeground = a.boolean(const ['borderOnForeground']) ?? true;
      final EdgeInsetsGeometry? margin = a.edgeInsets(const ['margin']);
      final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
      final bool semanticContainer = a.boolean(const ['semanticContainer']) ?? true;
      final Widget? child = a.optionalChild(const ['child']);
      final Card Function({
        Color? color,
        Color? shadowColor,
        Color? surfaceTintColor,
        double? elevation,
        ShapeBorder? shape,
        bool borderOnForeground,
        EdgeInsetsGeometry? margin,
        Clip? clipBehavior,
        Widget? child,
        bool semanticContainer,
      }) make = switch (variant) {
        'filled' => Card.filled,
        'outlined' => Card.outlined,
        _ => Card.new,
      };
      return make(
        color: color,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        elevation: elevation,
        shape: shape,
        borderOnForeground: borderOnForeground,
        margin: margin,
        clipBehavior: clip,
        semanticContainer: semanticContainer,
        child: child,
      );
    },
    example: 'Card(variant: "outlined", child: Padding(padding: "md", child: Text(text: "Outlined card")))',
  ),
  UiWidget(
    'Divider',
    group: UiGroup.material,
    doc: 'A thin horizontal line, coloured by the theme\'s divider.',
    params: <UiParam>[
      p('height', 'double', 'The space it takes, line included.'),
      p('thickness', 'double'),
      p('indent', 'Spacing'),
      p('endIndent', 'Spacing'),
      p('color', 'Color'),
      p('radius', 'BorderRadius'),
    ],
    build: (UiArgs a) => Divider(
      height: a.number(const ['height']),
      thickness: a.number(const ['thickness']),
      indent: a.spacing(const ['indent']),
      endIndent: a.spacing(const ['endIndent']),
      color: a.color(const ['color']),
      radius: a.borderRadius(const ['radius']),
    ),
    example: 'Divider(indent: "md", endIndent: "md")',
  ),
  UiWidget(
    'VerticalDivider',
    group: UiGroup.material,
    doc: 'A thin vertical line, for between Row children.',
    params: <UiParam>[
      p('width', 'double'),
      p('thickness', 'double'),
      p('indent', 'Spacing'),
      p('endIndent', 'Spacing'),
      p('color', 'Color'),
      p('radius', 'BorderRadius'),
    ],
    build: (UiArgs a) => VerticalDivider(
      width: a.number(const ['width']),
      thickness: a.number(const ['thickness']),
      indent: a.spacing(const ['indent']),
      endIndent: a.spacing(const ['endIndent']),
      color: a.color(const ['color']),
      radius: a.borderRadius(const ['radius']),
    ),
  ),

  // ------------------------------------------------------------------ lists
  UiWidget(
    'ListTile',
    group: UiGroup.material,
    doc: 'A row of a list: leading, title, subtitle, trailing. `title` and `subtitle` may be plain strings; '
        '`leading` and `trailing` may be icon names.',
    params: <UiParam>[
      p('leading', 'Widget|Icon'),
      p('title', 'Widget|String'),
      p('subtitle', 'Widget|String'),
      p('trailing', 'Widget|Icon'),
      p('isThreeLine', 'bool'),
      p('dense', 'bool'),
      p('visualDensity', 'String'),
      p('shape', 'ShapeBorder'),
      e('style', ListTileStyle.values),
      p('selectedColor', 'Color'),
      p('iconColor', 'Color'),
      p('textColor', 'Color'),
      p('titleTextStyle', 'TextStyle'),
      p('subtitleTextStyle', 'TextStyle'),
      p('leadingAndTrailingTextStyle', 'TextStyle'),
      p('contentPadding', 'EdgeInsets'),
      p('enabled', 'bool', null, 'true'),
      p('onTap', 'event'),
      p('onLongPress', 'event'),
      p('selected', 'bool', null, 'false'),
      p('focusColor', 'Color'),
      p('hoverColor', 'Color'),
      p('splashColor', 'Color'),
      p('tileColor', 'Color'),
      p('selectedTileColor', 'Color'),
      p('enableFeedback', 'bool'),
      p('horizontalTitleGap', 'Spacing'),
      p('minVerticalPadding', 'Spacing'),
      p('minLeadingWidth', 'double'),
      p('minTileHeight', 'double'),
      e('titleAlignment', ListTileTitleAlignment.values),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => ListTile(
      leading: a.iconOrChild(const ['leading']),
      title: a.label(const ['title']),
      subtitle: a.label(const ['subtitle']),
      trailing: a.iconOrChild(const ['trailing']),
      isThreeLine: a.boolean(const ['isThreeLine']),
      dense: a.boolean(const ['dense']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      shape: a.shape(const ['shape']),
      style: a.enumValue(ListTileStyle.values, const ['style']),
      selectedColor: a.color(const ['selectedColor']),
      iconColor: a.color(const ['iconColor']),
      textColor: a.color(const ['textColor']),
      titleTextStyle: a.textStyle(const ['titleTextStyle']),
      subtitleTextStyle: a.textStyle(const ['subtitleTextStyle']),
      leadingAndTrailingTextStyle: a.textStyle(const ['leadingAndTrailingTextStyle']),
      contentPadding: a.edgeInsets(const ['contentPadding']),
      enabled: a.boolean(const ['enabled']) ?? true,
      onTap: a.onTap(const ['onTap']),
      onLongPress: a.onTap(const ['onLongPress']),
      selected: a.boolean(const ['selected']) ?? false,
      focusColor: a.color(const ['focusColor']),
      hoverColor: a.color(const ['hoverColor']),
      splashColor: a.color(const ['splashColor']),
      tileColor: a.color(const ['tileColor']),
      selectedTileColor: a.color(const ['selectedTileColor']),
      enableFeedback: a.boolean(const ['enableFeedback']),
      horizontalTitleGap: a.spacing(const ['horizontalTitleGap']),
      minVerticalPadding: a.spacing(const ['minVerticalPadding']),
      minLeadingWidth: a.number(const ['minLeadingWidth']),
      minTileHeight: a.number(const ['minTileHeight']),
      titleAlignment: a.enumValue(ListTileTitleAlignment.values, const ['titleAlignment']),
      autofocus: a.boolean(const ['autofocus']) ?? false,
    ),
    example: 'ListTile(leading: "person", title: "Ada Lovelace", subtitle: "Analyst", trailing: "chevron_right", onTap: event "open" {})',
  ),
  UiWidget(
    'ExpansionTile',
    group: UiGroup.material,
    doc: 'A ListTile that opens to show more children. `onExpansionChanged` receives `{ value: <expanded> }`.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('subtitle', 'Widget|String'),
      p('leading', 'Widget|Icon'),
      p('trailing', 'Widget|Icon'),
      p('showTrailingIcon', 'bool', null, 'true'),
      p('children', 'List<Widget>'),
      p('initiallyExpanded', 'bool', null, 'false'),
      p('maintainState', 'bool', null, 'false'),
      p('enabled', 'bool', null, 'true'),
      p('onExpansionChanged', 'event<bool>'),
      p('tilePadding', 'EdgeInsets'),
      p('childrenPadding', 'EdgeInsets'),
      e('expandedCrossAxisAlignment', CrossAxisAlignment.values),
      p('expandedAlignment', 'Alignment'),
      p('backgroundColor', 'Color'),
      p('collapsedBackgroundColor', 'Color'),
      p('textColor', 'Color'),
      p('collapsedTextColor', 'Color'),
      p('iconColor', 'Color'),
      p('collapsedIconColor', 'Color'),
      p('shape', 'ShapeBorder'),
      p('collapsedShape', 'ShapeBorder'),
      e('clipBehavior', Clip.values),
      e('controlAffinity', ListTileControlAffinity.values),
      p('dense', 'bool'),
      p('visualDensity', 'String'),
    ],
    build: (UiArgs a) => ExpansionTile(
      title: a.label(const ['title']) ?? const SizedBox.shrink(),
      subtitle: a.label(const ['subtitle']),
      leading: a.iconOrChild(const ['leading']),
      trailing: a.iconOrChild(const ['trailing']),
      showTrailingIcon: a.boolean(const ['showTrailingIcon']) ?? true,
      initiallyExpanded: a.boolean(const ['initiallyExpanded']) ?? false,
      maintainState: a.boolean(const ['maintainState']) ?? false,
      enabled: a.boolean(const ['enabled']) ?? true,
      onExpansionChanged: a.onValue<bool>(const ['onExpansionChanged']),
      tilePadding: a.edgeInsets(const ['tilePadding']),
      childrenPadding: a.edgeInsets(const ['childrenPadding']),
      expandedCrossAxisAlignment: a.enumValue(CrossAxisAlignment.values, const ['expandedCrossAxisAlignment']),
      expandedAlignment: a.alignment(const ['expandedAlignment']),
      backgroundColor: a.color(const ['backgroundColor']),
      collapsedBackgroundColor: a.color(const ['collapsedBackgroundColor']),
      textColor: a.color(const ['textColor']),
      collapsedTextColor: a.color(const ['collapsedTextColor']),
      iconColor: a.color(const ['iconColor']),
      collapsedIconColor: a.color(const ['collapsedIconColor']),
      shape: a.shape(const ['shape']),
      collapsedShape: a.shape(const ['collapsedShape']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']),
      controlAffinity: a.enumValue(ListTileControlAffinity.values, const ['controlAffinity']),
      dense: a.boolean(const ['dense']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      children: a.children(const ['children']),
    ),
    example: 'ExpansionTile(title: "Advanced", leading: "tune", children: [ListTile(title: "Developer mode")])',
  ),

  // ------------------------------------------------------------------ chips
  UiWidget(
    'Chip',
    group: UiGroup.material,
    doc: 'A compact label. Give `onDeleted` for a delete icon.',
    params: <UiParam>[
      p('label', 'Widget|String'),
      p('avatar', 'Widget|Icon'),
      p('labelStyle', 'TextStyle'),
      p('labelPadding', 'EdgeInsets'),
      p('deleteIcon', 'Widget|Icon'),
      p('onDeleted', 'event'),
      p('deleteIconColor', 'Color'),
      p('deleteButtonTooltipMessage', 'String'),
      p('side', 'BorderSide'),
      p('shape', 'ShapeBorder'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('backgroundColor', 'Color'),
      p('color', 'Color', 'A colour for every state; see ButtonStyle for the state map.'),
      p('padding', 'EdgeInsets'),
      p('visualDensity', 'String'),
      e('materialTapTargetSize', MaterialTapTargetSize.values),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => Chip(
      label: a.label(const ['label']) ?? const SizedBox.shrink(),
      avatar: a.iconOrChild(const ['avatar']),
      labelStyle: a.textStyle(const ['labelStyle']),
      labelPadding: a.edgeInsets(const ['labelPadding']),
      deleteIcon: a.iconOrChild(const ['deleteIcon']),
      onDeleted: a.onTap(const ['onDeleted']),
      deleteIconColor: a.color(const ['deleteIconColor']),
      deleteButtonTooltipMessage: a.string(const ['deleteButtonTooltipMessage']),
      side: a.borderSide(const ['side']),
      shape: a.shape(const ['shape']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
      backgroundColor: a.color(const ['backgroundColor']),
      color: a.stateColor(const ['color']),
      padding: a.edgeInsets(const ['padding']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      materialTapTargetSize: a.enumValue(MaterialTapTargetSize.values, const ['materialTapTargetSize']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      autofocus: a.boolean(const ['autofocus']) ?? false,
    ),
    example: 'Chip(label: "Flutter", avatar: "code", onDeleted: event "remove" {})',
  ),
  UiWidget(
    'ActionChip',
    group: UiGroup.material,
    doc: 'A chip that does something when pressed.',
    params: <UiParam>[..._chipCommon, p('onPressed', 'event'), p('tooltip', 'String')],
    build: (UiArgs a) => ActionChip(
      label: a.label(const ['label']) ?? const SizedBox.shrink(),
      avatar: a.iconOrChild(const ['avatar']),
      labelStyle: a.textStyle(const ['labelStyle']),
      labelPadding: a.edgeInsets(const ['labelPadding']),
      side: a.borderSide(const ['side']),
      shape: a.shape(const ['shape']),
      backgroundColor: a.color(const ['backgroundColor']),
      padding: a.edgeInsets(const ['padding']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      onPressed: a.onTap(const ['onPressed']),
      tooltip: a.string(const ['tooltip']),
    ),
    example: 'ActionChip(label: "Directions", avatar: "directions", onPressed: event "directions" {})',
  ),
  UiWidget(
    'FilterChip',
    group: UiGroup.material,
    doc: 'A chip that toggles a filter on and off. `onSelected` receives `{ value: <selected> }`.',
    params: <UiParam>[
      ..._chipCommon,
      p('selected', 'bool', null, 'false'),
      p('onSelected', 'event<bool>'),
      p('selectedColor', 'Color'),
      p('showCheckmark', 'bool'),
      p('checkmarkColor', 'Color'),
      p('tooltip', 'String'),
    ],
    build: (UiArgs a) {
      final Widget label = a.label(const ['label']) ?? const SizedBox.shrink();
      final Widget? avatar = a.iconOrChild(const ['avatar']);
      final TextStyle? labelStyle = a.textStyle(const ['labelStyle']);
      final EdgeInsetsGeometry? labelPadding = a.edgeInsets(const ['labelPadding']);
      final BorderSide? side = a.borderSide(const ['side']);
      final OutlinedBorder? shape = a.shape(const ['shape']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final VisualDensity? visualDensity = a.visualDensity(const ['visualDensity']);
      final double? elevation = a.number(const ['elevation']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final Color? selectedColor = a.color(const ['selectedColor']);
      final bool? showCheckmark = a.boolean(const ['showCheckmark']);
      final Color? checkmarkColor = a.color(const ['checkmarkColor']);
      final String? tooltip = a.string(const ['tooltip']);
      return UiValue<bool>(
        value: a.boolean(const ['selected']),
        initial: false,
        onChanged: a.onValue<bool>(const ['onSelected']),
        builder: (BuildContext context, bool selected, ValueChanged<bool>? onSelected) => FilterChip(
          label: label,
          avatar: avatar,
          labelStyle: labelStyle,
          labelPadding: labelPadding,
          side: side,
          shape: shape,
          backgroundColor: backgroundColor,
          padding: padding,
          visualDensity: visualDensity,
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          selected: selected,
          onSelected: onSelected,
          selectedColor: selectedColor,
          showCheckmark: showCheckmark,
          checkmarkColor: checkmarkColor,
          tooltip: tooltip,
        ),
      );
    },
    example: 'FilterChip(label: "Vegetarian", selected: true, onSelected: event "ui.set" { key: "filters.vegetarian" })',
  ),
  UiWidget(
    'ChoiceChip',
    group: UiGroup.material,
    doc: 'One of a set of chips where one is chosen. `onSelected` receives `{ value: <selected> }`.',
    params: <UiParam>[
      ..._chipCommon,
      p('selected', 'bool', null, 'false'),
      p('onSelected', 'event<bool>'),
      p('selectedColor', 'Color'),
      p('showCheckmark', 'bool'),
      p('checkmarkColor', 'Color'),
      p('tooltip', 'String'),
    ],
    build: (UiArgs a) => ChoiceChip(
      label: a.label(const ['label']) ?? const SizedBox.shrink(),
      avatar: a.iconOrChild(const ['avatar']),
      labelStyle: a.textStyle(const ['labelStyle']),
      labelPadding: a.edgeInsets(const ['labelPadding']),
      side: a.borderSide(const ['side']),
      shape: a.shape(const ['shape']),
      backgroundColor: a.color(const ['backgroundColor']),
      padding: a.edgeInsets(const ['padding']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      selected: a.boolean(const ['selected']) ?? false,
      onSelected: a.onValue<bool>(const ['onSelected']),
      selectedColor: a.color(const ['selectedColor']),
      showCheckmark: a.boolean(const ['showCheckmark']),
      checkmarkColor: a.color(const ['checkmarkColor']),
      tooltip: a.string(const ['tooltip']),
    ),
    example: 'Wrap(spacing: "sm", children: [ChoiceChip(label: "Small", selected: true), ChoiceChip(label: "Large", selected: false)])',
  ),
  UiWidget(
    'InputChip',
    group: UiGroup.material,
    doc: 'A chip for a piece of input -- a recipient, a tag -- that may be selected and deleted.',
    params: <UiParam>[
      ..._chipCommon,
      p('selected', 'bool', null, 'false'),
      p('onSelected', 'event<bool>'),
      p('onPressed', 'event'),
      p('onDeleted', 'event'),
      p('deleteIcon', 'Widget|Icon'),
      p('isEnabled', 'bool', null, 'true'),
      p('selectedColor', 'Color'),
      p('showCheckmark', 'bool'),
      p('tooltip', 'String'),
    ],
    build: (UiArgs a) => InputChip(
      label: a.label(const ['label']) ?? const SizedBox.shrink(),
      avatar: a.iconOrChild(const ['avatar']),
      labelStyle: a.textStyle(const ['labelStyle']),
      labelPadding: a.edgeInsets(const ['labelPadding']),
      side: a.borderSide(const ['side']),
      shape: a.shape(const ['shape']),
      backgroundColor: a.color(const ['backgroundColor']),
      padding: a.edgeInsets(const ['padding']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      selected: a.boolean(const ['selected']) ?? false,
      onSelected: a.onValue<bool>(const ['onSelected']),
      onPressed: a.onTap(const ['onPressed']),
      onDeleted: a.onTap(const ['onDeleted']),
      deleteIcon: a.iconOrChild(const ['deleteIcon']),
      isEnabled: a.boolean(const ['isEnabled']) ?? true,
      selectedColor: a.color(const ['selectedColor']),
      showCheckmark: a.boolean(const ['showCheckmark']),
      tooltip: a.string(const ['tooltip']),
    ),
  ),

  // ------------------------------------------------------- small furniture
  UiWidget(
    'Badge',
    group: UiGroup.material,
    doc: 'A small status mark on its child. `count` shows a number (99+ past `maxCount`); with no label it is a dot.',
    params: <UiParam>[
      p('label', 'Widget|String'),
      p('count', 'int'),
      p('maxCount', 'int', null, '999'),
      p('isLabelVisible', 'bool', null, 'true'),
      p('backgroundColor', 'Color'),
      p('textColor', 'Color'),
      p('textStyle', 'TextStyle'),
      p('smallSize', 'double'),
      p('largeSize', 'double'),
      p('padding', 'EdgeInsets'),
      p('alignment', 'Alignment'),
      p('offset', 'Offset'),
      p('child', 'Widget|Icon'),
    ],
    build: (UiArgs a) {
      final int? count = a.integer(const ['count']);
      final int maxCount = a.integer(const ['maxCount']) ?? 999;
      final Widget? label = a.label(const ['label']);
      return Badge(
        label: count == null ? label : Text(count > maxCount ? '$maxCount+' : '$count'),
        isLabelVisible: a.boolean(const ['isLabelVisible']) ?? true,
        backgroundColor: a.color(const ['backgroundColor']),
        textColor: a.color(const ['textColor']),
        textStyle: a.textStyle(const ['textStyle']),
        smallSize: a.number(const ['smallSize']),
        largeSize: a.number(const ['largeSize']),
        padding: a.edgeInsets(const ['padding']),
        alignment: a.alignment(const ['alignment']),
        offset: a.offset(const ['offset']),
        child: a.iconOrChild(const ['child']),
      );
    },
    example: 'Badge(count: 3, child: "notifications")',
  ),
  UiWidget(
    'CircleAvatar',
    group: UiGroup.material,
    doc: 'A circle with an image, initials or an icon in it.',
    params: <UiParam>[
      p('child', 'Widget|String', 'Usually initials.'),
      p('backgroundColor', 'Color'),
      p('foregroundColor', 'Color'),
      p('backgroundImage', 'Image'),
      p('foregroundImage', 'Image', 'Drawn over the background image; falls back to it while loading.'),
      p('radius', 'double'),
      p('minRadius', 'double'),
      p('maxRadius', 'double'),
    ],
    build: (UiArgs a) {
      final double? radius = a.number(const ['radius']);
      final double? minRadius = a.number(const ['minRadius']);
      final double? maxRadius = a.number(const ['maxRadius']);
      return CircleAvatar(
        backgroundColor: a.color(const ['backgroundColor']),
        foregroundColor: a.color(const ['foregroundColor']),
        backgroundImage: a.image(const ['backgroundImage']),
        foregroundImage: a.image(const ['foregroundImage']),
        // Flutter asserts a radius is given one way only.
        radius: radius,
        minRadius: radius == null ? minRadius : null,
        maxRadius: radius == null ? maxRadius : null,
        child: a.label(const ['child']),
      );
    },
    example: 'CircleAvatar(child: "AL", backgroundColor: "tertiaryContainer", foregroundColor: "onTertiaryContainer")',
  ),
  UiWidget(
    'Tooltip',
    group: UiGroup.material,
    doc: 'A label that appears on long press or hover.',
    params: <UiParam>[
      p('message', 'String'),
      p('padding', 'EdgeInsets'),
      p('margin', 'EdgeInsets'),
      p('verticalOffset', 'double'),
      p('preferBelow', 'bool'),
      p('excludeFromSemantics', 'bool'),
      p('decoration', 'Decoration'),
      p('textStyle', 'TextStyle'),
      e('textAlign', TextAlign.values),
      p('waitDuration', 'Duration'),
      p('showDuration', 'Duration'),
      e('triggerMode', TooltipTriggerMode.values),
      p('enableFeedback', 'bool'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => Tooltip(
      message: a.string(const ['message']) ?? '',
      padding: a.edgeInsets(const ['padding']),
      margin: a.edgeInsets(const ['margin']),
      verticalOffset: a.number(const ['verticalOffset']),
      preferBelow: a.boolean(const ['preferBelow']),
      excludeFromSemantics: a.boolean(const ['excludeFromSemantics']),
      decoration: a.decoration(const ['decoration']),
      textStyle: a.textStyle(const ['textStyle']),
      textAlign: a.enumValue(TextAlign.values, const ['textAlign']),
      waitDuration: a.duration(const ['waitDuration']),
      showDuration: a.duration(const ['showDuration']),
      triggerMode: a.enumValue(TooltipTriggerMode.values, const ['triggerMode']),
      enableFeedback: a.boolean(const ['enableFeedback']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'CircularProgressIndicator',
    group: UiGroup.material,
    doc: 'A spinner, or a ring filling to `value` (0 to 1). `adaptive: true` is the platform\'s own on iOS and macOS.',
    params: <UiParam>[
      p('value', 'double', 'Leave out for an indeterminate spinner.'),
      p('color', 'Color'),
      p('backgroundColor', 'Color'),
      p('strokeWidth', 'double'),
      p('strokeAlign', 'double'),
      e('strokeCap', StrokeCap.values),
      p('padding', 'EdgeInsets'),
      p('adaptive', 'bool', null, 'false'),
      p('semanticsLabel', 'String'),
      p('semanticsValue', 'String'),
    ],
    build: (UiArgs a) {
      final double? value = a.number(const ['value']);
      final Color? color = a.color(const ['color']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? strokeWidth = a.number(const ['strokeWidth']);
      final double? strokeAlign = a.number(const ['strokeAlign']);
      final StrokeCap? strokeCap = a.enumValue(StrokeCap.values, const ['strokeCap']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final String? semanticsLabel = a.string(const ['semanticsLabel']);
      final String? semanticsValue = a.string(const ['semanticsValue']);
      if (a.boolean(const ['adaptive']) ?? false) {
        return CircularProgressIndicator.adaptive(
          value: value,
          valueColor: color == null ? null : AlwaysStoppedAnimation<Color>(color),
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth ?? 4,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );
      }
      return CircularProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
        strokeAlign: strokeAlign,
        strokeCap: strokeCap,
        padding: padding,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
      );
    },
    example: 'Row(spacing: "md", children: [CircularProgressIndicator(), CircularProgressIndicator(value: 0.6, color: "tertiary")])',
  ),
  UiWidget(
    'LinearProgressIndicator',
    group: UiGroup.material,
    doc: 'A bar, indeterminate or filling to `value` (0 to 1).',
    params: <UiParam>[
      p('value', 'double', 'Leave out for an indeterminate bar.'),
      p('color', 'Color'),
      p('backgroundColor', 'Color'),
      p('minHeight', 'double'),
      p('borderRadius', 'BorderRadius'),
      p('semanticsLabel', 'String'),
      p('semanticsValue', 'String'),
    ],
    build: (UiArgs a) => LinearProgressIndicator(
      value: a.number(const ['value']),
      color: a.color(const ['color']),
      backgroundColor: a.color(const ['backgroundColor']),
      minHeight: a.number(const ['minHeight']),
      borderRadius: a.borderRadius(const ['borderRadius']),
      semanticsLabel: a.string(const ['semanticsLabel']),
      semanticsValue: a.string(const ['semanticsValue']),
    ),
    example: 'LinearProgressIndicator(value: 0.3, borderRadius: "full", minHeight: 8)',
  ),
  UiWidget(
    'RefreshIndicator',
    group: UiGroup.material,
    doc: 'Pull to refresh around a scroll view. `onRefresh` fires an event; the spinner stays for `hold` '
        'milliseconds, since an rfw event has no reply to wait for.',
    params: <UiParam>[
      p('onRefresh', 'event'),
      p('hold', 'Duration', null, '800'),
      p('color', 'Color'),
      p('backgroundColor', 'Color'),
      p('displacement', 'double', null, '40'),
      p('edgeOffset', 'double', null, '0'),
      p('strokeWidth', 'double'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => RefreshIndicator(
      onRefresh: heldRefresh(a.onTap(const ['onRefresh']), a.duration(const ['hold']) ?? const Duration(milliseconds: 800)),
      color: a.color(const ['color']),
      backgroundColor: a.color(const ['backgroundColor']),
      displacement: a.number(const ['displacement']) ?? 40,
      edgeOffset: a.number(const ['edgeOffset']) ?? 0,
      strokeWidth: a.number(const ['strokeWidth']) ?? RefreshProgressIndicator.defaultStrokeWidth,
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'OverflowBar',
    group: UiGroup.material,
    doc: 'Children in a row, or in a column when the row will not fit -- dialog and card actions.',
    params: <UiParam>[
      p('spacing', 'Spacing', null, '0'),
      e('alignment', MainAxisAlignment.values),
      p('overflowSpacing', 'Spacing', null, '0'),
      e('overflowAlignment', OverflowBarAlignment.values, null, 'start'),
      e('overflowDirection', VerticalDirection.values, null, 'down'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) => OverflowBar(
      spacing: a.spacing(const ['spacing']) ?? 0,
      alignment: a.enumValue(MainAxisAlignment.values, const ['alignment']),
      overflowSpacing: a.spacing(const ['overflowSpacing']) ?? 0,
      overflowAlignment: a.enumValue(OverflowBarAlignment.values, const ['overflowAlignment']) ?? OverflowBarAlignment.start,
      overflowDirection: a.enumValue(VerticalDirection.values, const ['overflowDirection']) ?? VerticalDirection.down,
      children: a.children(const ['children']),
    ),
  ),
  UiWidget(
    'ToggleButtons',
    group: UiGroup.material,
    doc: 'A row of buttons pressed together, `isSelected` saying which are down: a day/week/month switch, a '
        'text-style bar. `onPressed` reports `{ value: <index> }`; the file decides what that does to '
        '`isSelected`. Material 3 prefers SegmentedButton for a single choice.',
    params: <UiParam>[
      p('isSelected', 'List<bool>', 'One per child, in order.'),
      p('onPressed', 'event<int>', 'The index pressed. With none, every button is disabled.'),
      p('borderRadius', 'BorderRadius', 'Rounds the ends of the row.'),
      p('constraints', 'BoxConstraints', 'The size each button is held to.'),
      e('direction', Axis.values, null, 'horizontal'),
      e('verticalDirection', VerticalDirection.values, null, 'down'),
      p('renderBorder', 'bool', null, 'true'),
      p('borderColor', 'Color'),
      p('selectedBorderColor', 'Color'),
      p('disabledBorderColor', 'Color'),
      p('borderWidth', 'double'),
      p('color', 'Color'),
      p('selectedColor', 'Color'),
      p('disabledColor', 'Color'),
      p('fillColor', 'Color'),
      p('textStyle', 'TextStyle'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) {
      final List<Widget> children = a.children(const ['children']);
      final List<bool> selected = a.list<bool>(const ['isSelected'], a.boolean) ?? const <bool>[];
      return ToggleButtons(
        isSelected: <bool>[
          for (int i = 0; i < children.length; i += 1) i < selected.length && selected[i],
        ],
        onPressed: a.onValue<int>(const ['onPressed']),
        borderRadius: a.borderRadius(const ['borderRadius'])?.resolve(Directionality.of(a.context)),
        constraints: a.boxConstraints(const ['constraints']),
        direction: a.enumValue(Axis.values, const ['direction']) ?? Axis.horizontal,
        verticalDirection: a.enumValue(VerticalDirection.values, const ['verticalDirection']) ?? VerticalDirection.down,
        renderBorder: a.boolean(const ['renderBorder']) ?? true,
        borderColor: a.color(const ['borderColor']),
        selectedBorderColor: a.color(const ['selectedBorderColor']),
        disabledBorderColor: a.color(const ['disabledBorderColor']),
        borderWidth: a.number(const ['borderWidth']),
        color: a.color(const ['color']),
        selectedColor: a.color(const ['selectedColor']),
        disabledColor: a.color(const ['disabledColor']),
        fillColor: a.color(const ['fillColor']),
        textStyle: a.textStyle(const ['textStyle']),
        children: children,
      );
    },
    example: 'ToggleButtons(isSelected: [true, false, false], borderRadius: 8, '
        'onPressed: event "range.pick" { }, children: [Text(text: "Day"), Text(text: "Week"), Text(text: "Month")])',
  ),
  UiWidget(
    'CarouselView',
    group: UiGroup.material,
    doc: 'A scrolling strip of cards. `itemExtent` makes every card that wide; `flexWeights` instead gives the '
        'visible ones shares of the width (`[3, 1]` is a big card with the next one peeking), and the shares '
        'move as it scrolls. `onTap` and `onIndexChanged` report `{ value: <index> }`. It needs a height: put '
        'it in a SizedBox or an AspectRatio.',
    params: <UiParam>[
      p('itemExtent', 'double', 'How wide (or tall) every card is.'),
      p('flexWeights', 'List<int>', 'Shares of the viewport for the visible cards, instead of `itemExtent`.'),
      p('shrinkExtent', 'double', 'How small a card may get while leaving.', '0'),
      p('itemSnapping', 'bool', 'Lets go on a card, not between two.', 'false'),
      e('scrollDirection', Axis.values, null, 'horizontal'),
      p('reverse', 'bool', null, 'false'),
      p('consumeMaxWeight', 'bool', 'With `flexWeights`, lets every card reach the largest share.', 'true'),
      p('infinite', 'bool', 'Scrolls round for ever.', 'false'),
      p('enableSplash', 'bool', 'The ink ripple on tap.', 'true'),
      p('padding', 'EdgeInsets', 'Around each card.'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shape', 'ShapeBorder'),
      e('itemClipBehavior', Clip.values, null, 'antiAlias'),
      p('overlayColor', 'Color', 'The ink colour while pressed.'),
      p('onTap', 'event<int>'),
      p('onIndexChanged', 'event<int>', 'The card that reached the leading edge.'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) {
      final double? itemExtent = a.number(const ['itemExtent']);
      final List<int>? weights = a.list<int>(const ['flexWeights'], a.integer);
      final double shrinkExtent = a.number(const ['shrinkExtent']) ?? 0;
      final bool itemSnapping = a.boolean(const ['itemSnapping']) ?? false;
      final Axis direction = a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.horizontal;
      final bool reverse = a.boolean(const ['reverse']) ?? false;
      final bool consumeMaxWeight = a.boolean(const ['consumeMaxWeight']) ?? true;
      final bool infinite = a.boolean(const ['infinite']) ?? false;
      final bool enableSplash = a.boolean(const ['enableSplash']) ?? true;
      final EdgeInsets? padding = a.edgeInsets(const ['padding'])?.resolve(Directionality.of(a.context));
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? elevation = a.number(const ['elevation']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final Clip clip = a.enumValue(Clip.values, const ['itemClipBehavior']) ?? Clip.antiAlias;
      final Color? overlay = a.color(const ['overlayColor']);
      final ValueChanged<int>? onTap = a.onValue<int>(const ['onTap']);
      final ValueChanged<int>? onIndexChanged = a.onValue<int>(const ['onIndexChanged']);
      final List<Widget> children = a.children(const ['children']);
      if (weights != null && weights.isNotEmpty) {
        return CarouselView.weighted(
          flexWeights: weights,
          shrinkExtent: shrinkExtent,
          itemSnapping: itemSnapping,
          scrollDirection: direction,
          reverse: reverse,
          consumeMaxWeight: consumeMaxWeight,
          infinite: infinite,
          enableSplash: enableSplash,
          padding: padding,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape is OutlinedBorder ? shape : null,
          itemClipBehavior: clip,
          overlayColor: overlay == null ? null : WidgetStatePropertyAll<Color>(overlay),
          onTap: onTap,
          onIndexChanged: onIndexChanged,
          children: children,
        );
      }
      return CarouselView(
        itemExtent: itemExtent ?? 200,
        shrinkExtent: shrinkExtent,
        itemSnapping: itemSnapping,
        scrollDirection: direction,
        reverse: reverse,
        infinite: infinite,
        enableSplash: enableSplash,
        padding: padding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape is OutlinedBorder ? shape : null,
        itemClipBehavior: clip,
        overlayColor: overlay == null ? null : WidgetStatePropertyAll<Color>(overlay),
        onTap: onTap,
        onIndexChanged: onIndexChanged,
        children: children,
      );
    },
    example: 'SizedBox(height: 180, child: CarouselView(itemExtent: 220, itemSnapping: true, children: ['
        'ColoredBox(color: .primaryContainer), ColoredBox(color: .secondaryContainer), '
        'ColoredBox(color: .tertiaryContainer)]))',
  ),
  UiWidget(
    'MaterialBanner',
    group: UiGroup.material,
    doc: 'A message across the top of the content with its own actions -- "you are offline", "an update is '
        'ready". Unlike a snack bar it stays until something takes it away, so put it in a Column above the '
        'rest and show it from data.',
    params: <UiParam>[
      p('content', 'Widget|String'),
      p('leading', 'Widget|Icon'),
      p('actions', 'List<Widget>', 'Text buttons, at the end or below.'),
      p('contentTextStyle', 'TextStyle'),
      p('backgroundColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('shadowColor', 'Color'),
      p('dividerColor', 'Color'),
      p('elevation', 'double'),
      p('padding', 'EdgeInsets'),
      p('margin', 'EdgeInsets'),
      p('leadingPadding', 'EdgeInsets'),
      p('forceActionsBelow', 'bool', 'Puts the actions on their own line whatever the width.', 'false'),
      e('overflowAlignment', OverflowBarAlignment.values, null, 'end'),
      p('minActionBarHeight', 'double', null, '52'),
    ],
    build: (UiArgs a) => MaterialBanner(
      content: a.label(const ['content']) ?? const SizedBox.shrink(),
      leading: a.iconOrChild(const ['leading']),
      actions: a.children(const ['actions']),
      contentTextStyle: a.textStyle(const ['contentTextStyle']),
      backgroundColor: a.color(const ['backgroundColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      shadowColor: a.color(const ['shadowColor']),
      dividerColor: a.color(const ['dividerColor']),
      elevation: a.number(const ['elevation']),
      padding: a.edgeInsets(const ['padding']),
      margin: a.edgeInsets(const ['margin']),
      leadingPadding: a.edgeInsets(const ['leadingPadding']),
      forceActionsBelow: a.boolean(const ['forceActionsBelow']) ?? false,
      overflowAlignment: a.enumValue(OverflowBarAlignment.values, const ['overflowAlignment']) ?? OverflowBarAlignment.end,
      minActionBarHeight: a.number(const ['minActionBarHeight']) ?? 52,
    ),
    example: 'MaterialBanner(leading: Icon(icon: "wifi_off"), content: "You are offline", '
        'actions: [TextButton(child: "Retry", onPressed: event "sync.retry" { })])',
  ),

];

/// The arguments the selectable chips share.
final List<UiParam> _chipCommon = <UiParam>[
  p('label', 'Widget|String'),
  p('avatar', 'Widget|Icon'),
  p('labelStyle', 'TextStyle'),
  p('labelPadding', 'EdgeInsets'),
  p('side', 'BorderSide'),
  p('shape', 'ShapeBorder'),
  p('backgroundColor', 'Color'),
  p('padding', 'EdgeInsets'),
  p('visualDensity', 'String'),
  p('elevation', 'double'),
  p('shadowColor', 'Color'),
  p('surfaceTintColor', 'Color'),
];

typedef _PlainButton = Widget Function({
  required VoidCallback? onPressed,
  VoidCallback? onLongPress,
  ButtonStyle? style,
  bool autofocus,
  Clip? clipBehavior,
  required Widget child,
});

typedef _IconButton = Widget Function({
  required VoidCallback? onPressed,
  VoidCallback? onLongPress,
  ButtonStyle? style,
  bool autofocus,
  Clip? clipBehavior,
  Widget? icon,
  required Widget label,
  IconAlignment? iconAlignment,
});

/// The five Material 3 buttons share every argument; with `icon` they are
/// their `.icon` constructor.
UiWidget _button(String name, String what, _PlainButton plain, _IconButton withIcon) => UiWidget(
  name,
  group: UiGroup.material,
  doc: '$what `child` may be a plain string; `icon` adds a leading icon. '
      'With no `onPressed` it is drawn disabled, as in Flutter.',
  params: <UiParam>[
    p('child', 'Widget|String'),
    p('icon', 'Widget|Icon'),
    e('iconAlignment', IconAlignment.values, 'Which side of the label the icon is on.', 'start'),
    p('onPressed', 'event'),
    p('onLongPress', 'event'),
    p('style', 'ButtonStyle'),
    p('autofocus', 'bool', null, 'false'),
    e('clipBehavior', Clip.values),
  ],
  build: (UiArgs a) {
    final Widget? child = a.label(const ['child']);
    final Widget? icon = a.iconOrChild(const ['icon']);
    final IconAlignment? iconAlignment = a.enumValue(IconAlignment.values, const ['iconAlignment']);
    final VoidCallback? onPressed = a.onTap(const ['onPressed']);
    final VoidCallback? onLongPress = a.onTap(const ['onLongPress']);
    final ButtonStyle? style = a.buttonStyle(const ['style']);
    final bool autofocus = a.boolean(const ['autofocus']) ?? false;
    final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
    if (icon != null) {
      return withIcon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: style,
        autofocus: autofocus,
        clipBehavior: clip,
        icon: icon,
        label: child ?? const SizedBox.shrink(),
        iconAlignment: iconAlignment,
      );
    }
    return plain(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      autofocus: autofocus,
      clipBehavior: clip,
      child: child ?? const SizedBox.shrink(),
    );
  },
  example: '$name(child: "Continue", icon: "arrow_forward", iconAlignment: "end", onPressed: event "next" {})',
);

Widget _ink(UiArgs a, {required bool circle}) {
  final VoidCallback? down = a.onTap(const ['onTapDown']);
  final Color? overlay = a.color(const ['overlayColor']);
  final Widget? child = a.optionalChild(const ['child']);
  final GestureTapCallback? onTap = a.onTap(const ['onTap']);
  final GestureTapCallback? onDoubleTap = a.onTap(const ['onDoubleTap']);
  final GestureLongPressCallback? onLongPress = a.onTap(const ['onLongPress']);
  final GestureTapCancelCallback? onTapCancel = a.onTap(const ['onTapCancel']);
  final ValueChanged<bool>? onHover = a.onValue<bool>(const ['onHover']);
  final BorderRadius? borderRadius = a.borderRadius(const ['borderRadius'])?.resolve(Directionality.maybeOf(a.context));
  final ShapeBorder? customBorder = a.shape(const ['customBorder']);
  final Color? splashColor = a.color(const ['splashColor']);
  final Color? highlightColor = a.color(const ['highlightColor']);
  final Color? hoverColor = a.color(const ['hoverColor']);
  final Color? focusColor = a.color(const ['focusColor']);
  final double? radius = a.number(const ['radius']);
  final bool enableFeedback = a.boolean(const ['enableFeedback']) ?? true;
  final bool excludeFromSemantics = a.boolean(const ['excludeFromSemantics']) ?? false;
  final bool canRequestFocus = a.boolean(const ['canRequestFocus']) ?? true;
  final bool autofocus = a.boolean(const ['autofocus']) ?? false;
  final WidgetStateProperty<Color?>? overlayColor = overlay == null ? null : WidgetStatePropertyAll<Color?>(overlay);
  final GestureTapDownCallback? onTapDown = down == null ? null : (_) => down();
  if (circle) {
    return InkResponse(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapCancel: onTapCancel,
      onHover: onHover,
      borderRadius: borderRadius,
      customBorder: customBorder,
      splashColor: splashColor,
      highlightColor: highlightColor,
      hoverColor: hoverColor,
      focusColor: focusColor,
      overlayColor: overlayColor,
      radius: radius,
      enableFeedback: enableFeedback,
      excludeFromSemantics: excludeFromSemantics,
      canRequestFocus: canRequestFocus,
      autofocus: autofocus,
      child: child,
    );
  }
  return InkWell(
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapCancel: onTapCancel,
    onHover: onHover,
    borderRadius: borderRadius,
    customBorder: customBorder,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    focusColor: focusColor,
    overlayColor: overlayColor,
    radius: radius,
    enableFeedback: enableFeedback,
    excludeFromSemantics: excludeFromSemantics,
    canRequestFocus: canRequestFocus,
    autofocus: autofocus,
    child: child,
  );
}

/// Flutter's default hero tag, which two FABs on one screen collide on. A
/// remote file that never names one gets this, the same for every FAB, which
/// is Flutter's behaviour; naming one is how to have two.
class _DefaultHeroTag {
  const _DefaultHeroTag();

  @override
  String toString() => '<default FloatingActionButton tag>';
}
