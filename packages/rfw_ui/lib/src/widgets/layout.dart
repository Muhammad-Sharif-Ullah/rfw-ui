import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit, ScrollCacheExtent;
import 'package:rfw/rfw.dart' show AnimationDefaults;

import 'args.dart';
import 'state.dart';
import 'spec.dart';

/// Layout, painting and scrolling: rfw's core widgets with every argument
/// their Flutter namesakes take and theme tokens throughout, and the ones rfw
/// leaves out. The widgets rfw animates implicitly (Align, Container, Opacity,
/// Padding, Positioned, Rotation, Scale, DefaultTextStyle) still do.
final List<UiWidget> layoutWidgets = <UiWidget>[
  UiWidget(
    'Align',
    group: UiGroup.layout,
    doc: 'Positions its child within itself. Changes animate, as rfw\'s Align does.',
    params: <UiParam>[
      p('alignment', 'Alignment', null, 'center'),
      p('widthFactor', 'double'),
      p('heightFactor', 'double'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedAlign(
      alignment: a.alignment(const ['alignment']) ?? Alignment.center,
      widthFactor: a.number(const ['widthFactor']),
      heightFactor: a.number(const ['heightFactor']),
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.optionalChild(const ['child']),
    ),
    example: 'Align(alignment: "bottomRight", child: Text(text: "corner"))',
  ),
  UiWidget(
    'AnimationDefaults',
    group: UiGroup.layout,
    doc: 'Sets the duration and curve every implicitly animated widget below it uses.',
    params: <UiParam>[p('duration', 'Duration'), p('curve', 'Curve'), p('child', 'Widget')],
    build: (UiArgs a) => AnimationDefaults(
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'AspectRatio',
    group: UiGroup.layout,
    doc: 'Sizes its child to a width:height ratio.',
    params: <UiParam>[p('aspectRatio', 'double', 'Width divided by height.', '1'), p('child', 'Widget')],
    build: (UiArgs a) => AspectRatio(aspectRatio: a.number(const ['aspectRatio']) ?? 1, child: a.optionalChild(const ['child'])),
    example: 'AspectRatio(aspectRatio: 1.777, child: ColoredBox(color: "primaryContainer"))',
  ),
  UiWidget(
    'Center',
    group: UiGroup.layout,
    doc: 'Centres its child.',
    params: <UiParam>[p('widthFactor', 'double'), p('heightFactor', 'double'), p('child', 'Widget')],
    build: (UiArgs a) => Center(
      widthFactor: a.number(const ['widthFactor']),
      heightFactor: a.number(const ['heightFactor']),
      child: a.optionalChild(const ['child']),
    ),
    example: 'Center(child: Text(text: "centred"))',
  ),
  UiWidget(
    'ClipOval',
    group: UiGroup.layout,
    doc: 'Clips its child to an oval -- a circle when the child is square.',
    params: <UiParam>[e('clipBehavior', Clip.values, null, 'antiAlias'), p('child', 'Widget')],
    build: (UiArgs a) => ClipOval(
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.antiAlias,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'ClipRect',
    group: UiGroup.layout,
    doc: 'Clips its child to its own bounds.',
    params: <UiParam>[e('clipBehavior', Clip.values, null, 'hardEdge'), p('child', 'Widget')],
    build: (UiArgs a) => ClipRect(
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'ClipRRect',
    group: UiGroup.layout,
    doc: 'Clips its child to a rounded rectangle.',
    params: <UiParam>[
      p('borderRadius', 'BorderRadius', null, '0'),
      e('clipBehavior', Clip.values, null, 'antiAlias'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => ClipRRect(
      borderRadius: a.borderRadius(const ['borderRadius']) ?? BorderRadius.zero,
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.antiAlias,
      child: a.optionalChild(const ['child']),
    ),
    example: 'ClipRRect(borderRadius: "lg", child: ColoredBox(color: "tertiaryContainer", child: SizedBox(width: 80, height: 80)))',
  ),
  UiWidget(
    'ColoredBox',
    group: UiGroup.layout,
    doc: 'Paints a colour behind its child.',
    params: <UiParam>[p('color', 'Color', null, 'transparent'), p('child', 'Widget')],
    build: (UiArgs a) => ColoredBox(
      color: a.color(const ['color']) ?? const Color(0x00000000),
      child: a.optionalChild(const ['child']),
    ),
    example: 'ColoredBox(color: "primaryContainer", child: Padding(padding: "md", child: Text(text: "tinted")))',
  ),
  _flex('Column', Axis.vertical),
  _flex('Row', Axis.horizontal),
  UiWidget(
    'ConstrainedBox',
    group: UiGroup.layout,
    doc: 'Imposes size limits on its child.',
    params: <UiParam>[p('constraints', 'BoxConstraints'), p('child', 'Widget')],
    build: (UiArgs a) => ConstrainedBox(
      constraints: a.boxConstraints(const ['constraints']) ?? const BoxConstraints(),
      child: a.optionalChild(const ['child']),
    ),
    example: 'ConstrainedBox(constraints: { maxWidth: 200 }, child: Text(text: "never wider than 200"))',
  ),
  UiWidget(
    'Container',
    group: UiGroup.layout,
    doc: 'Padding, margin, size, colour and decoration in one. Changes animate, as rfw\'s Container does.',
    params: <UiParam>[
      p('alignment', 'Alignment'),
      p('padding', 'EdgeInsets'),
      p('color', 'Color', 'Shorthand for a decoration that is only a colour; give one or the other.'),
      p('decoration', 'Decoration'),
      p('foregroundDecoration', 'Decoration'),
      p('width', 'Spacing'),
      p('height', 'Spacing'),
      p('constraints', 'BoxConstraints'),
      p('margin', 'EdgeInsets'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final Decoration? decoration = a.decoration(const ['decoration']);
      final Color? color = a.color(const ['color']);
      final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none;
      return AnimatedContainer(
        alignment: a.alignment(const ['alignment']),
        padding: a.edgeInsets(const ['padding']),
        // Flutter asserts on both; the decoration is the more specific ask.
        color: decoration == null ? color : null,
        decoration: decoration,
        foregroundDecoration: a.decoration(const ['foregroundDecoration']),
        width: a.spacing(const ['width']),
        height: a.spacing(const ['height']),
        constraints: a.boxConstraints(const ['constraints']),
        margin: a.edgeInsets(const ['margin']),
        // Flutter asserts a clip has a decoration to clip to.
        clipBehavior: decoration == null ? Clip.none : clip,
        duration: a.animDuration(const ['duration']),
        curve: a.animCurve(const ['curve']),
        onEnd: a.onTap(const ['onEnd']),
        child: a.optionalChild(const ['child']),
      );
    },
    example: 'Container(padding: "md", margin: { vertical: "sm" }, '
        'decoration: { color: "surfaceContainerHigh", borderRadius: "lg", border: { color: "outlineVariant" } }, '
        'child: Text(text: "A card-ish box", style: "bodyLarge"))',
  ),
  UiWidget(
    'DecoratedBox',
    group: UiGroup.layout,
    doc: 'Paints a decoration behind (or in front of) its child.',
    params: <UiParam>[
      p('decoration', 'Decoration'),
      e('position', DecorationPosition.values, null, 'background'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => DecoratedBox(
      decoration: a.decoration(const ['decoration']) ?? const BoxDecoration(),
      position: a.enumValue(DecorationPosition.values, const ['position']) ?? DecorationPosition.background,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'Directionality',
    group: UiGroup.layout,
    doc: 'Sets the text direction for everything below it.',
    params: <UiParam>[e('textDirection', TextDirection.values, null, 'ltr'), p('child', 'Widget')],
    build: (UiArgs a) => Directionality(
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']) ?? TextDirection.ltr,
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'Expanded',
    group: UiGroup.layout,
    doc: 'Fills the free space of a Row or Column, shared by flex.',
    params: <UiParam>[p('flex', 'int', null, '1'), p('child', 'Widget')],
    build: (UiArgs a) => Expanded(flex: a.integer(const ['flex']) ?? 1, child: a.child(const ['child'])),
    example: 'Row(children: [Expanded(child: Text(text: "grows")), Text(text: "fixed")])',
  ),
  UiWidget(
    'FittedBox',
    group: UiGroup.layout,
    doc: 'Scales its child to fit.',
    params: <UiParam>[
      e('fit', BoxFit.values, null, 'contain'),
      p('alignment', 'Alignment', null, 'center'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => FittedBox(
      fit: a.enumValue(BoxFit.values, const ['fit']) ?? BoxFit.contain,
      alignment: a.alignment(const ['alignment']) ?? Alignment.center,
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'Flexible',
    group: UiGroup.layout,
    doc: 'A Row or Column child that may take free space, up to its share.',
    params: <UiParam>[p('flex', 'int', null, '1'), e('fit', FlexFit.values, null, 'loose'), p('child', 'Widget')],
    build: (UiArgs a) => Flexible(
      flex: a.integer(const ['flex']) ?? 1,
      fit: a.enumValue(FlexFit.values, const ['fit']) ?? FlexFit.loose,
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'FractionallySizedBox',
    group: UiGroup.layout,
    doc: 'Sizes its child to a fraction of the space available.',
    params: <UiParam>[
      p('alignment', 'Alignment', null, 'center'),
      p('widthFactor', 'double', '0 to 1 of the available width.'),
      p('heightFactor', 'double', '0 to 1 of the available height.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => FractionallySizedBox(
      alignment: a.alignment(const ['alignment']) ?? Alignment.center,
      widthFactor: a.number(const ['widthFactor']),
      heightFactor: a.number(const ['heightFactor']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'GestureDetector',
    group: UiGroup.layout,
    doc: 'Taps, double taps and long presses on its child, without ink. For ink, use InkWell.',
    params: <UiParam>[
      p('onTap', 'event'),
      p('onTapDown', 'event'),
      p('onTapUp', 'event'),
      p('onTapCancel', 'event'),
      p('onDoubleTap', 'event'),
      p('onLongPress', 'event'),
      e('behavior', HitTestBehavior.values, 'Whether empty space inside it receives taps.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final VoidCallback? down = a.onTap(const ['onTapDown']);
      final VoidCallback? up = a.onTap(const ['onTapUp']);
      return GestureDetector(
        onTap: a.onTap(const ['onTap']),
        onTapDown: down == null ? null : (_) => down(),
        onTapUp: up == null ? null : (_) => up(),
        onTapCancel: a.onTap(const ['onTapCancel']),
        onDoubleTap: a.onTap(const ['onDoubleTap']),
        onLongPress: a.onTap(const ['onLongPress']),
        behavior: a.enumValue(HitTestBehavior.values, const ['behavior']),
        child: a.optionalChild(const ['child']),
      );
    },
  ),
  UiWidget(
    'GridView',
    group: UiGroup.layout,
    doc: 'A scrolling grid of children.',
    params: <UiParam>[..._gridViewParams, p('children', 'List<Widget>')],
    build: (UiArgs a) => _gridView(a, a.lazyChildren(const ['children'])),
    example: 'GridView(shrinkWrap: true, gridDelegate: { crossAxisCount: 3, mainAxisSpacing: "sm", crossAxisSpacing: "sm" }, '
        'children: [ColoredBox(color: "primary"), ColoredBox(color: "secondary"), ColoredBox(color: "tertiary")])',
  ),
  UiWidget(
    'GridView.builder',
    group: UiGroup.layout,
    needsUiRuntime: true,
    doc: 'A scrolling grid whose cells `itemBuilder` builds from `items`, each as it scrolls into view: '
        '`GridView.builder(items: data.photos, itemBuilder: (p) => Image(image: p.url))`. Needs UiRuntime.',
    params: <UiParam>[..._gridViewParams, ...itemBuilderParams()],
    build: (UiArgs a) {
      final UiItems? cells = a.items();
      if (cells == null) {
        return uiNeedsUiRuntime('GridView.builder', 'GridView(children: [...for m in items: ...])');
      }
      return _gridView(a, cells);
    },
    example: 'GridView.builder(shrinkWrap: true, gridDelegate: { crossAxisCount: 3, mainAxisSpacing: "sm", crossAxisSpacing: "sm" }, '
        'items: [.primary, .secondary, .tertiary], itemBuilder: (c) => ColoredBox(color: c))',
  ),
  UiWidget(
    'Icon',
    group: UiGroup.text,
    doc: 'An icon by name: `Icon(icon: "home")`, `Icon(icon: "cupertino.heart_fill")`. '
        'Size and colour default to the IconTheme in scope.',
    params: <UiParam>[
      p('icon', 'IconData'),
      p('size', 'double'),
      p('fill', 'double', 'Material Symbols fill, 0 to 1.'),
      p('weight', 'double', 'Material Symbols stroke weight.'),
      p('grade', 'double'),
      p('opticalSize', 'double'),
      p('color', 'Color'),
      p('shadows', 'List<BoxShadow>'),
      p('semanticLabel', 'String'),
      e('textDirection', TextDirection.values),
      p('applyTextScaling', 'bool'),
    ],
    build: (UiArgs a) => Icon(
      a.icon(const ['icon']),
      size: a.number(const ['size']),
      fill: a.number(const ['fill']),
      weight: a.number(const ['weight']),
      grade: a.number(const ['grade']),
      opticalSize: a.number(const ['opticalSize']),
      color: a.color(const ['color']),
      shadows: a.boxShadows(const ['shadows']),
      semanticLabel: a.string(const ['semanticLabel']),
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      applyTextScaling: a.boolean(const ['applyTextScaling']),
    ),
    example: 'Icon(icon: "favorite", color: "error", size: 32)',
  ),
  UiWidget(
    'IconTheme',
    group: UiGroup.text,
    doc: 'Sets the colour, size and opacity of every Icon below it.',
    params: <UiParam>[
      p('color', 'Color'),
      p('size', 'double'),
      p('opacity', 'double'),
      p('fill', 'double'),
      p('weight', 'double'),
      p('shadows', 'List<BoxShadow>'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => IconTheme.merge(
      data: IconThemeData(
        color: a.color(const ['color']),
        size: a.number(const ['size']),
        opacity: a.number(const ['opacity']),
        fill: a.number(const ['fill']),
        weight: a.number(const ['weight']),
        shadows: a.boxShadows(const ['shadows']),
      ),
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'Image',
    group: UiGroup.layout,
    doc: 'An image from a URL or an asset. '
        'Given a `width` and a `height` it decodes at that size times the device pixel ratio and no larger, '
        'so a photograph in a small box costs what the box costs rather than what the photograph does; '
        '`cacheWidth` and `cacheHeight` say it exactly. '
        'A picture that was not already decoded fades in over `fadeDuration`, behind it `placeholder`, '
        'and `error` stands in when it never arrives.',
    params: <UiParam>[
      p('source', 'Image'),
      p('width', 'double'),
      p('height', 'double'),
      p('cacheWidth', 'int', 'Decode at this many pixels across, whatever the box is. Written down, it is taken as it is.'),
      p('cacheHeight', 'int', 'Decode at this many pixels down, whatever the box is.'),
      p('placeholder', 'Widget', 'Shown until the picture arrives.'),
      p('error', 'Widget', 'Shown instead when it never does.'),
      p('fadeDuration', 'Duration', 'How long a picture that was not already decoded takes to fade in.', '200ms'),
      p('color', 'Color', 'Blended over the image with colorBlendMode.'),
      e('colorBlendMode', BlendMode.values),
      e('fit', BoxFit.values),
      p('alignment', 'Alignment', null, 'center'),
      e('repeat', ImageRepeat.values, null, 'noRepeat'),
      p('semanticLabel', 'String'),
      p('excludeFromSemantics', 'bool', null, 'false'),
      p('matchTextDirection', 'bool', null, 'false'),
      p('gaplessPlayback', 'bool', null, 'false'),
      e('filterQuality', FilterQuality.values, null, 'medium'),
      p('opacity', 'double'),
    ],
    build: (UiArgs a) {
      final double? width = a.number(const ['width']);
      final double? height = a.number(const ['height']);
      final int? cacheWidth = a.integer(const ['cacheWidth']);
      final int? cacheHeight = a.integer(const ['cacheHeight']);
      // Written down, the cache size is taken as it is and the box is not
      // consulted at all; otherwise the box, in device pixels, is the cap.
      final bool written = cacheWidth != null || cacheHeight != null;
      final double ratio = MediaQuery.devicePixelRatioOf(a.context);
      final ImageProvider? image = a.image(
        const ['source'],
        cacheWidth: written ? cacheWidth : (width == null ? null : (width * ratio).round()),
        cacheHeight: written ? cacheHeight : (height == null ? null : (height * ratio).round()),
      );
      final Widget? placeholder = a.optionalChild(const ['placeholder']);
      final Widget? failed = a.optionalChild(const ['error']);
      final Duration fade = a.duration(const ['fadeDuration']) ?? const Duration(milliseconds: 200);
      final Color? color = a.color(const ['color']);
      final BlendMode? blendMode = a.enumValue(BlendMode.values, const ['colorBlendMode']);
      final BoxFit? fit = a.enumValue(BoxFit.values, const ['fit']);
      final AlignmentGeometry alignment = a.alignment(const ['alignment']) ?? Alignment.center;
      final ImageRepeat repeat = a.enumValue(ImageRepeat.values, const ['repeat']) ?? ImageRepeat.noRepeat;
      final String? semanticLabel = a.string(const ['semanticLabel']);
      final bool excludeFromSemantics = a.boolean(const ['excludeFromSemantics']) ?? false;
      final bool matchTextDirection = a.boolean(const ['matchTextDirection']) ?? false;
      final bool gaplessPlayback = a.boolean(const ['gaplessPlayback']) ?? false;
      final FilterQuality filterQuality = a.enumValue(FilterQuality.values, const ['filterQuality']) ?? FilterQuality.medium;
      final double? opacity = a.number(const ['opacity']);
      if (image == null) {
        return SizedBox(width: width, height: height);
      }
      return Image(
        image: image,
        width: width,
        height: height,
        color: color,
        colorBlendMode: blendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        opacity: opacity == null ? null : AlwaysStoppedAnimation<double>(opacity),
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          // Already in the cache: no fade, no placeholder, nothing between
          // the person and the picture.
          if (wasSynchronouslyLoaded) {
            return child;
          }
          final Widget arriving = AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: fade,
            curve: Curves.easeOut,
            child: child,
          );
          if (placeholder == null) {
            return arriving;
          }
          return Stack(
            fit: StackFit.passthrough,
            children: <Widget>[if (frame == null) placeholder, arriving],
          );
        },
        // A broken URL is a remote-data problem, not a crash: show what the
        // file asked for, or keep the space, as this always did.
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            failed ?? SizedBox(width: width, height: height),
      );
    },
  ),
  UiWidget(
    'IntrinsicHeight',
    group: UiGroup.layout,
    doc: 'Sizes its child to the child\'s natural height. Expensive; use sparingly.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => IntrinsicHeight(child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'IntrinsicWidth',
    group: UiGroup.layout,
    doc: 'Sizes its child to the child\'s natural width. Expensive; use sparingly.',
    params: <UiParam>[p('stepWidth', 'double'), p('stepHeight', 'double'), p('child', 'Widget')],
    build: (UiArgs a) => IntrinsicWidth(
      stepWidth: a.number(const ['stepWidth']),
      stepHeight: a.number(const ['stepHeight']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'LimitedBox',
    group: UiGroup.layout,
    doc: 'Limits its child\'s size only where the parent leaves it unbounded.',
    params: <UiParam>[p('maxWidth', 'double'), p('maxHeight', 'double'), p('child', 'Widget')],
    build: (UiArgs a) => LimitedBox(
      maxWidth: a.number(const ['maxWidth']) ?? double.infinity,
      maxHeight: a.number(const ['maxHeight']) ?? double.infinity,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'ListBody',
    group: UiGroup.layout,
    doc: 'Lays children out one after another along an axis, without scrolling.',
    params: <UiParam>[e('mainAxis', Axis.values, null, 'vertical'), p('reverse', 'bool', null, 'false'), p('children', 'List<Widget>')],
    build: (UiArgs a) => ListBody(
      mainAxis: a.enumValue(Axis.values, const ['mainAxis']) ?? Axis.vertical,
      reverse: a.boolean(const ['reverse']) ?? false,
      children: a.children(const ['children']),
    ),
  ),
  UiWidget(
    'ListView',
    group: UiGroup.layout,
    doc: 'A scrolling list. Its children are built as they scroll into view -- a `...for` row that is never '
        'scrolled to is never built -- so a list of thousands costs what its visible rows cost. `separator` puts a '
        'widget between every two children, as ListView.separated does. `onEndReached` fires when the last row is '
        'built (so at once for a list shorter than the screen), then again only once the list has a different length: '
        'the place to load the next page.',
    params: <UiParam>[..._listViewParams(itemExtent: true), p('separator', 'Widget'), p('onEndReached', 'event'), p('children', 'List<Widget>')],
    build: (UiArgs a) {
      final Widget? separator = a.optionalChild(const ['separator']);
      return _listView(
        a,
        a.lazyChildren(const ['children']),
        separator: separator == null ? null : (BuildContext context, int index) => separator,
        itemExtent: true,
      );
    },
    example: 'ListView(shrinkWrap: true, separator: Divider(height: 1), children: [ListTile(title: "One"), ListTile(title: "Two")])',
  ),
  UiWidget(
    'ListView.builder',
    group: UiGroup.layout,
    needsUiRuntime: true,
    doc: 'A scrolling list whose rows `itemBuilder` builds from `items`, each as it scrolls into view: '
        '`ListView.builder(items: data.messages, itemBuilder: (m) => ListTile(title: m.name))`. `onEndReached` fires '
        'as on ListView. Needs UiRuntime; on rfw\'s Runtime, write `ListView(children: [...for m in items: ...])`.',
    params: <UiParam>[..._listViewParams(itemExtent: true), p('onEndReached', 'event'), ...itemBuilderParams()],
    build: (UiArgs a) {
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime('ListView.builder', 'ListView(children: [...for m in items: ...])');
      }
      return _listView(a, rows, itemExtent: true);
    },
    example: 'ListView.builder(shrinkWrap: true, items: ["One", "Two"], itemBuilder: (s) => ListTile(title: s))',
  ),
  UiWidget(
    'ListView.separated',
    group: UiGroup.layout,
    needsUiRuntime: true,
    doc: 'ListView.builder with `separatorBuilder` building what goes between every two rows, from the item of '
        'the row above it. Needs UiRuntime.',
    params: <UiParam>[..._listViewParams(itemExtent: false), p('onEndReached', 'event'), ...itemBuilderParams(separated: true)],
    build: (UiArgs a) {
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime('ListView.separated', 'ListView(separator: ..., children: [...for m in items: ...])');
      }
      return _listView(
        a,
        rows,
        separator: (BuildContext context, int index) => rows.buildWith(const <Object>['separatorBuilder'], index),
        itemExtent: false,
      );
    },
    example: 'ListView.separated(shrinkWrap: true, items: ["One", "Two"], itemBuilder: (s) => ListTile(title: s), '
        'separatorBuilder: (s) => Divider(height: 1))',
  ),
  UiWidget(
    'Offstage',
    group: UiGroup.layout,
    doc: 'Lays its child out but does not paint it or let it be hit.',
    params: <UiParam>[p('offstage', 'bool', null, 'true'), p('child', 'Widget')],
    build: (UiArgs a) => Offstage(offstage: a.boolean(const ['offstage']) ?? true, child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'Opacity',
    group: UiGroup.layout,
    doc: 'Makes its child partly transparent. Changes animate.',
    params: <UiParam>[
      p('opacity', 'double', '0 to 1.', '1'),
      p('alwaysIncludeSemantics', 'bool', null, 'false'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedOpacity(
      opacity: (a.number(const ['opacity']) ?? 1).clamp(0, 1),
      alwaysIncludeSemantics: a.boolean(const ['alwaysIncludeSemantics']) ?? false,
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'Padding',
    group: UiGroup.layout,
    doc: 'Insets its child: `Padding(padding: "md", ...)`, `{ horizontal: "lg", vertical: "sm" }`. Changes animate.',
    params: <UiParam>[p('padding', 'EdgeInsets', null, '0'), p('duration', 'Duration'), p('curve', 'Curve'), p('onEnd', 'event'), p('child', 'Widget')],
    build: (UiArgs a) => AnimatedPadding(
      padding: a.edgeInsets(const ['padding']) ?? EdgeInsets.zero,
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.optionalChild(const ['child']),
    ),
    example: 'Padding(padding: { horizontal: "lg", vertical: "sm" }, child: Text(text: "inset"))',
  ),
  UiWidget(
    'PageView',
    group: UiGroup.layout,
    doc: 'Pages that swipe, each built as it comes into view. `onPageChanged` receives `{ value: <index> }`.',
    params: <UiParam>[..._pageViewParams, p('children', 'List<Widget>')],
    build: (UiArgs a) => _pageView(a, a.lazyChildren(const ['children'])),
  ),
  UiWidget(
    'PageView.builder',
    group: UiGroup.layout,
    needsUiRuntime: true,
    doc: 'Pages that swipe, which `itemBuilder` builds from `items`, each as it comes into view. `onEndReached` '
        'fires when the last page is built, then again only once there is a different number of pages. Needs UiRuntime.',
    params: <UiParam>[..._pageViewParams, p('onEndReached', 'event'), ...itemBuilderParams()],
    build: (UiArgs a) {
      final UiItems? pages = a.items();
      if (pages == null) {
        return uiNeedsUiRuntime('PageView.builder', 'PageView(children: [...for m in items: ...])');
      }
      return _pageView(a, pages, onEndReached: true);
    },
  ),
  UiWidget(
    'Placeholder',
    group: UiGroup.layout,
    doc: 'A box with a cross through it, for something not built yet.',
    params: <UiParam>[
      p('color', 'Color'),
      p('strokeWidth', 'double', null, '2'),
      p('fallbackWidth', 'double', null, '400'),
      p('fallbackHeight', 'double', null, '400'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => Placeholder(
      color: a.color(const ['color']) ?? const Color(0xFF455A64),
      strokeWidth: a.number(const ['strokeWidth']) ?? 2,
      fallbackWidth: a.number(const ['fallbackWidth']) ?? 400,
      fallbackHeight: a.number(const ['fallbackHeight']) ?? 400,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'Positioned',
    group: UiGroup.layout,
    doc: 'Places a Stack child. `start` / `end` follow the text direction; `left` / `right` do not. Changes animate.',
    params: <UiParam>[
      p('start', 'double'),
      p('end', 'double'),
      p('left', 'double'),
      p('right', 'double'),
      p('top', 'double'),
      p('bottom', 'double'),
      p('width', 'double'),
      p('height', 'double'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double? start = a.spacing(const ['start']);
      final double? end = a.spacing(const ['end']);
      final double? left = a.spacing(const ['left']);
      final double? right = a.spacing(const ['right']);
      final double? top = a.spacing(const ['top']);
      final double? bottom = a.spacing(const ['bottom']);
      final double? width = a.number(const ['width']);
      final double? height = a.number(const ['height']);
      final Duration duration = a.animDuration(const ['duration']);
      final Curve curve = a.animCurve(const ['curve']);
      final VoidCallback? onEnd = a.onTap(const ['onEnd']);
      final Widget child = a.child(const ['child']);
      if (left != null || right != null) {
        return AnimatedPositioned(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          width: width,
          height: height,
          duration: duration,
          curve: curve,
          onEnd: onEnd,
          child: child,
        );
      }
      return AnimatedPositionedDirectional(
        start: start,
        end: end,
        top: top,
        bottom: bottom,
        width: width,
        height: height,
        duration: duration,
        curve: curve,
        onEnd: onEnd,
        child: child,
      );
    },
  ),
  UiWidget(
    'Rotation',
    group: UiGroup.layout,
    doc: 'Rotates its child by a number of turns (1 is a full circle). Changes animate.',
    params: <UiParam>[
      p('turns', 'double', null, '0'),
      p('alignment', 'Alignment', null, 'center'),
      e('filterQuality', FilterQuality.values),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedRotation(
      turns: a.number(const ['turns']) ?? 0,
      alignment: a.absoluteAlignment(const ['alignment']) ?? Alignment.center,
      filterQuality: a.enumValue(FilterQuality.values, const ['filterQuality']),
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'SafeArea',
    group: UiGroup.layout,
    doc: 'Insets its child away from notches, the status bar and the home indicator.',
    params: <UiParam>[
      p('left', 'bool', null, 'true'),
      p('top', 'bool', null, 'true'),
      p('right', 'bool', null, 'true'),
      p('bottom', 'bool', null, 'true'),
      p('minimum', 'EdgeInsets'),
      p('maintainBottomViewPadding', 'bool', null, 'false'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => SafeArea(
      left: a.boolean(const ['left']) ?? true,
      top: a.boolean(const ['top']) ?? true,
      right: a.boolean(const ['right']) ?? true,
      bottom: a.boolean(const ['bottom']) ?? true,
      minimum: a.edgeInsets(const ['minimum'])?.resolve(Directionality.maybeOf(a.context)) ?? EdgeInsets.zero,
      maintainBottomViewPadding: a.boolean(const ['maintainBottomViewPadding']) ?? false,
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'Scale',
    group: UiGroup.layout,
    doc: 'Scales its child. Changes animate.',
    params: <UiParam>[
      p('scale', 'double', null, '1'),
      p('alignment', 'Alignment', null, 'center'),
      e('filterQuality', FilterQuality.values),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedScale(
      scale: a.number(const ['scale']) ?? 1,
      alignment: a.absoluteAlignment(const ['alignment']) ?? Alignment.center,
      filterQuality: a.enumValue(FilterQuality.values, const ['filterQuality']),
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'SingleChildScrollView',
    group: UiGroup.layout,
    doc: 'Scrolls one child -- usually a Column -- that may be taller than the screen.',
    params: <UiParam>[
      e('scrollDirection', Axis.values, null, 'vertical'),
      p('reverse', 'bool', null, 'false'),
      p('padding', 'EdgeInsets'),
      p('primary', 'bool'),
      p('physics', 'String'),
      e('keyboardDismissBehavior', ScrollViewKeyboardDismissBehavior.values),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => SingleChildScrollView(
      scrollDirection: a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.vertical,
      reverse: a.boolean(const ['reverse']) ?? false,
      padding: a.edgeInsets(const ['padding']),
      primary: a.boolean(const ['primary']),
      physics: a.physics(const ['physics']),
      keyboardDismissBehavior: a.enumValue(ScrollViewKeyboardDismissBehavior.values, const ['keyboardDismissBehavior']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'SizedBox',
    group: UiGroup.layout,
    doc: 'A box of a fixed size. With no child it is a gap: `SizedBox(height: "md")`.',
    params: <UiParam>[p('width', 'Spacing'), p('height', 'Spacing'), p('child', 'Widget')],
    build: (UiArgs a) => SizedBox(width: a.spacing(const ['width']), height: a.spacing(const ['height']), child: a.optionalChild(const ['child'])),
    example: 'Column(children: [Text(text: "above"), SizedBox(height: "lg"), Text(text: "below")])',
  ),
  UiWidget(
    'SizedBoxExpand',
    group: UiGroup.layout,
    doc: 'As large as its parent allows.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => SizedBox.expand(child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'SizedBoxShrink',
    group: UiGroup.layout,
    doc: 'As small as its parent allows.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => SizedBox.shrink(child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'Spacer',
    group: UiGroup.layout,
    doc: 'Empty space that takes a share of a Row or Column.',
    params: <UiParam>[p('flex', 'int', null, '1')],
    build: (UiArgs a) => Spacer(flex: a.integer(const ['flex']) ?? 1),
  ),
  UiWidget(
    'Stack',
    group: UiGroup.layout,
    doc: 'Children on top of each other; place them with Positioned.',
    params: <UiParam>[
      p('alignment', 'Alignment', null, 'topStart'),
      e('textDirection', TextDirection.values),
      e('fit', StackFit.values, null, 'loose'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) => Stack(
      alignment: a.alignment(const ['alignment']) ?? AlignmentDirectional.topStart,
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      fit: a.enumValue(StackFit.values, const ['fit']) ?? StackFit.loose,
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
      children: a.children(const ['children']),
    ),
  ),
  UiWidget(
    'Transform',
    group: UiGroup.layout,
    doc: 'Rotates (radians), scales and translates its child without changing its layout. '
        '`rotateX` and `rotateY` turn it away from the screen; give it a `perspective` as well '
        '(0.001 is the usual) or the tilt is a flat squash.',
    params: <UiParam>[
      p('rotate', 'double', 'Radians, clockwise, in the plane of the screen.'),
      p('rotateX', 'double', 'Radians about the horizontal axis: the top tips away.'),
      p('rotateY', 'double', 'Radians about the vertical axis: the left edge tips away.'),
      p('perspective', 'double', 'How strongly depth foreshortens. 0 is none; 0.001 is the usual.', '0'),
      p('scale', 'double'),
      p('scaleX', 'double'),
      p('scaleY', 'double'),
      p('translate', 'Offset'),
      p('alignment', 'Alignment', 'The origin of rotation and scale.', 'center'),
      p('transformHitTests', 'bool', null, 'true'),
      e('filterQuality', FilterQuality.values),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double rotate = a.number(const ['rotate']) ?? 0;
      final double rotateX = a.number(const ['rotateX']) ?? 0;
      final double rotateY = a.number(const ['rotateY']) ?? 0;
      final double perspective = a.number(const ['perspective']) ?? 0;
      final double scale = a.number(const ['scale']) ?? 1;
      final double scaleX = a.number(const ['scaleX']) ?? scale;
      final double scaleY = a.number(const ['scaleY']) ?? scale;
      final Offset translate = a.offset(const ['translate']) ?? Offset.zero;
      final Matrix4 matrix = Matrix4.identity();
      // The perspective row goes on first, as everything after it is what
      // gets foreshortened.
      if (perspective != 0) {
        matrix.setEntry(3, 2, perspective);
      }
      matrix
        ..translateByDouble(translate.dx, translate.dy, 0, 1)
        ..rotateX(rotateX)
        ..rotateY(rotateY)
        ..rotateZ(rotate)
        ..scaleByDouble(scaleX, scaleY, 1, 1);
      return Transform(
        transform: matrix,
        alignment: a.alignment(const ['alignment']) ?? Alignment.center,
        transformHitTests: a.boolean(const ['transformHitTests']) ?? true,
        filterQuality: a.enumValue(FilterQuality.values, const ['filterQuality']),
        child: a.optionalChild(const ['child']),
      );
    },
  ),
  UiWidget(
    'Visibility',
    group: UiGroup.layout,
    doc: 'Shows its child or a replacement. Bind `visible` to data to show and hide without rebuilding the file.',
    params: <UiParam>[
      p('visible', 'bool', null, 'true'),
      p('replacement', 'Widget', 'Shown while hidden.', 'nothing'),
      p('maintainState', 'bool', null, 'false'),
      p('maintainAnimation', 'bool', null, 'false'),
      p('maintainSize', 'bool', null, 'false'),
      p('maintainInteractivity', 'bool', null, 'false'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final bool maintainSize = a.boolean(const ['maintainSize']) ?? false;
      final bool maintainInteractivity = a.boolean(const ['maintainInteractivity']) ?? false;
      final bool askedAnimation = a.boolean(const ['maintainAnimation']) ?? false;
      final bool askedState = a.boolean(const ['maintainState']) ?? false;
      // Flutter asserts each of these implies the next; a remote file asking
      // for the outer one gets the ones it needs rather than an assertion.
      final bool maintainAnimation = maintainSize || askedAnimation;
      final bool maintainState = maintainAnimation || askedState;
      return Visibility(
        visible: a.boolean(const ['visible']) ?? true,
        replacement: a.optionalChild(const ['replacement']) ?? const SizedBox.shrink(),
        maintainState: maintainState,
        maintainAnimation: maintainAnimation,
        maintainSize: maintainSize,
        maintainInteractivity: maintainSize && maintainInteractivity,
        child: a.child(const ['child']),
      );
    },
  ),
  UiWidget(
    'Wrap',
    group: UiGroup.layout,
    doc: 'Children in runs that wrap onto the next line -- chips, tags.',
    params: <UiParam>[
      e('direction', Axis.values, null, 'horizontal'),
      e('alignment', WrapAlignment.values, null, 'start'),
      p('spacing', 'Spacing', 'Between children in a run.', '0'),
      e('runAlignment', WrapAlignment.values, null, 'start'),
      p('runSpacing', 'Spacing', 'Between runs.', '0'),
      e('crossAxisAlignment', WrapCrossAlignment.values, null, 'start'),
      e('textDirection', TextDirection.values),
      e('verticalDirection', VerticalDirection.values, null, 'down'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) => Wrap(
      direction: a.enumValue(Axis.values, const ['direction']) ?? Axis.horizontal,
      alignment: a.enumValue(WrapAlignment.values, const ['alignment']) ?? WrapAlignment.start,
      spacing: a.spacing(const ['spacing']) ?? 0,
      runAlignment: a.enumValue(WrapAlignment.values, const ['runAlignment']) ?? WrapAlignment.start,
      runSpacing: a.spacing(const ['runSpacing']) ?? 0,
      crossAxisAlignment: a.enumValue(WrapCrossAlignment.values, const ['crossAxisAlignment']) ?? WrapCrossAlignment.start,
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      verticalDirection: a.enumValue(VerticalDirection.values, const ['verticalDirection']) ?? VerticalDirection.down,
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
      children: a.children(const ['children']),
    ),
    example: 'Wrap(spacing: "sm", runSpacing: "sm", children: [Chip(label: "rfw"), Chip(label: "flutter"), Chip(label: "ui")])',
  ),
  UiWidget(
    'IndexedStack',
    group: UiGroup.layout,
    doc: 'Shows the child at `index` and keeps the rest in the tree, with their state and their scroll '
        'positions. What a tab bar wants when leaving a tab should not forget where it was.',
    params: <UiParam>[
      p('index', 'int', 'Which child to show. Null shows none.', '0'),
      p('alignment', 'Alignment', null, 'topStart'),
      e('sizing', StackFit.values, 'How the children are sized.', 'loose'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) => IndexedStack(
      index: a.integer(const ['index']) ?? 0,
      alignment: a.alignment(const ['alignment']) ?? AlignmentDirectional.topStart,
      sizing: a.enumValue(StackFit.values, const ['sizing']) ?? StackFit.loose,
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
      children: a.children(const ['children']),
    ),
    example: 'IndexedStack(index: 1, children: [Text(text: "First"), Text(text: "Second")])',
  ),
  UiWidget(
    'OverflowBox',
    group: UiGroup.layout,
    doc: 'Gives its child constraints of its own, so the child may be larger than the space here: '
        'a picture wider than its column, a glow that spills past its card.',
    params: <UiParam>[
      p('minWidth', 'double'),
      p('maxWidth', 'double'),
      p('minHeight', 'double'),
      p('maxHeight', 'double'),
      p('alignment', 'Alignment', null, 'center'),
      e('fit', OverflowBoxFit.values, null, 'max'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => OverflowBox(
      minWidth: a.number(const ['minWidth']),
      maxWidth: a.number(const ['maxWidth']),
      minHeight: a.number(const ['minHeight']),
      maxHeight: a.number(const ['maxHeight']),
      alignment: a.alignment(const ['alignment']) ?? Alignment.center,
      fit: a.enumValue(OverflowBoxFit.values, const ['fit']) ?? OverflowBoxFit.max,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'UnconstrainedBox',
    group: UiGroup.layout,
    doc: 'Lets its child be whatever size it wants, whatever it was given. `constrainedAxis` keeps one axis.',
    params: <UiParam>[
      p('alignment', 'Alignment', null, 'center'),
      e('constrainedAxis', Axis.values, 'The axis that keeps its constraint.'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => UnconstrainedBox(
      alignment: a.alignment(const ['alignment']) ?? Alignment.center,
      constrainedAxis: a.enumValue(Axis.values, const ['constrainedAxis']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'FractionalTranslation',
    group: UiGroup.layout,
    doc: 'Moves its child by a fraction of the child\'s own size, without changing the layout: '
        '`{ x: 0.5 }` is half its width across. A badge hanging off a corner, a peeking card.',
    params: <UiParam>[
      p('translation', 'Offset', 'Fractions of the child\'s own width and height.'),
      p('transformHitTests', 'bool', null, 'true'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => FractionalTranslation(
      translation: a.offset(const ['translation']) ?? Offset.zero,
      transformHitTests: a.boolean(const ['transformHitTests']) ?? true,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'Table',
    group: UiGroup.layout,
    doc: 'Rows of cells in columns that line up down the whole table: `rows: [{ cells: [...] }, ...]`. '
        'Every row needs the same number of cells. `columnWidths` is one entry per column: '
        '`{ type: .flex, flex: 1 }`, `{ type: .fixed, width: 120 }`, `{ type: .fraction, fraction: 0.5 }` or '
        '`{ type: .intrinsic }`.',
    params: <UiParam>[
      p('rows', 'List<Map>', 'Each `{ cells: [...], decoration }`.'),
      p('columnWidths', 'List<Map>', 'One per column, from the left.'),
      p('defaultColumnWidth', 'Map', 'For columns `columnWidths` does not name.', '{ type: .flex }'),
      p('border', 'BorderSide', 'Drawn around and between every cell.'),
      e('defaultVerticalAlignment', TableCellVerticalAlignment.values, null, 'top'),
      p('textBaseline', 'String'),
    ],
    build: (UiArgs a) {
      final List<TableColumnWidth>? widths = a.list<TableColumnWidth>(const ['columnWidths'], (List<Object> k) => _columnWidth(a, k));
      final TableColumnWidth? fallback = _columnWidth(a, const ['defaultColumnWidth']);
      final BorderSide? side = a.borderSide(const ['border']);
      final TableCellVerticalAlignment alignment =
          a.enumValue(TableCellVerticalAlignment.values, const ['defaultVerticalAlignment']) ?? TableCellVerticalAlignment.top;
      final String? baseline = a.string(const ['textBaseline']);
      final List<TableRow> rows = _tableRows(a, const ['rows']);
      return Table(
        children: rows,
        columnWidths: widths == null
            ? null
            : <int, TableColumnWidth>{for (int i = 0; i < widths.length; i += 1) i: widths[i]},
        defaultColumnWidth: fallback ?? const FlexColumnWidth(),
        border: side == null ? null : TableBorder.all(color: side.color, width: side.width, style: side.style),
        defaultVerticalAlignment: alignment,
        textBaseline: baseline == 'ideographic' ? TextBaseline.ideographic : TextBaseline.alphabetic,
      );
    },
    example: 'Table(border: { color: .outline, width: 1 }, rows: ['
        '{ cells: [Padding(padding: "sm", child: Text(text: "Name")), Padding(padding: "sm", child: Text(text: "Score"))] }, '
        '{ cells: [Padding(padding: "sm", child: Text(text: "Ada")), Padding(padding: "sm", child: Text(text: "42"))] }])',
  ),
  UiWidget(
    'ListWheelScrollView',
    group: UiGroup.layout,
    doc: 'A list curved around a cylinder, as a date picker is. `onSelectedItemChanged` fires with the index '
        'in the middle.',
    params: <UiParam>[
      p('itemExtent', 'double', 'How tall each child is.', '40'),
      p('diameterRatio', 'double', 'Smaller is a tighter curve.', '2'),
      p('perspective', 'double', null, '0.003'),
      p('offAxisFraction', 'double', 'Shifts the axis sideways.', '0'),
      p('squeeze', 'double', null, '1'),
      p('magnification', 'double', 'How much bigger the middle one is, with `useMagnifier`.', '1'),
      p('useMagnifier', 'bool', null, 'false'),
      p('overAndUnderCenterOpacity', 'double', 'How faint the ones away from the middle are.', '1'),
      p('physics', 'String'),
      p('initialItem', 'int', null, '0'),
      p('onSelectedItemChanged', 'event<int>'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) {
      final double itemExtent = a.number(const ['itemExtent']) ?? 40;
      final double diameterRatio = a.number(const ['diameterRatio']) ?? 2;
      final double perspective = a.number(const ['perspective']) ?? 0.003;
      final double offAxisFraction = a.number(const ['offAxisFraction']) ?? 0;
      final double squeeze = a.number(const ['squeeze']) ?? 1;
      final double magnification = a.number(const ['magnification']) ?? 1;
      final bool useMagnifier = a.boolean(const ['useMagnifier']) ?? false;
      final double opacity = a.number(const ['overAndUnderCenterOpacity']) ?? 1;
      final ScrollPhysics? physics = a.physics(const ['physics']);
      final int initialItem = a.integer(const ['initialItem']) ?? 0;
      final ValueChanged<int>? onSelected = a.onValue<int>(const ['onSelectedItemChanged']);
      final List<Widget> children = a.children(const ['children']);
      return UiOwned<FixedExtentScrollController>(
        create: () => FixedExtentScrollController(initialItem: initialItem),
        builder: (BuildContext context, FixedExtentScrollController controller) => ListWheelScrollView(
          controller: controller,
          itemExtent: itemExtent,
          diameterRatio: diameterRatio,
          perspective: perspective,
          offAxisFraction: offAxisFraction,
          squeeze: squeeze,
          magnification: magnification,
          useMagnifier: useMagnifier,
          overAndUnderCenterOpacity: opacity,
          physics: physics ?? const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelected,
          children: children,
        ),
      );
    },
  ),
  UiWidget(
    'Scrollbar',
    group: UiGroup.layout,
    doc: 'A thumb beside the scroll view inside it. On a phone one appears while scrolling anyway; this is '
        'for one that stays, or one on a scroll view that is not the page.',
    params: <UiParam>[
      p('thumbVisibility', 'bool', 'Always shown, not only while scrolling.'),
      p('trackVisibility', 'bool'),
      p('thickness', 'double'),
      p('radius', 'double'),
      p('interactive', 'bool', 'The thumb itself can be dragged.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double? radius = a.number(const ['radius']);
      return Scrollbar(
        thumbVisibility: a.boolean(const ['thumbVisibility']),
        trackVisibility: a.boolean(const ['trackVisibility']),
        thickness: a.number(const ['thickness']),
        radius: radius == null ? null : Radius.circular(radius),
        interactive: a.boolean(const ['interactive']),
        child: a.child(const ['child']),
      );
    },
  ),

];

UiWidget _flex(String name, Axis axis) => UiWidget(
  name,
  group: UiGroup.layout,
  doc: axis == Axis.vertical
      ? 'Children top to bottom. `spacing` puts a gap between each: `Column(spacing: "md", ...)`.'
      : 'Children side by side. `spacing` puts a gap between each: `Row(spacing: "sm", ...)`.',
  params: <UiParam>[
    e('mainAxisAlignment', MainAxisAlignment.values, null, 'start'),
    e('mainAxisSize', MainAxisSize.values, null, 'max'),
    e('crossAxisAlignment', CrossAxisAlignment.values, null, 'center'),
    e('textDirection', TextDirection.values),
    e('verticalDirection', VerticalDirection.values, null, 'down'),
    e('textBaseline', TextBaseline.values, 'Needed when crossAxisAlignment is baseline.'),
    p('spacing', 'Spacing', null, '0'),
    p('children', 'List<Widget>'),
  ],
  build: (UiArgs a) {
    final CrossAxisAlignment cross = a.enumValue(CrossAxisAlignment.values, const ['crossAxisAlignment']) ?? CrossAxisAlignment.center;
    final TextBaseline? baseline = a.enumValue(TextBaseline.values, const ['textBaseline']);
    return Flex(
      direction: axis,
      mainAxisAlignment: a.enumValue(MainAxisAlignment.values, const ['mainAxisAlignment']) ?? MainAxisAlignment.start,
      mainAxisSize: a.enumValue(MainAxisSize.values, const ['mainAxisSize']) ?? MainAxisSize.max,
      crossAxisAlignment: cross,
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      verticalDirection: a.enumValue(VerticalDirection.values, const ['verticalDirection']) ?? VerticalDirection.down,
      // Flutter asserts a baseline alignment has a baseline to align to.
      textBaseline: baseline ?? (cross == CrossAxisAlignment.baseline ? TextBaseline.alphabetic : null),
      spacing: a.spacing(const ['spacing']) ?? 0,
      children: a.children(const ['children']),
    );
  },
  example: axis == Axis.vertical
      ? 'Column(spacing: "sm", crossAxisAlignment: "start", children: [Text(text: "Title", style: "titleLarge"), Text(text: "Body", style: "bodyMedium")])'
      : 'Row(spacing: "sm", children: [Icon(icon: "star"), Text(text: "Starred")])',
);

/// What every GridView reads but where its cells come from.
final List<UiParam> _gridViewParams = <UiParam>[
  p('gridDelegate', 'GridDelegate', null, '{ crossAxisCount: 2 }'),
  e('scrollDirection', Axis.values, null, 'vertical'),
  p('reverse', 'bool', null, 'false'),
  p('primary', 'bool'),
  p('physics', 'String', '`"never"`, `"always"`, `"bouncing"`, `"clamping"` or `"page"`.'),
  p('shrinkWrap', 'bool', 'Size to the children instead of filling the scroll axis.', 'false'),
  p('padding', 'EdgeInsets'),
  p('cacheExtent', 'double', 'Pixels laid out beyond the visible edge.'),
  e('keyboardDismissBehavior', ScrollViewKeyboardDismissBehavior.values),
  e('clipBehavior', Clip.values, null, 'hardEdge'),
  p('onEndReached', 'event', 'Fires when the last child is built, then again only once there is a different number of children.'),
];

/// A GridView of [cells], built as they scroll into view.
Widget _gridView(UiArgs a, UiRows? cells) {
  final SliverGridDelegate grid = a.gridDelegate(const ['gridDelegate']) ?? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2);
  final Axis scrollDirection = a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.vertical;
  final bool reverse = a.boolean(const ['reverse']) ?? false;
  final bool? primary = a.boolean(const ['primary']);
  final ScrollPhysics? physics = a.physics(const ['physics']);
  final bool shrinkWrap = a.boolean(const ['shrinkWrap']) ?? false;
  final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
  final ScrollCacheExtent? cacheExtent = a.cacheExtent(const ['cacheExtent']);
  final ScrollViewKeyboardDismissBehavior? dismiss = a.enumValue(ScrollViewKeyboardDismissBehavior.values, const ['keyboardDismissBehavior']);
  final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge;
  return UiEndReached(
    length: cells?.length ?? 0,
    onEnd: a.onTap(const ['onEndReached']),
    rows: cells,
    builder: (IndexedWidgetBuilder cell) => GridView.builder(
      gridDelegate: grid,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      scrollCacheExtent: cacheExtent,
      keyboardDismissBehavior: dismiss,
      clipBehavior: clip,
      itemCount: cells?.length ?? 0,
      itemBuilder: cell,
    ),
  );
}

/// What every ListView reads but where its rows come from. ListView.separated,
/// like Flutter's, has no `itemExtent`.
List<UiParam> _listViewParams({required bool itemExtent}) => <UiParam>[
  e('scrollDirection', Axis.values, null, 'vertical'),
  p('reverse', 'bool', null, 'false'),
  p('primary', 'bool'),
  p('physics', 'String', '`"never"`, `"always"`, `"bouncing"`, `"clamping"` or `"page"`.'),
  p('shrinkWrap', 'bool', null, 'false'),
  p('padding', 'EdgeInsets'),
  if (itemExtent) p('itemExtent', 'double'),
  p('cacheExtent', 'double', 'Pixels laid out beyond the visible edge.'),
  e('keyboardDismissBehavior', ScrollViewKeyboardDismissBehavior.values),
  e('clipBehavior', Clip.values, null, 'hardEdge'),
];

/// A ListView of [rows], built as they scroll into view, with [separator]
/// between every two when there is one.
Widget _listView(UiArgs a, UiRows? rows, {IndexedWidgetBuilder? separator, required bool itemExtent}) {
  final Axis scrollDirection = a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.vertical;
  final bool reverse = a.boolean(const ['reverse']) ?? false;
  final bool? primary = a.boolean(const ['primary']);
  final ScrollPhysics? physics = a.physics(const ['physics']);
  final bool shrinkWrap = a.boolean(const ['shrinkWrap']) ?? false;
  final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
  final ScrollCacheExtent? cacheExtent = a.cacheExtent(const ['cacheExtent']);
  final ScrollViewKeyboardDismissBehavior? dismiss = a.enumValue(ScrollViewKeyboardDismissBehavior.values, const ['keyboardDismissBehavior']);
  final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge;
  final double? extent = itemExtent ? a.number(const ['itemExtent']) : null;
  return UiEndReached(
    length: rows?.length ?? 0,
    onEnd: a.onTap(const ['onEndReached']),
    builder: (IndexedWidgetBuilder row) => separator == null
        ? ListView.builder(
            scrollDirection: scrollDirection,
            reverse: reverse,
            primary: primary,
            physics: physics,
            shrinkWrap: shrinkWrap,
            padding: padding,
            itemExtent: extent,
            scrollCacheExtent: cacheExtent,
            keyboardDismissBehavior: dismiss,
            clipBehavior: clip,
            itemCount: rows?.length ?? 0,
            itemBuilder: row,
          )
        : ListView.separated(
            scrollDirection: scrollDirection,
            reverse: reverse,
            primary: primary,
            physics: physics,
            shrinkWrap: shrinkWrap,
            padding: padding,
            scrollCacheExtent: cacheExtent,
            keyboardDismissBehavior: dismiss,
            clipBehavior: clip,
            itemCount: rows?.length ?? 0,
            itemBuilder: row,
            separatorBuilder: separator,
          ),
    rows: rows,
  );
}

/// What every PageView reads but where its pages come from.
final List<UiParam> _pageViewParams = <UiParam>[
  e('scrollDirection', Axis.values, null, 'horizontal'),
  p('reverse', 'bool', null, 'false'),
  p('physics', 'String'),
  p('pageSnapping', 'bool', null, 'true'),
  p('padEnds', 'bool', null, 'true'),
  p('initialPage', 'int', null, '0'),
  p('viewportFraction', 'double', 'How much of the viewport one page fills.', '1'),
  p('onPageChanged', 'event<int>'),
  e('clipBehavior', Clip.values, null, 'hardEdge'),
];

/// A PageView of [pages], each built as it comes into view; with
/// [onEndReached], firing `onEndReached` as a list does.
Widget _pageView(UiArgs a, UiRows? pages, {bool onEndReached = false}) {
  final int initialPage = a.integer(const ['initialPage']) ?? 0;
  final double viewportFraction = a.number(const ['viewportFraction']) ?? 1;
  final Axis scrollDirection = a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.horizontal;
  final bool reverse = a.boolean(const ['reverse']) ?? false;
  final ScrollPhysics? physics = a.physics(const ['physics']);
  final bool pageSnapping = a.boolean(const ['pageSnapping']) ?? true;
  final bool padEnds = a.boolean(const ['padEnds']) ?? true;
  final ValueChanged<int>? onPageChanged = a.onValue<int>(const ['onPageChanged']);
  final Clip clip = a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge;
  Widget view(IndexedWidgetBuilder page) => UiOwnedPageController(
    initialPage: initialPage,
    viewportFraction: viewportFraction,
    builder: (PageController controller) => PageView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      physics: physics,
      pageSnapping: pageSnapping,
      padEnds: padEnds,
      onPageChanged: onPageChanged,
      clipBehavior: clip,
      itemCount: pages?.length ?? 0,
      itemBuilder: page,
    ),
  );
  if (!onEndReached) {
    return view((BuildContext context, int index) => pages!.build(index));
  }
  return UiEndReached(length: pages?.length ?? 0, onEnd: a.onTap(const ['onEndReached']), rows: pages, builder: view);
}

/// A lazily built list's rows, and `onEndReached`: [builder] makes the scroll
/// view, given the builder of a row, which builds row `index` of [rows] and
/// notes when it is the last.
///
/// [onEnd] is called once the last of [length] rows has been built, and not
/// again until the list has a different length. This widget sits above the
/// scroll view, so the last row scrolling away and back again does not count
/// as reaching the end twice.
class UiEndReached extends StatefulWidget {
  const UiEndReached({super.key, required this.length, required this.onEnd, required this.rows, required this.builder});

  final int length;
  final VoidCallback? onEnd;
  final UiRows? rows;
  final Widget Function(IndexedWidgetBuilder row) builder;

  @override
  State<UiEndReached> createState() => _UiEndReachedState();
}

class _UiEndReachedState extends State<UiEndReached> {
  int? _firedFor;

  Widget _row(BuildContext context, int index) {
    final VoidCallback? onEnd = widget.onEnd;
    if (onEnd != null && index == widget.length - 1 && _firedFor != widget.length) {
      _firedFor = widget.length;
      // Rows are built during layout, and the handler may well change data:
      // that waits for the frame to finish.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          onEnd();
        }
      });
    }
    return widget.rows!.build(index);
  }

  @override
  Widget build(BuildContext context) => widget.builder(_row);
}

/// A [PageController] owned for a remote PageView.
class UiOwnedPageController extends StatefulWidget {
  const UiOwnedPageController({super.key, required this.initialPage, required this.viewportFraction, required this.builder});

  final int initialPage;
  final double viewportFraction;
  final Widget Function(PageController controller) builder;

  @override
  State<UiOwnedPageController> createState() => _UiOwnedPageControllerState();
}

class _UiOwnedPageControllerState extends State<UiOwnedPageController> {
  late PageController _controller = PageController(initialPage: widget.initialPage, viewportFraction: widget.viewportFraction);

  @override
  void didUpdateWidget(UiOwnedPageController old) {
    super.didUpdateWidget(old);
    // viewportFraction is fixed at construction; a new one needs a new controller.
    if (widget.viewportFraction != old.viewportFraction) {
      final int page = _controller.hasClients ? (_controller.page?.round() ?? widget.initialPage) : widget.initialPage;
      _controller.dispose();
      _controller = PageController(initialPage: page, viewportFraction: widget.viewportFraction);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// One entry of a `Table`'s `columnWidths`, or its `defaultColumnWidth`.
TableColumnWidth? _columnWidth(UiArgs a, List<Object> key) {
  List<Object> at(String name) => <Object>[...key, name];
  return switch (a.string(at('type'))) {
    'fixed' => FixedColumnWidth(a.number(at('width')) ?? 0),
    'fraction' => FractionColumnWidth(a.number(at('fraction')) ?? 0),
    'intrinsic' => IntrinsicColumnWidth(flex: a.number(at('flex'))),
    'flex' => FlexColumnWidth(a.number(at('flex')) ?? 1),
    _ => null,
  };
}

/// The `rows` of a `Table`: each `{ cells: [...], decoration }`.
List<TableRow> _tableRows(UiArgs a, List<Object> key) {
  return a.list<TableRow>(key, (List<Object> k) {
        final List<Widget> cells = a.children(<Object>[...k, 'cells']);
        if (cells.isEmpty) {
          return null;
        }
        return TableRow(decoration: a.decoration(<Object>[...k, 'decoration']), children: cells);
      }) ??
      const <TableRow>[];
}
