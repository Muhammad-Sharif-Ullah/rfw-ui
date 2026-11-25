# Lifecycle and memory

What the kit creates for a remote screen, when it frees it, and how the "no
leaks" claim is checked.

## The short answer

**No leaks were found, and every test is checked for them.** All of
`flutter test` runs under Flutter's leak tracker
([`test/flutter_test_config.dart`](../test/flutter_test_config.dart)). Any
test that leaves a controller, focus node, runtime or other disposable
undisposed fails, and so does one that disposes an object but keeps holding
it. A check that cannot fail proves nothing, so it was tested by deleting
the `dispose()` of the focus node a text field owns: the key and focus tests
then failed with `notDisposed: FocusNode`.

The leak tracker found one real leak, and it was in a test, not the kit: a
`UiThemeController` the test created and never disposed. That test is fixed.

The one thing that **grows** while a screen is open is `UiStore`, and it is
bounded by what the screen writes. See below.

## Who creates what, and who frees it

| Object | Created by | Freed | Checked by |
|---|---|---|---|
| `Runtime`, `DynamicContent` for the screen | your app | your `dispose()` | your code. The kit never creates the screen's runtime. |
| Runtime for dialogs and sheets | `UiRemoteWidget`, the first time a dialog opens | `UiRemoteWidget.dispose()` | leak tracker, every dialog test |
| `UiActions` (the `ui.*` dispatcher) and `UiStore` | `UiRemoteWidget` | garbage collected with it. Neither holds a listener, timer or stream. | leak tracker (not-GCed) |
| `UiScopeData` (keys and focus registry) for each screen or dialog | `_UiHost` state | with the state. Inputs unregister themselves in `dispose()`. | `keys_focus_test.dart` |
| `TextEditingController` and `FocusNode` of every text field (TextField, CupertinoTextField, CupertinoSearchTextField, SearchBar) | the field's state | the field's `dispose()` | leak tracker, plus the mutation check above |
| `PageController`, `FixedExtentScrollController`, `TransformationController` (PageView, CupertinoPicker, ListWheelScrollView, InteractiveViewer) | `UiOwned` state | `dispose()` | leak tracker |
| `AnimationController` and the delay `Timer` of every `Animate` | `UiTicker` state | `dispose()`: the timer is cancelled, then the controller disposed | leak tracker, `motion_test.dart` |
| The scroll listener of a `ScrollTransition` | `UiScrollDriver` state | `dispose()`: removed from the position, then the notifier disposed | leak tracker, `motion_test.dart` |
| App-bar slot size notifiers (Scaffold, AppBar, SliverAppBar) | their state | `dispose()`. A post-frame write checks it is still alive first. | leak tracker |
| Input values (Switch, Checkbox, Slider, ...) | `UiValue` state, as a plain field | with the state | nothing to free |
| Keys (`key: "email"`) | built on demand, equal by tree and name | never stored, so nothing to free | `UiKey` holds no registry |
| `UiThemeController` | your app | your `dispose()` | your code |

## The lifecycle of one remote screen

1. **Mount.** `UiRemoteWidget.initState` creates the dispatcher and store
   and listens to the screen's runtime, which is how dialogs learn about
   library edits. `_UiHost` creates the screen's `UiScopeData`. Each widget
   in the file is built by rfw's `_Widget`, then by the kit's builder, which
   decodes the arguments against the theme in scope.
2. **Data changes** (`data.update`, `ui.set`). The widgets subscribed to the
   changed path rebuild. On rfw's runtime a loop over a list depends on the
   whole list, so a change inside it rebuilds every row; on UiRuntime a row
   whose item is unchanged keeps its widget, and only the changed row
   rebuilds (see [runtime.md](runtime.md) and [performance.md](performance.md)).
   Each input keeps its own value, so it moves at once, and data that arrives
   later wins.
