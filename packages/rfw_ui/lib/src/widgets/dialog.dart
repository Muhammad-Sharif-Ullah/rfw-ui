import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';

/// What a dialog is made of. Showing one is an action, not a widget:
///
///     widget ConfirmDelete = AlertDialog(
///       title: "Delete this?",
///       actions: [
///         TextButton(child: "Cancel", onPressed: event "ui.pop" {}),
///         FilledButton(child: "Delete", onPressed: event "ui.pop" { result: true }),
///       ],
///     );
///
///     FilledButton(child: "Delete", onPressed: event "ui.dialog" { widget: "ConfirmDelete", onResult: "deleted" })
final List<UiWidget> dialogWidgets = <UiWidget>[
  UiWidget(
    'AlertDialog',
    group: UiGroup.dialog,
    doc: 'A dialog with a title, a message and actions -- open it with `event "ui.dialog" { widget: "<name>" }` '
        'and close it with `event "ui.pop" { result: ... }`. `adaptive: true` is a Cupertino alert on Apple platforms.',
    params: <UiParam>[
      p('icon', 'Widget|Icon'),
      p('iconColor', 'Color'),
      p('iconPadding', 'EdgeInsets'),
      p('title', 'Widget|String'),
      p('titlePadding', 'EdgeInsets'),
      p('titleTextStyle', 'TextStyle'),
      p('content', 'Widget|String'),
      p('contentPadding', 'EdgeInsets'),
      p('contentTextStyle', 'TextStyle'),
      p('actions', 'List<Widget>'),
      p('actionsPadding', 'EdgeInsets'),
      e('actionsAlignment', MainAxisAlignment.values),
      p('buttonPadding', 'EdgeInsets'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('semanticLabel', 'String'),
      p('insetPadding', 'EdgeInsets'),
      e('clipBehavior', Clip.values),
      p('shape', 'ShapeBorder'),
      p('alignment', 'Alignment'),
      p('scrollable', 'bool', 'Let a long title and content scroll.', 'false'),
      p('adaptive', 'bool', null, 'false'),
    ],
    build: (UiArgs a) {
      final Widget? icon = a.iconOrChild(const ['icon']);
      final Color? iconColor = a.color(const ['iconColor']);
      final EdgeInsetsGeometry? iconPadding = a.edgeInsets(const ['iconPadding']);
      final Widget? title = a.label(const ['title']);
      final EdgeInsetsGeometry? titlePadding = a.edgeInsets(const ['titlePadding']);
      final TextStyle? titleTextStyle = a.textStyle(const ['titleTextStyle']);
      final Widget? content = a.label(const ['content']);
      final EdgeInsetsGeometry? contentPadding = a.edgeInsets(const ['contentPadding']);
      final TextStyle? contentTextStyle = a.textStyle(const ['contentTextStyle']);
      final List<Widget> actions = a.children(const ['actions']);
      final EdgeInsetsGeometry? actionsPadding = a.edgeInsets(const ['actionsPadding']);
      final MainAxisAlignment? actionsAlignment = a.enumValue(MainAxisAlignment.values, const ['actionsAlignment']);
      final EdgeInsetsGeometry? buttonPadding = a.edgeInsets(const ['buttonPadding']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? elevation = a.number(const ['elevation']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final String? semanticLabel = a.string(const ['semanticLabel']);
      final EdgeInsets? insetPadding = a.edgeInsets(const ['insetPadding'])?.resolve(Directionality.maybeOf(a.context));
      final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final AlignmentGeometry? alignment = a.alignment(const ['alignment']);
      final bool scrollable = a.boolean(const ['scrollable']) ?? false;
      if (a.boolean(const ['adaptive']) ?? false) {
        return AlertDialog.adaptive(
          icon: icon,
          iconColor: iconColor,
          iconPadding: iconPadding,
          title: title,
          titlePadding: titlePadding,
          titleTextStyle: titleTextStyle,
          content: content,
          contentPadding: contentPadding,
          contentTextStyle: contentTextStyle,
          actions: actions.isEmpty ? null : actions,
          actionsPadding: actionsPadding,
          actionsAlignment: actionsAlignment,
          buttonPadding: buttonPadding,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          semanticLabel: semanticLabel,
          insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          clipBehavior: clip,
          shape: shape,
          alignment: alignment,
          scrollable: scrollable,
        );
      }
      return AlertDialog(
        icon: icon,
        iconColor: iconColor,
        iconPadding: iconPadding,
        title: title,
        titlePadding: titlePadding,
        titleTextStyle: titleTextStyle,
        content: content,
        contentPadding: contentPadding,
        contentTextStyle: contentTextStyle,
        actions: actions.isEmpty ? null : actions,
        actionsPadding: actionsPadding,
        actionsAlignment: actionsAlignment,
        buttonPadding: buttonPadding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        semanticLabel: semanticLabel,
        insetPadding: insetPadding,
        clipBehavior: clip,
        shape: shape,
        alignment: alignment,
        scrollable: scrollable,
      );
    },
    example: 'AlertDialog(icon: "delete_outline", title: "Delete draft?", content: "This cannot be undone.", '
        'actions: [TextButton(child: "Cancel", onPressed: event "ui.pop" {}), FilledButton(child: "Delete", onPressed: event "ui.pop" { result: true })])',
  ),
  UiWidget(
    'SimpleDialog',
    group: UiGroup.dialog,
    doc: 'A dialog of options. Each SimpleDialogOption can close it with `event "ui.pop" { result: ... }`.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('titlePadding', 'EdgeInsets'),
      p('titleTextStyle', 'TextStyle'),
      p('children', 'List<Widget>'),
      p('contentPadding', 'EdgeInsets'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('semanticLabel', 'String'),
      p('insetPadding', 'EdgeInsets'),
      e('clipBehavior', Clip.values),
      p('shape', 'ShapeBorder'),
      p('alignment', 'Alignment'),
    ],
    build: (UiArgs a) => SimpleDialog(
      title: a.label(const ['title']),
      titlePadding: a.edgeInsets(const ['titlePadding']) ?? const EdgeInsets.fromLTRB(24, 24, 24, 0),
      titleTextStyle: a.textStyle(const ['titleTextStyle']),
      contentPadding: a.edgeInsets(const ['contentPadding']) ?? const EdgeInsets.fromLTRB(0, 12, 0, 16),
      backgroundColor: a.color(const ['backgroundColor']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      semanticLabel: a.string(const ['semanticLabel']),
      insetPadding: a.edgeInsets(const ['insetPadding'])?.resolve(Directionality.maybeOf(a.context)),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']),
      shape: a.shape(const ['shape']),
      alignment: a.alignment(const ['alignment']),
      children: a.children(const ['children']),
    ),
    example: 'SimpleDialog(title: "Sort by", children: [SimpleDialogOption(child: "Newest", onPressed: event "ui.pop" { result: "new" }), '
        'SimpleDialogOption(child: "Oldest", onPressed: event "ui.pop" { result: "old" })])',
  ),
  UiWidget(
    'SimpleDialogOption',
    group: UiGroup.dialog,
    doc: 'One option of a SimpleDialog.',
    params: <UiParam>[p('child', 'Widget|String'), p('onPressed', 'event'), p('padding', 'EdgeInsets')],
    build: (UiArgs a) => SimpleDialogOption(
      onPressed: a.onTap(const ['onPressed']),
      padding: a.edgeInsets(const ['padding'])?.resolve(Directionality.maybeOf(a.context)),
      child: a.label(const ['child']),
    ),
  ),
  UiWidget(
    'Dialog',
    group: UiGroup.dialog,
    doc: 'A blank dialog surface for content of your own. `fullscreen: true` fills the screen.',
    params: <UiParam>[
      p('child', 'Widget'),
      p('fullscreen', 'bool', null, 'false'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('insetPadding', 'EdgeInsets'),
      e('clipBehavior', Clip.values),
      p('shape', 'ShapeBorder'),
      p('alignment', 'Alignment'),
    ],
    build: (UiArgs a) {
      final Widget? child = a.optionalChild(const ['child']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? elevation = a.number(const ['elevation']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final EdgeInsets? insetPadding = a.edgeInsets(const ['insetPadding'])?.resolve(Directionality.maybeOf(a.context));
      final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final AlignmentGeometry? alignment = a.alignment(const ['alignment']);
      if (a.boolean(const ['fullscreen']) ?? false) {
        return Dialog.fullscreen(backgroundColor: backgroundColor, child: child);
      }
      return Dialog(
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        insetPadding: insetPadding,
        clipBehavior: clip,
        shape: shape,
        alignment: alignment,
        child: child,
      );
    },
  ),
];
