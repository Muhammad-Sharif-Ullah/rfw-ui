# Changelog

## Unreleased

### Motion
- `Animate`: one widget for entrance, loop, ping-pong, delay, stagger and
  data-driven play/stop, with eight effects (`fade`, `scale`, `slide`,
  `rotate`, `blur`, `tint`, `shimmer`) that compose, first outermost. Its
  child is built once and handed to Flutter's render-object transitions, so a
  running animation costs a paint and no rebuild. A device set to reduce
  motion gets the end of the animation and no ticker at all.
- `ScrollTransition`: the same effect list, driven by the scroll view it sits
  in rather than by a clock -- a header that shrinks, fades and parallaxes.
- `AnimatedSwitcher` (with an explicit `value`, since rfw builds a child
  below the widget it was handed), `AnimatedSize`, `AnimatedCrossFade`,
  `Hero` and `AnimatedIcon` with all 14 of Flutter's animated icons.
- Measured: 60 shimmering cards cost 0.43 ms of build per frame against
  0.42 ms for the same screen written in Dart, and neither drops a frame
  (`doc/performance.md`, `doc/motion.md`).

### Effects
- `BackdropFilter`, `BackdropGroup`, `ImageFiltered`, `ShaderMask`,
  `ColorFiltered`, `ClipPath` (a `ShapeBorder` or SVG path data) and
  `RepaintBoundary`.
- `BackdropFilter` clips to its own bounds. In Flutter it blurs its whole
  layer, which without a clip is the screen; `borderRadius` makes the clip a
  rounded one and `clip: false` gives Flutter's behaviour back.

### Gestures
- `Dismissible`, `Draggable`, `DragTarget`, `InteractiveViewer`,
  `ReorderableListView` and `ReorderableListView.builder`.

### Slivers
- `SliverPersistentHeader` (a `child` that never rebuilds, or a `builder`
  given `shrinkOffset`, `t` and `overlapsContent`), `SliverResizingHeader`,
  `SliverLayoutBuilder`, `SliverCrossAxisExpanded`,
  `SliverConstrainedCrossAxis`, `SliverPrototypeExtentList`,
  `SliverVariedExtentList` (both with `.builder`), `SliverAnimatedOpacity`,
  `SliverIgnorePointer`, `SliverOffstage`, `SliverReorderableList`,
  `NestedScrollView` with `SliverOverlapAbsorber` and `SliverOverlapInjector`,
  and `CupertinoSliverRefreshControl`.

### Layout and Material
- `IndexedStack`, `OverflowBox`, `UnconstrainedBox`, `FractionalTranslation`,
  `Table`, `ListWheelScrollView`, `Scrollbar`.
- `ToggleButtons`, `CarouselView` (by item extent or by `flexWeights`) and
  `MaterialBanner`.
- `Transform` gained `rotateX`, `rotateY` and `perspective`.

### Actions
- `ui.haptic`: `light`, `medium`, `heavy`, `selection` or `vibrate`.

### Fixes
- An `Image` is decoded at the box it is drawn in, times the device pixel
  ratio, rather than at the picture's own size: 0.10 MB instead of 5.49 MB
  in the image cache for a 1200x1200 photograph in an 80-pixel box, measured.
  `cacheWidth` and `cacheHeight` override it, and it never upscales. `Image`
  also gained `placeholder`, `error` and `fadeDuration`.

### Runtime
- `UiRuntime`, the kit's own runtime, in place of rfw's `Runtime`, and
  `createUiRuntime()`, which makes it (or rfw's, built with
  `--dart-define=RFW_RUNTIME=rfw`). It builds the same render tree as rfw's
  for every catalog example and recipe, passes rfw's own runtime tests, and
  rebuilds only the widgets that read what changed. The studio and the app
  use it. See `doc/runtime.md`.
- Decoders of maps with many keys (text styles, decorations, button styles,
  input decorations) ask after the keys that were written, where the source
  can list them (`UiKeysSource`).

### Syntax
- `ListView.builder(...)`: a call may be named as Flutter names a
  constructor. And a builder's argument may be read whole: `(s) => Text(text: s)`.
  Both were parse errors before (`third_party/rfw/PATCHES.md`, 3 and 4).

