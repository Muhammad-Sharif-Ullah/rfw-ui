# Performance

How fast a screen built with `rfw_ui` is, compared with the same screen
written in Dart, and where the time goes. Every number here was measured, by
the app in [`../benchmark`](../benchmark). None is an estimate.

## On UiRuntime, the kit's own runtime

The kit now runs on [UiRuntime](runtime.md), in place of rfw's runtime. On the
same 300 cards (medians in ms, Apple M1, profile mode):

| | Flutter | kit on rfw | kit on UiRuntime |
|---|---|---|---|
| show the screen | 105.3 | 131.3 | **112.2** |
| change every title | 43.7 | 75.5 | **27.9** |
| change one title | 30.4 | 59.7 | **8.4** |
| live heap, MB | 63.8 | 76.2 | **65.4** |

A data change is now faster than Flutter's `setState`, and a first build costs
7% more than Flutter's, where on rfw it cost 25% more. The rest of this page
was measured on rfw's runtime, the one `--dart-define=RFW_RUNTIME=rfw` still
gives. Its figures stand for that runtime.

## The short answer (on rfw's runtime)

- **Scrolling is as smooth as Flutter.** Scrolling 1,000 cards for 4 seconds
  dropped no frames with any of the four builds. Per-frame build times were
  within half a millisecond of each other.
- **Building a screen costs about a third more than Flutter.** That's 300
  cards in 141 ms against 105 ms. Nearly all of it is rfw itself: rfw's own
  widgets take 135 ms. The kit adds 2–4% on top of rfw, and theme tokens add
  2% more.
- **Changing data costs about twice what Flutter does.** Every rfw screen
  pays this, not just this kit's, and it has a workaround (see below).
- **Dialogs open as fast as Flutter's.** That's 5.1 ms against 4.3 ms, after
  the fix described under "Drawbacks".

- **A long list costs what its visible rows cost.** A `ListView` of 10,000
  cards mounts in 5.0 ms, as Flutter's does (4.9 ms). It took 562.7 ms
  before the kit's lists built their rows as they scroll in.

**Why** it is slower, from a CPU profile, is in
[why-slower.md](why-slower.md). In short, every argument is a hash-map lookup
at runtime, and a data change throws away each row's lookups and does them
all again. Both are in rfw. The repository now carries rfw with each lookup
key hashed once (`third_party/rfw`), which takes 8% off a mount and 18% off a
data change, measured. The tables below were measured before that change and
before lazy lists, unless they say otherwise.

## How it was measured

[`benchmark/lib/screens.dart`](../benchmark/lib/screens.dart) builds the same
card four ways. Each card has an avatar icon, a title, a grey subtitle and
two buttons.

| Build | What it is |
|---|---|
| `flutter` | Dart widgets, written by hand. The baseline. |
| `rfwCore` | rfw's own `core.widgets` + `core.material`, as rfw ships them. |
| `uiLiteral` | `rfw_ui` reading the same source text as `rfwCore`. |
| `uiTokens` | `rfw_ui` written as intended: `padding: { horizontal: "md" }`, `style: { base: "titleMedium" }`, `icon: "account_circle"`. |

The app runs in **profile mode** (`flutter run --profile -d macos`): AOT
compiled, with no asserts. Debug-mode numbers mostly measure the asserts, so
none are used here. Each scenario is repeated ten times. The first run warms
the glyph and text-layout caches for every build alike and is thrown away, so
each figure is the median of the remaining nine.

Two kinds of number appear below:

- **UI-thread work, in ms.** This is the time from the first callback of the
  frame a change causes to its last, which covers build, layout, paint and
  composite. Any synchronous work in the change itself (an event handler, a
  `data.update`) is added on. Waiting for the vsync is not counted.
- **Frame timings,** from the engine's `FrameTiming`, for scrolling, where a
  whole run of frames matters.

Machine: Apple M1, 8 GB, macOS 26.6, Flutter 3.47.3, rfw 1.1.4. A mid-range
phone is roughly 2–4× slower. The ratios between the builds are what carry
over, not the milliseconds.

To run it yourself:

```bash
cd packages/rfw_ui/benchmark
flutter run --profile -d macos     # prints BENCH {...} lines, then quits
```

## Results

### Building a screen

| Cards (eager, in a Column) | flutter | rfwCore | uiLiteral | uiTokens |
|---|---|---|---|---|
| 50: UI-thread ms | 12.7 | 22.0 | 22.0 | 22.1 |
| 300: UI-thread ms | **105.0** | 135.3 | 138.2 | **140.8** |
| 300: elements in the tree | 33,326 | 37,830 | 36,932 | 37,232 |

