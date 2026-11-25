# UiRuntime: the kit's own runtime

`UiRuntime` replaces rfw's `Runtime`. It builds the same widgets from the same
files, faster, and rebuilds only what a change touches. The `.builder`
widgets (`ListView.builder` and the rest) need it.

```dart
final Runtime runtime = createUiRuntime()   // was: Runtime()
  ..update(uiLibraryName, createUiWidgets())
  ..update(const LibraryName(<String>['main']), parseLibraryFile(source));
```

Nothing else changes. `UiRuntime` is a `Runtime`: libraries are registered,
listened to and disposed of as before, and `RemoteWidget` and `UiRemoteWidget`
take it as they take rfw's. The text format, the binary format, the parser,
`DynamicContent`, `checkUiLibrary` and every widget of the kit are the same.

**Switching back:** build with `--dart-define=RFW_RUNTIME=rfw`, and
`createUiRuntime()` gives rfw's `Runtime`. Everything but the `.builder`
widgets works there. Those show an error that says what to write instead.

## The numbers

300 cards, profile mode, Apple M1, measured with
[`benchmark/tool/profile.ts`](../benchmark/tool/profile.ts). The builds took
turns in one session, and each figure is the median of their rounds' medians,
in ms of a frame. "rfw" is the kit on rfw's runtime (`uiTokens`).

| | Flutter | rfw | **UiRuntime** |
|---|---|---|---|
| show the screen (3 rounds) | 105.3 | 131.3 | **112.2** (1.07×) |
| change every card's title (3 rounds) | 43.7 | 75.5 | **27.9** (0.64×) |
| change one card's title (3 rounds) | 30.4 | 59.7 | **8.4** (0.28×) |
| change one value one `Text` reads (4 rounds) | 37 | 9.3 | **9.2** (0.25×) |
| a `ListView` of 10,000 (2 rounds) | 3.9 | 4.7 | **4.1** |
| a `ListView.builder` of 10,000 (2 rounds) | 4.3 | -- | **4.6** |
| live heap, MB | 63.8 | 76.2 | **65.4** |

- **Changing data is faster than Flutter's `setState`.** A row whose item is
  unchanged is not rebuilt, and nothing that read no changed value is.
  Flutter's `setState` rebuilds every card. Written by hand, a Flutter app
  would need keys, `const` widgets and a selector library to do the same.
- **Showing a screen costs 7% more than Flutter.** It was 25% more on rfw. What
  is left is the cost of reading a screen file at runtime: in a frame's build,
  Dart's maps (+1.9 ms over Flutter) and the kit's decoding of arguments
  (2.5 ms). That is what Flutter does at compile time.
- **Changing one value costs about what it costs on rfw.** Both subscribe each
  widget to what it reads. The time left is the layout of the screen that the
  changed `Text` sits in, not the build.
- **Memory is Flutter's, near enough:** 1.6 MB more for 300 cards, 11 MB less
  than rfw.

The machine was busier in some sessions than in others, and times moved by
up to 5% between rounds. Compare the columns, not the pages.

On a phone (an Android 16 handset, profile mode), Flutter takes about 530 ms
to show the same 300 cards: about five times the Mac's time. The comparison
on the phone did not finish, because its USB connection dropped after each
launch, so there are no phone numbers for the other builds yet.

## What it does differently

rfw's runtime copies a widget's arguments into every widget it is passed to,
and copies every row of a list again for its loop variable. Each read of an
argument builds a key, hashes it and looks it up in a cache, and a data change
throws those caches away. `UiRuntime` does none of that:

1. **An argument is read where it is written.** A builder's
   `a.string(['title'])` looks in the call's own argument map. A reference,
   `args.title` or a loop's `item.title`, is followed through an environment
   that says what `args`, each loop variable and each builder argument hold
   where the value was written. Nothing is copied.
   ([`lib/src/runtime/eval.dart`](../lib/src/runtime/eval.dart))
2. **Nothing is allocated for an argument nobody wrote.** Most of the fifty
   paths a styled `Text` asks after were never written. Each is a map lookup
   that answers null.
3. **Names are worked out once.** What a call calls, whether a kit widget,
   another local widget or a remote widget through the imports, is kept on the
   call until the libraries change.