### Widgets
- `ListView.builder`, `ListView.separated`, `GridView.builder`,
  `PageView.builder`, `SliverList.builder`, `SliverList.separated` and
  `SliverGrid.builder`: `items`, `itemCount` and `itemBuilder: (item) => ...`,
  built as they scroll into view. They need UiRuntime.
- `PageView` builds each page as it comes into view.

### Syntax
- A name may be written with a dot instead of quotes: `textAlign: .center`,
  `style: { base: .bodyLarge, color: .onSurfaceVariant }`,
  `icon: .cupertino.heart_fill`, and as a switch case (`.compact:`). It is
  read as the quoted string, so the binary file a phone gets is unchanged.
  The parser change is in `third_party/rfw` (see its `PATCHES.md`). The
  studio's editor colours these names and completes them after the dot.

### Widgets
- `ListView`, `GridView`, `SliverList`, `SliverFixedExtentList` and
  `SliverGrid` build their children as they scroll into view, `...for` rows
  included. A 10,000-row list mounts in 5.0 ms (it was 562.7 ms; Flutter
  4.9 ms).
- `onEndReached` on `ListView`, `GridView` and `SliverList`: fires once the
  last row is built, and again only after the list's length changes.
- `LayoutBuilder` and `ScreenBuilder`: `(size) => ...` with sizes, Material's
  window class as `breakpoint`, `orientation`, and for the screen its
  `brightness`, `platform` and `textScale`.
- `CustomPaint`: a list of shapes (rect, circle, line, arc, SVG path, text),
  filled or stroked, in a colour or gradient, optionally in `viewBox` units.
- `LineChart`, `BarChart` and `PieChart`.

### Keys and focus
- Every widget takes `key`. Under `UiRemoteWidget` it is a `GlobalKey` scoped
  to its screen or dialog, so a row's state moves with its item when a list
  reorders (rfw builds every child unkeyed, so on its own it does not). Under
  a plain `RemoteWidget` it is a `ValueKey`.
- `ui.focus { key }`, `ui.unfocus`, `ui.focusNext`, `ui.focusPrevious` and
  `ui.scrollTo { key, alignment, duration, curve }`.
- `FocusTraversalGroup`, `FocusTraversalOrder` and `ExcludeFocus`.
- Text fields own a focus node, registered under their key.

### Performance
- Dialogs and sheets are built on a runtime of their own. Registering a
  modal's library used to rebuild every remote widget behind it: 100 ms over
  a screen of 300 cards, now 5 ms (plain Flutter: 4.3 ms). See
  `doc/performance.md` and `benchmark/`.
- `doc/why-slower.md`: why a remote screen builds slower than Flutter, from
  a CPU profile (`benchmark/tool/profile.ts`). The cost is rfw's per-argument
  lookups, and a data change repeating them. The kit's own code is 2.4 ms of
  a 153 ms frame.
- rfw is now carried in `third_party/rfw` with each lookup key hashed once.
  Measured with stock and patched runs taking turns: 8% off a mount and 18%
  off a data change.
- The benchmark has a `listmount` mode, for a feed in a `ListView`.

### Themes
- `uiThemeSchema()`: the JSON Schema of one side of a theme, generated from
  the decoder (`theme.schema.json`). The theme console validates against it
  and draws its form from it.
- A component theme's text style that names no font takes the theme's
  `fontFamily`, and so does a button style's text written on a widget.
- `UiThemeContext`: `context.spacing.md`, `context.radius.lg`, `context.text`,
  `context.colors` for Dart screens.

### Tools
- `checkUiLibrary`: the mistakes rfw passes over in silence, by line.
- `tool/render_screen_test.dart` (a screen to a PNG, with real fonts),
  `tool/image_tool_test.dart` (palette, colours at points, side-by-side
  compare), and `benchmark/` (profile-mode numbers against Flutter).
- Every test runs under the leak tracker.

## 0.1.0

First release.

### Widgets: the `ui` library
- 154 widgets under one import, `import ui;`. It is a superset of rfw's
  `core.widgets` and `core.material`, with the same names and arguments, so an
  existing file can switch imports and keep working.