rfw wraps every widget a remote file builds in one of its own (`_Widget`)
that resolves the arguments. That's about 13% more elements, and the extra
time above comes from resolving the arguments. `rfw_ui` has *fewer* elements
than rfw's own widgets because some of rfw's core widgets are themselves
built from more than one widget.

At 50 cards, a typical screen, the difference is 9 ms once, when the screen
first appears.

### Changing data

| 300 cards | flutter | rfwCore | uiLiteral | uiTokens |
|---|---|---|---|---|
| change every title: UI-thread ms | 44.1 | 85.0 | 85.6 | 86.1 |
| change one title: UI-thread ms | 31.8 | 66.1 | 76.6 | 76.3 |

`flutter` here calls `setState` at the top of the list, which rebuilds every
card. That's what a plain `StatefulWidget` does.

**Why one change costs nearly as much as all of them.** A list in rfw is
`...for item in data.items`, and the widget holding the loop depends on
`data.items` as a whole. Change anything inside the list and that widget
re-resolves every item's arguments and rebuilds every row. The kit pays about
15% more than rfw's own widgets here, because each rebuilt widget decodes its
arguments again through the theme.

**What helps.** Two things, depending on who changes the value.

- A value only the screen changes, such as a row's "liked" or "expanded",
  belongs in rfw `state` on the row's own widget, not in `data`:

  ```
  widget FeedRow { liked: false } = Row(children: [
    Text(text: args.title),
    IconButton(
      icon: switch state.liked { true: "favorite", default: "favorite_border" },
      onPressed: set state.liked = true,
    ),
  ]);
  ```

  Setting `state` rebuilds that one row. The list's data never changes.
- A value the app or server changes has to go into `data`. If it is inside
  the list, the list rebuilds. rfw has no way to index data by another value
  (`data.likes[item.id]` is not valid rfw), so it cannot live elsewhere and
  still be looked up per row. Keep such lists to the rows on screen (paging),
  and batch updates into one `data.update` rather than one per row.

### Long lists

A feed of cards in a `ListView`, mounted 20 times, median UI-thread ms
(`bun tool/profile.ts uiTokens:listmount:10000:20`, profile mode, M1):

| 10,000 rows | flutter | uiTokens, rows bound up front | uiTokens, rows built as they scroll in |
|---|---|---|---|
| mount | 4.9 | 562.7 | **5.0** |

Before, rfw bound every row of the `...for` (a copy of the row's description
each) before the list built the first ten. Now the list asks for row `i` when
it scrolls into view. 300 rows mount in 5.3 ms the same way.

### Scrolling

1,000 cards in a `ListView`, scrolled 55,000 px at a constant speed over 4 s.
It was run twice per build, and both runs are shown.

| | flutter | rfwCore | uiLiteral | uiTokens |
|---|---|---|---|---|
| frames | 260 / 260 | 260 / 260 | 260 / 260 | 260 / 260 |
| build p50 ms | 3.14 / 2.98 | 2.87 / 2.82 | 2.73 / 2.80 | 2.73 / 2.87 |
| build p99 ms | 4.13 / 4.25 | 4.31 / 4.50 | 4.71 / 4.74 | 4.93 / 4.95 |
| worst frame ms | 4.30 / 4.39 | 5.17 / 5.13 | 4.92 / 4.95 | 7.42 / 5.18 |
| frames over 16.7 ms | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| raster p50 ms | 0.63 / 0.66 | 0.61 / 0.63 | 0.59 / 0.61 | 0.63 / 0.63 |

A `ListView` only builds the rows coming into view, so it costs the same
however it was written. The remote list does create one small widget object
per item every time the list itself rebuilds, but not while scrolling.

An earlier run had one 187 ms frame in the `uiTokens` scroll. It did not
happen again in two later passes of every build. It looks like a garbage
collection or a window event rather than anything in the kit, but it is
reported here because it was seen.

### Motion

The claim behind the whole motion layer is that **an animated frame paints a
layer and rebuilds nothing** ([motion.md](motion.md)). This is the screen
that tests it: a header that shrinks and fades with the scroll
(`ScrollTransition`), a blurred bar over it (`BackdropFilter`), and 60 cards
each wrapped in an `Animate` running a shimmer on a 1.4 s loop, for as long
as it is on screen. The same screen is written in Dart beside it
(`FlutterMotion` in `benchmark/lib/screens.dart`), the same way a careful
Dart author would write it: one `AnimationController` per card and an
`AnimatedBuilder` with the card passed as `child:`.

Scrolled 4 s at a constant speed with every animation still running:

