# rfw_ui

A UI kit for [Remote Flutter Widgets](https://pub.dev/packages/rfw). It adds
what rfw leaves out, so a screen sent as data can look and behave like one
written in Dart:

- **217 widgets** under one import: rfw's own core and material widgets with
  every argument their Flutter namesakes take, plus inputs (TextField, Switch,
  Checkbox, Radio, Slider, DropdownMenu, SegmentedButton, chips, SearchBar),
  navigation (NavigationBar, NavigationRail, TabBar, Drawer, Stepper), dialogs,
  Cupertino widgets and slivers, lists that build their rows as they scroll
  in, Flutter's `.builder` widgets (`ListView.builder`, `GridView.builder`,
  `PageView.builder`, ...), `LayoutBuilder` and `ScreenBuilder`,
  `CustomPaint`, and line, bar and pie charts.
- **Motion and effects**: `Animate` (fade, scale, slide, rotate, blur, tint,
  shimmer, with delay, stagger, loop and ping-pong), `ScrollTransition`,
  `Hero`, `AnimatedSwitcher`, and the compositing layer -- `BackdropFilter`,
  `ImageFiltered`, `ShaderMask`, `ColorFiltered`, `ClipPath`. An animated
  frame paints a layer and rebuilds nothing ([doc/motion.md](doc/motion.md)).
- **Gestures**: `Dismissible`, `Draggable` and `DragTarget`,
  `InteractiveViewer`, `ReorderableListView`.
- **A runtime of its own**, `UiRuntime`, in place of rfw's: the same screens,
  built faster, and a data change rebuilds only the widgets that read it
  ([doc/runtime.md](doc/runtime.md)).
- **Theme tokens** instead of repeated styles: `style: "titleLarge"`,
  `style: { base: "titleLarge", fontWeight: "bold" }` (that's
  `titleLarge.copyWith(...)`), `color: "primary"`, `padding: "md"`,
  `borderRadius: "lg"`.
- **Actions** for what a widget alone can't do: `ui.dialog`, `ui.bottomSheet`,
  `ui.snackBar`, the date and time pickers, `ui.pop`, `ui.set` for two-way
  binding, `ui.themeMode`, and `ui.focus` / `ui.unfocus` / `ui.scrollTo`.
- **Keys** on every widget: `key: item.id`. State moves with its item when a
  list reorders, and `ui.focus` and `ui.scrollTo` find a widget by its key.
- **One theme document** for light and dark together, decoded into a full
  `ThemeData`: colour scheme, text theme and 39 component themes.

## Set it up

```dart
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

final Runtime runtime = createUiRuntime()         // UiRuntime; rfw's with --dart-define=RFW_RUNTIME=rfw
  ..update(uiLibraryName, createUiWidgets())      // what `import ui;` reaches
  ..update(const LibraryName(<String>['app', 'home']), library);
final DynamicContent data = DynamicContent();

// Use UiRemoteWidget wherever you'd use RemoteWidget. It runs the ui.* actions
// and passes every other event to onEvent, the same as RemoteWidget does.
UiRemoteWidget(
  runtime: runtime,
  data: data,
  widget: const FullyQualifiedWidgetName(LibraryName(<String>['app', 'home']), 'root'),
  onEvent: (String name, DynamicMap args) { /* your own events */ },
);
```

`ui` contains every widget in rfw's `core.widgets` and `core.material`, under
the same names and reading the same arguments. An existing file can replace its
imports with `import ui;` and keep working.

## Write a screen

```
import ui;

widget root = Scaffold(
  appBar: AppBar(title: "Inbox"),
  body: ListView(padding: "md", children: [
    Text(text: "Welcome back.", style: { base: "displaySmall", fontWeight: "bold", color: "primary" }),
    SizedBox(height: "sm"),
    TextField(
      decoration: { labelText: "Email", prefixIcon: "mail_outline" },
      onChanged: event "ui.set" { key: "form.email" },
    ),
    Text(text: ["You typed: ", data.form.email], style: "bodySmall"),
    FilledButton(child: "Delete", icon: "delete", onPressed: event "ui.dialog" { widget: "Confirm", onResult: "delete" }),
  ]),
);

widget Confirm = AlertDialog(
  title: "Delete this?",
  actions: [
    TextButton(child: "Cancel", onPressed: event "ui.pop" { }),
    FilledButton(child: "Delete", onPressed: event "ui.pop" { result: true }),
  ],
);
```