- rfw's widgets now take every argument their Flutter namesakes take (for
  example `Row` / `Column` `spacing`, `Text` `selectionColor`, `Card` variants,
  and button `icon` + `iconAlignment`), and they still animate implicitly as
  rfw's do.
- New widgets:
  - **inputs:** TextField, Checkbox(ListTile), Switch(ListTile),
    RadioGroup / Radio(ListTile), Slider, RangeSlider, DropdownButton,
    DropdownMenu, PopupMenuButton, SegmentedButton, SearchBar,
    CalendarDatePicker
  - **chips:** Chip, ActionChip, FilterChip, ChoiceChip, InputChip
  - **navigation:** NavigationBar, NavigationRail, BottomNavigationBar,
    TabBar / Tab / TabBarView / DefaultTabController, NavigationDrawer,
    BottomAppBar, Stepper, ExpansionTile
  - **dialogs:** AlertDialog, SimpleDialog, Dialog, and the Cupertino alert
    and action sheet
  - **Cupertino:** page scaffold, navigation bar, button, switch, slider,
    text and search fields, segmented control, list sections, picker, date
    picker, tab bar
  - **slivers:** CustomScrollView, SliverList, SliverGrid, SliverAppBar
    (medium and large too), FlexibleSpaceBar, SliverFillRemaining,
    PinnedHeaderSliver, the Cupertino large title, and more
  - **other:** Badge, CircleAvatar, Tooltip, RichText, SelectableText,
    Visibility, Transform, PageView
- Shorthands: a string where a widget is expected is `Text`, and an icon name
  where an icon widget is expected is `Icon`. Every Material and Cupertino
  icon in the SDK is reachable by name (`"home"`, `"cupertino.heart_fill"`).
- Inputs keep their own value and re-sync when bound data changes, so they
  respond even when nothing is bound.
- `Scaffold.appBar` and `AppBar.bottom` take their content's real height (an
  AppBar with a TabBar under it), rather than rfw's fixed 56 pixels.

### Theme tokens
- Colours: ARGB ints, scheme roles (`"primary"`), theme colours, custom
  tokens, `"#RRGGBB"`, and opacity (`"onSurface/60"`).
- Text styles: a name (`"titleLarge"`, or a named theme style), or
  `{ base: ..., ...overrides }`, which is copyWith.
- Spacing and radius tokens (`"md"`, `"full"`), state maps for any
  `WidgetStateProperty`, and `16` read as a double wherever rfw ignores it.

### Actions: `UiRemoteWidget`
- `ui.set`, `ui.toggle`, `ui.dialog`, `ui.bottomSheet`, `ui.cupertinoDialog`,
  `ui.cupertinoModal`, `ui.pop`, `ui.snackBar`, `ui.pickDate`,
  `ui.pickDateRange`, `ui.pickTime`, `ui.themeMode`, `ui.copy`.
- Modals show a widget of the file with `args`, share the opener's data, can
  open further modals, and return results through `key` / `onResult`.
- Every modal is shown in the opener's themes, Cupertino routes included
  (Flutter's Cupertino routes do not carry them over by themselves).
- Every other event reaches `onEvent` unchanged.

### Theme document
- `UiThemeDocument`: `shared`, `light`, `dark` and `mode` in one map (from
  rfw text, a blob or JSON), decoded into a full `ThemeData`. That covers the
  colour scheme from a seed with role overrides, all 15 text styles, 39
  component themes, and `UiTokens`.
- Named styles resolve their base where they are used, so they keep the
  locale's sizes (`ThemeData.textTheme` has none until `Theme` merges them in).
- `UiThemeDocument.problems` lists unknown keys. `UiThemeController` and
  `UiTheme` provide light/dark switching. `ScopedTheme` themes part of an app
  for Cupertino widgets as well as Material ones.

### Tooling
- `catalog.json` and `icons.json` describe every widget, parameter, action,
  type and token for the studio editor's hover and completion.
- Tests hold every widget to its documented parameters, render every example,
  and hold every component theme to its key list. `catalog_export_test` fails
  when the catalog is stale; `make catalog` regenerates it.
