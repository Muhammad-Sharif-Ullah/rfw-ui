import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'args.dart';
import 'slot.dart';
import 'spec.dart';
import 'state.dart';

/// The iOS widgets. rfw ships none.
///
/// Colours take the same tokens as everywhere else, which resolve against the
/// Material theme in scope; a CupertinoTheme, where there is one, still styles
/// whatever is left unset. Cupertino icons are `"cupertino.<name>"`.
final List<UiWidget> cupertinoWidgets = <UiWidget>[
  UiWidget(
    'CupertinoPageScaffold',
    group: UiGroup.cupertino,
    doc: 'An iOS screen: a navigation bar over a child. A translucent bar lets the child scroll under it.',
    params: <UiParam>[
      p('navigationBar', 'Widget', 'Usually a CupertinoNavigationBar.'),
      p('backgroundColor', 'Color'),
      p('resizeToAvoidBottomInset', 'bool', null, 'true'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final Widget? bar = a.optionalChild(const ['navigationBar']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final bool resize = a.boolean(const ['resizeToAvoidBottomInset']) ?? true;
      final Widget child = a.child(const ['child']);
      return UiSlots(
        initial: const <String, SlotValue>{'bar': SlotValue(Size.fromHeight(kMinInteractiveDimensionCupertino), false)},
        builder: (BuildContext context, UiSlot Function(String, Widget) slot) => CupertinoPageScaffold(
          navigationBar: bar == null ? null : slot('bar', bar),
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resize,
          child: child,
        ),
      );
    },
  ),
  UiWidget(
    'CupertinoNavigationBar',
    group: UiGroup.cupertino,
    doc: 'The iOS top bar: leading, middle, trailing. `middle` may be a string.',
    params: <UiParam>[
      p('leading', 'Widget|Icon'),
      p('automaticallyImplyLeading', 'bool', null, 'true'),
      p('automaticallyImplyMiddle', 'bool', null, 'true'),
      p('previousPageTitle', 'String'),
      p('middle', 'Widget|String'),
      p('trailing', 'Widget|Icon'),
      p('border', 'Border', 'The line under the bar; `{ bottom: "none" }` hides it.'),
      p('backgroundColor', 'Color'),
      p('automaticBackgroundVisibility', 'bool', null, 'true'),
      p('enableBackgroundFilterBlur', 'bool', null, 'true'),
      e('brightness', Brightness.values),
      p('padding', 'EdgeInsets'),
      p('transitionBetweenRoutes', 'bool', null, 'true'),
    ],
    build: (UiArgs a) {
      final BoxBorder? border = a.border(const ['border']);
      final bool transition = a.boolean(const ['transitionBetweenRoutes']) ?? true;
      final CupertinoNavigationBar bar = CupertinoNavigationBar(
        leading: a.iconOrChild(const ['leading']),
        automaticallyImplyLeading: a.boolean(const ['automaticallyImplyLeading']) ?? true,
        automaticallyImplyMiddle: a.boolean(const ['automaticallyImplyMiddle']) ?? true,
        previousPageTitle: a.string(const ['previousPageTitle']),
        middle: a.label(const ['middle']),
        trailing: a.iconOrChild(const ['trailing']),
        border: border is Border ? border : _defaultNavBorder,
        backgroundColor: a.color(const ['backgroundColor']),
        automaticBackgroundVisibility: a.boolean(const ['automaticBackgroundVisibility']) ?? true,
        enableBackgroundFilterBlur: a.boolean(const ['enableBackgroundFilterBlur']) ?? true,
        brightness: a.enumValue(Brightness.values, const ['brightness']),
        padding: a.directionalInsets(const ['padding']),
        transitionBetweenRoutes: transition,
      );
      UiSlot.report(a.context, bar, obstructs: bar.shouldFullyObstruct(a.context));
      return bar;
    },
    example: 'CupertinoNavigationBar(middle: "Settings", trailing: CupertinoButton(child: "Done", padding: 0, onPressed: event "done" {}))',
  ),
  UiWidget(
    'CupertinoButton',
    group: UiGroup.cupertino,
    doc: 'An iOS button. `variant` is `plain`, `filled` or `tinted`; `child` may be a string.',
    params: <UiParam>[
      p('child', 'Widget|String'),
      p('onPressed', 'event'),
      p('onLongPress', 'event'),
      oneOf('variant', <String>['plain', 'filled', 'tinted'], null, 'plain'),
      e('sizeStyle', CupertinoButtonSize.values, null, 'large'),
      p('padding', 'EdgeInsets'),
      p('color', 'Color'),
      p('foregroundColor', 'Color'),
      p('disabledColor', 'Color'),
      p('minimumSize', 'Size'),
      p('pressedOpacity', 'double', null, '0.4'),
      p('borderRadius', 'BorderRadius'),
      p('alignment', 'Alignment', null, 'center'),
      p('focusColor', 'Color'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final Widget child = a.label(const ['child']) ?? const SizedBox.shrink();
      final VoidCallback? onPressed = a.onTap(const ['onPressed']);
      final VoidCallback? onLongPress = a.onTap(const ['onLongPress']);
      final String variant = a.string(const ['variant']) ?? 'plain';
      final CupertinoButtonSize sizeStyle = a.enumValue(CupertinoButtonSize.values, const ['sizeStyle']) ?? CupertinoButtonSize.large;
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final Color? color = a.color(const ['color']);
      final Color? foregroundColor = a.color(const ['foregroundColor']);
      final Color disabledColor = a.color(const ['disabledColor']) ?? CupertinoColors.quaternarySystemFill;
      final Size? minimumSize = a.size(const ['minimumSize']);
      final double pressedOpacity = a.number(const ['pressedOpacity']) ?? 0.4;
      final BorderRadius? borderRadius = a.borderRadius(const ['borderRadius'])?.resolve(Directionality.maybeOf(a.context));
      final AlignmentGeometry alignment = a.alignment(const ['alignment']) ?? Alignment.center;
      final Color? focusColor = a.color(const ['focusColor']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      switch (variant) {
        case 'filled':
          return CupertinoButton.filled(
            onPressed: onPressed,
            onLongPress: onLongPress,
            sizeStyle: sizeStyle,
            padding: padding,
            color: color,
            foregroundColor: foregroundColor,
            disabledColor: disabledColor,
            minimumSize: minimumSize,
            pressedOpacity: pressedOpacity,
            borderRadius: borderRadius,
            alignment: alignment,
            focusColor: focusColor,
            autofocus: autofocus,
            child: child,
          );
        case 'tinted':
          return CupertinoButton.tinted(
            onPressed: onPressed,
            onLongPress: onLongPress,
            sizeStyle: sizeStyle,
            padding: padding,
            color: color,
            foregroundColor: foregroundColor,
            disabledColor: disabledColor,
            minimumSize: minimumSize,
            pressedOpacity: pressedOpacity,
            borderRadius: borderRadius,
            alignment: alignment,
            focusColor: focusColor,
            autofocus: autofocus,
            child: child,
          );
        default:
          return CupertinoButton(
            onPressed: onPressed,
            onLongPress: onLongPress,
            sizeStyle: sizeStyle,
            padding: padding,
            color: color,
            foregroundColor: foregroundColor,
            disabledColor: disabledColor,
            minimumSize: minimumSize,
            pressedOpacity: pressedOpacity,
            borderRadius: borderRadius,
            alignment: alignment,
            focusColor: focusColor,
            autofocus: autofocus,
            child: child,
          );
      }
    },
    example: 'CupertinoButton(variant: "filled", child: "Continue", onPressed: event "next" {})',
  ),
  UiWidget(
    'CupertinoSwitch',
    group: UiGroup.cupertino,
    doc: 'The iOS switch. `onChanged` receives `{ value: <on> }`.',
    params: <UiParam>[
      p('value', 'bool'),
      p('onChanged', 'event<bool>'),
      p('activeTrackColor', 'Color'),
      p('inactiveTrackColor', 'Color'),
      p('thumbColor', 'Color'),
      p('inactiveThumbColor', 'Color'),
      p('trackOutlineColor', 'Color'),
      p('trackOutlineWidth', 'double'),
      p('focusColor', 'Color'),
      p('onLabelColor', 'Color'),
      p('offLabelColor', 'Color'),
      p('thumbIcon', 'Map', 'An icon name, or `{ default: "...", selected: "..." }`.'),
      p('applyTheme', 'bool'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final Color? activeTrackColor = a.color(const ['activeTrackColor']);
      final Color? inactiveTrackColor = a.color(const ['inactiveTrackColor']);
      final Color? thumbColor = a.color(const ['thumbColor']);
      final Color? inactiveThumbColor = a.color(const ['inactiveThumbColor']);
      final WidgetStateProperty<Color?>? trackOutlineColor = a.stateColor(const ['trackOutlineColor']);
      final double? trackOutlineWidth = a.number(const ['trackOutlineWidth']);
      final Color? focusColor = a.color(const ['focusColor']);
      final Color? onLabelColor = a.color(const ['onLabelColor']);
      final Color? offLabelColor = a.color(const ['offLabelColor']);
      final WidgetStateProperty<Icon?>? thumbIcon = a.state<Icon>(const ['thumbIcon'], (List<Object> k) {
        final IconData? data = a.icon(k);
        return data == null ? null : Icon(data);
      });
      final bool? applyTheme = a.boolean(const ['applyTheme']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<bool>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool>(const ['onChanged']),
        builder: (BuildContext context, bool value, ValueChanged<bool>? onChanged) => CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          thumbColor: thumbColor,
          inactiveThumbColor: inactiveThumbColor,
          trackOutlineColor: trackOutlineColor,
          trackOutlineWidth: trackOutlineWidth == null ? null : WidgetStatePropertyAll<double?>(trackOutlineWidth),
          focusColor: focusColor,
          onLabelColor: onLabelColor,
          offLabelColor: offLabelColor,
          thumbIcon: thumbIcon,
          applyTheme: applyTheme,
          autofocus: autofocus,
        ),
      );
    },
    example: 'CupertinoSwitch(value: true, onChanged: event "ui.set" { key: "airplane" })',
  ),
  UiWidget(
    'CupertinoSlider',
    group: UiGroup.cupertino,
    doc: 'The iOS slider. `onChanged` receives `{ value: <number> }`.',
    params: <UiParam>[
      p('value', 'double'),
      p('min', 'double', null, '0'),
      p('max', 'double', null, '1'),
      p('divisions', 'int'),
      p('onChanged', 'event<double>'),
      p('onChangeStart', 'event<double>'),
      p('onChangeEnd', 'event<double>'),
      p('activeColor', 'Color'),
      p('thumbColor', 'Color'),
    ],
    build: (UiArgs a) {
      final double min = a.number(const ['min']) ?? 0;
      final double maxGiven = a.number(const ['max']) ?? 1;
      final double max = maxGiven < min ? min : maxGiven;
      final int? divisions = a.integer(const ['divisions']);
      final ValueChanged<double>? onChangeStart = a.onValue<double>(const ['onChangeStart']);
      final ValueChanged<double>? onChangeEnd = a.onValue<double>(const ['onChangeEnd']);
      final Color? activeColor = a.color(const ['activeColor']);
      final Color thumbColor = a.color(const ['thumbColor']) ?? CupertinoColors.white;
      return UiValue<double>(
        value: a.number(const ['value']),
        initial: min,
        onChanged: a.onValue<double>(const ['onChanged']),
        builder: (BuildContext context, double value, ValueChanged<double>? onChanged) => CupertinoSlider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions != null && divisions > 0 ? divisions : null,
          onChanged: onChanged,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          activeColor: activeColor,
          thumbColor: thumbColor,
        ),
      );
    },
  ),
  UiWidget(
    'CupertinoTextField',
    group: UiGroup.cupertino,
    doc: 'The iOS text field. `placeholder` is its hint; `onChanged` / `onSubmitted` receive `{ value: "<text>" }`.',
    params: <UiParam>[
      p('value', 'String'),
      p('placeholder', 'String'),
      p('placeholderStyle', 'TextStyle'),
      p('prefix', 'Widget|Icon'),
      p('suffix', 'Widget|Icon'),
      e('clearButtonMode', OverlayVisibilityMode.values, null, 'never'),
      p('onChanged', 'event<String>'),
      p('onSubmitted', 'event<String>'),
      p('onEditingComplete', 'event'),
      p('onTap', 'event'),
      p('decoration', 'Decoration', '`"none"` for a borderless field.'),
      p('padding', 'EdgeInsets', null, '7'),
      p('keyboardType', 'String'),
      e('textInputAction', TextInputAction.values),
      e('textCapitalization', TextCapitalization.values),
      p('style', 'TextStyle'),
      e('textAlign', TextAlign.values, null, 'start'),
      p('obscureText', 'bool', null, 'false'),
      p('autocorrect', 'bool', null, 'true'),
      p('maxLines', 'int', null, '1'),
      p('minLines', 'int'),
      p('maxLength', 'int'),
      p('readOnly', 'bool', null, 'false'),
      p('enabled', 'bool', null, 'true'),
      p('autofocus', 'bool', null, 'false'),
      p('cursorColor', 'Color'),
      p('inputFormatters', 'List<Map>'),
    ],
    build: (UiArgs a) {
      final String? placeholder = a.string(const ['placeholder']);
      final TextStyle placeholderStyle = a.textStyle(const ['placeholderStyle']) ??
          const TextStyle(fontWeight: FontWeight.w400, color: CupertinoColors.placeholderText);
      final Widget? prefix = a.iconOrChild(const ['prefix']);
      final Widget? suffix = a.iconOrChild(const ['suffix']);
      final OverlayVisibilityMode clear = a.enumValue(OverlayVisibilityMode.values, const ['clearButtonMode']) ?? OverlayVisibilityMode.never;
      final ValueChanged<String>? onChanged = a.onValue<String>(const ['onChanged']);
      final ValueChanged<String>? onSubmitted = a.onValue<String>(const ['onSubmitted']);
      final VoidCallback? onEditingComplete = a.onTap(const ['onEditingComplete']);
      final GestureTapCallback? onTap = a.onTap(const ['onTap']);
      final bool bare = a.string(const ['decoration']) == 'none';
      final Decoration? decoration = a.decoration(const ['decoration']);
      final EdgeInsetsGeometry padding = a.edgeInsets(const ['padding']) ?? const EdgeInsets.all(7);
      final TextInputType? keyboardType = a.keyboardType(const ['keyboardType']);
      final TextInputAction? action = a.enumValue(TextInputAction.values, const ['textInputAction']);
      final TextCapitalization capitalization = a.enumValue(TextCapitalization.values, const ['textCapitalization']) ?? TextCapitalization.none;
      final TextStyle? style = a.textStyle(const ['style']);
      final TextAlign textAlign = a.enumValue(TextAlign.values, const ['textAlign']) ?? TextAlign.start;
      final bool obscureText = a.boolean(const ['obscureText']) ?? false;
      final bool autocorrect = a.boolean(const ['autocorrect']) ?? true;
      final int maxLines = obscureText ? 1 : (a.integer(const ['maxLines']) ?? 1);
      final int? minLines = a.integer(const ['minLines']);
      final int? maxLength = a.integer(const ['maxLength']);
      final bool readOnly = a.boolean(const ['readOnly']) ?? false;
      final bool enabled = a.boolean(const ['enabled']) ?? true;
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      final Color? cursorColor = a.color(const ['cursorColor']);
      final List<TextInputFormatter>? formatters = a.inputFormatters(const ['inputFormatters']);
      return UiTextController(
        value: a.string(const ['value']),
        id: a.key,
        builder: (BuildContext context, TextEditingController controller, FocusNode focusNode) => CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          // `"none"` is borderless; a decoration of the file's own replaces
          // the default; no decoration is the iOS rounded field.
          decoration: bare ? null : (decoration is BoxDecoration ? decoration : _defaultFieldDecoration),
          placeholder: placeholder,
          placeholderStyle: placeholderStyle,
          prefix: prefix,
          suffix: suffix,
          clearButtonMode: clear,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          onTap: onTap,
          padding: padding,
          keyboardType: keyboardType,
          textInputAction: action,
          textCapitalization: capitalization,
          style: style,
          textAlign: textAlign,
          obscureText: obscureText,
          autocorrect: autocorrect,
          maxLines: maxLines,
          minLines: minLines != null && minLines > maxLines ? maxLines : minLines,
          maxLength: maxLength,
          readOnly: readOnly,
          enabled: enabled,
          autofocus: autofocus,
          cursorColor: cursorColor,
          inputFormatters: formatters,
        ),
      );
    },
    example: 'CupertinoTextField(placeholder: "Name", prefix: "cupertino.person", clearButtonMode: "editing")',
  ),
  UiWidget(
    'CupertinoSearchTextField',
    group: UiGroup.cupertino,
    doc: 'The iOS search field. `onChanged` / `onSubmitted` receive `{ value: "<query>" }`.',
    params: <UiParam>[
      p('value', 'String'),
      p('placeholder', 'String'),
      p('placeholderStyle', 'TextStyle'),
      p('style', 'TextStyle'),
      p('onChanged', 'event<String>'),
      p('onSubmitted', 'event<String>'),
      p('onTap', 'event'),
      p('onSuffixTap', 'event', 'Replaces the default, which clears the field.'),
      p('backgroundColor', 'Color'),
      p('borderRadius', 'BorderRadius'),
      p('padding', 'EdgeInsets'),
      p('itemColor', 'Color'),
      p('itemSize', 'double', null, '20'),
      p('prefixIcon', 'Widget|Icon'),
      p('suffixIcon', 'IconData'),
      e('suffixMode', OverlayVisibilityMode.values, null, 'editing'),
      p('keyboardType', 'String'),
      p('enabled', 'bool'),
      p('autofocus', 'bool', null, 'false'),
      p('autocorrect', 'bool', null, 'true'),
    ],
    build: (UiArgs a) {
      final String? placeholder = a.string(const ['placeholder']);
      final TextStyle? placeholderStyle = a.textStyle(const ['placeholderStyle']);
      final TextStyle? style = a.textStyle(const ['style']);
      final ValueChanged<String>? onChanged = a.onValue<String>(const ['onChanged']);
      final ValueChanged<String>? onSubmitted = a.onValue<String>(const ['onSubmitted']);
      final VoidCallback? onTap = a.onTap(const ['onTap']);
      final VoidCallback? onSuffixTap = a.onTap(const ['onSuffixTap']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final BorderRadius? borderRadius = a.borderRadius(const ['borderRadius'])?.resolve(Directionality.maybeOf(a.context));
      final EdgeInsetsGeometry padding = a.edgeInsets(const ['padding']) ?? const EdgeInsetsDirectional.fromSTEB(5.5, 8, 5.5, 8);
      final Color itemColor = a.color(const ['itemColor']) ?? CupertinoColors.secondaryLabel;
      final double itemSize = a.number(const ['itemSize']) ?? 20;
      final Widget? prefixIcon = a.iconOrChild(const ['prefixIcon']);
      final IconData? suffixIcon = a.icon(const ['suffixIcon']);
      final OverlayVisibilityMode suffixMode = a.enumValue(OverlayVisibilityMode.values, const ['suffixMode']) ?? OverlayVisibilityMode.editing;
      final TextInputType? keyboardType = a.keyboardType(const ['keyboardType']);
      final bool? enabled = a.boolean(const ['enabled']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      final bool autocorrect = a.boolean(const ['autocorrect']) ?? true;
      return UiTextController(
        value: a.string(const ['value']),
        id: a.key,
        builder: (BuildContext context, TextEditingController controller, FocusNode focusNode) => CupertinoSearchTextField(
          controller: controller,
          focusNode: focusNode,
          placeholder: placeholder,
          placeholderStyle: placeholderStyle,
          style: style,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          onSuffixTap: onSuffixTap,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          padding: padding,
          itemColor: itemColor,
          itemSize: itemSize,
          prefixIcon: prefixIcon ?? const Icon(CupertinoIcons.search),
          suffixIcon: Icon(suffixIcon ?? CupertinoIcons.xmark_circle_fill),
          suffixMode: suffixMode,
          keyboardType: keyboardType,
          enabled: enabled,
          autofocus: autofocus,
          autocorrect: autocorrect,
        ),
      );
    },
    example: 'CupertinoSearchTextField(placeholder: "Search", onChanged: event "ui.set" { key: "q" })',
  ),
  UiWidget(
    'CupertinoSlidingSegmentedControl',
    group: UiGroup.cupertino,
    doc: 'The iOS segmented control. `segments: [{ value, label }]`; `onValueChanged` receives `{ value }`.',
    params: <UiParam>[
      p('segments', 'List<Map>', 'Each `{ value, label, enabled }`; `label` is a string or a widget.'),
      p('groupValue', 'value'),
      p('onValueChanged', 'event<value>'),
      p('thumbColor', 'Color'),
      p('backgroundColor', 'Color'),
      p('padding', 'EdgeInsets'),
      p('proportionalWidth', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final List<_Segment> segments = _segments(a, ['segments']);
      final Color thumbColor = a.color(const ['thumbColor']) ??
          const CupertinoDynamicColor.withBrightness(color: Color(0xFFFFFFFF), darkColor: Color(0xFF636366));
      final Color backgroundColor = a.color(const ['backgroundColor']) ?? CupertinoColors.tertiarySystemFill;
      final EdgeInsetsGeometry padding = a.edgeInsets(const ['padding']) ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 3);
      final bool proportional = a.boolean(const ['proportionalWidth']) ?? false;
      final Object? groupValue = a.scalar(const ['groupValue']);
      final ValueChanged<Object?>? report = a.onValue<Object?>(const ['onValueChanged']);
      if (segments.length < 2) {
        return const SizedBox.shrink();
      }
      return UiValue<Object?>(
        value: groupValue,
        initial: segments.first.value,
        onChanged: report ?? (Object? _) {},
        builder: (BuildContext context, Object? value, ValueChanged<Object?>? onChanged) =>
            CupertinoSlidingSegmentedControl<Object>(
              children: <Object, Widget>{for (final _Segment s in segments) s.value: s.label},
              disabledChildren: <Object>{for (final _Segment s in segments) if (!s.enabled) s.value},
              groupValue: segments.any((_Segment s) => s.value == value) ? value : null,
              onValueChanged: (Object? v) => onChanged?.call(v),
              thumbColor: thumbColor,
              backgroundColor: backgroundColor,
              padding: padding,
              proportionalWidth: proportional,
            ),
      );
    },
    example: 'CupertinoSlidingSegmentedControl(groupValue: "map", segments: [{ value: "map", label: "Map" }, '
        '{ value: "transit", label: "Transit" }, { value: "satellite", label: "Satellite" }])',
  ),
  UiWidget(
    'CupertinoActivityIndicator',
    group: UiGroup.cupertino,
    doc: 'The iOS spinner. With `progress` (0 to 1) it is partly revealed instead of spinning.',
    params: <UiParam>[
      p('animating', 'bool', null, 'true'),
      p('radius', 'double', null, '10'),
      p('color', 'Color'),
      p('progress', 'double'),
    ],
    build: (UiArgs a) {
      final double radius = a.number(const ['radius']) ?? 10;
      final Color? color = a.color(const ['color']);
      final double? progress = a.number(const ['progress']);
      final bool animating = a.boolean(const ['animating']) ?? true;
      if (progress != null) {
        return CupertinoActivityIndicator.partiallyRevealed(radius: radius, color: color, progress: progress.clamp(0, 1));
      }
      return CupertinoActivityIndicator(animating: animating, radius: radius, color: color);
    },
    example: 'CupertinoActivityIndicator(radius: 14)',
  ),
  UiWidget(
    'CupertinoListSection',
    group: UiGroup.cupertino,
    doc: 'A group of CupertinoListTiles, as in iOS Settings. `insetGrouped: true` is the rounded, inset style.',
    params: <UiParam>[
      p('children', 'List<Widget>'),
      p('header', 'Widget|String'),
      p('footer', 'Widget|String'),
      p('insetGrouped', 'bool', null, 'false'),
      p('margin', 'EdgeInsets'),
      p('backgroundColor', 'Color'),
      p('decoration', 'Decoration'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('dividerMargin', 'double'),
      p('additionalDividerMargin', 'double'),
      p('topMargin', 'double'),
      p('hasLeading', 'bool', null, 'true'),
      p('separatorColor', 'Color'),
    ],
    build: (UiArgs a) {
      final List<Widget> children = a.children(const ['children']);
      final Widget? header = a.label(const ['header']);
      final Widget? footer = a.label(const ['footer']);
      final EdgeInsetsGeometry? margin = a.edgeInsets(const ['margin']);
      final Color backgroundColor = a.color(const ['backgroundColor']) ?? CupertinoColors.systemGroupedBackground;
      final BoxDecoration? decoration = a.decoration(const ['decoration']) is BoxDecoration ? a.decoration(const ['decoration']) as BoxDecoration : null;
      final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge;
      final double? dividerMargin = a.number(const ['dividerMargin']);
      final double? additional = a.number(const ['additionalDividerMargin']);
      final double? topMargin = a.number(const ['topMargin']);
      final bool hasLeading = a.boolean(const ['hasLeading']) ?? true;
      final Color? separatorColor = a.color(const ['separatorColor']);
      final bool insetGrouped = a.boolean(const ['insetGrouped']) ?? false;
      // Flutter asserts a section has a header or rows.
      if (children.isEmpty && header == null) {
        return const SizedBox.shrink();
      }
      if (insetGrouped) {
        return CupertinoListSection.insetGrouped(
          header: header,
          footer: footer,
          margin: margin,
          backgroundColor: backgroundColor,
          decoration: decoration,
          clipBehavior: clip,
          dividerMargin: dividerMargin ?? 14,
          additionalDividerMargin: additional,
          topMargin: topMargin,
          hasLeading: hasLeading,
          separatorColor: separatorColor,
          children: children.isEmpty ? null : children,
        );
      }
      return CupertinoListSection(
        header: header,
        footer: footer,
        margin: margin ?? EdgeInsets.zero,
        backgroundColor: backgroundColor,
        decoration: decoration,
        clipBehavior: clip,
        dividerMargin: dividerMargin ?? 14,
        additionalDividerMargin: additional,
        topMargin: topMargin ?? 22,
        hasLeading: hasLeading,
        separatorColor: separatorColor,
        children: children.isEmpty ? null : children,
      );
    },
    example: 'CupertinoListSection(insetGrouped: true, header: "Network", children: ['
        'CupertinoListTile(title: "Wi-Fi", leading: "cupertino.wifi", additionalInfo: "Home", trailing: CupertinoListTileChevron())])',
  ),
  UiWidget(
    'CupertinoListTile',
    group: UiGroup.cupertino,
    doc: 'A row of a CupertinoListSection. `notched: true` is the inset-grouped style with a larger leading.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('subtitle', 'Widget|String'),
      p('additionalInfo', 'Widget|String'),
      p('leading', 'Widget|Icon'),
      p('trailing', 'Widget|Icon'),
      p('onTap', 'event'),
      p('notched', 'bool', null, 'false'),
      p('backgroundColor', 'Color'),
      p('backgroundColorActivated', 'Color'),
      p('padding', 'EdgeInsets'),
      p('leadingSize', 'double'),
      p('leadingToTitle', 'double'),
    ],
    build: (UiArgs a) {
      final Widget title = a.label(const ['title']) ?? const SizedBox.shrink();
      final Widget? subtitle = a.label(const ['subtitle']);
      final Widget? additionalInfo = a.label(const ['additionalInfo']);
      final Widget? leading = a.iconOrChild(const ['leading']);
      final Widget? trailing = a.iconOrChild(const ['trailing']);
      final VoidCallback? onTap = a.onTap(const ['onTap']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? activated = a.color(const ['backgroundColorActivated']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final double? leadingSize = a.number(const ['leadingSize']);
      final double? leadingToTitle = a.number(const ['leadingToTitle']);
      if (a.boolean(const ['notched']) ?? false) {
        return CupertinoListTile.notched(
          title: title,
          subtitle: subtitle,
          additionalInfo: additionalInfo,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          backgroundColor: backgroundColor,
          backgroundColorActivated: activated,
          padding: padding,
          leadingSize: leadingSize ?? 30,
          leadingToTitle: leadingToTitle ?? 12,
        );
      }
      return CupertinoListTile(
        title: title,
        subtitle: subtitle,
        additionalInfo: additionalInfo,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        backgroundColor: backgroundColor,
        backgroundColorActivated: activated,
        padding: padding,
        leadingSize: leadingSize ?? 28,
        leadingToTitle: leadingToTitle ?? 16,
      );
    },
  ),
  UiWidget(
    'CupertinoListTileChevron',
    group: UiGroup.cupertino,
    doc: 'The grey chevron for the trailing end of a CupertinoListTile.',
    params: <UiParam>[],
    build: (UiArgs a) => const CupertinoListTileChevron(),
  ),
  UiWidget(
    'CupertinoCheckbox',
    group: UiGroup.cupertino,
    doc: 'The iOS-style checkbox. `onChanged` receives `{ value: <checked> }`.',
    params: <UiParam>[
      p('value', 'bool'),
      p('tristate', 'bool', null, 'false'),
      p('onChanged', 'event<bool>'),
      p('activeColor', 'Color'),
      p('fillColor', 'Color', 'A colour, or a map by state.'),
      p('checkColor', 'Color'),
      p('focusColor', 'Color'),
      p('side', 'BorderSide'),
      p('shape', 'ShapeBorder'),
      p('semanticLabel', 'String'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final bool tristate = a.boolean(const ['tristate']) ?? false;
      final Color? activeColor = a.color(const ['activeColor']);
      final WidgetStateProperty<Color?>? fillColor = a.stateColor(const ['fillColor']);
      final Color? checkColor = a.color(const ['checkColor']);
      final Color? focusColor = a.color(const ['focusColor']);
      final BorderSide? side = a.borderSide(const ['side']);
      final OutlinedBorder? shape = a.shape(const ['shape']);
      final String? semanticLabel = a.string(const ['semanticLabel']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<bool?>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool?>(const ['onChanged']),
        builder: (BuildContext context, bool? value, ValueChanged<bool?>? onChanged) => CupertinoCheckbox(
          value: tristate ? value : (value ?? false),
          tristate: tristate,
          onChanged: onChanged,
          activeColor: activeColor,
          fillColor: fillColor,
          checkColor: checkColor,
          focusColor: focusColor,
          side: side,
          shape: shape,
          semanticLabel: semanticLabel,
          autofocus: autofocus,
        ),
      );
    },
  ),
  UiWidget(
    'CupertinoRadio',
    group: UiGroup.cupertino,
    doc: 'The iOS-style radio, for use inside a RadioGroup. `useCheckmarkStyle: true` draws a checkmark instead of a dot.',
    params: <UiParam>[
      p('value', 'value'),
      p('toggleable', 'bool', null, 'false'),
      p('enabled', 'bool'),
      p('activeColor', 'Color'),
      p('inactiveColor', 'Color'),
      p('fillColor', 'Color'),
      p('focusColor', 'Color'),
      p('useCheckmarkStyle', 'bool', null, 'false'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => CupertinoRadio<Object>(
      value: a.scalar(const ['value']) ?? '',
      toggleable: a.boolean(const ['toggleable']) ?? false,
      enabled: a.boolean(const ['enabled']),
      activeColor: a.color(const ['activeColor']),
      inactiveColor: a.color(const ['inactiveColor']),
      fillColor: a.color(const ['fillColor']),
      focusColor: a.color(const ['focusColor']),
      useCheckmarkStyle: a.boolean(const ['useCheckmarkStyle']) ?? false,
      autofocus: a.boolean(const ['autofocus']) ?? false,
    ),
  ),
  UiWidget(
    'CupertinoPicker',
    group: UiGroup.cupertino,
    doc: 'The iOS wheel. `onSelectedItemChanged` receives `{ value: <index> }`. Give it a height, as in a '
        '`ui.cupertinoModal` sheet of 216.',
    params: <UiParam>[
      p('children', 'List<Widget>'),
      p('itemExtent', 'double', 'The height of one row.', '32'),
      p('initialItem', 'int', null, '0'),
      p('onSelectedItemChanged', 'event<int>'),
      p('diameterRatio', 'double'),
      p('backgroundColor', 'Color'),
      p('offAxisFraction', 'double', null, '0'),
      p('useMagnifier', 'bool', null, 'false'),
      p('magnification', 'double', null, '1'),
      p('squeeze', 'double'),
      p('looping', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final List<Widget> children = a.children(const ['children']);
      final double itemExtent = a.number(const ['itemExtent']) ?? 32;
      final int initial = a.integer(const ['initialItem']) ?? 0;
      final ValueChanged<int>? onChanged = a.onValue<int>(const ['onSelectedItemChanged']);
      final double diameterRatio = a.number(const ['diameterRatio']) ?? 1.07;
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double offAxisFraction = a.number(const ['offAxisFraction']) ?? 0;
      final bool useMagnifier = a.boolean(const ['useMagnifier']) ?? false;
      final double magnification = a.number(const ['magnification']) ?? 1;
      final double squeeze = a.number(const ['squeeze']) ?? 1.45;
      final bool looping = a.boolean(const ['looping']) ?? false;
      if (children.isEmpty) {
        return const SizedBox.shrink();
      }
      return UiOwned<FixedExtentScrollController>(
        create: () => FixedExtentScrollController(initialItem: initial.clamp(0, children.length - 1)),
        builder: (BuildContext context, FixedExtentScrollController controller) => CupertinoPicker(
          scrollController: controller,
          itemExtent: itemExtent <= 0 ? 32 : itemExtent,
          onSelectedItemChanged: onChanged,
          diameterRatio: diameterRatio,
          backgroundColor: backgroundColor,
          offAxisFraction: offAxisFraction,
          useMagnifier: useMagnifier,
          magnification: magnification,
          squeeze: squeeze,
          looping: looping,
          children: children,
        ),
      );
    },
    example: 'SizedBox(height: 150, child: CupertinoPicker(itemExtent: 32, children: [Text(text: "Apple"), Text(text: "Banana"), Text(text: "Cherry")]))',
  ),
  UiWidget(
    'CupertinoDatePicker',
    group: UiGroup.cupertino,
    doc: 'The iOS date and time wheels, inline. `onDateTimeChanged` receives `{ value: "<ISO date-time>" }`. '
        'For a sheet, put it in a `ui.cupertinoModal`.',
    params: <UiParam>[
      e('mode', CupertinoDatePickerMode.values, null, 'dateAndTime'),
      p('initialDateTime', 'Date'),
      p('minimumDate', 'Date'),
      p('maximumDate', 'Date'),
      p('minimumYear', 'int', null, '1'),
      p('maximumYear', 'int'),
      p('minuteInterval', 'int', null, '1'),
      p('use24hFormat', 'bool', null, 'false'),
      e('dateOrder', DatePickerDateOrder.values),
      p('backgroundColor', 'Color'),
      p('showDayOfWeek', 'bool', null, 'false'),
      p('itemExtent', 'double'),
      p('onDateTimeChanged', 'event<Date>'),
    ],
    build: (UiArgs a) {
      final CupertinoDatePickerMode mode = a.enumValue(CupertinoDatePickerMode.values, const ['mode']) ?? CupertinoDatePickerMode.dateAndTime;
      final DateTime? minimum = a.date(const ['minimumDate']);
      final DateTime? maximumGiven = a.date(const ['maximumDate']);
      final DateTime? maximum = minimum != null && maximumGiven != null && maximumGiven.isBefore(minimum) ? minimum : maximumGiven;
      final int minuteInterval = a.integer(const ['minuteInterval']) ?? 1;
      final int interval = minuteInterval > 0 && 60 % minuteInterval == 0 ? minuteInterval : 1;
      DateTime initial = a.date(const ['initialDateTime']) ?? DateTime.now();
      if (minimum != null && initial.isBefore(minimum)) {
        initial = minimum;
      }
      if (maximum != null && initial.isAfter(maximum)) {
        initial = maximum;
      }
      // Flutter asserts the initial minute is on the interval.
      initial = initial.copyWith(minute: initial.minute - initial.minute % interval, second: 0, millisecond: 0, microsecond: 0);
      return CupertinoDatePicker(
        mode: mode,
        initialDateTime: initial,
        minimumDate: minimum,
        maximumDate: maximum,
        minimumYear: a.integer(const ['minimumYear']) ?? 1,
        maximumYear: a.integer(const ['maximumYear']),
        minuteInterval: interval,
        use24hFormat: a.boolean(const ['use24hFormat']) ?? false,
        dateOrder: a.enumValue(DatePickerDateOrder.values, const ['dateOrder']),
        backgroundColor: a.color(const ['backgroundColor']),
        showDayOfWeek: (a.boolean(const ['showDayOfWeek']) ?? false) && mode == CupertinoDatePickerMode.date,
        itemExtent: a.number(const ['itemExtent']) ?? 32,
        onDateTimeChanged: a.onValue<DateTime>(const ['onDateTimeChanged']) ?? (DateTime _) {},
      );
    },
    example: 'SizedBox(height: 200, child: CupertinoDatePicker(mode: "date", initialDateTime: "2026-10-23"))',
  ),
  UiWidget(
    'CupertinoTabBar',
    group: UiGroup.cupertino,
    doc: 'The iOS bottom tab bar. `items: [{ icon, activeIcon, label }]`; `onTap` receives `{ value: <index> }`.',
    params: <UiParam>[
      p('items', 'List<Map>', 'Each `{ icon, activeIcon, label, tooltip, backgroundColor }`.'),
      p('currentIndex', 'int', null, '0'),
      p('onTap', 'event<int>'),
      p('backgroundColor', 'Color'),
      p('activeColor', 'Color'),
      p('inactiveColor', 'Color'),
      p('iconSize', 'double', null, '30'),
      p('height', 'double', null, '50'),
      p('border', 'Border'),
    ],
    build: (UiArgs a) {
      final List<BottomNavigationBarItem> items = a.list<BottomNavigationBarItem>(const ['items'], (List<Object> k) {
            List<Object> at(String name) => <Object>[...k, name];
            return BottomNavigationBarItem(
              icon: a.iconOrChild(at('icon')) ?? const SizedBox.square(dimension: 30),
              activeIcon: a.iconOrChild(at('activeIcon')),
              label: a.string(at('label')),
              tooltip: a.string(at('tooltip')),
              backgroundColor: a.color(at('backgroundColor')),
            );
          }) ??
          const <BottomNavigationBarItem>[];
      final int? currentIndex = a.integer(const ['currentIndex']);
      final ValueChanged<int>? onTap = a.onValue<int>(const ['onTap']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? activeColor = a.color(const ['activeColor']);
      final Color inactiveColor = a.color(const ['inactiveColor']) ?? CupertinoColors.inactiveGray;
      final double iconSize = a.number(const ['iconSize']) ?? 30;
      final double height = a.number(const ['height']) ?? 50;
      final BoxBorder? border = a.border(const ['border']);
      if (items.length < 2) {
        return const SizedBox.shrink();
      }
      return UiValue<int>(
        value: currentIndex,
        initial: 0,
        onChanged: onTap ?? (int _) {},
        builder: (BuildContext context, int index, ValueChanged<int>? tapped) => CupertinoTabBar(
          items: items,
          currentIndex: index.clamp(0, items.length - 1),
          onTap: tapped,
          backgroundColor: backgroundColor,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          iconSize: iconSize,
          height: height,
          border: border is Border ? border : _defaultTabBorder,
        ),
      );
    },
    example: 'CupertinoTabBar(items: [{ icon: "cupertino.house", label: "Home" }, { icon: "cupertino.settings", label: "Settings" }])',
  ),
  UiWidget(
    'CupertinoAlertDialog',
    group: UiGroup.dialog,
    doc: 'The iOS alert. Open it with `event "ui.cupertinoDialog" { widget: "<name>" }`; its actions are '
        'CupertinoDialogActions that close it with `event "ui.pop" { result: ... }`.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('content', 'Widget|String'),
      p('actions', 'List<Widget>'),
      p('insetAnimationDuration', 'Duration'),
    ],
    build: (UiArgs a) => CupertinoAlertDialog(
      title: a.label(const ['title']),
      content: a.label(const ['content']),
      actions: a.children(const ['actions']),
      insetAnimationDuration: a.duration(const ['insetAnimationDuration']) ?? const Duration(milliseconds: 100),
    ),
    example: 'CupertinoAlertDialog(title: "Allow notifications?", content: "You can change this in Settings.", actions: ['
        'CupertinoDialogAction(child: "Don\'t allow", onPressed: event "ui.pop" {}), '
        'CupertinoDialogAction(child: "Allow", isDefaultAction: true, onPressed: event "ui.pop" { result: true })])',
  ),
  UiWidget(
    'CupertinoDialogAction',
    group: UiGroup.dialog,
    doc: 'A button of a CupertinoAlertDialog.',
    params: <UiParam>[
      p('child', 'Widget|String'),
      p('onPressed', 'event'),
      p('isDefaultAction', 'bool', 'Bold, for the action most people want.', 'false'),
      p('isDestructiveAction', 'bool', 'Red, for one that deletes or cannot be undone.', 'false'),
      p('textStyle', 'TextStyle'),
    ],
    build: (UiArgs a) => CupertinoDialogAction(
      onPressed: a.onTap(const ['onPressed']),
      isDefaultAction: a.boolean(const ['isDefaultAction']) ?? false,
      isDestructiveAction: a.boolean(const ['isDestructiveAction']) ?? false,
      textStyle: a.textStyle(const ['textStyle']),
      child: a.label(const ['child']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'CupertinoActionSheet',
    group: UiGroup.dialog,
    doc: 'The iOS action sheet. Open it with `event "ui.cupertinoModal" { widget: "<name>" }`.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('message', 'Widget|String'),
      p('actions', 'List<Widget>'),
      p('cancelButton', 'Widget'),
    ],
    build: (UiArgs a) {
      final List<Widget> actions = a.children(const ['actions']);
      final Widget? title = a.label(const ['title']);
      final Widget? message = a.label(const ['message']);
      final Widget? cancel = a.optionalChild(const ['cancelButton']);
      // Flutter asserts there is something to show.
      return CupertinoActionSheet(
        title: title,
        message: message ?? (title == null && actions.isEmpty && cancel == null ? const SizedBox.shrink() : null),
        actions: actions.isEmpty ? null : actions,
        cancelButton: cancel,
      );
    },
    example: 'CupertinoActionSheet(title: "Share photo", actions: [CupertinoActionSheetAction(child: "Messages", onPressed: event "ui.pop" { result: "messages" })], '
        'cancelButton: CupertinoActionSheetAction(child: "Cancel", isDefaultAction: true, onPressed: event "ui.pop" {}))',
  ),
  UiWidget(
    'CupertinoActionSheetAction',
    group: UiGroup.dialog,
    doc: 'A button of a CupertinoActionSheet.',
    params: <UiParam>[
      p('child', 'Widget|String'),
      p('onPressed', 'event'),
      p('isDefaultAction', 'bool', null, 'false'),
      p('isDestructiveAction', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => CupertinoActionSheetAction(
      onPressed: a.onTap(const ['onPressed']) ?? () {},
      isDefaultAction: a.boolean(const ['isDefaultAction']) ?? false,
      isDestructiveAction: a.boolean(const ['isDestructiveAction']) ?? false,
      child: a.label(const ['child']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'CupertinoPopupSurface',
    group: UiGroup.dialog,
    doc: 'The rounded, blurred surface iOS draws a popup on -- for a `ui.cupertinoModal` of your own content.',
    params: <UiParam>[p('isSurfacePainted', 'bool', null, 'true'), p('blurSigma', 'double', null, '30'), p('child', 'Widget')],
    build: (UiArgs a) => CupertinoPopupSurface(
      isSurfacePainted: a.boolean(const ['isSurfacePainted']) ?? true,
      blurSigma: a.number(const ['blurSigma']) ?? 30,
      child: a.optionalChild(const ['child']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'CupertinoSliverRefreshControl',
    group: UiGroup.cupertino,
    doc: 'Pull to refresh, iOS style, as the first sliver of a CustomScrollView. '
        '`onRefresh` fires an event; the spinner stays for `hold` milliseconds, since an rfw event has no reply '
        'to wait for. It is pulled by overscrolling, so the scroll view needs bouncing physics '
        '(`physics: .bouncing`), which is what iOS gives it anyway.',
    params: <UiParam>[
      p('onRefresh', 'event'),
      p('hold', 'Duration', null, '800'),
      p('refreshTriggerPullDistance', 'double', 'How far it must be pulled.', '100'),
      p('refreshIndicatorExtent', 'double', 'How much room the spinner keeps while it turns.', '60'),
    ],
    build: (UiArgs a) => CupertinoSliverRefreshControl(
      onRefresh: heldRefresh(
        a.onTap(const ['onRefresh']),
        a.duration(const ['hold']) ?? const Duration(milliseconds: 800),
      ),
      refreshTriggerPullDistance: a.number(const ['refreshTriggerPullDistance']) ?? 100,
      refreshIndicatorExtent: a.number(const ['refreshIndicatorExtent']) ?? 60,
    ),
  ),

];

class _Segment {
  const _Segment(this.value, this.label, this.enabled);

  final Object value;
  final Widget label;
  final bool enabled;
}

List<_Segment> _segments(UiArgs a, List<Object> key) {
  return a.list<_Segment>(key, (List<Object> k) {
        final Object? value = a.scalar(<Object>[...k, 'value']);
        if (value == null) {
          return null;
        }
        return _Segment(
          value,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: a.label(<Object>[...k, 'label']) ?? Text('$value'),
          ),
          a.boolean(<Object>[...k, 'enabled']) ?? true,
        );
      }) ??
      const <_Segment>[];
}

/// CupertinoNavigationBar's and CupertinoTabBar's own default borders,
/// repeated because a nullable `border:` argument means "none", not "default".
const Border _defaultNavBorder = Border(
  bottom: BorderSide(color: Color(0x4D000000), width: 0),
);

const Border _defaultTabBorder = Border(
  top: BorderSide(color: Color(0x4D000000), width: 0),
);

/// CupertinoTextField's own default, repeated for the same reason: its
/// `decoration:` is null for borderless, so the default cannot be asked for.
const BoxDecoration _defaultFieldDecoration = BoxDecoration(
  color: CupertinoDynamicColor.withBrightness(color: CupertinoColors.white, darkColor: CupertinoColors.black),
  border: Border.fromBorderSide(
    BorderSide(
      color: CupertinoDynamicColor.withBrightness(color: Color(0x33000000), darkColor: Color(0x33FFFFFF)),
      width: 0,
    ),
  ),
  borderRadius: BorderRadius.all(Radius.circular(5)),
);
