import 'package:flutter/material.dart';

import 'args.dart';
import 'slot.dart';
import 'spec.dart';
import 'state.dart';

/// Screens and the ways between them: Scaffold, app bars, tabs, navigation
/// bars, rails, drawers and steppers.
///
/// A selected index is kept by the widget and reported as `{ value: <index> }`,
/// so a bottom bar highlights the tab you tapped even before the data behind
/// it changes -- bind `selectedIndex` to data and use `ui.set` to switch the
/// body with it.
final List<UiWidget> navigationWidgets = <UiWidget>[
  UiWidget(
    'Scaffold',
    group: UiGroup.navigation,
    doc: 'A screen: app bar, body, floating button, drawers, bottom bar. The app bar\'s height is its own -- '
        'an AppBar with a TabBar under it is as tall as both.',
    params: <UiParam>[
      p('appBar', 'Widget'),
      p('body', 'Widget'),
      p('floatingActionButton', 'Widget'),
      p('floatingActionButtonLocation', 'String', '`endFloat`, `centerFloat`, `startFloat`, `endDocked`, `centerDocked`, `endTop`, `miniEndFloat`, ...'),
      p('persistentFooterButtons', 'List<Widget>'),
      p('drawer', 'Widget'),
      p('endDrawer', 'Widget'),
      p('bottomNavigationBar', 'Widget'),
      p('bottomSheet', 'Widget'),
      p('backgroundColor', 'Color'),
      p('resizeToAvoidBottomInset', 'bool'),
      p('primary', 'bool', null, 'true'),
      p('extendBody', 'bool', null, 'false'),
      p('extendBodyBehindAppBar', 'bool', null, 'false'),
      p('drawerScrimColor', 'Color'),
      p('drawerEdgeDragWidth', 'double'),
      p('drawerEnableOpenDragGesture', 'bool', null, 'true'),
      p('endDrawerEnableOpenDragGesture', 'bool', null, 'true'),
    ],
    build: (UiArgs a) {
      final Widget? appBar = a.optionalChild(const ['appBar']);
      final Widget? body = a.optionalChild(const ['body']);
      final Widget? fab = a.optionalChild(const ['floatingActionButton']);
      final FloatingActionButtonLocation? fabLocation = _fabLocations[a.string(const ['floatingActionButtonLocation'])];
      final List<Widget> footer = a.children(const ['persistentFooterButtons']);
      final Widget? drawer = a.optionalChild(const ['drawer']);
      final Widget? endDrawer = a.optionalChild(const ['endDrawer']);
      final Widget? bottomNavigationBar = a.optionalChild(const ['bottomNavigationBar']);
      final Widget? bottomSheet = a.optionalChild(const ['bottomSheet']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final bool? resizeToAvoidBottomInset = a.boolean(const ['resizeToAvoidBottomInset']);
      final bool primary = a.boolean(const ['primary']) ?? true;
      final bool extendBody = a.boolean(const ['extendBody']) ?? false;
      final bool extendBodyBehindAppBar = a.boolean(const ['extendBodyBehindAppBar']) ?? false;
      final Color? drawerScrimColor = a.color(const ['drawerScrimColor']);
      final double? drawerEdgeDragWidth = a.number(const ['drawerEdgeDragWidth']);
      final bool drawerDrag = a.boolean(const ['drawerEnableOpenDragGesture']) ?? true;
      final bool endDrawerDrag = a.boolean(const ['endDrawerEnableOpenDragGesture']) ?? true;
      return UiSlots(
        initial: const <String, SlotValue>{'appBar': SlotValue(Size.fromHeight(kToolbarHeight))},
        builder: (BuildContext context, UiSlot Function(String, Widget) slot) => Scaffold(
          appBar: appBar == null ? null : slot('appBar', appBar),
          body: body,
          floatingActionButton: fab,
          floatingActionButtonLocation: fabLocation,
          persistentFooterButtons: footer.isEmpty ? null : footer,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          bottomSheet: bottomSheet,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          primary: primary,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawerScrimColor: drawerScrimColor,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          drawerEnableOpenDragGesture: drawerDrag,
          endDrawerEnableOpenDragGesture: endDrawerDrag,
        ),
      );
    },
  ),
  UiWidget(
    'AppBar',
    group: UiGroup.navigation,
    doc: 'The bar at the top of a Scaffold. `title` may be a string; `bottom` is usually a TabBar.',
    params: <UiParam>[
      p('leading', 'Widget|Icon'),
      p('automaticallyImplyLeading', 'bool', 'Show a back or menu button when there is somewhere to go.', 'true'),
      p('title', 'Widget|String'),
      p('actions', 'List<Widget>'),
      p('flexibleSpace', 'Widget'),
      p('bottom', 'Widget', 'Usually a TabBar.'),
      p('elevation', 'double'),
      p('scrolledUnderElevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('backgroundColor', 'Color'),
      p('foregroundColor', 'Color'),
      p('iconTheme', 'Map', '`{ color, size, opacity }` for the leading icon.'),
      p('actionsIconTheme', 'Map', '`{ color, size, opacity }` for the actions.'),
      p('primary', 'bool', null, 'true'),
      p('centerTitle', 'bool'),
      p('titleSpacing', 'double'),
      p('toolbarOpacity', 'double', null, '1'),
      p('bottomOpacity', 'double', null, '1'),
      p('toolbarHeight', 'double'),
      p('leadingWidth', 'double'),
      p('toolbarTextStyle', 'TextStyle'),
      p('titleTextStyle', 'TextStyle'),
      p('shape', 'ShapeBorder'),
      p('forceMaterialTransparency', 'bool', null, 'false'),
      e('clipBehavior', Clip.values),
      p('actionsPadding', 'EdgeInsets'),
    ],
    build: (UiArgs a) {
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
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? foregroundColor = a.color(const ['foregroundColor']);
      final IconThemeData? iconTheme = _iconTheme(a, ['iconTheme']);
      final IconThemeData? actionsIconTheme = _iconTheme(a, ['actionsIconTheme']);
      final bool primary = a.boolean(const ['primary']) ?? true;
      final bool? centerTitle = a.boolean(const ['centerTitle']);
      final double? titleSpacing = a.spacing(const ['titleSpacing']);
      final double toolbarOpacity = a.number(const ['toolbarOpacity']) ?? 1;
      final double bottomOpacity = a.number(const ['bottomOpacity']) ?? 1;
      final double? toolbarHeight = a.number(const ['toolbarHeight']);
      final double? leadingWidth = a.number(const ['leadingWidth']);
      final TextStyle? toolbarTextStyle = a.textStyle(const ['toolbarTextStyle']);
      final TextStyle? titleTextStyle = a.textStyle(const ['titleTextStyle']);
      final ShapeBorder? shape = a.shape(const ['shape']);
      final bool forceTransparent = a.boolean(const ['forceMaterialTransparency']) ?? false;
      final Clip? clip = a.enumValue(Clip.values, const ['clipBehavior']);
      final EdgeInsetsGeometry? actionsPadding = a.edgeInsets(const ['actionsPadding']);
      return UiSlots(
        initial: const <String, SlotValue>{'bottom': SlotValue(Size.fromHeight(kTextTabBarHeight))},
        builder: (BuildContext context, UiSlot Function(String, Widget) slot) {
          final AppBar bar = AppBar(
            leading: leading,
            automaticallyImplyLeading: implyLeading,
            title: title,
            actions: actions.isEmpty ? null : actions,
            flexibleSpace: flexibleSpace,
            bottom: bottom == null ? null : slot('bottom', bottom),
            elevation: elevation,
            scrolledUnderElevation: scrolledUnderElevation,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            iconTheme: iconTheme,
            actionsIconTheme: actionsIconTheme,
            primary: primary,
            centerTitle: centerTitle,
            titleSpacing: titleSpacing,
            toolbarOpacity: toolbarOpacity,
            bottomOpacity: bottomOpacity,
            toolbarHeight: toolbarHeight,
            leadingWidth: leadingWidth,
            toolbarTextStyle: toolbarTextStyle,
            titleTextStyle: titleTextStyle,
            shape: shape,
            forceMaterialTransparency: forceTransparent,
            clipBehavior: clip,
            actionsPadding: actionsPadding,
          );
          UiSlot.report(context, bar);
          return bar;
        },
      );
    },
    example: 'AppBar(title: "Inbox", actions: [IconButton(icon: "search", onPressed: event "search" {})])',
  ),
  UiWidget(
    'BottomAppBar',
    group: UiGroup.navigation,
    doc: 'A bar along the bottom of a Scaffold, for actions; pairs with a docked FloatingActionButton.',
    params: <UiParam>[
      p('color', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('height', 'double'),
      p('padding', 'EdgeInsets'),
      e('clipBehavior', Clip.values, null, 'none'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => BottomAppBar(
      color: a.color(const ['color']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      height: a.number(const ['height']),
      padding: a.edgeInsets(const ['padding']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']) ?? Clip.none,
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'NavigationBar',
    group: UiGroup.navigation,
    doc: 'The Material 3 bottom bar. `destinations` are NavigationDestination widgets; '
        '`onDestinationSelected` receives `{ value: <index> }`.',
    params: <UiParam>[
      p('destinations', 'List<Widget>'),
      p('selectedIndex', 'int', null, '0'),
      p('onDestinationSelected', 'event<int>'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('indicatorColor', 'Color'),
      p('indicatorShape', 'ShapeBorder'),
      p('height', 'double'),
      e('labelBehavior', NavigationDestinationLabelBehavior.values),
      p('labelTextStyle', 'TextStyle', 'A style, or a map by state.'),
      p('labelPadding', 'EdgeInsets'),
      p('overlayColor', 'Color'),
      p('animationDuration', 'Duration'),
    ],
    build: (UiArgs a) {
      final List<Widget> destinations = a.children(const ['destinations']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? elevation = a.number(const ['elevation']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final Color? indicatorColor = a.color(const ['indicatorColor']);
      final ShapeBorder? indicatorShape = a.shape(const ['indicatorShape']);
      final double? height = a.number(const ['height']);
      final NavigationDestinationLabelBehavior? labelBehavior =
          a.enumValue(NavigationDestinationLabelBehavior.values, const ['labelBehavior']);
      final WidgetStateProperty<TextStyle?>? labelTextStyle = a.state<TextStyle>(const ['labelTextStyle'], a.textStyle);
      final EdgeInsetsGeometry? labelPadding = a.edgeInsets(const ['labelPadding']);
      final WidgetStateProperty<Color?>? overlayColor = a.stateColor(const ['overlayColor']);
      final Duration? animationDuration = a.duration(const ['animationDuration']);
      final int? selectedIndex = a.integer(const ['selectedIndex']);
      final ValueChanged<int>? onSelected = a.onValue<int>(const ['onDestinationSelected']);
      // Flutter asserts at least two destinations.
      if (destinations.length < 2) {
        return const SizedBox.shrink();
      }
      return UiValue<int>(
        value: selectedIndex,
        initial: 0,
        onChanged: onSelected,
        builder: (BuildContext context, int index, ValueChanged<int>? onSelected) => NavigationBar(
          destinations: destinations,
          selectedIndex: index.clamp(0, destinations.length - 1),
          onDestinationSelected: onSelected,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          indicatorColor: indicatorColor,
          indicatorShape: indicatorShape,
          height: height,
          labelBehavior: labelBehavior,
          labelTextStyle: labelTextStyle,
          labelPadding: labelPadding,
          overlayColor: overlayColor,
          animationDuration: animationDuration,
        ),
      );
    },
    example: 'NavigationBar(selectedIndex: 0, onDestinationSelected: event "ui.set" { key: "tab" }, destinations: ['
        'NavigationDestination(icon: "home_outlined", selectedIcon: "home", label: "Home"), '
        'NavigationDestination(icon: "person_outline", selectedIcon: "person", label: "Profile")])',
  ),
  UiWidget(
    'NavigationDestination',
    group: UiGroup.navigation,
    doc: 'One destination of a NavigationBar.',
    params: <UiParam>[
      p('icon', 'Widget|Icon'),
      p('selectedIcon', 'Widget|Icon'),
      p('label', 'String'),
      p('tooltip', 'String'),
      p('enabled', 'bool', null, 'true'),
    ],
    build: (UiArgs a) => NavigationDestination(
      icon: a.iconOrChild(const ['icon']) ?? const SizedBox.square(dimension: 24),
      selectedIcon: a.iconOrChild(const ['selectedIcon']),
      label: a.string(const ['label']) ?? '',
      tooltip: a.string(const ['tooltip']),
      enabled: a.boolean(const ['enabled']) ?? true,
    ),
  ),
  UiWidget(
    'NavigationRail',
    group: UiGroup.navigation,
    doc: 'Destinations down the side of a wide screen. `destinations: [{ icon, selectedIcon, label }]`; '
        '`onDestinationSelected` receives `{ value: <index> }`.',
    params: <UiParam>[
      p('destinations', 'List<Map>', 'Each `{ icon, selectedIcon, label, disabled, padding }`.'),
      p('selectedIndex', 'int'),
      p('onDestinationSelected', 'event<int>'),
      p('extended', 'bool', null, 'false'),
      e('labelType', NavigationRailLabelType.values),
      p('leading', 'Widget'),
      p('trailing', 'Widget'),
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('groupAlignment', 'double', '-1 top, 0 centre, 1 bottom.'),
      p('minWidth', 'double'),
      p('minExtendedWidth', 'double'),
      p('useIndicator', 'bool'),
      p('indicatorColor', 'Color'),
      p('indicatorShape', 'ShapeBorder'),
      p('selectedLabelTextStyle', 'TextStyle'),
      p('unselectedLabelTextStyle', 'TextStyle'),
      p('selectedIconTheme', 'Map'),
      p('unselectedIconTheme', 'Map'),
    ],
    build: (UiArgs a) {
      final List<NavigationRailDestination> destinations = a.list<NavigationRailDestination>(const ['destinations'], (List<Object> k) {
            return NavigationRailDestination(
              icon: a.iconOrChild(<Object>[...k, 'icon']) ?? const SizedBox.square(dimension: 24),
              selectedIcon: a.iconOrChild(<Object>[...k, 'selectedIcon']),
              label: a.label(<Object>[...k, 'label']) ?? const SizedBox.shrink(),
              disabled: a.boolean(<Object>[...k, 'disabled']) ?? false,
              padding: a.edgeInsets(<Object>[...k, 'padding']),
            );
          }) ??
          const <NavigationRailDestination>[];
      final bool extended = a.boolean(const ['extended']) ?? false;
      final NavigationRailLabelType? labelType = a.enumValue(NavigationRailLabelType.values, const ['labelType']);
      final Widget? leading = a.optionalChild(const ['leading']);
      final Widget? trailing = a.optionalChild(const ['trailing']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final double? elevation = a.number(const ['elevation']);
      final double? groupAlignment = a.number(const ['groupAlignment']);
      final double? minWidth = a.number(const ['minWidth']);
      final double? minExtendedWidth = a.number(const ['minExtendedWidth']);
      final bool? useIndicator = a.boolean(const ['useIndicator']);
      final Color? indicatorColor = a.color(const ['indicatorColor']);
      final ShapeBorder? indicatorShape = a.shape(const ['indicatorShape']);
      final TextStyle? selectedLabel = a.textStyle(const ['selectedLabelTextStyle']);
      final TextStyle? unselectedLabel = a.textStyle(const ['unselectedLabelTextStyle']);
      final IconThemeData? selectedIcon = _iconTheme(a, ['selectedIconTheme']);
      final IconThemeData? unselectedIcon = _iconTheme(a, ['unselectedIconTheme']);
      final int? selectedIndex = a.integer(const ['selectedIndex']);
      final ValueChanged<int>? onSelected = a.onValue<int>(const ['onDestinationSelected']);
      if (destinations.length < 2) {
        return const SizedBox.shrink();
      }
      return UiValue<int>(
        value: selectedIndex,
        initial: 0,
        onChanged: onSelected,
        builder: (BuildContext context, int index, ValueChanged<int>? onSelected) => NavigationRail(
          destinations: destinations,
          selectedIndex: index.clamp(0, destinations.length - 1),
          onDestinationSelected: onSelected,
          extended: extended,
          // Flutter asserts an extended rail shows no separate labels.
          labelType: extended ? NavigationRailLabelType.none : labelType,
          leading: leading,
          trailing: trailing,
          backgroundColor: backgroundColor,
          elevation: elevation,
          groupAlignment: groupAlignment,
          minWidth: minWidth,
          minExtendedWidth: minExtendedWidth,
          useIndicator: useIndicator,
          indicatorColor: indicatorColor,
          indicatorShape: indicatorShape,
          selectedLabelTextStyle: selectedLabel,
          unselectedLabelTextStyle: unselectedLabel,
          selectedIconTheme: selectedIcon,
          unselectedIconTheme: unselectedIcon,
        ),
      );
    },
    example: 'SizedBox(height: 300, child: NavigationRail(labelType: "all", destinations: [{ icon: "inbox", label: "Inbox" }, '
        '{ icon: "send", label: "Sent" }]))',
  ),
  UiWidget(
    'BottomNavigationBar',
    group: UiGroup.navigation,
    doc: 'The Material 2 bottom bar. `items: [{ icon, activeIcon, label }]`; `onTap` receives `{ value: <index> }`.',
    params: <UiParam>[
      p('items', 'List<Map>', 'Each `{ icon, activeIcon, label, tooltip, backgroundColor }`.'),
      p('currentIndex', 'int', null, '0'),
      p('onTap', 'event<int>'),
      e('type', BottomNavigationBarType.values),
      p('elevation', 'double'),
      p('backgroundColor', 'Color'),
      p('fixedColor', 'Color'),
      p('selectedItemColor', 'Color'),
      p('unselectedItemColor', 'Color'),
      p('iconSize', 'double', null, '24'),
      p('selectedFontSize', 'double', null, '14'),
      p('unselectedFontSize', 'double', null, '12'),
      p('selectedLabelStyle', 'TextStyle'),
      p('unselectedLabelStyle', 'TextStyle'),
      p('showSelectedLabels', 'bool'),
      p('showUnselectedLabels', 'bool'),
      e('landscapeLayout', BottomNavigationBarLandscapeLayout.values),
    ],
    build: (UiArgs a) {
      final List<BottomNavigationBarItem> items = _barItems(a, ['items']);
      final BottomNavigationBarType? type = a.enumValue(BottomNavigationBarType.values, const ['type']);
      final double? elevation = a.number(const ['elevation']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? fixedColor = a.color(const ['fixedColor']);
      final Color? selectedItemColor = a.color(const ['selectedItemColor']);
      final Color? unselectedItemColor = a.color(const ['unselectedItemColor']);
      final double iconSize = a.number(const ['iconSize']) ?? 24;
      final double selectedFontSize = a.number(const ['selectedFontSize']) ?? 14;
      final double unselectedFontSize = a.number(const ['unselectedFontSize']) ?? 12;
      final TextStyle? selectedLabelStyle = a.textStyle(const ['selectedLabelStyle']);
      final TextStyle? unselectedLabelStyle = a.textStyle(const ['unselectedLabelStyle']);
      final bool? showSelectedLabels = a.boolean(const ['showSelectedLabels']);
      final bool? showUnselectedLabels = a.boolean(const ['showUnselectedLabels']);
      final BottomNavigationBarLandscapeLayout? landscape =
          a.enumValue(BottomNavigationBarLandscapeLayout.values, const ['landscapeLayout']);
      final int? currentIndex = a.integer(const ['currentIndex']);
      final ValueChanged<int>? onTapped = a.onValue<int>(const ['onTap']);
      if (items.length < 2) {
        return const SizedBox.shrink();
      }
      return UiValue<int>(
        value: currentIndex,
        initial: 0,
        onChanged: onTapped,
        builder: (BuildContext context, int index, ValueChanged<int>? onTap) => BottomNavigationBar(
          items: items,
          currentIndex: index.clamp(0, items.length - 1),
          onTap: onTap,
          type: type,
          elevation: elevation,
          backgroundColor: backgroundColor,
          // Flutter asserts on both; selectedItemColor is the newer name.
          fixedColor: selectedItemColor == null ? fixedColor : null,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          iconSize: iconSize,
          selectedFontSize: selectedFontSize,
          unselectedFontSize: unselectedFontSize,
          selectedLabelStyle: selectedLabelStyle,
          unselectedLabelStyle: unselectedLabelStyle,
          showSelectedLabels: showSelectedLabels,
          showUnselectedLabels: showUnselectedLabels,
          landscapeLayout: landscape,
        ),
      );
    },
    example: 'BottomNavigationBar(items: [{ icon: "home", label: "Home" }, { icon: "settings", label: "Settings" }])',
  ),
  UiWidget(
    'DefaultTabController',
    group: UiGroup.navigation,
    doc: 'Coordinates a TabBar and a TabBarView below it. `length` must match the number of tabs.',
    params: <UiParam>[
      p('length', 'int'),
      p('initialIndex', 'int', null, '0'),
      p('animationDuration', 'Duration'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final int length = a.integer(const ['length']) ?? 0;
      return DefaultTabController(
        length: length < 0 ? 0 : length,
        initialIndex: (a.integer(const ['initialIndex']) ?? 0).clamp(0, length <= 0 ? 0 : length - 1),
        animationDuration: a.duration(const ['animationDuration']),
        child: a.child(const ['child']),
      );
    },
    example: 'DefaultTabController(length: 2, child: Column(children: [TabBar(tabs: [Tab(text: "Chats"), Tab(text: "Calls")]), '
        'SizedBox(height: 120, child: TabBarView(children: [Center(child: Text(text: "chats")), Center(child: Text(text: "calls"))]))]))',
  ),
  UiWidget(
    'TabBar',
    group: UiGroup.navigation,
    doc: 'A row of tabs, for an AppBar\'s `bottom` or anywhere above a TabBarView. Needs a DefaultTabController above it; '
        'without one it keeps its own. `variant: "secondary"` is the Material 3 secondary style.',
    params: <UiParam>[
      p('tabs', 'List<Widget>', 'Usually Tab widgets.'),
      oneOf('variant', <String>['primary', 'secondary'], null, 'primary'),
      p('isScrollable', 'bool', null, 'false'),
      e('tabAlignment', TabAlignment.values),
      p('padding', 'EdgeInsets'),
      p('indicatorColor', 'Color'),
      p('indicatorWeight', 'double', null, '2'),
      p('indicatorPadding', 'EdgeInsets'),
      p('indicator', 'Decoration'),
      e('indicatorSize', TabBarIndicatorSize.values),
      p('dividerColor', 'Color'),
      p('dividerHeight', 'double'),
      p('labelColor', 'Color'),
      p('labelStyle', 'TextStyle'),
      p('labelPadding', 'EdgeInsets'),
      p('unselectedLabelColor', 'Color'),
      p('unselectedLabelStyle', 'TextStyle'),
      p('overlayColor', 'Color'),
      p('onTap', 'event<int>'),
    ],
    build: (UiArgs a) {
      final List<Widget> tabs = a.children(const ['tabs']);
      final bool secondary = a.string(const ['variant']) == 'secondary';
      final bool isScrollable = a.boolean(const ['isScrollable']) ?? false;
      final TabAlignment? tabAlignment = a.enumValue(TabAlignment.values, const ['tabAlignment']);
      final EdgeInsetsGeometry? padding = a.edgeInsets(const ['padding']);
      final Color? indicatorColor = a.color(const ['indicatorColor']);
      final double indicatorWeight = a.number(const ['indicatorWeight']) ?? 2;
      final EdgeInsetsGeometry indicatorPadding = a.edgeInsets(const ['indicatorPadding']) ?? EdgeInsets.zero;
      final Decoration? indicator = a.decoration(const ['indicator']);
      final TabBarIndicatorSize? indicatorSize = a.enumValue(TabBarIndicatorSize.values, const ['indicatorSize']);
      final Color? dividerColor = a.color(const ['dividerColor']);
      final double? dividerHeight = a.number(const ['dividerHeight']);
      final Color? labelColor = a.color(const ['labelColor']);
      final TextStyle? labelStyle = a.textStyle(const ['labelStyle']);
      final EdgeInsetsGeometry? labelPadding = a.edgeInsets(const ['labelPadding']);
      final Color? unselectedLabelColor = a.color(const ['unselectedLabelColor']);
      final TextStyle? unselectedLabelStyle = a.textStyle(const ['unselectedLabelStyle']);
      final WidgetStateProperty<Color?>? overlayColor = a.stateColor(const ['overlayColor']);
      final ValueChanged<int>? onTap = a.onValue<int>(const ['onTap']);
      // A scrollable bar may only start-align, a fixed one may not.
      final TabAlignment? alignment = switch (tabAlignment) {
        TabAlignment.start || TabAlignment.startOffset when !isScrollable => null,
        _ => tabAlignment,
      };
      final TabBar bar = secondary
          ? TabBar.secondary(
              tabs: tabs,
              isScrollable: isScrollable,
              tabAlignment: alignment,
              padding: padding,
              indicatorColor: indicatorColor,
              indicatorWeight: indicatorWeight,
              indicatorPadding: indicatorPadding,
              indicator: indicator,
              indicatorSize: indicatorSize,
              dividerColor: dividerColor,
              dividerHeight: dividerHeight,
              labelColor: labelColor,
              labelStyle: labelStyle,
              labelPadding: labelPadding,
              unselectedLabelColor: unselectedLabelColor,
              unselectedLabelStyle: unselectedLabelStyle,
              overlayColor: overlayColor,
              onTap: onTap,
            )
          : TabBar(
              tabs: tabs,
              isScrollable: isScrollable,
              tabAlignment: alignment,
              padding: padding,
              indicatorColor: indicatorColor,
              indicatorWeight: indicatorWeight,
              indicatorPadding: indicatorPadding,
              indicator: indicator,
              indicatorSize: indicatorSize,
              dividerColor: dividerColor,
              dividerHeight: dividerHeight,
              labelColor: labelColor,
              labelStyle: labelStyle,
              labelPadding: labelPadding,
              unselectedLabelColor: unselectedLabelColor,
              unselectedLabelStyle: unselectedLabelStyle,
              overlayColor: overlayColor,
              onTap: onTap,
            );
      UiSlot.report(a.context, bar);
      if (DefaultTabController.maybeOf(a.context) == null) {
        return DefaultTabController(length: tabs.length, child: bar);
      }
      return bar;
    },
    example: 'TabBar(tabs: [Tab(text: "One"), Tab(text: "Two", icon: "star")])',
  ),
  UiWidget(
    'Tab',
    group: UiGroup.navigation,
    doc: 'One tab of a TabBar: text, an icon, or both.',
    params: <UiParam>[
      p('text', 'String'),
      p('icon', 'Widget|Icon'),
      p('iconMargin', 'EdgeInsets'),
      p('height', 'double'),
      p('child', 'Widget', 'Instead of `text`.'),
    ],
    build: (UiArgs a) {
      final String? text = a.string(const ['text']);
      final Widget? child = a.optionalChild(const ['child']);
      final Widget? icon = a.iconOrChild(const ['icon']);
      return Tab(
        // Flutter asserts on both, and on neither with no icon either.
        text: child == null ? (text ?? (icon == null ? '' : null)) : null,
        icon: icon,
        iconMargin: a.edgeInsets(const ['iconMargin']),
        height: a.number(const ['height']),
        child: child,
      );
    },
  ),
  UiWidget(
    'TabBarView',
    group: UiGroup.navigation,
    doc: 'One page per tab of the TabBar it shares a DefaultTabController with. Needs a bounded height -- an '
        'Expanded or a SizedBox.',
    params: <UiParam>[p('children', 'List<Widget>'), p('physics', 'String'), p('viewportFraction', 'double', null, '1')],
    build: (UiArgs a) {
      final List<Widget> pages = a.children(const ['children']);
      final ScrollPhysics? physics = a.physics(const ['physics']);
      final double viewportFraction = a.number(const ['viewportFraction']) ?? 1;
      final TabBarView view = TabBarView(physics: physics, viewportFraction: viewportFraction, children: pages);
      if (DefaultTabController.maybeOf(a.context) == null) {
        return DefaultTabController(length: pages.length, child: view);
      }
      return view;
    },
  ),
  UiWidget(
    'Drawer',
    group: UiGroup.navigation,
    doc: 'The panel a Scaffold\'s `drawer` or `endDrawer` slides in.',
    params: <UiParam>[
      p('backgroundColor', 'Color'),
      p('elevation', 'double'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('shape', 'ShapeBorder'),
      p('width', 'double'),
      p('semanticLabel', 'String'),
      e('clipBehavior', Clip.values),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => Drawer(
      backgroundColor: a.color(const ['backgroundColor']),
      elevation: a.number(const ['elevation']),
      shadowColor: a.color(const ['shadowColor']),
      surfaceTintColor: a.color(const ['surfaceTintColor']),
      shape: a.shape(const ['shape']),
      width: a.number(const ['width']),
      semanticLabel: a.string(const ['semanticLabel']),
      clipBehavior: a.enumValue(Clip.values, const ['clipBehavior']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'DrawerHeader',
    group: UiGroup.navigation,
    doc: 'The top of a Drawer.',
    params: <UiParam>[
      p('decoration', 'Decoration'),
      p('margin', 'EdgeInsets'),
      p('padding', 'EdgeInsets'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => DrawerHeader(
      decoration: a.decoration(const ['decoration']),
      margin: a.edgeInsets(const ['margin']) ?? const EdgeInsets.only(bottom: 8),
      padding: a.edgeInsets(const ['padding']) ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      child: a.optionalChild(const ['child']),
    ),
  ),
  UiWidget(
    'NavigationDrawer',
    group: UiGroup.navigation,
    doc: 'The Material 3 drawer of destinations. `children` mixes NavigationDrawerDestination widgets with headings '
        'and dividers; `onDestinationSelected` receives `{ value: <index among the destinations> }`.',
    params: <UiParam>[
      p('children', 'List<Widget>'),
      p('selectedIndex', 'int', null, '0'),
      p('onDestinationSelected', 'event<int>'),
      p('backgroundColor', 'Color'),
      p('shadowColor', 'Color'),
      p('surfaceTintColor', 'Color'),
      p('elevation', 'double'),
      p('indicatorColor', 'Color'),
      p('indicatorShape', 'ShapeBorder'),
      p('tilePadding', 'EdgeInsets'),
      p('header', 'Widget'),
      p('footer', 'Widget'),
    ],
    build: (UiArgs a) {
      final List<Widget> children = a.children(const ['children']);
      final Color? backgroundColor = a.color(const ['backgroundColor']);
      final Color? shadowColor = a.color(const ['shadowColor']);
      final Color? surfaceTintColor = a.color(const ['surfaceTintColor']);
      final double? elevation = a.number(const ['elevation']);
      final Color? indicatorColor = a.color(const ['indicatorColor']);
      final ShapeBorder? indicatorShape = a.shape(const ['indicatorShape']);
      final EdgeInsetsGeometry tilePadding = a.edgeInsets(const ['tilePadding']) ?? const EdgeInsets.symmetric(horizontal: 12);
      final Widget? header = a.optionalChild(const ['header']);
      final Widget? footer = a.optionalChild(const ['footer']);
      return UiValue<int>(
        value: a.integer(const ['selectedIndex']),
        initial: 0,
        onChanged: a.onValue<int>(const ['onDestinationSelected']),
        builder: (BuildContext context, int index, ValueChanged<int>? onSelected) => NavigationDrawer(
          selectedIndex: index,
          onDestinationSelected: onSelected,
          backgroundColor: backgroundColor,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          indicatorColor: indicatorColor,
          indicatorShape: indicatorShape,
          tilePadding: tilePadding,
          header: header,
          footer: footer,
          children: children,
        ),
      );
    },
  ),
  UiWidget(
    'NavigationDrawerDestination',
    group: UiGroup.navigation,
    doc: 'One destination of a NavigationDrawer.',
    params: <UiParam>[
      p('icon', 'Widget|Icon'),
      p('selectedIcon', 'Widget|Icon'),
      p('label', 'Widget|String'),
      p('backgroundColor', 'Color'),
      p('enabled', 'bool', null, 'true'),
    ],
    build: (UiArgs a) => NavigationDrawerDestination(
      icon: a.iconOrChild(const ['icon']) ?? const SizedBox.square(dimension: 24),
      selectedIcon: a.iconOrChild(const ['selectedIcon']),
      label: a.label(const ['label']) ?? const SizedBox.shrink(),
      backgroundColor: a.color(const ['backgroundColor']),
      enabled: a.boolean(const ['enabled']) ?? true,
    ),
  ),
  UiWidget(
    'Stepper',
    group: UiGroup.navigation,
    doc: 'A sequence of steps. `steps: [{ title, subtitle, content, state, isActive }]`. Kept by the widget, '
        'Continue and Cancel move between steps; their events still fire, and `onStepTapped` receives `{ value: <index> }`.',
    params: <UiParam>[
      p('steps', 'List<Map>', 'Each `{ title, subtitle, content, state: "indexed" | "editing" | "complete" | "disabled" | "error", isActive, label }`.'),
      p('currentStep', 'int', null, '0'),
      p('onStepTapped', 'event<int>'),
      p('onStepContinue', 'event'),
      p('onStepCancel', 'event'),
      e('type', StepperType.values, null, 'vertical'),
      p('elevation', 'double'),
      p('margin', 'EdgeInsets'),
      p('connectorColor', 'Color', 'A colour, or a map by state.'),
      p('connectorThickness', 'double'),
      p('stepIconHeight', 'double'),
      p('stepIconWidth', 'double'),
    ],
    build: (UiArgs a) {
      final List<Step> steps = a.list<Step>(const ['steps'], (List<Object> k) {
            List<Object> at(String name) => <Object>[...k, name];
            return Step(
              title: a.label(at('title')) ?? const SizedBox.shrink(),
              subtitle: a.label(at('subtitle')),
              content: a.optionalChild(at('content')) ?? const SizedBox.shrink(),
              state: a.enumValue(StepState.values, at('state')) ?? StepState.indexed,
              isActive: a.boolean(at('isActive')) ?? false,
              label: a.label(at('label')),
            );
          }) ??
          const <Step>[];
      final VoidCallback? onContinue = a.onTap(const ['onStepContinue']);
      final VoidCallback? onCancel = a.onTap(const ['onStepCancel']);
      final StepperType type = a.enumValue(StepperType.values, const ['type']) ?? StepperType.vertical;
      final double? elevation = a.number(const ['elevation']);
      final EdgeInsetsGeometry? margin = a.edgeInsets(const ['margin']);
      final WidgetStateProperty<Color?>? connectorColor = a.stateColor(const ['connectorColor']);
      final double? connectorThickness = a.number(const ['connectorThickness']);
      final double? stepIconHeight = a.number(const ['stepIconHeight']);
      final double? stepIconWidth = a.number(const ['stepIconWidth']);
      final int? currentStep = a.integer(const ['currentStep']);
      final ValueChanged<int>? onStepTapped = a.onValue<int>(const ['onStepTapped']);
      if (steps.isEmpty) {
        return const SizedBox.shrink();
      }
      return UiValue<int>(
        value: currentStep,
        initial: 0,
        onChanged: onStepTapped ?? (int _) {},
        builder: (BuildContext context, int current, ValueChanged<int>? go) {
          final int at = current.clamp(0, steps.length - 1);
          return Stepper(
            steps: steps,
            currentStep: at,
            onStepTapped: go,
            onStepContinue: () {
              onContinue?.call();
              if (at < steps.length - 1) {
                go?.call(at + 1);
              }
            },
            onStepCancel: () {
              onCancel?.call();
              if (at > 0) {
                go?.call(at - 1);
              }
            },
            type: type,
            elevation: elevation,
            margin: margin,
            // Stepper wants a colour in every state; a state the map leaves
            // out gets Stepper's own inactive grey.
            connectorColor: connectorColor == null
                ? null
                : WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) => connectorColor.resolve(states) ?? const Color(0xFFBDBDBD),
                  ),
            connectorThickness: connectorThickness,
            stepIconHeight: stepIconHeight,
            stepIconWidth: stepIconWidth,
          );
        },
      );
    },
    example: 'Stepper(steps: [{ title: "Account", content: Text(text: "Email and password"), isActive: true }, '
        '{ title: "Profile", content: Text(text: "Name and photo") }])',
  ),
];

IconThemeData? _iconTheme(UiArgs a, List<Object> key) {
  if (!a.source.isMap(key)) {
    return null;
  }
  return IconThemeData(
    color: a.color(<Object>[...key, 'color']),
    size: a.number(<Object>[...key, 'size']),
    opacity: a.number(<Object>[...key, 'opacity']),
  );
}

List<BottomNavigationBarItem> _barItems(UiArgs a, List<Object> key) {
  return a.list<BottomNavigationBarItem>(key, (List<Object> k) {
        List<Object> at(String name) => <Object>[...k, name];
        final Widget icon = a.iconOrChild(at('icon')) ?? const SizedBox.square(dimension: 24);
        return BottomNavigationBarItem(
          icon: icon,
          activeIcon: a.iconOrChild(at('activeIcon')),
          label: a.string(at('label')),
          tooltip: a.string(at('tooltip')),
          backgroundColor: a.color(at('backgroundColor')),
        );
      }) ??
      const <BottomNavigationBarItem>[];
}

const Map<String?, FloatingActionButtonLocation> _fabLocations = <String?, FloatingActionButtonLocation>{
  'startTop': FloatingActionButtonLocation.startTop,
  'miniStartTop': FloatingActionButtonLocation.miniStartTop,
  'centerTop': FloatingActionButtonLocation.centerTop,
  'miniCenterTop': FloatingActionButtonLocation.miniCenterTop,
  'endTop': FloatingActionButtonLocation.endTop,
  'miniEndTop': FloatingActionButtonLocation.miniEndTop,
  'startFloat': FloatingActionButtonLocation.startFloat,
  'miniStartFloat': FloatingActionButtonLocation.miniStartFloat,
  'centerFloat': FloatingActionButtonLocation.centerFloat,
  'miniCenterFloat': FloatingActionButtonLocation.miniCenterFloat,
  'endFloat': FloatingActionButtonLocation.endFloat,
  'miniEndFloat': FloatingActionButtonLocation.miniEndFloat,
  'startDocked': FloatingActionButtonLocation.startDocked,
  'miniStartDocked': FloatingActionButtonLocation.miniStartDocked,
  'centerDocked': FloatingActionButtonLocation.centerDocked,
  'miniCenterDocked': FloatingActionButtonLocation.miniCenterDocked,
  'endDocked': FloatingActionButtonLocation.endDocked,
  'miniEndDocked': FloatingActionButtonLocation.miniEndDocked,
  'endContained': FloatingActionButtonLocation.endContained,
};
