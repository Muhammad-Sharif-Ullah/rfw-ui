import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../decode/resolver.dart';
import '../theme/theme_document.dart';
import '../decode/decoder.dart' show UiDecoder;
import '../widgets/args.dart' show encodeValue;
import '../widgets/scope.dart';
import '../widgets/spec.dart';
import 'store.dart';

/// One `ui.*` action: what a remote file fires to have the app do something
/// rfw cannot express -- show a dialog, write a value, pick a date.
@immutable
class UiAction {
  const UiAction(this.name, {required this.doc, required this.params, this.example});

  /// The event name: `ui.dialog`.
  final String name;
  final String doc;
  final List<UiParam> params;
  final String? example;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'doc': doc,
    'params': <Map<String, Object?>>[for (final UiParam p in params) p.toJson()],
    if (example != null) 'example': example,
  };
}

/// The arguments every action that opens something shares.
final List<UiParam> _resultParams = <UiParam>[
  p('key', 'String', 'Write the result into data at this dotted path (`"form.date"`).'),
  p('onResult', 'String', 'Fire this event with `{ value: <result> }` once there is one -- another `ui.*` action, or the app\'s own.'),
];

final List<UiParam> _modalParams = <UiParam>[
  p('widget', 'String', 'The name of a widget declared in this file (or one it imports) to show.'),
  p('args', 'Map', 'Arguments for that widget, which it reads as `args.*`.'),
  ..._resultParams,
];

