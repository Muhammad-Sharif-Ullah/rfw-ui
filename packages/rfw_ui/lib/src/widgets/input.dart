import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'args.dart';
import 'spec.dart';
import 'state.dart';

/// Inputs. rfw ships none of these, because every one of them holds state.
///
/// Each reports what changed as `{ value: ... }` merged into its event's
/// arguments, and each keeps its own value so it responds at once (see
/// [UiValue]). To bind one to data with no Dart at all, point its handler at
/// the `ui.set` action:
///
///     Switch(value: data.settings.wifi, onChanged: event "ui.set" { key: "settings.wifi" })
final List<UiWidget> inputWidgets = <UiWidget>[
  UiWidget(
    'FocusTraversalGroup',
    group: UiGroup.input,
    doc: 'Decides the order Tab, `"next"` on a keyboard and `ui.focusNext` move through the focusable widgets '
        'inside it. `"ordered"` follows the `order` of each FocusTraversalOrder; the others go by position.',
    params: <UiParam>[
      oneOf('policy', <String>['readingOrder', 'widgetOrder', 'ordered'], null, 'readingOrder'),
      p('descendantsAreFocusable', 'bool', 'False takes the focus away from everything inside.', 'true'),
      p('descendantsAreTraversable', 'bool', 'False leaves everything inside focusable, but out of the Tab order.', 'true'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => FocusTraversalGroup(
      policy: switch (a.string(const ['policy'])) {
        'widgetOrder' => WidgetOrderTraversalPolicy(),
        'ordered' => OrderedTraversalPolicy(),
        _ => ReadingOrderTraversalPolicy(),
      },
      descendantsAreFocusable: a.boolean(const ['descendantsAreFocusable']) ?? true,
      descendantsAreTraversable: a.boolean(const ['descendantsAreTraversable']) ?? true,
      child: a.optionalChild(const ['child']) ?? const SizedBox.shrink(),
    ),
    example: 'FocusTraversalGroup(policy: "ordered", child: Column(children: [\n'
        '  FocusTraversalOrder(order: 2, child: TextField(decoration: { labelText: "Second" })),\n'
        '  FocusTraversalOrder(order: 1, child: TextField(decoration: { labelText: "First" })),\n'
        ']))',
  ),
  UiWidget(
    'FocusTraversalOrder',
    group: UiGroup.input,
    doc: 'Places its child in the focus order of the nearest `FocusTraversalGroup(policy: "ordered")`: lower first.',
    params: <UiParam>[p('order', 'double', null, '0'), p('child', 'Widget')],
    build: (UiArgs a) => FocusTraversalOrder(
      order: NumericFocusOrder(a.number(const ['order']) ?? 0),
      child: a.optionalChild(const ['child']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'ExcludeFocus',
    group: UiGroup.input,
    doc: 'Keeps everything inside from taking the focus, while `excluding` is true.',
    params: <UiParam>[p('excluding', 'bool', null, 'true'), p('child', 'Widget')],
    build: (UiArgs a) => ExcludeFocus(
      excluding: a.boolean(const ['excluding']) ?? true,
      child: a.optionalChild(const ['child']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'TextField',
    group: UiGroup.input,
    doc: 'A text input. `value` seeds it and replaces the text whenever the data behind it changes; '
        '`onChanged` and `onSubmitted` receive `{ value: "<text>" }`.',
    params: <UiParam>[
      p('value', 'String'),
      p('decoration', 'InputDecoration', '`"none"` for a bare field.'),
      p('onChanged', 'event<String>'),
      p('onSubmitted', 'event<String>'),
      p('onEditingComplete', 'event'),
      p('onTap', 'event'),
      p('keyboardType', 'String', '`text`, `multiline`, `number`, `decimal`, `phone`, `email`, `url`, `name`, `visiblePassword`, ...'),
      e('textInputAction', TextInputAction.values),
      e('textCapitalization', TextCapitalization.values, null, 'none'),
      p('style', 'TextStyle'),
      e('textAlign', TextAlign.values, null, 'start'),
      e('textDirection', TextDirection.values),
      p('autofocus', 'bool', null, 'false'),
      p('obscureText', 'bool', 'For passwords.', 'false'),
      p('obscuringCharacter', 'String', null, '•'),
      p('autocorrect', 'bool', null, 'true'),
      p('enableSuggestions', 'bool', null, 'true'),
      p('maxLines', 'int', null, '1'),
      p('minLines', 'int'),
      p('expands', 'bool', null, 'false'),
      p('maxLength', 'int'),
      p('readOnly', 'bool', null, 'false'),
      p('enabled', 'bool'),
      p('showCursor', 'bool'),
      p('cursorColor', 'Color'),
      p('cursorWidth', 'double', null, '2'),
      p('cursorHeight', 'double'),
      p('inputFormatters', 'List<Map>', '`"digitsOnly"`, `"singleLine"`, `{ allow: "<regex>" }`, `{ deny: "<regex>" }`.'),
    ],
    build: (UiArgs a) {
      final InputDecoration? decoration = a.inputDecoration(const ['decoration']);
      final ValueChanged<String>? onChanged = a.onValue<String>(const ['onChanged']);
      final ValueChanged<String>? onSubmitted = a.onValue<String>(const ['onSubmitted']);
      final VoidCallback? onEditingComplete = a.onTap(const ['onEditingComplete']);
      final GestureTapCallback? onTap = a.onTap(const ['onTap']);
      final TextInputType? keyboardType = a.keyboardType(const ['keyboardType']);
      final TextInputAction? textInputAction = a.enumValue(TextInputAction.values, const ['textInputAction']);
      final TextCapitalization capitalization = a.enumValue(TextCapitalization.values, const ['textCapitalization']) ?? TextCapitalization.none;
      final TextStyle? style = a.textStyle(const ['style']);
      final TextAlign textAlign = a.enumValue(TextAlign.values, const ['textAlign']) ?? TextAlign.start;
      final TextDirection? textDirection = a.enumValue(TextDirection.values, const ['textDirection']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      final bool obscureText = a.boolean(const ['obscureText']) ?? false;
      final String obscuringCharacter = a.string(const ['obscuringCharacter']) ?? '•';
      final bool autocorrect = a.boolean(const ['autocorrect']) ?? true;
      final bool enableSuggestions = a.boolean(const ['enableSuggestions']) ?? true;
      final bool expands = a.boolean(const ['expands']) ?? false;
      // An obscured field is one line, and an expanding one has no line count:
      // Flutter asserts both, so the argument gives way rather than the app.
      final int? maxLines = expands ? null : (obscureText ? 1 : (a.integer(const ['maxLines']) ?? 1));
      final int? minLines = expands ? null : a.integer(const ['minLines']);
      final int? maxLength = a.integer(const ['maxLength']);
      final bool readOnly = a.boolean(const ['readOnly']) ?? false;
      final bool? enabled = a.boolean(const ['enabled']);
      final bool? showCursor = a.boolean(const ['showCursor']);
      final Color? cursorColor = a.color(const ['cursorColor']);
      final double cursorWidth = a.number(const ['cursorWidth']) ?? 2;
      final double? cursorHeight = a.number(const ['cursorHeight']);
      final List<TextInputFormatter>? formatters = a.inputFormatters(const ['inputFormatters']);
      return UiTextController(
        value: a.string(const ['value']),
        id: a.key,
        builder: (BuildContext context, TextEditingController controller, FocusNode focusNode) => TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          onTap: onTap,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: capitalization,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          autofocus: autofocus,
          obscureText: obscureText,
          obscuringCharacter: obscuringCharacter.isEmpty ? '•' : obscuringCharacter.characters.first,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          maxLines: maxLines,
          minLines: minLines != null && maxLines != null && minLines > maxLines ? maxLines : minLines,
          expands: expands,
          maxLength: maxLength,
          readOnly: readOnly,
          enabled: enabled,
          showCursor: showCursor,
          cursorColor: cursorColor,
          cursorWidth: cursorWidth,
          cursorHeight: cursorHeight,
          inputFormatters: formatters,
        ),
      );
    },
    example: 'TextField(decoration: { labelText: "Email", hintText: "you@example.com", prefixIcon: "mail_outline", '
        'border: "outline" }, keyboardType: "email", onChanged: event "ui.set" { key: "form.email" })',
  ),
  UiWidget(
    'Checkbox',
    group: UiGroup.input,
    doc: 'A checkbox. `onChanged` receives `{ value: <checked> }`; with `tristate` the value may also be null.',
    params: <UiParam>[
      p('value', 'bool'),
      p('tristate', 'bool', null, 'false'),
      p('onChanged', 'event<bool>'),
      p('activeColor', 'Color'),
      p('checkColor', 'Color'),
      p('fillColor', 'Color', 'A colour, or a map by state.'),
      p('focusColor', 'Color'),
      p('hoverColor', 'Color'),
      p('overlayColor', 'Color'),
      p('splashRadius', 'double'),
      e('materialTapTargetSize', MaterialTapTargetSize.values),
      p('visualDensity', 'String'),
      p('shape', 'ShapeBorder'),
      p('side', 'BorderSide'),
      p('isError', 'bool', null, 'false'),
      p('semanticLabel', 'String'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final bool tristate = a.boolean(const ['tristate']) ?? false;
      final Color? activeColor = a.color(const ['activeColor']);
      final Color? checkColor = a.color(const ['checkColor']);
      final WidgetStateProperty<Color?>? fillColor = a.stateColor(const ['fillColor']);
      final Color? focusColor = a.color(const ['focusColor']);
      final Color? hoverColor = a.color(const ['hoverColor']);
      final WidgetStateProperty<Color?>? overlayColor = a.stateColor(const ['overlayColor']);
      final double? splashRadius = a.number(const ['splashRadius']);
      final MaterialTapTargetSize? tapTarget = a.enumValue(MaterialTapTargetSize.values, const ['materialTapTargetSize']);
      final VisualDensity? visualDensity = a.visualDensity(const ['visualDensity']);
      final OutlinedBorder? shape = a.shape(const ['shape']);
      final BorderSide? side = a.borderSide(const ['side']);
      final bool isError = a.boolean(const ['isError']) ?? false;
      final String? semanticLabel = a.string(const ['semanticLabel']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<bool?>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool?>(const ['onChanged']),
        builder: (BuildContext context, bool? value, ValueChanged<bool?>? onChanged) => Checkbox(
          value: tristate ? value : (value ?? false),
          tristate: tristate,
          onChanged: onChanged,
          activeColor: activeColor,
          checkColor: checkColor,
          fillColor: fillColor,
          focusColor: focusColor,
          hoverColor: hoverColor,
          overlayColor: overlayColor,
          splashRadius: splashRadius,
          materialTapTargetSize: tapTarget,
          visualDensity: visualDensity,
          shape: shape,
          side: side,
          isError: isError,
          semanticLabel: semanticLabel,
          autofocus: autofocus,
        ),
      );
    },
    example: 'Checkbox(value: true, onChanged: event "ui.set" { key: "agree" })',
  ),
  UiWidget(
    'CheckboxListTile',
    group: UiGroup.input,
    doc: 'A ListTile with a checkbox; tapping anywhere on it toggles.',
    params: <UiParam>[
      p('value', 'bool'),
      p('tristate', 'bool', null, 'false'),
      p('onChanged', 'event<bool>'),
      ..._tileParams,
      p('checkColor', 'Color'),
      p('checkboxShape', 'ShapeBorder'),
      p('isError', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final bool tristate = a.boolean(const ['tristate']) ?? false;
      final _Tile tile = _Tile.read(a);
      final Color? checkColor = a.color(const ['checkColor']);
      final OutlinedBorder? checkboxShape = a.shape(const ['checkboxShape']);
      final bool isError = a.boolean(const ['isError']) ?? false;
      return UiValue<bool?>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool?>(const ['onChanged']),
        builder: (BuildContext context, bool? value, ValueChanged<bool?>? onChanged) => CheckboxListTile(
          value: tristate ? value : (value ?? false),
          tristate: tristate,
          onChanged: onChanged,
          title: tile.title,
          subtitle: tile.subtitle,
          secondary: tile.secondary,
          isThreeLine: tile.isThreeLine,
          dense: tile.dense,
          selected: tile.selected,
          controlAffinity: tile.controlAffinity,
          contentPadding: tile.contentPadding,
          activeColor: tile.activeColor,
          tileColor: tile.tileColor,
          selectedTileColor: tile.selectedTileColor,
          shape: tile.shape,
          visualDensity: tile.visualDensity,
          enabled: tile.enabled,
          checkColor: checkColor,
          checkboxShape: checkboxShape,
          isError: isError,
        ),
      );
    },
    example: 'CheckboxListTile(value: false, title: "Email me updates", subtitle: "About once a month", onChanged: event "ui.set" { key: "updates" })',
  ),
  UiWidget(
    'Switch',
    group: UiGroup.input,
    doc: 'An on/off switch. `onChanged` receives `{ value: <on> }`. `adaptive: true` is a Cupertino switch on Apple platforms.',
    params: <UiParam>[
      p('value', 'bool'),
      p('onChanged', 'event<bool>'),
      p('adaptive', 'bool', null, 'false'),
      p('activeThumbColor', 'Color'),
      p('activeTrackColor', 'Color'),
      p('inactiveThumbColor', 'Color'),
      p('inactiveTrackColor', 'Color'),
      p('thumbColor', 'Color', 'A colour, or a map by state.'),
      p('trackColor', 'Color', 'A colour, or a map by state.'),
      p('trackOutlineColor', 'Color', 'A colour, or a map by state.'),
      p('thumbIcon', 'Map', 'An icon name, or `{ default: "close", selected: "check" }`.'),
      e('materialTapTargetSize', MaterialTapTargetSize.values),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final bool adaptive = a.boolean(const ['adaptive']) ?? false;
      final Color? activeThumbColor = a.color(const ['activeThumbColor']);
      final Color? activeTrackColor = a.color(const ['activeTrackColor']);
      final Color? inactiveThumbColor = a.color(const ['inactiveThumbColor']);
      final Color? inactiveTrackColor = a.color(const ['inactiveTrackColor']);
      final WidgetStateProperty<Color?>? thumbColor = a.stateColor(const ['thumbColor']);
      final WidgetStateProperty<Color?>? trackColor = a.stateColor(const ['trackColor']);
      final WidgetStateProperty<Color?>? trackOutlineColor = a.stateColor(const ['trackOutlineColor']);
      final WidgetStateProperty<Icon?>? thumbIcon = a.state<Icon>(const ['thumbIcon'], (List<Object> k) {
        final IconData? data = a.icon(k);
        return data == null ? null : Icon(data);
      });
      final MaterialTapTargetSize? tapTarget = a.enumValue(MaterialTapTargetSize.values, const ['materialTapTargetSize']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<bool>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool>(const ['onChanged']),
        builder: (BuildContext context, bool value, ValueChanged<bool>? onChanged) => adaptive
            ? Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: activeThumbColor,
                activeTrackColor: activeTrackColor,
                inactiveThumbColor: inactiveThumbColor,
                inactiveTrackColor: inactiveTrackColor,
                thumbColor: thumbColor,
                trackColor: trackColor,
                trackOutlineColor: trackOutlineColor,
                thumbIcon: thumbIcon,
                materialTapTargetSize: tapTarget,
                autofocus: autofocus,
              )
            : Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: activeThumbColor,
                activeTrackColor: activeTrackColor,
                inactiveThumbColor: inactiveThumbColor,
                inactiveTrackColor: inactiveTrackColor,
                thumbColor: thumbColor,
                trackColor: trackColor,
                trackOutlineColor: trackOutlineColor,
                thumbIcon: thumbIcon,
                materialTapTargetSize: tapTarget,
                autofocus: autofocus,
              ),
      );
    },
    example: 'Switch(value: true, thumbIcon: { default: "close", selected: "check" }, onChanged: event "ui.set" { key: "wifi" })',
  ),
  UiWidget(
    'SwitchListTile',
    group: UiGroup.input,
    doc: 'A ListTile with a switch; tapping anywhere on it toggles.',
    params: <UiParam>[
      p('value', 'bool'),
      p('onChanged', 'event<bool>'),
      ..._tileParams,
      p('activeTrackColor', 'Color'),
      p('inactiveThumbColor', 'Color'),
      p('inactiveTrackColor', 'Color'),
      p('thumbIcon', 'Map', 'An icon name, or `{ default: "close", selected: "check" }`.'),
    ],
    build: (UiArgs a) {
      final _Tile tile = _Tile.read(a);
      final Color? activeTrackColor = a.color(const ['activeTrackColor']);
      final Color? inactiveThumbColor = a.color(const ['inactiveThumbColor']);
      final Color? inactiveTrackColor = a.color(const ['inactiveTrackColor']);
      final WidgetStateProperty<Icon?>? thumbIcon = a.state<Icon>(const ['thumbIcon'], (List<Object> k) {
        final IconData? data = a.icon(k);
        return data == null ? null : Icon(data);
      });
      return UiValue<bool>(
        value: a.boolean(const ['value']),
        initial: false,
        onChanged: a.onValue<bool>(const ['onChanged']),
        builder: (BuildContext context, bool value, ValueChanged<bool>? onChanged) => SwitchListTile(
          value: value,
          // SwitchListTile has no `enabled`; no handler is how it is disabled.
          onChanged: tile.enabled == false ? null : onChanged,
          title: tile.title,
          subtitle: tile.subtitle,
          secondary: tile.secondary,
          isThreeLine: tile.isThreeLine,
          dense: tile.dense,
          selected: tile.selected,
          controlAffinity: tile.controlAffinity,
          contentPadding: tile.contentPadding,
          activeThumbColor: tile.activeColor,
          tileColor: tile.tileColor,
          selectedTileColor: tile.selectedTileColor,
          shape: tile.shape,
          visualDensity: tile.visualDensity,
          activeTrackColor: activeTrackColor,
          inactiveThumbColor: inactiveThumbColor,
          inactiveTrackColor: inactiveTrackColor,
          thumbIcon: thumbIcon,
        ),
      );
    },
    example: 'SwitchListTile(value: true, title: "Wi-Fi", secondary: "wifi", onChanged: event "ui.set" { key: "wifi" })',
  ),
  UiWidget(
    'RadioGroup',
    group: UiGroup.input,
    doc: 'Holds the selection for every Radio and RadioListTile below it. `onChanged` receives `{ value: <the chosen radio\'s value> }`.',
    params: <UiParam>[p('groupValue', 'value'), p('onChanged', 'event<value>'), p('child', 'Widget')],
    build: (UiArgs a) {
      final Widget child = a.child(const ['child']);
      final ValueChanged<Object?>? report = a.onValue<Object?>(const ['onChanged']);
      return UiValue<Object?>(
        value: a.scalar(const ['groupValue']),
        initial: null,
        // A group with no handler still selects: a radio that ignores the tap
        // is a broken radio, and there is no disabled look for a whole group.
        onChanged: report ?? (Object? _) {},
        builder: (BuildContext context, Object? value, ValueChanged<Object?>? onChanged) => RadioGroup<Object>(
          groupValue: value,
          onChanged: onChanged ?? (Object? _) {},
          child: child,
        ),
      );
    },
    example: 'RadioGroup(groupValue: "card", onChanged: event "ui.set" { key: "pay" }, child: Column(children: ['
        'RadioListTile(value: "card", title: "Card"), RadioListTile(value: "cash", title: "Cash")]))',
  ),
  UiWidget(
    'Radio',
    group: UiGroup.input,
    doc: 'One choice of a RadioGroup above it; selected when its `value` is the group\'s.',
    params: <UiParam>[
      p('value', 'value'),
      p('enabled', 'bool'),
      p('toggleable', 'bool', 'Tapping the selected radio clears the group.', 'false'),
      p('activeColor', 'Color'),
      p('fillColor', 'Color', 'A colour, or a map by state.'),
      p('focusColor', 'Color'),
      p('hoverColor', 'Color'),
      p('overlayColor', 'Color'),
      p('splashRadius', 'double'),
      e('materialTapTargetSize', MaterialTapTargetSize.values),
      p('visualDensity', 'String'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => Radio<Object>(
      value: a.scalar(const ['value']) ?? '',
      enabled: a.boolean(const ['enabled']),
      toggleable: a.boolean(const ['toggleable']) ?? false,
      activeColor: a.color(const ['activeColor']),
      fillColor: a.stateColor(const ['fillColor']),
      focusColor: a.color(const ['focusColor']),
      hoverColor: a.color(const ['hoverColor']),
      overlayColor: a.stateColor(const ['overlayColor']),
      splashRadius: a.number(const ['splashRadius']),
      materialTapTargetSize: a.enumValue(MaterialTapTargetSize.values, const ['materialTapTargetSize']),
      visualDensity: a.visualDensity(const ['visualDensity']),
      autofocus: a.boolean(const ['autofocus']) ?? false,
    ),
  ),
  UiWidget(
    'RadioListTile',
    group: UiGroup.input,
    doc: 'A ListTile with a radio, for use inside a RadioGroup.',
    params: <UiParam>[
      p('value', 'value'),
      p('toggleable', 'bool', null, 'false'),
      ..._tileParams,
      p('fillColor', 'Color', 'A colour, or a map by state.'),
    ],
    build: (UiArgs a) {
      final _Tile tile = _Tile.read(a);
      return RadioListTile<Object>(
        value: a.scalar(const ['value']) ?? '',
        toggleable: a.boolean(const ['toggleable']) ?? false,
        title: tile.title,
        subtitle: tile.subtitle,
        secondary: tile.secondary,
        isThreeLine: tile.isThreeLine,
        dense: tile.dense,
        selected: tile.selected,
        controlAffinity: tile.controlAffinity,
        contentPadding: tile.contentPadding,
        activeColor: tile.activeColor,
        tileColor: tile.tileColor,
        selectedTileColor: tile.selectedTileColor,
        shape: tile.shape,
        visualDensity: tile.visualDensity,
        enabled: tile.enabled,
        fillColor: a.stateColor(const ['fillColor']),
      );
    },
  ),
  UiWidget(
    'Slider',
    group: UiGroup.input,
    doc: 'Picks a number by dragging. `onChanged` receives `{ value: <number> }` while dragging, `onChangeEnd` once on release.',
    params: <UiParam>[
      p('value', 'double'),
      p('min', 'double', null, '0'),
      p('max', 'double', null, '1'),
      p('divisions', 'int', 'Snap to this many steps.'),
      p('label', 'String', 'Shown above the thumb while dragging; `{value}` is replaced by the value.'),
      p('onChanged', 'event<double>'),
      p('onChangeStart', 'event<double>'),
      p('onChangeEnd', 'event<double>'),
      p('secondaryTrackValue', 'double'),
      p('activeColor', 'Color'),
      p('inactiveColor', 'Color'),
      p('secondaryActiveColor', 'Color'),
      p('thumbColor', 'Color'),
      p('overlayColor', 'Color'),
      p('padding', 'EdgeInsets'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final double min = a.number(const ['min']) ?? 0;
      final double max = a.number(const ['max']) ?? 1;
      final int? divisions = a.integer(const ['divisions']);
      final String? label = a.string(const ['label']);
      final ValueChanged<double>? onChangeStart = a.onValue<double>(const ['onChangeStart']);
      final ValueChanged<double>? onChangeEnd = a.onValue<double>(const ['onChangeEnd']);
      final double? secondary = a.number(const ['secondaryTrackValue']);
      final Color? activeColor = a.color(const ['activeColor']);
      final Color? inactiveColor = a.color(const ['inactiveColor']);
      final Color? secondaryActiveColor = a.color(const ['secondaryActiveColor']);
      final Color? thumbColor = a.color(const ['thumbColor']);
      final WidgetStateProperty<Color?>? overlayColor = a.stateColor(const ['overlayColor']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<double>(
        value: a.number(const ['value']),
        initial: min,
        onChanged: a.onValue<double>(const ['onChanged']),
        builder: (BuildContext context, double value, ValueChanged<double>? onChanged) => Slider(
          value: value.clamp(min, max < min ? min : max),
          min: min,
          max: max < min ? min : max,
          divisions: divisions != null && divisions > 0 ? divisions : null,
          label: label?.replaceAll('{value}', _short(value)),
          onChanged: onChanged,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          secondaryTrackValue: secondary?.clamp(min, max < min ? min : max),
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          secondaryActiveColor: secondaryActiveColor,
          thumbColor: thumbColor,
          overlayColor: overlayColor,
          padding: padding,
          autofocus: autofocus,
        ),
      );
    },
    example: 'Slider(value: 40, min: 0, max: 100, divisions: 10, label: "{value}%", onChanged: event "ui.set" { key: "volume" })',
  ),
  UiWidget(
    'RangeSlider',
    group: UiGroup.input,
    doc: 'Picks a range by dragging two thumbs. `onChanged` receives `{ value: { start, end } }`.',
    params: <UiParam>[
      p('values', 'Map', '`{ start, end }`.'),
      p('min', 'double', null, '0'),
      p('max', 'double', null, '1'),
      p('divisions', 'int'),
      p('labels', 'Map', '`{ start, end }`; `{value}` is replaced by each value.'),
      p('onChanged', 'event<Range>'),
      p('onChangeEnd', 'event<Range>'),
      p('activeColor', 'Color'),
      p('inactiveColor', 'Color'),
    ],
    build: (UiArgs a) {
      final double min = a.number(const ['min']) ?? 0;
      final double max = a.number(const ['max']) ?? 1;
      final double top = max < min ? min : max;
      final double? start = a.number(const ['values', 'start']);
      final double? end = a.number(const ['values', 'end']);
      final int? divisions = a.integer(const ['divisions']);
      final String? startLabel = a.string(const ['labels', 'start']);
      final String? endLabel = a.string(const ['labels', 'end']);
      final ValueChanged<RangeValues>? onChangeEnd = a.onValue<RangeValues>(const ['onChangeEnd']);
      final Color? activeColor = a.color(const ['activeColor']);
      final Color? inactiveColor = a.color(const ['inactiveColor']);
      return UiValue<RangeValues>(
        value: start == null || end == null ? null : RangeValues(start, end),
        initial: RangeValues(min, top),
        onChanged: a.onValue<RangeValues>(const ['onChanged']),
        builder: (BuildContext context, RangeValues values, ValueChanged<RangeValues>? onChanged) {
          final double s = values.start.clamp(min, top);
          final double e = values.end.clamp(s, top);
          return RangeSlider(
            values: RangeValues(s, e),
            min: min,
            max: top,
            divisions: divisions != null && divisions > 0 ? divisions : null,
            labels: startLabel == null && endLabel == null
                ? null
                : RangeLabels(
                    (startLabel ?? '{value}').replaceAll('{value}', _short(s)),
                    (endLabel ?? '{value}').replaceAll('{value}', _short(e)),
                  ),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          );
        },
      );
    },
    example: 'RangeSlider(values: { start: 20, end: 80 }, min: 0, max: 100, divisions: 20, labels: { start: "{value}", end: "{value}" })',
  ),
  UiWidget(
    'DropdownButton',
    group: UiGroup.input,
    doc: 'A compact menu of options. `items: [{ value, label }]`; `onChanged` receives `{ value: <the chosen value> }`.',
    params: <UiParam>[
      p('value', 'value'),
      p('items', 'List<Map>', 'Each `{ value, label, enabled }`; `label` is a string or a widget.'),
      p('onChanged', 'event<value>'),
      p('hint', 'Widget|String', 'Shown when nothing is chosen.'),
      p('disabledHint', 'Widget|String'),
      p('isExpanded', 'bool', 'Fill the width instead of hugging the label.', 'false'),
      p('isDense', 'bool', null, 'false'),
      p('elevation', 'int', null, '8'),
      p('style', 'TextStyle'),
      p('icon', 'Widget|Icon'),
      p('iconSize', 'double', null, '24'),
      p('iconEnabledColor', 'Color'),
      p('iconDisabledColor', 'Color'),
      p('itemHeight', 'double'),
      p('focusColor', 'Color'),
      p('dropdownColor', 'Color'),
      p('menuMaxHeight', 'double'),
      p('borderRadius', 'BorderRadius'),
      p('alignment', 'Alignment'),
      p('padding', 'EdgeInsets'),
      p('underline', 'Widget', 'Replaces the line under the button; `SizedBoxShrink()` for none.'),
      p('autofocus', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final List<DropdownMenuItem<Object>> items = _options(a, ['items'])
          .map((_Option o) => DropdownMenuItem<Object>(value: o.value, enabled: o.enabled, child: o.label))
          .toList();
      final Widget? hint = a.label(const ['hint']);
      final Widget? disabledHint = a.label(const ['disabledHint']);
      final bool isExpanded = a.boolean(const ['isExpanded']) ?? false;
      final bool isDense = a.boolean(const ['isDense']) ?? false;
      final int elevation = a.integer(const ['elevation']) ?? 8;
      final TextStyle? style = a.textStyle(const ['style']);
      final Widget? icon = a.iconOrChild(const ['icon']);
      final double iconSize = a.number(const ['iconSize']) ?? 24;
      final Color? iconEnabledColor = a.color(const ['iconEnabledColor']);
      final Color? iconDisabledColor = a.color(const ['iconDisabledColor']);
      final double? itemHeight = a.number(const ['itemHeight']);
      final Color? focusColor = a.color(const ['focusColor']);
      final Color? dropdownColor = a.color(const ['dropdownColor']);
      final double? menuMaxHeight = a.number(const ['menuMaxHeight']);
      final BorderRadius? borderRadius = a.borderRadius(const ['borderRadius'])?.resolve(Directionality.maybeOf(a.context));
      final AlignmentGeometry alignment = a.alignment(const ['alignment']) ?? AlignmentDirectional.centerStart;
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final Widget? underline = a.optionalChild(const ['underline']);
      final bool autofocus = a.boolean(const ['autofocus']) ?? false;
      return UiValue<Object?>(
        value: a.scalar(const ['value']),
        initial: null,
        onChanged: a.onValue<Object?>(const ['onChanged']),
        builder: (BuildContext context, Object? value, ValueChanged<Object?>? onChanged) => DropdownButton<Object>(
          // A value no item has is an assertion in Flutter and a typo in a
          // remote file; it shows as nothing chosen instead.
          value: items.any((DropdownMenuItem<Object> i) => i.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
          hint: hint,
          disabledHint: disabledHint,
          isExpanded: isExpanded,
          isDense: isDense,
          elevation: elevation,
          style: style,
          icon: icon,
          iconSize: iconSize,
          iconEnabledColor: iconEnabledColor,
          iconDisabledColor: iconDisabledColor,
          itemHeight: itemHeight != null && itemHeight >= kMinInteractiveDimension ? itemHeight : kMinInteractiveDimension,
          focusColor: focusColor,
          dropdownColor: dropdownColor,
          menuMaxHeight: menuMaxHeight,
          borderRadius: borderRadius,
          alignment: alignment,
          padding: padding,
          underline: underline,
          autofocus: autofocus,
        ),
      );
    },
    example: 'DropdownButton(value: "md", items: [{ value: "sm", label: "Small" }, { value: "md", label: "Medium" }, '
        '{ value: "lg", label: "Large" }], onChanged: event "ui.set" { key: "size" })',
  ),
  UiWidget(
    'DropdownMenu',
    group: UiGroup.input,
    doc: 'The Material 3 dropdown: a text field that opens a menu, optionally filtering as you type. '
        '`entries: [{ value, label, leadingIcon }]`; `onSelected` receives `{ value }`.',
    params: <UiParam>[
      p('entries', 'List<Map>', 'Each `{ value, label, leadingIcon, trailingIcon, enabled }`; `label` is a string.'),
      p('initialSelection', 'value'),
      p('onSelected', 'event<value>'),
      p('label', 'Widget|String'),
      p('hintText', 'String'),
      p('helperText', 'String'),
      p('errorText', 'String'),
      p('leadingIcon', 'Widget|Icon'),
      p('trailingIcon', 'Widget|Icon'),
      p('width', 'double'),
      p('menuHeight', 'double'),
      p('enabled', 'bool', null, 'true'),
      p('enableFilter', 'bool', null, 'false'),
      p('enableSearch', 'bool', null, 'true'),
      p('requestFocusOnTap', 'bool', 'False makes it a pure picker with no keyboard.'),
      p('textStyle', 'TextStyle'),
      p('expandedInsets', 'EdgeInsets', 'Give `0` to fill the width.'),
    ],
    build: (UiArgs a) => DropdownMenu<Object>(
      dropdownMenuEntries: _options(a, ['entries'])
          .map((_Option o) => DropdownMenuEntry<Object>(
                value: o.value,
                label: o.text ?? '${o.value}',
                leadingIcon: o.leading,
                trailingIcon: o.trailing,
                enabled: o.enabled,
              ))
          .toList(),
      initialSelection: a.scalar(const ['initialSelection']),
      onSelected: a.onValue<Object?>(const ['onSelected']),
      label: a.label(const ['label']),
      hintText: a.string(const ['hintText']),
      helperText: a.string(const ['helperText']),
      errorText: a.string(const ['errorText']),
      leadingIcon: a.iconOrChild(const ['leadingIcon']),
      trailingIcon: a.iconOrChild(const ['trailingIcon']),
      width: a.number(const ['width']),
      menuHeight: a.number(const ['menuHeight']),
      enabled: a.boolean(const ['enabled']) ?? true,
      enableFilter: a.boolean(const ['enableFilter']) ?? false,
      enableSearch: a.boolean(const ['enableSearch']) ?? true,
      requestFocusOnTap: a.boolean(const ['requestFocusOnTap']),
      textStyle: a.textStyle(const ['textStyle']),
      expandedInsets: a.edgeInsets(const ['expandedInsets']),
    ),
    example: 'DropdownMenu(label: "Country", initialSelection: "bd", entries: [{ value: "bd", label: "Bangladesh" }, '
        '{ value: "jp", label: "Japan" }], onSelected: event "ui.set" { key: "country" })',
  ),
  UiWidget(
    'PopupMenuButton',
    group: UiGroup.input,
    doc: 'A button that opens a menu. `items: [{ value, label, icon }]` (or `{ divider: true }`); '
        '`onSelected` receives `{ value }`.',
    params: <UiParam>[
      p('items', 'List<Map>', 'Each `{ value, label, icon, enabled }`, or `{ divider: true }`.'),
      p('onSelected', 'event<value>'),
      p('onCanceled', 'event'),
      p('initialValue', 'value'),
      p('tooltip', 'String'),
      p('icon', 'Widget|Icon', 'The button; a "more" icon by default.'),
      p('iconSize', 'double'),
      p('iconColor', 'Color'),
      p('child', 'Widget', 'A button of your own instead of the icon.'),
      p('elevation', 'double'),
      p('color', 'Color'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('shape', 'ShapeBorder'),
      p('offset', 'Offset'),
      e('position', PopupMenuPosition.values),
      p('padding', 'EdgeInsets'),
      p('menuPadding', 'EdgeInsets'),
      p('enabled', 'bool', null, 'true'),
    ],
    build: (UiArgs a) {
      final List<_Option> options = _options(a, ['items']);
      final Widget? child = a.optionalChild(const ['child']);
      final Widget? icon = a.iconOrChild(const ['icon']);
      return PopupMenuButton<Object>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Object>>[
          for (final _Option o in options)
            if (o.divider)
              const PopupMenuDivider()
            else
              PopupMenuItem<Object>(
                value: o.value,
                enabled: o.enabled,
                child: o.leading == null
                    ? o.label
                    : Row(mainAxisSize: MainAxisSize.min, spacing: 12, children: <Widget>[o.leading!, o.label]),
              ),
        ],
        onSelected: a.onValue<Object>(const ['onSelected']),
        onCanceled: a.onTap(const ['onCanceled']),
        initialValue: a.scalar(const ['initialValue']),
        tooltip: a.string(const ['tooltip']),
        // Flutter asserts on both; a custom child is the more specific ask.
        icon: child == null ? icon : null,
        iconSize: a.number(const ['iconSize']),
        iconColor: a.color(const ['iconColor']),
        elevation: a.number(const ['elevation']),
        color: a.color(const ['color']),
        shadowColor: a.color(const ['shadowColor']),
        surfaceTintColor: a.color(const ['surfaceTintColor']),
        shape: a.shape(const ['shape']),
        offset: a.offset(const ['offset']) ?? Offset.zero,
        position: a.enumValue(PopupMenuPosition.values, const ['position']),
        padding: a.edgeInsets(const ['padding']) ?? const EdgeInsets.all(8),
        menuPadding: a.edgeInsets(const ['menuPadding']),
        enabled: a.boolean(const ['enabled']) ?? true,
        child: child,
      );
    },
    example: 'PopupMenuButton(items: [{ value: "edit", label: "Edit", icon: "edit" }, { divider: true }, '
        '{ value: "delete", label: "Delete", icon: "delete" }], onSelected: event "menu" {})',
  ),
  UiWidget(
    'SegmentedButton',
    group: UiGroup.input,
    doc: 'Two to five connected options. `segments: [{ value, label, icon }]`; `selected` is a value, or a list with '
        '`multiSelectionEnabled`. `onSelectionChanged` receives `{ value }` -- a list when several may be chosen.',
    params: <UiParam>[
      p('segments', 'List<Map>', 'Each `{ value, label, icon, tooltip, enabled }`.'),
      p('selected', 'value', 'A value, or a list of values.'),
      p('onSelectionChanged', 'event<value>'),
      p('multiSelectionEnabled', 'bool', null, 'false'),
      p('emptySelectionAllowed', 'bool', null, 'false'),
      p('showSelectedIcon', 'bool', null, 'true'),
      p('selectedIcon', 'Widget|Icon'),
      p('style', 'ButtonStyle'),
      e('direction', Axis.values, null, 'horizontal'),
    ],
    build: (UiArgs a) {
      final List<ButtonSegment<Object>> segments = _options(a, ['segments'])
          .map((_Option o) => ButtonSegment<Object>(
                value: o.value,
                label: o.hasLabel ? o.label : null,
                icon: o.leading,
                tooltip: o.tooltip,
                enabled: o.enabled,
              ))
          .toList();
      final bool multi = a.boolean(const ['multiSelectionEnabled']) ?? false;
      final bool emptyAllowed = a.boolean(const ['emptySelectionAllowed']) ?? false;
      final bool showSelectedIcon = a.boolean(const ['showSelectedIcon']) ?? true;
      final Widget? selectedIcon = a.iconOrChild(const ['selectedIcon']);
      final ButtonStyle? style = a.buttonStyle(const ['style']);
      final Axis direction = a.enumValue(Axis.values, const ['direction']) ?? Axis.horizontal;
      final ValueChanged<Object?>? report = a.onValue<Object?>(const ['onSelectionChanged']);
      final Set<Object>? given = a.source.isList(['selected'])
          ? (a.list<Object>(const ['selected'], a.scalar) ?? const <Object>[]).toSet()
          : switch (a.scalar(const ['selected'])) {
              null => null,
              final Object one => <Object>{one},
            };
      if (segments.isEmpty) {
        return const SizedBox.shrink();
      }
      return UiValue<Set<Object>>(
        value: given,
        initial: emptyAllowed ? <Object>{} : <Object>{segments.first.value},
        equals: setEquals,
        onChanged: report == null ? null : (Set<Object> s) => report(multi ? s.toList() : (s.isEmpty ? null : s.first)),
        builder: (BuildContext context, Set<Object> selected, ValueChanged<Set<Object>>? onChanged) {
          final Set<Object> known = selected.where((Object v) => segments.any((ButtonSegment<Object> s) => s.value == v)).toSet();
          // Flutter asserts the selection is legal for the mode; a remote file
          // that says otherwise gets the nearest legal selection.
          final Set<Object> legal = !multi && known.length > 1
              ? <Object>{known.first}
              : (known.isEmpty && !emptyAllowed ? <Object>{segments.first.value} : known);
          return SegmentedButton<Object>(
            segments: segments,
            selected: legal,
            onSelectionChanged: onChanged,
            multiSelectionEnabled: multi,
            emptySelectionAllowed: emptyAllowed,
            showSelectedIcon: showSelectedIcon,
            selectedIcon: selectedIcon,
            style: style,
            direction: direction,
          );
        },
      );
    },
    example: 'SegmentedButton(selected: "week", segments: [{ value: "day", label: "Day" }, { value: "week", label: "Week" }, '
        '{ value: "month", label: "Month", icon: "calendar_month" }], onSelectionChanged: event "ui.set" { key: "range" })',
  ),
  UiWidget(
    'SearchBar',
    group: UiGroup.input,
    doc: 'A rounded search field. `onChanged` / `onSubmitted` receive `{ value: "<query>" }`.',
    params: <UiParam>[
      p('value', 'String'),
      p('hintText', 'String'),
      p('leading', 'Widget|Icon'),
      p('trailing', 'List<Widget>'),
      p('onChanged', 'event<String>'),
      p('onSubmitted', 'event<String>'),
      p('onTap', 'event'),
      p('constraints', 'BoxConstraints'),
      p('elevation', 'double'),
      p('backgroundColor', 'Color'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('overlayColor', 'Color'),
      p('side', 'BorderSide'),
      p('shape', 'ShapeBorder'),
      p('padding', 'EdgeInsets'),
      p('textStyle', 'TextStyle'),
      p('hintStyle', 'TextStyle'),
      e('textCapitalization', TextCapitalization.values),
      p('enabled', 'bool', null, 'true'),
      p('autoFocus', 'bool', null, 'false'),
      e('textInputAction', TextInputAction.values),
      p('keyboardType', 'String'),
    ],
    build: (UiArgs a) {
      final String? hintText = a.string(const ['hintText']);
      final Widget? leading = a.iconOrChild(const ['leading']);
      final List<Widget> trailing = a.children(const ['trailing']);
      final ValueChanged<String>? onChanged = a.onValue<String>(const ['onChanged']);
      final ValueChanged<String>? onSubmitted = a.onValue<String>(const ['onSubmitted']);
      final VoidCallback? onTap = a.onTap(const ['onTap']);
      final BoxConstraints? constraints = a.boxConstraints(const ['constraints']);
      final WidgetStateProperty<double?>? elevation = a.state<double>(const ['elevation'], a.number);
      final WidgetStateProperty<Color?>? backgroundColor = a.stateColor(const ['backgroundColor']);
      final WidgetStateProperty<Color?>? shadowColor = a.stateColor(const ['shadowColor']);
      final WidgetStateProperty<Color?>? surfaceTintColor = a.stateColor(const ['surfaceTintColor']);
      final WidgetStateProperty<Color?>? overlayColor = a.stateColor(const ['overlayColor']);
      final WidgetStateProperty<BorderSide?>? side = a.state<BorderSide>(const ['side'], a.borderSide);
      final WidgetStateProperty<OutlinedBorder?>? shape = a.state<OutlinedBorder>(const ['shape'], a.shape);
      final WidgetStateProperty<EdgeInsetsGeometry?>? padding = a.state<EdgeInsetsGeometry>(const ['padding'], a.edgeInsets);
      final WidgetStateProperty<TextStyle?>? textStyle = a.state<TextStyle>(const ['textStyle'], a.textStyle);
      final WidgetStateProperty<TextStyle?>? hintStyle = a.state<TextStyle>(const ['hintStyle'], a.textStyle);
      final TextCapitalization? capitalization = a.enumValue(TextCapitalization.values, const ['textCapitalization']);
      final bool enabled = a.boolean(const ['enabled']) ?? true;
      final bool autoFocus = a.boolean(const ['autoFocus']) ?? false;
      final TextInputAction? action = a.enumValue(TextInputAction.values, const ['textInputAction']);
      final TextInputType? keyboardType = a.keyboardType(const ['keyboardType']);
      return UiTextController(
        value: a.string(const ['value']),
        id: a.key,
        builder: (BuildContext context, TextEditingController controller, FocusNode focusNode) => SearchBar(
          controller: controller,
          focusNode: focusNode,
          hintText: hintText,
          leading: leading,
          trailing: trailing.isEmpty ? null : trailing,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          constraints: constraints,
          elevation: elevation,
          backgroundColor: backgroundColor,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          overlayColor: overlayColor,
          side: side,
          shape: shape,
          padding: padding,
          textStyle: textStyle,
          hintStyle: hintStyle,
          textCapitalization: capitalization,
          enabled: enabled,
          autoFocus: autoFocus,
          textInputAction: action,
          keyboardType: keyboardType,
        ),
      );
    },
    example: 'SearchBar(hintText: "Search", leading: "search", onChanged: event "ui.set" { key: "query" })',
  ),
  UiWidget(
    'CalendarDatePicker',
    group: UiGroup.input,
    doc: 'A month calendar to pick a date inline. For a dialog, use the `ui.pickDate` action. '
        '`onDateChanged` receives `{ value: "<YYYY-MM-DD>" }`.',
    params: <UiParam>[
      p('initialDate', 'Date'),
      p('firstDate', 'Date', null, '1900-01-01'),
      p('lastDate', 'Date', null, '2100-12-31'),
      p('currentDate', 'Date', 'The date marked as today.'),
      p('onDateChanged', 'event<Date>'),
      e('initialCalendarMode', DatePickerMode.values, null, 'day'),
    ],
    build: (UiArgs a) {
      final DateTime first = a.date(const ['firstDate']) ?? DateTime(1900);
      final DateTime lastGiven = a.date(const ['lastDate']) ?? DateTime(2100, 12, 31);
      final DateTime last = lastGiven.isBefore(first) ? first : lastGiven;
      final DateTime? initial = a.date(const ['initialDate']);
      return CalendarDatePicker(
        initialDate: initial == null || initial.isBefore(first) || initial.isAfter(last) ? null : initial,
        firstDate: first,
        lastDate: last,
        currentDate: a.date(const ['currentDate']),
        onDateChanged: a.onValue<DateTime>(const ['onDateChanged']) ?? (DateTime _) {},
        initialCalendarMode: a.enumValue(DatePickerMode.values, const ['initialCalendarMode']) ?? DatePickerMode.day,
      );
    },
    example: 'CalendarDatePicker(initialDate: "2026-10-23", firstDate: "2026-01-01", lastDate: "2026-12-31", '
        'onDateChanged: event "ui.set" { key: "date" })',
  ),
];

/// One entry of an `items` / `entries` / `segments` list.
class _Option {
  const _Option({
    required this.value,
    required this.label,
    required this.text,
    required this.hasLabel,
    required this.leading,
    required this.trailing,
    required this.tooltip,
    required this.enabled,
    required this.divider,
  });

  final Object value;
  final Widget label;
  final String? text;
  final bool hasLabel;
  final Widget? leading;
  final Widget? trailing;
  final String? tooltip;
  final bool enabled;
  final bool divider;
}

/// `[{ value, label, icon | leadingIcon, trailingIcon, tooltip, enabled }]`,
/// where a label is a string or a widget and an icon a name or a widget.
List<_Option> _options(UiArgs a, List<Object> key) {
  return a.list<_Option>(key, (List<Object> k) {
        List<Object> at(String name) => <Object>[...k, name];
        final bool divider = a.boolean(at('divider')) ?? false;
        final Object? value = a.scalar(at('value'));
        if (value == null && !divider) {
          return null;
        }
        final String? text = a.string(at('label'));
        final Widget? label = a.label(at('label'));
        return _Option(
          value: value ?? '',
          label: label ?? Text('${value ?? ''}'),
          text: text,
          hasLabel: label != null,
          leading: a.iconOrChild(at('icon')) ?? a.iconOrChild(at('leadingIcon')),
          trailing: a.iconOrChild(at('trailingIcon')),
          tooltip: a.string(at('tooltip')),
          enabled: a.boolean(at('enabled')) ?? true,
          divider: divider,
        );
      }) ??
      const <_Option>[];
}

/// The ListTile arguments the checkbox, switch and radio tiles share.
final List<UiParam> _tileParams = <UiParam>[
  p('title', 'Widget|String'),
  p('subtitle', 'Widget|String'),
  p('secondary', 'Widget|Icon', 'The widget opposite the control -- usually an icon.'),
  p('isThreeLine', 'bool', null, 'false'),
  p('dense', 'bool'),
  p('selected', 'bool', null, 'false'),
  e('controlAffinity', ListTileControlAffinity.values),
  p('contentPadding', 'EdgeInsets'),
  p('activeColor', 'Color'),
  p('tileColor', 'Color'),
  p('selectedTileColor', 'Color'),
  p('shape', 'ShapeBorder'),
  p('visualDensity', 'String'),
  p('enabled', 'bool'),
];

class _Tile {
  const _Tile._(
    this.title,
    this.subtitle,
    this.secondary,
    this.isThreeLine,
    this.dense,
    this.selected,
    this.controlAffinity,
    this.contentPadding,
    this.activeColor,
    this.tileColor,
    this.selectedTileColor,
    this.shape,
    this.visualDensity,
    this.enabled,
  );

  factory _Tile.read(UiArgs a) => _Tile._(
    a.label(const ['title']),
    a.label(const ['subtitle']),
    a.iconOrChild(const ['secondary']),
    a.boolean(const ['isThreeLine']) ?? false,
    a.boolean(const ['dense']),
    a.boolean(const ['selected']) ?? false,
    a.enumValue(ListTileControlAffinity.values, const ['controlAffinity']),
    a.edgeInsets(const ['contentPadding']),
    a.color(const ['activeColor']),
    a.color(const ['tileColor']),
    a.color(const ['selectedTileColor']),
    a.shape(const ['shape']),
    a.visualDensity(const ['visualDensity']),
    a.boolean(const ['enabled']),
  );

  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool isThreeLine;
  final bool? dense;
  final bool selected;
  final ListTileControlAffinity? controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final Color? activeColor;
  final Color? tileColor;
  final Color? selectedTileColor;
  final ShapeBorder? shape;
  final VisualDensity? visualDensity;
  final bool? enabled;
}

/// A slider value as a label shows it: no `.0` on a whole number.
String _short(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