4. **What reads nothing that changes is built once.** A call with no `args`,
   `data`, `state`, loop variable, builder argument or switch anywhere in it is
   built once per screen and reused, and Flutter skips it on a rebuild. This is
   Dart's `const`, found by the runtime.
5. **Each widget subscribes to exactly what it read.** A `data.*` or `state.*`
   path a widget reads while it builds is noted against that widget's element.
   A change rebuilds those elements and no others. A changed title rebuilds one
   `Text`, not the screen. ([`lib/src/runtime/cells.dart`](../lib/src/runtime/cells.dart))
6. **A row whose item is unchanged keeps its widget.** This holds for loops and
   `.builder` rows alike. Items are compared all the way down, nested maps
   included. A row is kept only if making it read no data or state, so a row
   chosen by `switch data.mode` is made again when the mode changes. The rows
   live on the element that owns the list, so two copies of one widget never
   share them.
7. **The theme is looked up once per screen,** and kit widgets resolve tokens
   against it. Under a local widget that is not the kit's, which may set a
   theme of its own, kit widgets look theirs up as before. A new theme rebuilds
   everything.
8. **A map's decoder asks after the keys that were written.** A text style, a
   decoration, a button style or an input decoration reads its few written
   keys, not the dozens it knows (`UiKeysSource`).
9. **Event arguments are read when the event fires,** not on every build. The
   values are the same, because a widget is rebuilt whenever what it read
   changes.
10. **A remote widget without state adds no element.** Its body is built in its
    place. One with state gets one element, which holds the state.

## Where it differs from rfw's

Knowingly, and nowhere else:

1. `Runtime.blobNodeFor(context)` returns null for its widgets. Nothing in this
   repository calls it.
2. State inside a list row survives a data change that keeps the row. rfw
   re-curries every row, so it resets that state.
3. Event arguments are read when the event fires (see 9 above).
4. rfw's private types and their `toString` texts are not reproduced.

## How it is held to rfw's behaviour

- **rfw's own runtime tests, run against it.** `test/runtime/rfw_*_parity_test.dart`
  are rfw 1.1.4's `runtime_test.dart`, `remote_widget_test.dart` and
  `core_widgets_test.dart`, with `Runtime()` changed to `UiRuntime()`. Two are
  skipped, each because it checks one of rfw's private `toString`s.
- **Every kit test on both runtimes.** `make test` runs the kit's suite once on
  `UiRuntime` and once with `RFW_RUNTIME=rfw`.
- **The same render tree.** `test/runtime/differential_test.dart` renders every
  catalog example and every skill recipe on both runtimes. The render trees
  (each render object's size, offset, constraints and paint properties) must
  be identical.
- **What is new** has its own tests:
  - `rebuild_test.dart`: what is kept, and that it is never stale;
  - `state_test.dart`;
  - `eval_test.dart`;
  - `../builder_widgets_test.dart`.

## The `.builder` widgets

```
ListView.builder(
  items: data.messages,
  itemBuilder: (m) => ListTile(title: m.name, onTap: event "open" { id: m.id }),
)
```

The seven `.builder` widgets are `ListView.builder`, `ListView.separated`,
`GridView.builder`, `PageView.builder`, `SliverList.builder`,
`SliverList.separated` and `SliverGrid.builder`. Each takes its plain form's
parameters, with `items`, `itemCount` and `itemBuilder` (and
`separatorBuilder`) in place of `children`.

- **What `itemBuilder` receives:**
  - with `items`, the row's item, whatever it is: a map (`m.name`), a string
    (`Text(text: m)`) or a number;
  - with `itemCount` and no `items`, the row's index;
  - when both are written, `itemCount` caps the rows.
- **Lazy.** Rows are built as they scroll into view.
- **`onEndReached`** works as it does on `ListView`.
- **The rest of the screen is still in reach.** `args.*`, `data.*` and
  `state.*` read inside the builder as they do around it.

They need `UiRuntime`: rfw's runtime cannot hand a local widget a list item,
only numbers, strings and flags. On rfw's, write
`ListView(children: [...for m in items: ...])`, which is lazy too.