/// Every action [UiActions] handles, in catalog order.
final List<UiAction> uiActions = <UiAction>[
  UiAction(
    'ui.set',
    doc: 'Writes a value into data. Inputs report `{ value }`, so pointing one\'s handler here binds it: '
        'the widget reading `data.<key>` rebuilds.',
    params: <UiParam>[
      p('key', 'String', 'A dotted path: `"settings.wifi"`, `"items.0.done"`.'),
      p('value', 'value', 'What to write; an input fills it in.'),
    ],
    example: 'Switch(value: data.settings.wifi, onChanged: event "ui.set" { key: "settings.wifi" })',
  ),
  UiAction(
    'ui.toggle',
    doc: 'Flips a true/false value in data.',
    params: <UiParam>[p('key', 'String')],
    example: 'IconButton(icon: "visibility", onPressed: event "ui.toggle" { key: "showPassword" })',
  ),
  UiAction(
    'ui.dialog',
    doc: 'Shows a widget of this file as a Material dialog, usually an AlertDialog. `ui.pop` inside it closes it with a result.',
    params: <UiParam>[
      ..._modalParams,
      p('barrierDismissible', 'bool', 'Tapping outside closes it.', 'true'),
      p('barrierColor', 'Color'),
      p('useRootNavigator', 'bool', 'Cover the whole app rather than the nearest navigator.', 'false'),
    ],
    example: 'FilledButton(child: "Delete", onPressed: event "ui.dialog" { widget: "ConfirmDelete", args: { name: data.file.name }, onResult: "delete" })',
  ),
  UiAction(
    'ui.bottomSheet',
    doc: 'Slides a widget of this file up from the bottom as a modal sheet.',
    params: <UiParam>[
      ..._modalParams,
      p('isScrollControlled', 'bool', 'Let it be taller than half the screen.', 'false'),
      p('showDragHandle', 'bool'),
      p('isDismissible', 'bool', null, 'true'),
      p('enableDrag', 'bool', null, 'true'),
      p('useSafeArea', 'bool', null, 'true'),
      p('backgroundColor', 'Color'),
      p('useRootNavigator', 'bool', null, 'false'),
    ],
    example: 'IconButton(icon: "share", onPressed: event "ui.bottomSheet" { widget: "ShareSheet", showDragHandle: true })',
  ),
  UiAction(
    'ui.cupertinoDialog',
    doc: 'Shows a widget of this file as an iOS alert, usually a CupertinoAlertDialog.',
    params: <UiParam>[..._modalParams, p('barrierDismissible', 'bool', null, 'false'), p('useRootNavigator', 'bool', null, 'false')],
  ),
  UiAction(
    'ui.cupertinoModal',
    doc: 'Slides a widget of this file up as an iOS popup -- a CupertinoActionSheet, or a picker in a CupertinoPopupSurface.',
    params: <UiParam>[..._modalParams, p('barrierDismissible', 'bool', null, 'true'), p('useRootNavigator', 'bool', null, 'false')],
  ),
  UiAction(
    'ui.pop',
    doc: 'Closes the dialog or sheet this is in, handing `result` to whoever opened it.',
    params: <UiParam>[p('result', 'value')],
    example: 'TextButton(child: "OK", onPressed: event "ui.pop" { result: true })',
  ),
  UiAction(
    'ui.snackBar',
    doc: 'Shows a message at the bottom of the screen.',
    params: <UiParam>[
      p('message', 'String'),
      p('actionLabel', 'String'),
      p('onAction', 'String', 'The event the action fires.'),
      p('actionArgs', 'Map', 'Arguments for that event.'),
      p('duration', 'Duration', null, '4000'),
      oneOf('behavior', <String>['fixed', 'floating']),
      p('showCloseIcon', 'bool'),
    ],
    example: 'TextButton(child: "Archive", onPressed: event "ui.snackBar" { message: "Archived", actionLabel: "Undo", onAction: "unarchive" })',
  ),
  UiAction(
    'ui.pickDate',
    doc: 'Shows the Material date picker. The result is `"YYYY-MM-DD"`.',
    params: <UiParam>[
      p('initial', 'Date'),
      p('first', 'Date', null, '1900-01-01'),
      p('last', 'Date', null, '2100-12-31'),
      oneOf('entryMode', <String>['calendar', 'input', 'calendarOnly', 'inputOnly'], null, 'calendar'),
      p('helpText', 'String'),
      ..._resultParams,
    ],
    example: 'OutlinedButton(child: "Birthday", icon: "cake", onPressed: event "ui.pickDate" { initial: data.form.birthday, key: "form.birthday" })',
  ),
  UiAction(
    'ui.pickDateRange',
    doc: 'Shows the Material date range picker. The result is `{ start, end }`.',
    params: <UiParam>[
      p('start', 'Date'),
      p('end', 'Date'),
      p('first', 'Date', null, '1900-01-01'),
      p('last', 'Date', null, '2100-12-31'),
      p('helpText', 'String'),
      ..._resultParams,
    ],
  ),
  UiAction(
    'ui.pickTime',
    doc: 'Shows the Material time picker. The result is `"HH:mm"`.',
    params: <UiParam>[
      p('initial', 'String', '`"HH:mm"`.'),
      oneOf('entryMode', <String>['dial', 'input', 'dialOnly', 'inputOnly'], null, 'dial'),
      p('helpText', 'String'),
      ..._resultParams,
    ],
  ),
  UiAction(
    'ui.themeMode',
    doc: 'Switches between light and dark, when the app has a UiThemeController.',
    params: <UiParam>[oneOf('mode', <String>['light', 'dark', 'system', 'toggle'], null, 'toggle')],
    example: 'IconButton(icon: "dark_mode", onPressed: event "ui.themeMode" { mode: "toggle" })',
  ),
  UiAction(
    'ui.focus',
    doc: 'Moves the keyboard focus to the widget with this key: a text field, or the first focusable widget '
        'under it. Point a field\'s `onSubmitted` here to choose where its "next" goes.',
    params: <UiParam>[p('key', 'String', 'The `key` of the widget to focus.')],
    example: 'TextField(key: "email", textInputAction: "next", onSubmitted: event "ui.focus" { key: "password" })',
  ),
  UiAction(
    'ui.unfocus',
    doc: 'Takes the focus from whatever has it, which also closes the keyboard.',
    params: <UiParam>[],
    example: 'TextField(textInputAction: "done", onSubmitted: event "ui.unfocus" { })',
  ),
  UiAction(
    'ui.focusNext',
    doc: 'Moves the focus to the next widget in traversal order, as the Tab key does. A text field with '
        '`textInputAction: "next"` does this by itself.',
    params: <UiParam>[],
  ),
  UiAction(
    'ui.focusPrevious',
    doc: 'Moves the focus to the previous widget in traversal order, as Shift-Tab does.',
    params: <UiParam>[],
  ),
  UiAction(
    'ui.scrollTo',
    doc: 'Scrolls every scroll view around the widget with this key until it is in view.',
    params: <UiParam>[
      p('key', 'String', 'The `key` of the widget to bring into view.'),
      p('alignment', 'double', '0 puts it at the leading edge, 1 at the trailing edge, 0.5 in the middle.', '0'),
      p('duration', 'Duration', null, '300'),
      p('curve', 'Curve', null, 'easeInOut'),
    ],
    example: 'TextButton(child: "Jump to the terms", onPressed: event "ui.scrollTo" { key: "terms" })',
  ),
  UiAction(
    'ui.copy',
    doc: 'Copies text to the clipboard.',
    params: <UiParam>[p('text', 'String'), p('message', 'String', 'A snack bar to confirm it, if given.')],
  ),
  UiAction(
    'ui.haptic',
    doc: 'A little buzz under the finger. `selection` is the tick a picker makes going past a value; '
        'light, medium and heavy are impacts; `vibrate` is the plain one. Silent where the platform has no '
        'haptics, and on iOS only where the system allows it.',
    params: <UiParam>[
      oneOf('type', <String>['light', 'medium', 'heavy', 'selection', 'vibrate'], null, 'light'),
    ],
    example: 'GestureDetector(onLongPress: event "ui.haptic" { type: "medium" }, child: Card())',
  ),
];