### Values

| Type | Accepts |
|---|---|
| Colour | `0xFF6750A4`, a scheme role (`"primary"`, `"onSurfaceVariant"`, ...), a theme colour (`"divider"`), a custom token (`"success"`), `"#RRGGBB"`, and any of them with an opacity in percent: `"onSurface/60"` |
| Text style | A text theme name (`"titleLarge"`) or a named style from the theme (`"hero"`). A map with `base` is that style's copyWith: `{ base: "titleLarge", fontWeight: "bold" }`. A map without `base` is a plain style, the same as in rfw |
| Spacing | A number or a token: `"xs"` `"sm"` `"md"` `"lg"` `"xl"`. Works for padding, margin, `SizedBox`, and the `spacing` of Row, Column and Wrap |
| Edge insets | A number, a token, rfw's `[start, top, end, bottom]`, or `{ all, horizontal, vertical, top, bottom, start, end }` |
| Radius | A number or a token (`"md"`, `"full"`), or `{ top, bottom, start, end, topStart, ... }` |
| Shape | `"stadium"`, `"circle"`, a number (a rounded rectangle), or `{ type, borderRadius, side }` |
| Icon | A Material icon name (`"home"`), or a Cupertino one with a prefix (`"cupertino.heart_fill"`). Every icon in the SDK is available |
| Number | `16` and `16.0` are both fine. rfw's own widgets ignore `16` wherever they expect a double |
| State map | Any colour, style or size a Flutter widget resolves per state: `{ default: "primary", pressed: "primaryContainer", disabled: "outline" }` |

Shorthands: where a widget is expected, a string is `Text`
(`title: "Inbox"`, `child: "Continue"`). Where an icon widget is expected, an
icon name is `Icon` (`leading: "person"`).

Any name may be written with a dot instead of quotes: `color: .primary`,
`style: { base: .titleLarge }`, `padding: .md`, `textAlign: .center`. It is
the same string. The copy of rfw in `third_party/rfw` reads it (see its
`PATCHES.md`), and the binary file a phone downloads is unchanged.

### Lists, layout and drawing

```
ListView(onEndReached: event "loadMore" { }, children: [...for m in data.messages: MessageRow(m: m)])
LayoutBuilder(builder: (size) => switch size.breakpoint { .compact: Column(children: [A(), B()]), default: Row(children: [A(), B()]) })
CustomPaint(width: 48, height: 48, viewBox: [0, 0, 24, 24], shapes: [{ shape: .path, d: "M4 12 L10 18 L20 6", stroke: 2, cap: .round }])
LineChart(points: data.prices, fill: "primary/15", smooth: true, height: 120)
```

- A `ListView`, `GridView` or sliver list builds a row only when it scrolls
  into view, so a list of 10,000 mounts in about the time Flutter's does.
  `onEndReached` fires when the last row is built: load the next page there.
- `LayoutBuilder` passes the space it is given, `ScreenBuilder` the window.
  Both name the width as Material's window class (`compact`, `medium`,
  `expanded`, `large`, `extraLarge`), because rfw can switch on a name but
  can't compare numbers.
- `CustomPaint` draws a list of shapes: rect, circle, line, arc, SVG path and
  text. `LineChart`, `BarChart` and `PieChart` are drawn the same way.

### Inputs and `ui.set`

Every input reports its value as `{ value }` merged into its event's arguments.
rfw's `set state.x = ...` can't read that value, so the `ui.set` action
exists. It writes the value into `data`, and every widget reading that path
rebuilds:

```
Switch(value: data.settings.wifi, onChanged: event "ui.set" { key: "settings.wifi" })
```

Each input also keeps its own value. It responds immediately even when nothing
is bound to it (a literal `value: true`, or a preview), and data changes still
take precedence.

### Actions