| ms per frame | flutter | uiTokens | uiRuntime |
|---|---|---|---|
| frames | 611 | 611 | 611 |
| build p50 | 0.37 | 0.37 | 0.39 |
| build p90 | 0.81 | 0.86 | 0.85 |
| build p99 | 1.47 | 1.75 | 1.65 |
| build worst | 1.97 | 2.08 | 2.69 |
| raster p50 | 1.63 | 1.68 | 1.72 |
| raster p90 | 2.53 | 2.50 | 2.54 |
| **frames over 16.7 ms** | **0** | **0** | **0** |

Standing still, with the 60 shimmers running and nothing else happening
(2 s, 234 frames):

| ms per frame | flutter | uiTokens | uiRuntime |
|---|---|---|---|
| build p50 | 0.42 | 0.43 | 0.45 |
| build p99 | 1.04 | 1.07 | 1.08 |
| raster p50 | 1.58 | 1.67 | 1.57 |
| frames over 16.7 ms | 0 | 0 | 0 |

**Sixty running animations cost 0.43 ms of build per frame on the kit and
0.42 ms in hand-written Dart.** That is the rule holding: what the frame
costs is the layers being painted, and the remote subtree underneath them is
not rebuilt, so rfw's per-argument lookups are not paid again. A build that
rebuilt its subtree would show the difference here first, and in the ratio
between the two columns.

Mounting that screen (median of 9, after a warm-up run):

| | flutter | uiTokens | uiRuntime |
|---|---|---|---|
| UI-thread ms | 3.9 | 6.8 | 7.2 |
| elements | 886 | 1,003 | 1,004 |

The mount figures move by 1–2 ms between runs on an otherwise busy machine;
the two kit columns are the same number within that noise. The gap to Dart is
the usual first-build cost of rfw's argument resolution, not anything the
animations add.

#### On real phones

The same screen, the same scenario, run on two devices over a cable
(`flutter run --profile -d <id> --dart-define=ONLY=motion`). Both phones
drive a 60 Hz display, so 16.7 ms is the budget:

| Scrolling 4 s, ms per frame | macOS M1 | | | iPhone, iOS 27 | | | CPH2891, Android 16 | | |
|---|---|---|---|---|---|---|---|---|---|
| | flutter | uiTokens | uiRuntime | flutter | uiTokens | uiRuntime | flutter | uiTokens | uiRuntime |
| build p50 | 0.37 | 0.37 | 0.39 | 1.58 | 1.65 | 1.69 | 2.63 | 2.73 | 2.95 |
| build p99 | 1.47 | 1.75 | 1.65 | 3.90 | 4.94 | 4.58 | 6.11 | 5.93 | 5.76 |
| raster p50 | 1.63 | 1.68 | 1.72 | 2.71 | 2.80 | 2.82 | 9.92 | 8.80 | 9.32 |
| raster worst | 12.49 | 3.47 | 4.70 | 6.44 | 4.20 | 4.25 | 16.64 | 14.41 | 16.17 |
| **frames over 16.7 ms** | **0** | **0** | **0** | **0** | **0** | **0** | **0** | **0** | **0** |

| Standing still, 60 shimmers, ms per frame | macOS M1 | | | iPhone | | | CPH2891 | | |
|---|---|---|---|---|---|---|---|---|---|
| | flutter | uiTokens | uiRuntime | flutter | uiTokens | uiRuntime | flutter | uiTokens | uiRuntime |
| build p50 | 0.42 | 0.43 | 0.45 | 1.72 | 1.71 | 1.73 | 2.15 | 2.55 | 3.03 |
| raster p50 | 1.58 | 1.67 | 1.57 | 2.87 | 2.97 | 2.96 | 5.28 | 6.24 | 8.38 |
| frames over 16.7 ms | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

| Mounting it, median UI-thread ms | flutter | uiTokens | uiRuntime |
|---|---|---|---|
| macOS M1 | 3.9 | 6.8 | 7.2 |
| iPhone, iOS 27 | 9.0 | 12.7 | 13.4 |
| CPH2891, Android 16 | 19.7 | 15.7 | 17.6 |

**No build drops a frame on either phone**, scrolling or standing still, and
the gap between the kit and hand-written Dart is a tenth of a millisecond of
build on the iPhone and a tenth on the Android. The Android's raster is the
one number near its budget (8.8-9.9 ms of 16.7), and it is the same number
for Dart: a blurred bar and sixty `ShaderMask`s cost what they cost, whoever
builds them.

The Android mount figures read the wrong way round -- the kit faster than
Dart -- because a single mount of this screen is 15-20 ms on that phone with
a 5 ms spread between runs. Read them as "the same", not as a win.