/// Signature of an app's own event handler -- the same as rfw's.
typedef UiEventHandler = void Function(String name, DynamicMap arguments);

/// Carries out `ui.*` events and passes every other event to the app.
///
/// One per remote tree. [library] is where `widget:` names are looked up --
/// the library of the remote widget at the root -- and modals share it, the
/// [runtime] and the [store], so a dialog sees the same `data.*` its opener
/// does and can open a dialog of its own.
class UiActions {
  UiActions({required this.runtime, required this.library, required this.store, this.onEvent});

  final Runtime runtime;
  final LibraryName library;
  final UiStore store;

  /// Events that are not `ui.*`, and `ui.*` ones this version does not know.
  final UiEventHandler? onEvent;

  /// Prepares a modal's content and returns its builder. [UiRemoteWidget]
  /// sets this: it registers a library that calls the named widget with the
  /// given args, which has to happen here, while handling the event, and not
  /// in the builder -- registering a library rebuilds every remote widget, and
  /// a route's builder runs mid-build.
  WidgetBuilder Function(String widget, DynamicMap args, int depth, UiScopeData? opener)? modalBuilder;

  /// Handles [name], fired from a remote widget built in [context]; [depth] is
  /// how many modals deep that widget is, and [scope] is its tree's, where
  /// `ui.focus` and `ui.scrollTo` look keys up.
  void dispatch(BuildContext context, String name, DynamicMap args, {int depth = 0, UiScopeData? scope}) {
    switch (name) {
      case 'ui.set':
        final String? key = _string(args['key']);
        if (key != null) {
          store.set(key, args['value']);
        }
      case 'ui.toggle':
        final String? key = _string(args['key']);
        if (key != null) {
          store.set(key, store.get(key) != true);
        }
      case 'ui.dialog':
        _modal(context, args, depth, scope, (WidgetBuilder builder) => showDialog<Object?>(
          context: context,
          builder: builder,
          barrierDismissible: _bool(args['barrierDismissible']) ?? true,
          barrierColor: _color(context, args['barrierColor']),
          useRootNavigator: _bool(args['useRootNavigator']) ?? false,
        ));
      case 'ui.bottomSheet':
        _modal(context, args, depth, scope, (WidgetBuilder builder) => showModalBottomSheet<Object?>(
          context: context,
          builder: builder,
          isScrollControlled: _bool(args['isScrollControlled']) ?? false,
          showDragHandle: _bool(args['showDragHandle']),
          isDismissible: _bool(args['isDismissible']) ?? true,
          enableDrag: _bool(args['enableDrag']) ?? true,
          useSafeArea: _bool(args['useSafeArea']) ?? true,
          backgroundColor: _color(context, args['backgroundColor']),
          useRootNavigator: _bool(args['useRootNavigator']) ?? false,
        ));
      case 'ui.cupertinoDialog':
        _modal(context, args, depth, scope, (WidgetBuilder builder) => showCupertinoDialog<Object?>(
          context: context,
          builder: builder,
          barrierDismissible: _bool(args['barrierDismissible']) ?? false,
          useRootNavigator: _bool(args['useRootNavigator']) ?? false,
        ));
      case 'ui.cupertinoModal':
        _modal(context, args, depth, scope, (WidgetBuilder builder) => showCupertinoModalPopup<Object?>(
          context: context,
          builder: builder,
          barrierDismissible: _bool(args['barrierDismissible']) ?? true,
          useRootNavigator: _bool(args['useRootNavigator']) ?? false,
        ));
      case 'ui.pop':
        Navigator.maybeOf(context)?.maybePop(args['result']);
      case 'ui.snackBar':
        _snackBar(context, args, depth, scope);
      case 'ui.pickDate':
        final DateTime first = _date(args['first']) ?? DateTime(1900);
        final DateTime last = _later(_date(args['last']) ?? DateTime(2100, 12, 31), first);
        final DateTime? initial = _date(args['initial']);
        _result(context, args, depth, scope, showDatePicker(
          context: context,
          firstDate: first,
          lastDate: last,
          initialDate: initial == null || initial.isBefore(first) || initial.isAfter(last) ? null : initial,
          initialEntryMode: switch (args['entryMode']) {
            'input' => DatePickerEntryMode.input,
            'calendarOnly' => DatePickerEntryMode.calendarOnly,
            'inputOnly' => DatePickerEntryMode.inputOnly,
            _ => DatePickerEntryMode.calendar,
          },
          helpText: _string(args['helpText']),
          useRootNavigator: false,
        ));
      case 'ui.pickDateRange':
        final DateTime first = _date(args['first']) ?? DateTime(1900);
        final DateTime last = _later(_date(args['last']) ?? DateTime(2100, 12, 31), first);
        final DateTime? start = _date(args['start']);
        final DateTime? end = _date(args['end']);
        final bool fits = start != null && end != null && !end.isBefore(start) && !start.isBefore(first) && !end.isAfter(last);
        _result(context, args, depth, scope, showDateRangePicker(
          context: context,
          firstDate: first,
          lastDate: last,
          initialDateRange: fits ? DateTimeRange(start: start, end: end) : null,
          helpText: _string(args['helpText']),
          useRootNavigator: false,
        ));
      case 'ui.pickTime':
        _result(context, args, depth, scope, showTimePicker(
          context: context,
          initialTime: _time(args['initial']) ?? TimeOfDay.now(),
          initialEntryMode: switch (args['entryMode']) {
            'input' => TimePickerEntryMode.input,
            'dialOnly' => TimePickerEntryMode.dialOnly,
            'inputOnly' => TimePickerEntryMode.inputOnly,
            _ => TimePickerEntryMode.dial,
          },
          helpText: _string(args['helpText']),
          useRootNavigator: false,
        ));
      case 'ui.themeMode':
        final UiThemeController? theme = UiTheme.maybeOf(context);
        if (theme == null) {
          onEvent?.call(name, args);
          return;
        }
        switch (args['mode']) {
          case 'light':
            theme.mode = ThemeMode.light;
          case 'dark':
            theme.mode = ThemeMode.dark;
          case 'system':
            theme.mode = ThemeMode.system;
          default:
            theme.toggle(Theme.of(context).brightness);
        }
      case 'ui.focus':
        final String? key = _string(args['key']);
        if (key != null) {
          scope?.focusNode(key)?.requestFocus();
        }
      case 'ui.unfocus':
        FocusManager.instance.primaryFocus?.unfocus();
      case 'ui.focusNext':
        FocusManager.instance.primaryFocus?.nextFocus();
      case 'ui.focusPrevious':
        FocusManager.instance.primaryFocus?.previousFocus();
      case 'ui.scrollTo':
        final String? key = _string(args['key']);
        final BuildContext? target = key == null ? null : scope?.find(key);
        if (target == null) {
          return;
        }
        final int? ms = _int(args['duration']);
        Scrollable.ensureVisible(
          target,
          alignment: switch (args['alignment']) {
            final num v => v.toDouble().clamp(0, 1),
            _ => 0,
          },
          duration: Duration(milliseconds: ms ?? 300),
          curve: UiDecoder.curveNamed(_string(args['curve'])) ?? Curves.easeInOut,
        );
      case 'ui.copy':
        final String? text = _string(args['text']);
        if (text == null) {
          return;
        }
        Clipboard.setData(ClipboardData(text: text));
        final String? message = _string(args['message']);
        if (message != null) {
          _snackBar(context, <String, Object?>{'message': message}, depth, scope);
        }
      case 'ui.haptic':
        switch (args['type']) {
          case 'medium':
            HapticFeedback.mediumImpact();
          case 'heavy':
            HapticFeedback.heavyImpact();
          case 'selection':
            HapticFeedback.selectionClick();
          case 'vibrate':
            HapticFeedback.vibrate();
          default:
            HapticFeedback.lightImpact();
        }
      default:
        onEvent?.call(name, args);
    }
  }