| Event | Does |
|---|---|
| `ui.set { key, value }` | Writes into data at a dotted path (`"form.email"`, `"items.0.done"`) |
| `ui.toggle { key }` | Flips a bool in data |
| `ui.dialog { widget, args }` | Shows a widget from this file as a dialog; it reads `args.*` |
| `ui.bottomSheet { widget, args, showDragHandle, isScrollControlled }` | Shows a modal bottom sheet |
| `ui.cupertinoDialog` / `ui.cupertinoModal` | The same for an iOS alert, or an action sheet / popup |
| `ui.pop { result }` | Closes the dialog or sheet it's in and returns `result` |
| `ui.snackBar { message, actionLabel, onAction }` | Shows a snack bar; its action fires `onAction` |
| `ui.pickDate` / `ui.pickTime` / `ui.pickDateRange` | Show the Material pickers. Results come back as `"YYYY-MM-DD"`, `"HH:mm"`, or `{ start, end }` |
| `ui.themeMode { mode }` | `light`, `dark`, `system` or `toggle`, when there's a `UiTheme` above the app |
| `ui.copy { text }` | Copies text to the clipboard |
| `ui.focus { key }` | Moves the keyboard focus to the widget with that key |
| `ui.unfocus` / `ui.focusNext` / `ui.focusPrevious` | Closes the keyboard, or moves along the focus order |
| `ui.scrollTo { key, alignment }` | Scrolls the keyed widget into view |

Anything that returns a result takes `key` (write the result into data there)
and `onResult` (fire that event with `{ value }`; it can be another `ui.*`
action). A dialog shares its opener's `data`, and it can open further dialogs.

## The theme document

One document holds both brightnesses. `shared` is merged under `light` and
`dark`. Inside each one, the keys are `ThemeData`'s own names, so Flutter's
documentation covers this format too:

```
{
  name: "Harbour",
  mode: "system",
  shared: {
    fontFamily: "Inter",
    textTheme: { displaySmall: { fontWeight: "bold", letterSpacing: -1 } },
    tokens: {
      spacing: { md: 16 },
      colors: { success: 0xFF1E8E3E },
      textStyles: { hero: { base: "displaySmall", color: "primary" } },
    },
    appBarTheme: { backgroundColor: "surfaceContainer" },
    filledButtonTheme: { style: { shape: "stadium" } },
    inputDecorationTheme: { filled: true, border: { type: "outline", borderRadius: "md" } },
  },
  light: { colorScheme: { seed: 0xFF2F6BFF } },
  dark:  { colorScheme: { seed: 0xFF2F6BFF, surface: "#101114" } },
}
```

```dart
final UiThemeDocument doc = UiThemeDocument.decode(parseDataFile(text)); // or decodeDataBlob, or jsonDecode
final UiThemeController theme = UiThemeController(document: doc);

ListenableBuilder(
  listenable: theme,
  builder: (context, _) => UiTheme(
    controller: theme,
    child: MaterialApp(theme: theme.light, darkTheme: theme.dark, themeMode: theme.mode),
  ),
);
```

- `colorScheme` takes a `seed` (with optional `variant` and `contrastLevel`)
  and any of its 46 roles as overrides. A role may name another role.
- `textTheme` takes the 15 styles. A style without `base` changes its own
  default; with `base` it starts from that style instead. `bodyColor`,
  `displayColor` and `fontFamily` recolour or refont every style.
- Component themes: `appBarTheme`, `badgeTheme`, `bottomAppBarTheme`,
  `bottomNavigationBarTheme`, `bottomSheetTheme`, `cardTheme`,
  `checkboxTheme`, `chipTheme`, `cupertinoOverrideTheme`, `datePickerTheme`,
  `dialogTheme`, `dividerTheme`, `drawerTheme`, `dropdownMenuTheme`,
  `elevatedButtonTheme`, `expansionTileTheme`, `filledButtonTheme`,
  `floatingActionButtonTheme`, `iconButtonTheme`, `inputDecorationTheme`,
  `listTileTheme`, `navigationBarTheme`, `navigationDrawerTheme`,
  `navigationRailTheme`, `outlinedButtonTheme`, `popupMenuTheme`,
  `progressIndicatorTheme`, `radioTheme`, `scrollbarTheme`, `searchBarTheme`,
  `segmentedButtonTheme`, `sliderTheme`, `snackBarTheme`, `switchTheme`,
  `tabBarTheme`, `textButtonTheme`, `textSelectionTheme`, `timePickerTheme`,
  `tooltipTheme`.
- `tokens` become the `UiTokens` theme extension. Read it from Dart with
  `UiTokens.of(context)`. A named style keeps its `base` as a name and is
  resolved where it's used, because `ThemeData.textTheme` has no font sizes
  until `Theme` merges in the locale's geometry.