**What was found by measuring.** The first version of this screen blurred the
whole window rather than the 48-pixel bar. That is Flutter's own
`BackdropFilter` behaviour without a clip, and the kit then only clipped when
a `borderRadius` was given. It now clips to its own bounds by default, which
is both correct and what bounds the cost; `clip: false` gives the old
behaviour back. The table above is the clipped screen.

### Opening a dialog

| UI-thread ms, tap to the first frame | flutter | uiTokens, before | uiTokens, now |
|---|---|---|---|
| over an empty screen | 4.3 | 2.7 | 4.9 |
| over a screen of 300 cards | 4.3 | **100.0** | **5.1** |

### Starting up

| Per call, ms | |
|---|---|
| `parseLibraryFile`, 13 KB of rfw text (the `/ui-kit` demo screen) | 0.6–1.2 |
| `decodeLibraryBlob`, the same screen as a binary blob | 0.1 |
| `createUiWidgets()` | 0.01 |
| `parseDataFile` / `decodeDataBlob` of the demo theme | 0.08 / 0.01 |
| `UiThemeDocument.decode`, both brightnesses, 39 component themes | 1.6 |

Text is about 9× slower to parse than binary, and both are small next to a
frame. Ship `.rfw` binary to phones anyway: on a slow phone the text figure
is a few milliseconds per screen, and it is paid every time a screen loads.

### Size

| | |
|---|---|
| `icons.g.dart`, every Material and Cupertino icon by name | 496 KB of source |
| `catalog.json` + `icons.json`, which the studio editor loads | 512 KB (about 60 KB gzipped) |

The icon table is what lets a remote file name any SDK icon. Names resolve to
the SDK's own constants, so Flutter's icon tree-shaking still works for a
release build. Codepoints in rfw's own `{ icon, fontFamily }` form are the
exception, and they need `--no-tree-shake-icons`.

## Drawbacks, and what has been done about each

| Drawback | Measured cost | Status |
|---|---|---|
| Opening a dialog rebuilt the whole screen behind it: registering the dialog's library on the screen's runtime rebuilt every remote widget. | 100 ms over 300 cards | **Fixed.** Dialogs and sheets are built on a runtime of their own, which holds the screen's libraries plus one per dialog depth. Now 5.1 ms. A test holds it: the screen's runtime is not notified once in 50 dialogs (`test/lifecycle_test.dart`). |
| A change anywhere in a list rebuilds the whole list. | 66–76 ms for one title in 300 | rfw's design: a loop depends on its whole list, and rfw cannot index data by a value. Not fixable in the kit. Screen-only values go in rfw `state` (a one-row rebuild); keep data-driven lists short. |
| A first build costs about 30% more than Dart. | +36 ms at 300 cards, +9 ms at 50 | rfw's argument lookups: a key built and hashed, and a hash map searched, for every argument of every widget. The kit's own code is 2.4 ms of 153 ([why-slower.md](why-slower.md)). **Partly fixed:** rfw is carried with each key hashed once (`third_party/rfw`): 8% off a mount and 18% off a data change, measured with stock and patched runs taking turns. The rest needs a runtime of our own. |
| Every widget re-decodes its arguments on rebuild (`"primary/50"` is parsed each time). | 2.3 ms of a 93 ms data change, by the CPU profile | **Not the cause**, profiled since. A data change is slow because rfw drops every row's argument cache and looks every argument up again ([why-slower.md](why-slower.md#4-a-data-change-repeats-the-lookups)). A cache in the kit would not help, since the kit cannot tell an unchanged argument from a changed one without asking rfw. |
| `...for` lists bound every row up front, even in a `ListView`. | 562.7 ms for a 10,000-row `ListView` | **Fixed** for `ListView`, `GridView` and the sliver lists, which now build each row as it scrolls in: 5.0 ms. A `Column` still builds every child, as Flutter's does, so long lists go in a `ListView`. |
| rfw text is parsed on the phone. | 0.6–1.2 ms per 13 KB here | Serve `.rfw` binary (9× faster). The console already serves both. |

## What these numbers do not cover

- **A real phone, except for motion.** The motion screen was run on an
  iPhone (iOS 27) and a CPH2891 (Android 16) as well, and the table above
  carries both. Everything else on this page ran on an M1 Mac; the ratios
  hold, and the milliseconds are 2–4× higher on a phone — which is what the
  motion rows show.
- **Memory over hours of use.** Leaks are covered separately, in
  [lifecycle-and-memory.md](lifecycle-and-memory.md). These runs did not
  record heap size.
- **Raster cost of very heavy effects.** The motion screen above has one
  blurred bar and 60 shimmers, and rasters in 1.7 ms. A screen of blurs over
  blurs is the same render objects whoever builds them, and has not been
  measured.