  /// Opens [args]' widget with [show], then routes the result.
  void _modal(BuildContext context, DynamicMap args, int depth, UiScopeData? scope, Future<Object?> Function(WidgetBuilder) show) {
    final String? widget = _string(args['widget']);
    final WidgetBuilder Function(String, DynamicMap, int, UiScopeData?)? prepare = modalBuilder;
    if (widget == null || prepare == null) {
      return;
    }
    final Object? given = args['args'];
    final DynamicMap widgetArgs = given is Map<String, Object?> ? given : const <String, Object?>{};
    final WidgetBuilder content = prepare(widget, widgetArgs, depth, scope);
    // A modal's route is built under the navigator, above whatever Theme the
    // opener sat in. Material's dialog and sheet carry those themes across;
    // the Cupertino routes do not, and would show in the app's theme. So the
    // opener's themes are carried across here, for all of them alike.
    final NavigatorState? navigator = Navigator.maybeOf(context, rootNavigator: _bool(args['useRootNavigator']) ?? false);
    final CapturedThemes? themes = navigator == null ? null : InheritedTheme.capture(from: context, to: navigator.context);
    _result(
      context,
      args,
      depth,
      scope,
      show((BuildContext inner) => themes == null ? content(inner) : themes.wrap(content(inner))),
    );
  }

