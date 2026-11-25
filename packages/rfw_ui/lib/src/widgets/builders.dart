import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';

/// Material's window size class of [width]: compact under 600, medium under
/// 840, expanded under 1200, large under 1600, then extraLarge.
String breakpointOf(double width) => switch (width) {
  < 600 => 'compact',
  < 840 => 'medium',
  < 1200 => 'expanded',
  < 1600 => 'large',
  _ => 'extraLarge',
};

/// A limit as a remote file can hold it: rfw's values cannot be infinite, so
/// no limit is -1.
double _limit(double value) => value.isFinite ? value : -1;

String _orientation(double width, double height) => width > height ? 'landscape' : 'portrait';

/// Widgets that build their child from what is only known on the device.
final List<UiWidget> builderWidgets = <UiWidget>[
  UiWidget(
    'LayoutBuilder',
    group: UiGroup.builder,
    doc: 'Builds its child from the space its parent gives it: '
        '`LayoutBuilder(builder: (size) => switch size.breakpoint { .compact: Column(...), default: Row(...) })`. '
        '`size` has `maxWidth`, `maxHeight`, `minWidth` and `minHeight` (-1 for a side with no limit, as along a scroll view), '
        '`breakpoint` (Material\'s window class of `maxWidth`: `compact` under 600, `medium` under 840, `expanded` under 1200, '
        '`large` under 1600, then `extraLarge`) and `orientation` (`landscape` when wider than tall, else `portrait`).',
    params: <UiParam>[p('builder', 'Builder')],
    build: (UiArgs a) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => a.builder(<Object>['builder'], <String, Object?>{
        'maxWidth': _limit(c.maxWidth),
        'maxHeight': _limit(c.maxHeight),
        'minWidth': c.minWidth,
        'minHeight': c.minHeight,
        'breakpoint': breakpointOf(c.maxWidth),
        'orientation': _orientation(c.maxWidth, c.maxHeight),
      }),
    ),
    example: 'LayoutBuilder(builder: (size) => switch size.breakpoint { .compact: Text(text: "One column"), default: Text(text: "Two columns") })',
  ),
  UiWidget(
    'ScreenBuilder',
    group: UiGroup.builder,
    doc: 'Builds its child from the screen and the app\'s settings, wherever it sits: '
        '`ScreenBuilder(builder: (screen) => ...)`. `screen` has `width` and `height` (the window\'s), `breakpoint` and '
        '`orientation` (as LayoutBuilder has them), `brightness` (`light` or `dark`: the theme\'s), `platform` '
        '(`android`, `iOS`, `macOS`, `windows`, `linux` or `fuchsia`) and `textScale` (the user\'s text size, 1 by default).',
    params: <UiParam>[p('builder', 'Builder')],
    build: (UiArgs a) {
      final Size size = MediaQuery.sizeOf(a.context);
      final ThemeData theme = Theme.of(a.context);
      return a.builder(<Object>['builder'], <String, Object?>{
        'width': size.width,
        'height': size.height,
        'breakpoint': breakpointOf(size.width),
        'orientation': _orientation(size.width, size.height),
        'brightness': theme.brightness.name,
        'platform': theme.platform.name,
        'textScale': MediaQuery.textScalerOf(a.context).scale(1),
      });
    },
    example: 'ScreenBuilder(builder: (screen) => Text(text: screen.breakpoint))',
  ),
];