3. **A dialog opens** (`ui.dialog`, `ui.bottomSheet`, ...). The first one
   creates the dialog runtime and copies the screen's libraries into it.
   Each depth reuses one library name (`ui.modal.0`, `ui.modal.1`), so 50
   dialogs make two libraries, not 50. The dialog gets its own
   `UiScopeData`, whose parent is the opener's. The screen's runtime is not
   touched, so the screen does not rebuild; a test holds this.
4. **A dialog closes.** Its route, its `_UiHost` and everything under it are
   disposed by the navigator. Its `ui.modal.N` library stays, to be reused by
   the next dialog at that depth.
5. **Unmount.** `UiRemoteWidget.dispose` stops listening to the screen's
   runtime and disposes the dialog runtime. Everything else goes with the
   element tree.

`test/lifecycle_test.dart` runs this end to end:

- A screen with every widget that owns a controller (four text fields, a
  switch, a `PageView`, a `CupertinoPicker`, a button that opens a nested
  dialog) is mounted and taken down 20 times.
- 50 rounds of a dialog over a dialog are opened and closed.
- One key is written 1,000 times.

All of it runs under the leak tracker.

## What grows, and how far

| What | Grows with | Bound | Freed |
|---|---|---|---|
| `UiStore` | every distinct path `ui.set` writes | what the screen writes. A form of 20 fields keeps 20 values; writing `rows.0` … `rows.999` keeps 1,000. | with the screen, or `store.set('rows', null)` |
| Dialog runtime libraries | the deepest dialog-in-a-dialog opened | one library per depth | with the screen |
| rfw's own caches in a runtime | widgets and libraries in use | rfw's | when the runtime is disposed |

`UiStore` keeps a copy because rfw's `DynamicContent` can be written but not
read back, and `ui.toggle` and `ui.set` on a nested path need the current
value. It is not a leak in the garbage-collector sense, but a screen that
writes ever-new keys for hours will hold them all. Write lists as one root,
not one key per item.

## Pictures

An `Image` is decoded into Flutter's `ImageCache`, which holds 100 pictures
or 100 MB, whichever comes first. What it holds is the **decoded** picture,
four bytes a pixel, at whatever size it was decoded -- not the size of the
file. A 1200x1200 photograph is 5.5 MB in the cache however small the box it
is drawn in, so eighteen of them fill the cache and start evicting.

The kit decodes an `Image` to the box it is drawn in, times the device pixel
ratio. Measured on the benchmark's `assets/photo.png` (1200x1200) in an
80-pixel box, on three devices (`--dart-define=ONLY=images`):

| MB in the image cache | pixel ratio | at its own size (before) | to the box (now) |
|---|---|---|---|
| macOS, M1 | 2.0 | 5.49 | **0.10** |
| iPhone, iOS 27 | 3.0 | 5.49 | **0.22** |
| CPH2891, Android 16 | 1.7 | 5.49 | **0.07** |

That is 25x less on the phone with the densest screen and 78x less on the
one with the coarsest, for the same picture on the same screen, and it is why
a list of photographs no longer pushes everything else out of the cache. The
picture is decoded once per size, so the same photograph drawn in two
different boxes is two entries.

The rules, in order:

- `cacheWidth` / `cacheHeight`, written down, win entirely.
- Otherwise `width` / `height` times `MediaQuery.devicePixelRatioOf(context)`.
- With neither, the picture is decoded as it is. An `Image` with no box in a
  list is the one case still worth writing `cacheWidth` for.

It is never upscaled: a picture smaller than its box is decoded as it is.

## Your side of it

Three things are yours to dispose, as they would be without the kit:

```dart
@override
void dispose() {
  runtime.dispose();        // the screen's Runtime
  themeController.dispose(); // if you made a UiThemeController
  super.dispose();
}
```

`DynamicContent` holds no resources and needs no dispose.

## Not yet checked

- **A long session on a phone.** The leak tracker checks that objects are
  disposed and collected after each test. Heap growth over an hour of real
  use, measured with DevTools on a device, has not been done.
- **Isolates and platform views.** The kit makes none.