  /// Writes a modal's or picker's result to `key` and fires `onResult`. A
  /// dismissed modal -- a null result -- does neither.
  void _result(BuildContext context, DynamicMap args, int depth, UiScopeData? scope, Future<Object?> pending) {
    final String? key = _string(args['key']);
    final String? onResult = _string(args['onResult']);
    pending.then((Object? value) {
      if (value == null) {
        return;
      }
      final Object? encoded = encodeValue(value);
      if (key != null) {
        store.set(key, encoded);
      }
      if (onResult != null && context.mounted) {
        dispatch(context, onResult, <String, Object?>{'value': encoded}, depth: depth, scope: scope);
      }
    });
  }

  void _snackBar(BuildContext context, DynamicMap args, int depth, UiScopeData? scope) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    final String? message = _string(args['message']);
    if (messenger == null || message == null) {
      return;
    }
    final String? label = _string(args['actionLabel']);
    final String? onAction = _string(args['onAction']);
    final Object? actionArgs = args['actionArgs'];
    final int? ms = _int(args['duration']);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: ms == null ? const Duration(milliseconds: 4000) : Duration(milliseconds: ms),
          behavior: switch (args['behavior']) {
            'floating' => SnackBarBehavior.floating,
            'fixed' => SnackBarBehavior.fixed,
            _ => null,
          },
          showCloseIcon: _bool(args['showCloseIcon']),
          action: label == null
              ? null
              : SnackBarAction(
                  label: label,
                  onPressed: () {
                    if (onAction != null && context.mounted) {
                      dispatch(
                        context,
                        onAction,
                        actionArgs is Map<String, Object?> ? actionArgs : const <String, Object?>{},
                        depth: depth,
                        scope: scope,
                      );
                    }
                  },
                ),
        ),
      );
  }

  static String? _string(Object? v) => v is String ? v : null;

  static bool? _bool(Object? v) => v is bool ? v : null;

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final double d => d.round(),
    _ => null,
  };

  static Color? _color(BuildContext context, Object? v) => switch (v) {
    final int argb => Color(argb),
    final String token => UiResolver.of(context).color(token),
    _ => null,
  };

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static DateTime _later(DateTime a, DateTime b) => a.isBefore(b) ? b : a;

  static TimeOfDay? _time(Object? v) {
    if (v is! String) {
      return null;
    }
    final List<String> parts = v.split(':');
    if (parts.length < 2) {
      return null;
    }
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}
