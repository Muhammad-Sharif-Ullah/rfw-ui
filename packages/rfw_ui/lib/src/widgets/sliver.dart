import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSliverNavigationBar;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints, SliverLayoutDimensions;

import 'args.dart';
import 'builders.dart' show breakpointOf;
import 'layout.dart' show UiEndReached;
import 'slot.dart';
import 'spec.dart';

/// Slivers: the pieces of a CustomScrollView. rfw ships none.
///
/// A sliver goes only where a sliver is expected -- `CustomScrollView(slivers:
/// [...])`, or the `sliver:` of another sliver -- and a box widget goes inside
/// a SliverToBoxAdapter. Mixing them up is a layout error, as in Flutter.
final List<UiWidget> sliverWidgets = <UiWidget>[
  UiWidget(
    'CustomScrollView',
    group: UiGroup.sliver,
    doc: 'A scroll view made of slivers: collapsing app bars, lists, grids and boxes in one scroll.',
    params: <UiParam>[
      p('slivers', 'List<Widget>'),
      e('scrollDirection', Axis.values, null, 'vertical'),
      p('reverse', 'bool', null, 'false'),
      p('primary', 'bool'),
      p('physics', 'String'),
      p('shrinkWrap', 'bool', null, 'false'),
      p('anchor', 'double', null, '0'),
      p('cacheExtent', 'double', 'Pixels laid out beyond the visible edge.'),
      e('keyboardDismissBehavior', ScrollViewKeyboardDismissBehavior.values),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
    ],
    build: (UiArgs a) => CustomScrollView(
      slivers: a.children(const ['slivers']),
      scrollDirection: a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.vertical,
      reverse: a.boolean(const ['reverse']) ?? false,
      primary: a.boolean(const ['primary']),
      physics: a.physics(const ['physics']),
      shrinkWrap: a.boolean(const ['shrinkWrap']) ?? false,
      anchor: a.number(const ['anchor']) ?? 0,
      scrollCacheExtent: a.cacheExtent(const ['cacheExtent']),
      keyboardDismissBehavior: a.enumValue(ScrollViewKeyboardDismissBehavior.values, const ['keyboardDismissBehavior']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
    ),
    example: 'SizedBox(height: 400, child: CustomScrollView(slivers: [SliverAppBar(title: "Library", pinned: true), '
        'SliverPadding(padding: "md", sliver: SliverList(separator: SizedBox(height: "sm"), children: [Text(text: "One"), Text(text: "Two")])), '
        'SliverGrid(gridDelegate: { crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4 }, children: [ColoredBox(color: "primary"), ColoredBox(color: "secondary"), ColoredBox(color: "tertiary")]), '
        'SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(text: "The end")))]))',
  ),
  UiWidget(
    'SliverToBoxAdapter',
    group: UiGroup.sliver,
    doc: 'One ordinary widget, as a sliver.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => SliverToBoxAdapter(child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'SliverList',
    group: UiGroup.sliver,
    doc: 'Children one after another, built as they scroll into view. `separator` goes between every two. '
        '`onEndReached` fires when the last child is built, then again only once there is a different number of children.',
    params: <UiParam>[p('children', 'List<Widget>'), p('separator', 'Widget'), p('onEndReached', 'event')],
    build: (UiArgs a) {
      final Widget? separator = a.optionalChild(const ['separator']);
      return _sliverList(
        a,
        a.lazyChildren(const ['children']),
        separator: separator == null ? null : (BuildContext context, int index) => separator,
      );
    },
  ),
  UiWidget(
    'SliverList.builder',
    group: UiGroup.sliver,
    needsUiRuntime: true,
    doc: 'A SliverList whose rows `itemBuilder` builds from `items`, each as it scrolls into view. Needs UiRuntime.',
    params: <UiParam>[...itemBuilderParams(), p('onEndReached', 'event')],
    build: (UiArgs a) {
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime('SliverList.builder', 'SliverList(children: [...for m in items: ...])');
      }
      return _sliverList(a, rows);
    },
  ),
  UiWidget(
    'SliverList.separated',
    group: UiGroup.sliver,
    needsUiRuntime: true,
    doc: 'SliverList.builder with `separatorBuilder` building what goes between every two rows, from the item of '
        'the row above it. Needs UiRuntime.',
    params: <UiParam>[...itemBuilderParams(separated: true), p('onEndReached', 'event')],
    build: (UiArgs a) {
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime('SliverList.separated', 'SliverList(separator: ..., children: [...for m in items: ...])');
      }
      return _sliverList(
        a,
        rows,
        separator: (BuildContext context, int index) => rows.buildWith(const <Object>['separatorBuilder'], index),
      );
    },
  ),
  UiWidget(
    'SliverFixedExtentList',
    group: UiGroup.sliver,
    doc: 'A list whose children are all `itemExtent` tall -- cheaper to lay out than SliverList.',
    params: <UiParam>[p('itemExtent', 'double', null, '48'), p('children', 'List<Widget>')],
    build: (UiArgs a) {
      final UiLazyChildren? rows = a.lazyChildren(const ['children']);
      return SliverFixedExtentList.builder(
        itemExtent: a.number(const ['itemExtent']) ?? 48,
        itemCount: rows?.length ?? 0,
        itemBuilder: (BuildContext context, int index) => rows!.build(index),
      );
    },
  ),
  UiWidget(
    'SliverGrid',
    group: UiGroup.sliver,
    doc: 'A grid, as a sliver.',
    params: <UiParam>[p('gridDelegate', 'GridDelegate', null, '{ crossAxisCount: 2 }'), p('children', 'List<Widget>')],
    build: (UiArgs a) {
      final UiLazyChildren? cells = a.lazyChildren(const ['children']);
      return SliverGrid.builder(
        gridDelegate: a.gridDelegate(const ['gridDelegate']) ?? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: cells?.length ?? 0,
        itemBuilder: (BuildContext context, int index) => cells!.build(index),
      );
    },
  ),
  UiWidget(
    'SliverGrid.builder',
    group: UiGroup.sliver,
    needsUiRuntime: true,
    doc: 'A sliver grid whose cells `itemBuilder` builds from `items`, each as it scrolls into view. `onEndReached` '
        'fires when the last cell is built, then again only once there is a different number of cells. Needs UiRuntime.',
    params: <UiParam>[p('gridDelegate', 'GridDelegate', null, '{ crossAxisCount: 2 }'), ...itemBuilderParams(), p('onEndReached', 'event')],
    build: (UiArgs a) {
      final UiItems? cells = a.items();
      if (cells == null) {
        return uiNeedsUiRuntime('SliverGrid.builder', 'SliverGrid(children: [...for m in items: ...])');
      }
      final SliverGridDelegate grid = a.gridDelegate(const ['gridDelegate']) ?? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2);
      return UiEndReached(
        length: cells.length,
        onEnd: a.onTap(const ['onEndReached']),
        rows: cells,
        builder: (IndexedWidgetBuilder cell) => SliverGrid.builder(gridDelegate: grid, itemCount: cells.length, itemBuilder: cell),
      );
    },
  ),
  UiWidget(
    'SliverPadding',
    group: UiGroup.sliver,
    doc: 'Insets a sliver.',
    params: <UiParam>[p('padding', 'EdgeInsets', null, '0'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverPadding(
      padding: a.edgeInsets(const ['padding']) ?? EdgeInsets.zero,
      sliver: a.optionalChild(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverAppBar',
    group: UiGroup.sliver,
    doc: 'An app bar that scrolls with the content -- pinned, floating, or expanding over a FlexibleSpaceBar. '
        '`variant: "medium" | "large"` is the Material 3 collapsing title.',
    params: <UiParam>[
      oneOf('variant', <String>['small', 'medium', 'large'], null, 'small'),
      p('leading', 'Widget|Icon'),
      p('automaticallyImplyLeading', 'bool', null, 'true'),
      p('title', 'Widget|String'),
      p('actions', 'List<Widget>'),
      p('flexibleSpace', 'Widget', 'Usually a FlexibleSpaceBar.'),
      p('bottom', 'Widget', 'Usually a TabBar.'),
      p('elevation', 'double'),
      p('scrolledUnderElevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('forceElevated', 'bool', null, 'false'),
      p('backgroundColor', 'Color'),
      p('foregroundColor', 'Color'),
      p('primary', 'bool', null, 'true'),
      p('centerTitle', 'bool'),
      p('titleSpacing', 'double'),
      p('collapsedHeight', 'double'),
      p('expandedHeight', 'double'),
      p('floating', 'bool', 'Comes back as soon as you scroll up.', 'false'),
      p('pinned', 'bool', 'Stays at the top once collapsed.', 'false'),
      p('snap', 'bool', 'With floating: comes back all at once.', 'false'),
      p('stretch', 'bool', 'Stretches on overscroll.', 'false'),
      p('shape', 'ShapeBorder'),
      p('toolbarHeight', 'double', null, '56'),
      p('leadingWidth', 'double'),
      p('titleTextStyle', 'TextStyle'),
      p('forceMaterialTransparency', 'bool', null, 'false'),
      e('clipBehavior', Clip.values),
      p('actionsPadding', 'EdgeInsets'),
    ],
    build: (UiArgs a) {
      final String variant = a.string(const ['variant']) ?? 'small';
      final Widget? leading = a.iconOrChild(const ['leading']);
      final bool implyLeading = a.boolean(const ['automaticallyImplyLeading']) ?? true;
      final Widget? title = a.label(const ['title']);
      final List<Widget> actions = a.children(const ['actions']);
      final Widget? flexibleSpace = a.optionalChild(const ['flexibleSpace']);
      final Widget? bottom = a.optionalChild(const ['bottom']);
      final double? elevation = a.number(const ['elevation']);
      final double? scrolledUnderElevation = a.number(const ['scrolledUnderElevation']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final bool forceElevated = a.boolean(const ['forceElevated']) ?? false;
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? foregroundColor = a.color(const ['foregroundColor']);
      final bool primary = a.boolean(const ['primary']) ?? true;
      final bool? centerTitle = a.boolean(const ['centerTitle']);
      final double? titleSpacing = a.spacing(const ['titleSpacing']);
      final double? collapsedHeight = a.number(const ['collapsedHeight']);
      final double? expandedHeight = a.number(const ['expandedHeight']);
      final bool floating = a.boolean(const ['floating']) ?? false;
      final bool pinned = a.boolean(const ['pinned']) ?? false;
      // Flutter asserts a snap has something to snap: only a floating bar does.
      final bool askedSnap = a.boolean(const ['snap']) ?? false;
      final bool snap = floating && askedSnap;
      final bool stretch = a.boolean(const ['stretch']) ?? false;
      final ShapeBorder? shape = a.shape(const ['shape']);
      final double toolbarHeight = a.number(const ['toolbarHeight']) ?? kToolbarHeight;
      final double? leadingWidth = a.number(const ['leadingWidth']);
      final TextStyle? titleTextStyle = a.textStyle(const ['titleTextStyle']);
      final bool forceTransparent = a.boolean(const ['forceMaterialTransparency']) ?? false;
      final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
      final EdgeInsetsGeometry? actionsPadding = a.edgeInsets(const ['actionsPadding']);
      return UiSlots(
        initial: const <String, SlotValue>{'bottom': SlotValue(Size.fromHeight(kTextTabBarHeight))},
        builder: (BuildContext context, UiSlot Function(String, Widget) slot) {
          final PreferredSizeWidget? bar = bottom == null ? null : slot('bottom', bottom);
          final List<Widget>? acts = actions.isEmpty ? null : actions;
          // A collapsed bar is at least as tall as its toolbar and bottom.
          final double floor = toolbarHeight + (bar?.preferredSize.height ?? 0);
          final double? collapsed = collapsedHeight == null || collapsedHeight < floor ? null : collapsedHeight;
          return switch (variant) {
            'medium' => SliverAppBar.medium(
              leading: leading,
              automaticallyImplyLeading: implyLeading,
              title: title,
              actions: acts,
              flexibleSpace: flexibleSpace,
              bottom: bar,
              elevation: elevation,
              scrolledUnderElevation: scrolledUnderElevation,
              shadowColor: shadowColor,
              surfaceTintColor: surfaceTintColor,
              forceElevated: forceElevated,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              primary: primary,
              centerTitle: centerTitle,
              titleSpacing: titleSpacing,
              collapsedHeight: collapsed,
              expandedHeight: expandedHeight,
              floating: floating,
              pinned: pinned || !floating,
              snap: snap,
              stretch: stretch,
              shape: shape,
              toolbarHeight: toolbarHeight,
              leadingWidth: leadingWidth,
              titleTextStyle: titleTextStyle,
              forceMaterialTransparency: forceTransparent,
              clipBehavior: clip,
              actionsPadding: actionsPadding,
            ),
            'large' => SliverAppBar.large(
              leading: leading,
              automaticallyImplyLeading: implyLeading,
              title: title,
              actions: acts,
              flexibleSpace: flexibleSpace,
              bottom: bar,
              elevation: elevation,
              scrolledUnderElevation: scrolledUnderElevation,
              shadowColor: shadowColor,
              surfaceTintColor: surfaceTintColor,
              forceElevated: forceElevated,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              primary: primary,
              centerTitle: centerTitle,
              titleSpacing: titleSpacing,
              collapsedHeight: collapsed,
              expandedHeight: expandedHeight,
              floating: floating,
              pinned: pinned || !floating,
              snap: snap,
              stretch: stretch,
              shape: shape,
              toolbarHeight: toolbarHeight,
              leadingWidth: leadingWidth,
              titleTextStyle: titleTextStyle,
              forceMaterialTransparency: forceTransparent,
              clipBehavior: clip,
              actionsPadding: actionsPadding,
            ),
            _ => SliverAppBar(
              leading: leading,
              automaticallyImplyLeading: implyLeading,
              title: title,
              actions: acts,
              flexibleSpace: flexibleSpace,
              bottom: bar,
              elevation: elevation,
              scrolledUnderElevation: scrolledUnderElevation,
              shadowColor: shadowColor,
              surfaceTintColor: surfaceTintColor,
              forceElevated: forceElevated,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              primary: primary,
              centerTitle: centerTitle,
              titleSpacing: titleSpacing,
              collapsedHeight: collapsed,
              expandedHeight: expandedHeight,
              floating: floating,
              pinned: pinned,
              snap: snap,
              stretch: stretch,
              shape: shape,
              toolbarHeight: toolbarHeight,
              leadingWidth: leadingWidth,
              titleTextStyle: titleTextStyle,
              forceMaterialTransparency: forceTransparent,
              clipBehavior: clip,
              actionsPadding: actionsPadding,
            ),
          };
        },
      );
    },
  ),
  UiWidget(
    'FlexibleSpaceBar',
    group: UiGroup.sliver,
    doc: 'What an expanded SliverAppBar shows: a background that collapses into the title.',
    params: <UiParam>[
      p('title', 'Widget|String'),
      p('background', 'Widget', 'Usually an Image.'),
      p('centerTitle', 'bool'),
      p('titlePadding', 'EdgeInsets'),
      e('collapseMode', CollapseMode.values, null, 'parallax'),
      p('stretchModes', 'List<String>', '`zoomBackground`, `blurBackground`, `fadeTitle`.'),
      p('expandedTitleScale', 'double', null, '1.5'),
    ],
    build: (UiArgs a) => FlexibleSpaceBar(
      title: a.label(const ['title']),
      background: a.optionalChild(const ['background']),
      centerTitle: a.boolean(const ['centerTitle']),
      titlePadding: a.edgeInsets(const ['titlePadding']),
      collapseMode: a.enumValue(CollapseMode.values, const ['collapseMode']) ?? CollapseMode.parallax,
      stretchModes: a.list<StretchMode>(const ['stretchModes'], (List<Object> k) => a.enumValue(StretchMode.values, k)) ??
          const <StretchMode>[StretchMode.zoomBackground],
      expandedTitleScale: (a.number(const ['expandedTitleScale']) ?? 1.5).clamp(1, double.infinity),
    ),
  ),
  UiWidget(
    'SliverFillRemaining',
    group: UiGroup.sliver,
    doc: 'Fills whatever is left of the viewport -- an empty state, a footer pushed to the bottom.',
    params: <UiParam>[
      p('hasScrollBody', 'bool', 'False when the child is not itself scrollable.', 'true'),
      p('fillOverscroll', 'bool', null, 'false'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => SliverFillRemaining(
      hasScrollBody: a.boolean(const ['hasScrollBody']) ?? true,
      fillOverscroll: a.boolean(const ['fillOverscroll']) ?? false,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'SliverFillViewport',
    group: UiGroup.sliver,
    doc: 'Children that each fill the viewport (or `viewportFraction` of it) -- pages, as a sliver.',
    params: <UiParam>[p('viewportFraction', 'double', null, '1'), p('padEnds', 'bool', null, 'true'), p('children', 'List<Widget>')],
    build: (UiArgs a) => SliverFillViewport(
      viewportFraction: (a.number(const ['viewportFraction']) ?? 1).clamp(0.01, double.infinity),
      padEnds: a.boolean(const ['padEnds']) ?? true,
      delegate: SliverChildListDelegate(a.children(const ['children'])),
    ),
  ),
  UiWidget(
    'SliverSafeArea',
    group: UiGroup.sliver,
    doc: 'Insets a sliver away from notches and system bars.',
    params: <UiParam>[
      p('left', 'bool', null, 'true'),
      p('top', 'bool', null, 'true'),
      p('right', 'bool', null, 'true'),
      p('bottom', 'bool', null, 'true'),
      p('minimum', 'EdgeInsets'),
      p('sliver', 'Widget'),
    ],
    build: (UiArgs a) => SliverSafeArea(
      left: a.boolean(const ['left']) ?? true,
      top: a.boolean(const ['top']) ?? true,
      right: a.boolean(const ['right']) ?? true,
      bottom: a.boolean(const ['bottom']) ?? true,
      minimum: a.edgeInsets(const ['minimum'])?.resolve(Directionality.maybeOf(a.context)) ?? EdgeInsets.zero,
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverOpacity',
    group: UiGroup.sliver,
    doc: 'Makes a sliver partly transparent.',
    params: <UiParam>[p('opacity', 'double', null, '1'), p('alwaysIncludeSemantics', 'bool', null, 'false'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverOpacity(
      opacity: (a.number(const ['opacity']) ?? 1).clamp(0, 1),
      alwaysIncludeSemantics: a.boolean(const ['alwaysIncludeSemantics']) ?? false,
      sliver: a.optionalChild(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverVisibility',
    group: UiGroup.sliver,
    doc: 'Shows a sliver or a replacement sliver.',
    params: <UiParam>[
      p('visible', 'bool', null, 'true'),
      p('replacementSliver', 'Widget'),
      p('maintainState', 'bool', null, 'false'),
      p('maintainAnimation', 'bool', null, 'false'),
      p('maintainSize', 'bool', null, 'false'),
      p('sliver', 'Widget'),
    ],
    build: (UiArgs a) {
      final bool maintainSize = a.boolean(const ['maintainSize']) ?? false;
      final bool askedAnimation = a.boolean(const ['maintainAnimation']) ?? false;
      final bool askedState = a.boolean(const ['maintainState']) ?? false;
      final bool maintainAnimation = maintainSize || askedAnimation;
      return SliverVisibility(
        visible: a.boolean(const ['visible']) ?? true,
        replacementSliver: a.optionalChild(const ['replacementSliver']) ?? const SliverToBoxAdapter(),
        maintainState: maintainAnimation || askedState,
        maintainAnimation: maintainAnimation,
        maintainSize: maintainSize,
        sliver: a.child(const ['sliver']),
      );
    },
  ),
  UiWidget(
    'SliverMainAxisGroup',
    group: UiGroup.sliver,
    doc: 'Slivers grouped along the scroll, so a pinned header inside stays only while its group is on screen.',
    params: <UiParam>[p('slivers', 'List<Widget>')],
    build: (UiArgs a) => SliverMainAxisGroup(slivers: a.children(const ['slivers'])),
  ),
  UiWidget(
    'SliverCrossAxisGroup',
    group: UiGroup.sliver,
    doc: 'Slivers side by side across the scroll.',
    params: <UiParam>[p('slivers', 'List<Widget>')],
    build: (UiArgs a) => SliverCrossAxisGroup(slivers: a.children(const ['slivers'])),
  ),
  UiWidget(
    'PinnedHeaderSliver',
    group: UiGroup.sliver,
    doc: 'A header that sticks to the top as everything else scrolls under it.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => PinnedHeaderSliver(child: a.optionalChild(const ['child'])),
  ),
  UiWidget(
    'SliverFloatingHeader',
    group: UiGroup.sliver,
    doc: 'A header that scrolls away and slides back as soon as you scroll up.',
    params: <UiParam>[e('snapMode', FloatingHeaderSnapMode.values), p('child', 'Widget')],
    build: (UiArgs a) => SliverFloatingHeader(
      snapMode: a.enumValue(FloatingHeaderSnapMode.values, const ['snapMode']),
      child: a.child(const ['child']),
    ),
  ),
  UiWidget(
    'DecoratedSliver',
    group: UiGroup.sliver,
    doc: 'Paints a decoration behind a whole sliver -- a card behind a list section.',
    params: <UiParam>[p('decoration', 'Decoration'), e('position', DecorationPosition.values, null, 'background'), p('sliver', 'Widget')],
    build: (UiArgs a) => DecoratedSliver(
      decoration: a.decoration(const ['decoration']) ?? const BoxDecoration(),
      position: a.enumValue(DecorationPosition.values, const ['position']) ?? DecorationPosition.background,
      sliver: a.optionalChild(const ['sliver']),
    ),
  ),
  UiWidget(
    'CupertinoSliverNavigationBar',
    group: UiGroup.sliver,
    doc: 'The iOS large-title bar that shrinks to a regular bar as you scroll.',
    params: <UiParam>[
      p('largeTitle', 'Widget|String'),
      p('leading', 'Widget|Icon'),
      p('automaticallyImplyLeading', 'bool', null, 'true'),
      p('previousPageTitle', 'String'),
      p('middle', 'Widget|String', 'The small title once collapsed.'),
      p('alwaysShowMiddle', 'bool', null, 'true'),
      p('trailing', 'Widget|Icon'),
      p('backgroundColor', 'Color'),
      p('automaticBackgroundVisibility', 'bool', null, 'true'),
      p('enableBackgroundFilterBlur', 'bool', null, 'true'),
      p('padding', 'EdgeInsets'),
      p('stretch', 'bool', null, 'false'),
    ],
    build: (UiArgs a) => CupertinoSliverNavigationBar(
      largeTitle: a.label(const ['largeTitle']) ?? const Text(''),
      leading: a.iconOrChild(const ['leading']),
      automaticallyImplyLeading: a.boolean(const ['automaticallyImplyLeading']) ?? true,
      previousPageTitle: a.string(const ['previousPageTitle']),
      middle: a.label(const ['middle']),
      alwaysShowMiddle: a.boolean(const ['alwaysShowMiddle']) ?? true,
      trailing: a.iconOrChild(const ['trailing']),
      backgroundColor: a.color(const ['backgroundColor']),
      automaticBackgroundVisibility: a.boolean(const ['automaticBackgroundVisibility']) ?? true,
      enableBackgroundFilterBlur: a.boolean(const ['enableBackgroundFilterBlur']) ?? true,
      padding: a.directionalInsets(const ['padding']),
      stretch: a.boolean(const ['stretch']) ?? false,
    ),
    example: 'SizedBox(height: 300, child: CustomScrollView(slivers: [CupertinoSliverNavigationBar(largeTitle: "Mail"), '
        'SliverFillRemaining(child: Center(child: Text(text: "No messages")))]))',
  ),
  UiWidget(
    'SliverPersistentHeader',
    group: UiGroup.sliver,
    doc: 'A header that collapses from `maxExtent` to `minExtent` as the list scrolls under it, `pinned` to stay '
        'at its minimum or `floating` to come back on the way up. '
        'Give it a `child` and the header is built once and only resized -- that is the cheap one. '
        'Give it a `builder` instead and it is built again every frame it changes size, with '
        '`shrinkOffset` (pixels collapsed), `t` (0 to 1 across the collapse, since rfw cannot divide) and '
        '`overlapsContent`; reach for that only when something must move rather than merely resize. '
        'A `ScrollTransition` inside a `PinnedHeaderSliver` moves without rebuilding at all.',
    params: <UiParam>[
      p('minExtent', 'double', null, '0'),
      p('maxExtent', 'double', null, '0'),
      p('pinned', 'bool', 'Stays at its minimum instead of scrolling away.', 'false'),
      p('floating', 'bool', 'Comes back as soon as the list is scrolled up.', 'false'),
      p('child', 'Widget', 'Built once and resized.'),
      p('builder', 'Builder', 'Built again as it collapses: `(h) => ...` with `h.shrinkOffset`, `h.t`, `h.overlapsContent`.'),
    ],
    build: (UiArgs a) {
      final double min = a.number(const ['minExtent']) ?? 0;
      final double max = a.number(const ['maxExtent']) ?? 0;
      final bool pinned = a.boolean(const ['pinned']) ?? false;
      final bool floating = a.boolean(const ['floating']) ?? false;
      final Widget? child = a.optionalChild(const ['child']);
      return SliverPersistentHeader(
        pinned: pinned,
        floating: floating,
        delegate: UiHeaderDelegate(args: a, min: min, max: math.max(max, min), child: child),
      );
    },
    example: 'CustomScrollView(slivers: ['
        'SliverPersistentHeader(minExtent: 60, maxExtent: 160, pinned: true, '
        'child: ColoredBox(color: .primaryContainer, child: Center(child: Text(text: "Header")))), '
        'SliverToBoxAdapter(child: SizedBox(height: 600))])',
  ),
  UiWidget(
    'SliverResizingHeader',
    group: UiGroup.sliver,
    doc: 'A pinned header that shrinks from `maxExtent` to `minExtent` as the list scrolls, and no further. '
        'Simpler than SliverPersistentHeader: no builder, and the child is laid out once at each size.',
    params: <UiParam>[
      p('minExtent', 'double', 'Nothing by default.', '0'),
      p('maxExtent', 'double', "The child's own height by default."),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double? min = a.number(const ['minExtent']);
      final double? max = a.number(const ['maxExtent']);
      return SliverResizingHeader(
        minExtentPrototype: min == null ? null : SizedBox(height: min),
        maxExtentPrototype: max == null ? null : SizedBox(height: max),
        child: a.optionalChild(const ['child']),
      );
    },
  ),
  UiWidget(
    'SliverLayoutBuilder',
    group: UiGroup.sliver,
    doc: 'Builds a sliver from where the scroll view has got to: `(s) => ...` with `s.scrollOffset` (how far this '
        'sliver has been scrolled), `s.precedingScrollExtent`, `s.remainingPaintExtent`, `s.crossAxisExtent` and '
        '`s.breakpoint`. It builds again whenever those change, which while scrolling is every frame: for an '
        'effect rather than a layout, `ScrollTransition` moves without rebuilding.',
    params: <UiParam>[p('builder', 'Builder')],
    build: (UiArgs a) => SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints c) => a.builder(const ['builder'], <String, Object?>{
        'scrollOffset': c.scrollOffset,
        'precedingScrollExtent': c.precedingScrollExtent,
        'remainingPaintExtent': c.remainingPaintExtent,
        'crossAxisExtent': c.crossAxisExtent,
        'breakpoint': breakpointOf(c.crossAxisExtent),
      }),
    ),
  ),
  UiWidget(
    'SliverCrossAxisExpanded',
    group: UiGroup.sliver,
    doc: 'Gives a sliver a share of the width inside a `SliverCrossAxisGroup`, as Expanded does in a Row. '
        'Without one, every sliver in the group takes what it asks for.',
    params: <UiParam>[p('flex', 'int', null, '1'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverCrossAxisExpanded(
      flex: a.integer(const ['flex']) ?? 1,
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverConstrainedCrossAxis',
    group: UiGroup.sliver,
    doc: 'Caps how wide the sliver inside it may be: a column of text that stops widening on a tablet.',
    params: <UiParam>[p('maxExtent', 'double', null, '0'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverConstrainedCrossAxis(
      maxExtent: a.number(const ['maxExtent']) ?? 0,
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverPrototypeExtentList',
    group: UiGroup.sliver,
    doc: 'Every row the height of `prototypeItem`, which is laid out once and never shown. '
        'The viewport then knows where every row is without laying any of them out, as SliverList cannot.',
    params: <UiParam>[p('prototypeItem', 'Widget'), p('children', 'List<Widget>')],
    build: (UiArgs a) {
      final Widget prototype = a.optionalChild(const ['prototypeItem']) ?? const SizedBox(height: 48);
      final UiLazyChildren? rows = a.lazyChildren(const ['children']);
      return SliverPrototypeExtentList.builder(
        prototypeItem: prototype,
        itemCount: rows?.length ?? 0,
        itemBuilder: (BuildContext context, int index) => rows!.build(index),
      );
    },
  ),
  UiWidget(
    'SliverPrototypeExtentList.builder',
    group: UiGroup.sliver,
    needsUiRuntime: true,
    doc: 'A `SliverPrototypeExtentList` whose rows `itemBuilder` builds from `items`. '
        "Needs UiRuntime; on rfw's Runtime, write `SliverPrototypeExtentList(children: [...for r in items: ...])`.",
    params: <UiParam>[p('prototypeItem', 'Widget'), ...itemBuilderParams()],
    build: (UiArgs a) {
      final Widget prototype = a.optionalChild(const ['prototypeItem']) ?? const SizedBox(height: 48);
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime(
          'SliverPrototypeExtentList.builder',
          'SliverPrototypeExtentList(children: [...for r in items: ...])',
        );
      }
      return SliverPrototypeExtentList.builder(
        prototypeItem: prototype,
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) => rows.build(index),
      );
    },
  ),
  UiWidget(
    'SliverVariedExtentList',
    group: UiGroup.sliver,
    doc: 'Row *n* is `extents[n]` tall, so the viewport knows where every row is without laying any out. '
        'Fewer extents than rows and it starts again from the first, which is how two alternating heights are '
        'written as `extents: [80, 120]`.',
    params: <UiParam>[
      p('extents', 'List<double>', 'One height per row, repeated from the start when there are fewer than rows.'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) {
      final List<double> extents = a.list<double>(const ['extents'], a.number) ?? const <double>[];
      final UiLazyChildren? rows = a.lazyChildren(const ['children']);
      return SliverVariedExtentList.builder(
        itemCount: rows?.length ?? 0,
        itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) => _extentAt(extents, index),
        itemBuilder: (BuildContext context, int index) => rows!.build(index),
      );
    },
  ),
  UiWidget(
    'SliverVariedExtentList.builder',
    group: UiGroup.sliver,
    needsUiRuntime: true,
    doc: 'A `SliverVariedExtentList` whose rows `itemBuilder` builds from `items`. '
        "Needs UiRuntime; on rfw's Runtime, write `SliverVariedExtentList(children: [...for r in items: ...])`.",
    params: <UiParam>[p('extents', 'List<double>'), ...itemBuilderParams()],
    build: (UiArgs a) {
      final List<double> extents = a.list<double>(const ['extents'], a.number) ?? const <double>[];
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime(
          'SliverVariedExtentList.builder',
          'SliverVariedExtentList(children: [...for r in items: ...])',
        );
      }
      return SliverVariedExtentList.builder(
        itemCount: rows.length,
        itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) => _extentAt(extents, index),
        itemBuilder: (BuildContext context, int index) => rows.build(index),
      );
    },
  ),
  UiWidget(
    'SliverAnimatedOpacity',
    group: UiGroup.sliver,
    doc: 'Fades a sliver when its `opacity` changes, as Opacity does for a box.',
    params: <UiParam>[
      p('opacity', 'double', null, '1'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('alwaysIncludeSemantics', 'bool', null, 'false'),
      p('onEnd', 'event'),
      p('sliver', 'Widget'),
    ],
    build: (UiArgs a) => SliverAnimatedOpacity(
      opacity: (a.number(const ['opacity']) ?? 1).clamp(0.0, 1.0),
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      alwaysIncludeSemantics: a.boolean(const ['alwaysIncludeSemantics']) ?? false,
      onEnd: a.onTap(const ['onEnd']),
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverIgnorePointer',
    group: UiGroup.sliver,
    doc: 'Lets taps fall through the sliver inside it, as IgnorePointer does for a box.',
    params: <UiParam>[p('ignoring', 'bool', null, 'true'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverIgnorePointer(
      ignoring: a.boolean(const ['ignoring']) ?? true,
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverOffstage',
    group: UiGroup.sliver,
    doc: 'Keeps the sliver inside it in the tree, with its state, but gives it no space and draws nothing.',
    params: <UiParam>[p('offstage', 'bool', null, 'true'), p('sliver', 'Widget')],
    build: (UiArgs a) => SliverOffstage(
      offstage: a.boolean(const ['offstage']) ?? true,
      sliver: a.child(const ['sliver']),
    ),
  ),
  UiWidget(
    'SliverReorderableList',
    group: UiGroup.sliver,
    doc: 'Rows dragged into a new order, inside a CustomScrollView. `onReorder` fires with '
        '`{ oldIndex, newIndex }`, where `newIndex` is already where the row lands once it has been taken out; move the item in your data there. '
        'Flutter draws no drag handles here: wrap part of each row in a `ReorderableDragStartListener`, or '
        'press and hold.',
    params: <UiParam>[
      p('onReorder', 'event', 'Receives `{ oldIndex, newIndex }`.'),
      p('itemExtent', 'double'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) {
      final ValueChanged<Map<String, Object?>>? handler = a.onValues(const ['onReorder']);
      final List<Widget> children = a.children(const ['children']);
      return SliverReorderableList(
        itemExtent: a.number(const ['itemExtent']),
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => ReorderableDelayedDragStartListener(
          key: children[index].key ?? ValueKey<int>(index),
          index: index,
          child: children[index],
        ),
        onReorderItem: (int oldIndex, int newIndex) =>
            handler?.call(<String, Object?>{'oldIndex': oldIndex, 'newIndex': newIndex}),
      );
    },
  ),
  UiWidget(
    'NestedScrollView',
    group: UiGroup.sliver,
    doc: 'A collapsing header over a body that scrolls on its own: tabs under an app bar, each tab keeping its '
        'place. Put the app bar in `headerSlivers` inside a `SliverOverlapAbsorber`, and start each scroll view '
        "in the body with a `SliverOverlapInjector`, or the body's first rows hide behind a pinned bar.",
    params: <UiParam>[
      p('headerSlivers', 'List<Widget>', 'The slivers above the body: usually one SliverOverlapAbsorber over a SliverAppBar.'),
      p('body', 'Widget'),
      p('floatHeaderSlivers', 'bool', 'Let a floating header come back before the body is back at the top.', 'false'),
      e('scrollDirection', Axis.values, null, 'vertical'),
      p('reverse', 'bool', null, 'false'),
      p('physics', 'String'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
    ],
    build: (UiArgs a) {
      final List<Widget> header = a.children(const ['headerSlivers']);
      return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerScrolled) => header,
        body: a.child(const ['body']),
        floatHeaderSlivers: a.boolean(const ['floatHeaderSlivers']) ?? false,
        scrollDirection: a.enumValue(Axis.values, const ['scrollDirection']) ?? Axis.vertical,
        reverse: a.boolean(const ['reverse']) ?? false,
        physics: a.physics(const ['physics']),
        clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.hardEdge,
      );
    },
  ),
  UiWidget(
    'SliverOverlapAbsorber',
    group: UiGroup.sliver,
    doc: 'Takes the space a pinned header in a NestedScrollView would overlap and hands it to the '
        '`SliverOverlapInjector`s in the body. Outside a NestedScrollView it is simply its sliver.',
    params: <UiParam>[p('sliver', 'Widget')],
    build: (UiArgs a) => UiOverlap(sliver: a.optionalChild(const ['sliver'])),
  ),
  UiWidget(
    'SliverOverlapInjector',
    group: UiGroup.sliver,
    doc: 'Puts back the space the `SliverOverlapAbsorber` took, at the top of one of the body\'s scroll views. '
        'Outside a NestedScrollView it is nothing at all.',
    params: <UiParam>[p('sliver', 'Widget')],
    build: (UiArgs a) => UiOverlap(sliver: a.optionalChild(const ['sliver']), inject: true),
  ),

];

/// A SliverList of [rows], built as they scroll into view, with [separator]
/// between every two when there is one.
Widget _sliverList(UiArgs a, UiRows? rows, {IndexedWidgetBuilder? separator}) => UiEndReached(
  length: rows?.length ?? 0,
  onEnd: a.onTap(const ['onEndReached']),
  rows: rows,
  builder: (IndexedWidgetBuilder row) => separator == null
      ? SliverList.builder(itemCount: rows?.length ?? 0, itemBuilder: row)
      : SliverList.separated(itemCount: rows?.length ?? 0, itemBuilder: row, separatorBuilder: separator),
);

/// `extents[index]`, starting again from the first when there are fewer
/// extents than rows, and 48 when there are none.
double _extentAt(List<double> extents, int index) =>
    extents.isEmpty ? 48 : extents[index % extents.length];

/// A `SliverPersistentHeader`'s content.
///
/// With a [child] it hands back the same widget at every size, so the element
/// is reused and the remote subtree is never rebuilt, however far the header
/// is scrolled. With a builder it is built again whenever the size changes,
/// which is what a builder is for.
class UiHeaderDelegate extends SliverPersistentHeaderDelegate {
  const UiHeaderDelegate({required this.args, required this.min, required this.max, required this.child});

  final UiArgs args;
  final double min;
  final double max;
  final Widget? child;

  @override
  double get minExtent => min;

  @override
  double get maxExtent => max;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double span = max - min;
    return args.optionalBuilder(const <Object>['builder'], <String, Object?>{
          'shrinkOffset': shrinkOffset,
          'overlapsContent': overlapsContent,
          't': span <= 0 ? 0.0 : (shrinkOffset / span).clamp(0.0, 1.0),
        }) ??
        child ??
        const SizedBox.shrink();
  }

  @override
  bool shouldRebuild(UiHeaderDelegate old) =>
      old.min != min || old.max != max || old.child != child || old.args != args;
}

/// `SliverOverlapAbsorber` and `SliverOverlapInjector`, which both need the
/// handle a [NestedScrollView] owns.
///
/// Flutter's `sliverOverlapAbsorberHandleFor` asserts when there is no
/// NestedScrollView above, and a remote file is data: it may be written
/// wrongly, or previewed on its own. With none above, the absorber is its
/// sliver and the injector is nothing.
class UiOverlap extends StatelessWidget {
  const UiOverlap({super.key, this.sliver, this.inject = false});

  final Widget? sliver;
  final bool inject;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<NestedScrollView>() == null) {
      return inject ? const SliverToBoxAdapter() : (sliver ?? const SliverToBoxAdapter());
    }
    final SliverOverlapAbsorberHandle handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    if (inject) {
      return SliverOverlapInjector(handle: handle, sliver: sliver);
    }
    return SliverOverlapAbsorber(handle: handle, sliver: sliver);
  }
}