To give just one screen its own theme inside an app, use
`ScopedTheme(data: doc.light, child: ...)` instead of `Theme`. A plain nested
`Theme` reuses the app's `CupertinoTheme`, which leaves every Cupertino widget
in the app's colours.

Unknown keys are ignored, so a typo never stops a theme from loading.
`UiThemeDocument.problems(map)` lists them, for an editor to show.

### Focus and keys

`textInputAction: "next"` moves to the next field by itself. To send it
somewhere in particular, give the target a `key` and point `onSubmitted` at
`ui.focus { key: "code" }`. `FocusTraversalGroup(policy: "ordered")` with
`FocusTraversalOrder(order: n)` sets the order Tab and "next" follow. Every
widget takes `key`; under `UiRemoteWidget` it is a `GlobalKey` scoped to the
screen or dialog, so a row's state follows it when the list reorders. See
[doc/focus-and-keys.md](doc/focus-and-keys.md).

### Dart screens on the same tokens

`context.spacing.md`, `context.radius.lg`, `context.text.titleLarge` and
`context.colors.primary` read the same theme a remote file's `"md"` and
`"primary"` do (`UiThemeContext`), so a screen written in Dart and one sent
as data cannot drift apart.

## Check a file before it is shown

rfw passes over most mistakes in silence: an argument it does not know is
ignored, and a colour or style name that names nothing becomes the default.
`checkUiLibrary(library, text, theme: theme)` lists them, with their lines:

```
line 4:3 Text.style.base: "titleLarg" is not a text style (titleLarge, bodyMedium, ... or one the theme names)
line 7:3 Card.elevaton is not an argument of Card
```

## Tools

```bash
# A PNG of a screen with real fonts and icons, after the list of what is wrong with it.
RFW_SCREEN=/abs/screen.rfwtxt RFW_OUT=/abs/out.png [RFW_THEME=/abs/theme.rfwtxt] flutter test tool/render_screen_test.dart

# A design image's palette, colours at points, or a side-by-side with a render.
RFW_IMAGE=/abs/design.png [RFW_COMPARE=/abs/out.png RFW_OUT=/abs/side.png] flutter test tool/image_tool_test.dart

# Profile-mode benchmarks against plain Flutter.
cd benchmark && flutter run --profile -d macos
```

The `rfw-ui-from-image` skill (`skills/rfw-ui-from-image/`) wraps the first
two into a workflow that builds a screen from a design.

## Documents

[doc/](doc/README.md) answers the questions asked of the kit, with what was
measured to answer them: performance against Flutter, lifecycle and leaks,
focus and keys, studio imports, the theme format, and what is not built yet.

## Add a widget

Each widget is one `UiWidget` entry, holding its builder and its documentation
together (`lib/src/widgets/*.dart`):

```dart
UiWidget(
  'Gap',
  group: UiGroup.layout,
  doc: 'Empty space along the parent Row or Column.',
  params: <UiParam>[p('size', 'Spacing', null, '0')],
  build: (UiArgs a) => SizedBox.square(dimension: a.spacing(['size']) ?? 0),
  example: 'Column(children: [Text(text: "a"), Gap(size: "md"), Text(text: "b")])',
)
```

`test/catalog_test.dart` fails if a builder reads an argument it doesn't
declare, or declares one it never reads, and it renders every `example`. Then
run `make catalog` from the repository root. That regenerates `catalog.json`,
which the studio editor's hover and completion read, and copies it to the
frontend.

## Tests

```
flutter test
```

Every test runs under Flutter's leak tracker (`test/flutter_test_config.dart`):
anything left undisposed fails the test that made it.

`decoder_test` covers values and tokens. `catalog_test` checks every widget
against its docs and renders every example. `actions_test` covers every action
on screen, and `keys_focus_test` keys, focus and scrolling. `lifecycle_test`
mounts and unmounts, opens fifty dialogs, and pins what rebuilds. `theme_test`
covers the document format, and checks every component theme against its key
list. `theme_schema_test` holds the generated schema to the decoder.
`check_test` holds the checker to no false alarms on any example.
`skill_recipes_test` keeps the skill's recipes valid. `catalog_export_test`
keeps `catalog.json` current.
