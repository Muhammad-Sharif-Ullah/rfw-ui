# What the kit cannot build yet

217 widgets, chosen as the ones app screens actually use. Flutter has about
400. This is what is left, by why it is left.

## Needs more than data can say

rfw screens are data with no code in them. These take a Dart function, so
they need a local widget in the app, or a data format of their own:

- **Painting by code.** `CustomPaint` draws a list of shapes, and
  `LineChart`, `BarChart` and `PieChart` are drawn the same way, but nothing
  computes as it draws. What that leaves out: arcs in SVG path data (`A`),
  touch on a chart (tooltips, selecting a bar), axes and labels drawn for
  you, and signatures or anything else drawn by a finger. Shapes that
  animate are now possible: an `Animate` around a `CustomPaint` moves the
  whole picture, though not one shape within it.
- **Comparing numbers.** `LayoutBuilder` and `ScreenBuilder` name the width
  (`compact` ... `extraLarge`) because rfw can switch on a name but cannot
  test `width > 600`. A breakpoint of your own needs the app to compute it.
  `SliverLayoutBuilder` names the same thing for a sliver.
- **Futures and streams** (`FutureBuilder`, `StreamBuilder`). In rfw the app
  pushes data instead, so these are not needed in the same form.
- **Lists that animate their own changes.** `SliverAnimatedList` and
  `SliverAnimatedGrid` work by imperative calls on a `GlobalKey` state
  (`insertItem`, `removeItem`). A declarative form means diffing the item
  list against the last build and animating the difference, which is a
  design of its own. Until then: `AnimatedSwitcher` for a swap, `Animate`
  with `stagger` for an entrance, and `Dismissible` for a removal.

## Straightforward to add

- **Layout:** `Flow`, `Baseline`.
- **Material:** `DataTable`, `Autocomplete`, `MenuAnchor` / `MenuBar`,
  `SearchAnchor`, `ExpansionPanelList`, `Form` with validators.
- **Cupertino:** `CupertinoTabScaffold`, `CupertinoContextMenu`,
  `CupertinoTimerPicker`, `CupertinoFormSection` / `CupertinoFormRow`,
  `CupertinoScrollbar`.
- **Accessibility:** `Semantics` and the sliver forms of it. That is a pass
  of its own, not a widget.

## Motion and effects: what is there, and what is not

The kit animates ([motion.md](motion.md)): `Animate` with eight effects,
`ScrollTransition`, the implicit transitions, `Hero`, `AnimatedSwitcher`,
`AnimatedSize`, `AnimatedCrossFade`, `AnimatedIcon`, and the compositing
layer -- `BackdropFilter`, `ImageFiltered`, `ShaderMask`, `ColorFiltered`,
`ClipPath`, `RepaintBoundary`. What it does not do:

- **Fragment shaders** (`FragmentProgram`). They load asynchronously, need
  an asset pipeline and a cache, and are a project of their own.
- **Lottie and Rive.** Both are packages; register them as local widgets in
  the app that needs them, as with any plugin.
- **Physics-based motion** (`SpringSimulation`, fling-driven animation).
  `Animate` runs on a duration and a curve.

## Belongs in the app, not the kit

Video, web views, maps and the camera need plugins. Register them as local
widgets in the app that needs them.

## Not done in the tooling

- **Editor hover and completion across studio files.** Imports render, but
  the editor does not yet suggest the widgets an imported file declares.
- **The theme console's live preview needs the studio build.** Without
  `make rfw-studio` the panel says so, rather than drawing a sketch.
  ThemeData is too large to imitate faithfully in HTML.
