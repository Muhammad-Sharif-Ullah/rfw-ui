# Why a remote screen is slower than Flutter

[performance.md](performance.md) says how much slower. This says why, from
a CPU profile of the same screen built three ways. Every number below was
measured, and the place in rfw's source behind each cost is named.

## The short answer

- **Only build is slower.** A remote screen ends up with the same render
  objects a Dart one has. Layout and paint cost the same within a few
  milliseconds, and so does rasterizing, which
  [performance.md](performance.md#scrolling) measures.
- **It is rfw, not the kit.** rfw's own `core.widgets` cost the same as
  `rfw_ui`, within run-to-run noise. The kit's own code is 2.4 ms of a
  153 ms frame.
- **It is not the extra widget rfw puts around each one.** Creating and
  mounting those elements costs about 2 ms.
- **It is that every argument is looked up at runtime.** A Dart `Text(title)`
  is a field already in hand. A remote `Text(text: args.title)` is found by
  building a key for the path, hashing it, searching a hash map, and on a miss
  walking references through the card's arguments and the loop's item to the
  data. This screen does 90,600 of those per mount. More than a third of the
  time spent reading is the hashing alone, and the cache all this fills stays
  in memory for as long as the widget does.
- **A data change repeats almost all of it.** rfw rebuilds each row with a new
  description object, sees a changed widget, and throws away the row's cache,
  so every argument of every row is looked up again.
- **The biggest fixes are in rfw.** Hashing each key once, a two-line change
  to rfw, takes about 16 ms (11%) off the kit's mount and 16–24 ms (19–26%)
  off a data change. That patch is now shipped: the repository carries rfw
  with it in `third_party/rfw`. Measured again there, with stock and patched
  runs taking turns, it took 8% off a mount and 18% off a data change.

## How this was measured

[`benchmark/tool/profile.ts`](../benchmark/tool/profile.ts) runs one scenario
of the [benchmark](../benchmark) in profile mode on macOS and reads the Dart
VM's CPU samples for exactly the frames it measures. The screen is a feed of
cards, each with an icon, a title, a subtitle and two buttons, in a
`SingleChildScrollView(Column)`, so every card is built. It is measured three
ways:

| | |
|---|---|
| `flutter` | Dart widgets, by hand. The baseline. |
| `rfwCore` | rfw's own `core.widgets` + `core.material` |
| `rfw_ui` (`uiTokens`) | this kit, written with theme tokens |

There are two scenarios. **Mount** puts 300 cards on an empty screen, 40
times. **Data change** replaces every card's title with `data.update` (rfw)
or `setState` (Flutter) on a mounted screen, 40 times. Frames are forced
rather than waited for, so no vsync wait is counted. The frame times below
are medians. Each part of a frame is the median frame's wall time multiplied
by that part's share of the CPU samples.

Machine: Apple M1, Flutter 3.47.3, rfw 1.1.4. How the profiler works, and the
four things about it that had to be got right, is in the
[benchmark README](../benchmark/README.md#where-the-time-goes-the-cpu-profiler).

## Where the time goes

### The frame

| median, ms | flutter | rfwCore | rfw_ui |
|---|---|---|---|
| **Mount, 300 cards** | **102.9** | **150.2** | **152.7** |
| build | 51.2 | 92.1 | 95.3 |
| layout | 42.3 | 46.3 | 47.2 |
| paint and compositing | 9.3 | 11.6 | 10.0 |
| **Data change, 300 cards** | **39.6** | **84.5** | **93.4** |
| build | 23.1 | 63.7 | 71.0 |
| layout | 10.3 | 12.9 | 13.4 |
| paint | 5.8 | 7.2 | 8.0 |
| **Mount, 1,000 cards** | **312.6** | | **521.9** |
| build | 143.5 | | 338.9 |
| layout | 136.2 | | 147.2 |

The gap is build: 1.9× Flutter's on a mount, 3.1× on a data change. The few
milliseconds' difference in layout and paint is noise. An earlier batch of
the same runs had layout within a millisecond across all three, and garbage
collection outside build is under 2 ms in every run.

rfwCore and rfw_ui are within the noise of each other. The earlier batch had
the kit 2 ms *faster* than rfwCore on a data change, where this one has it
9 ms slower.

### What the extra time is

The kit's mount against Flutter's, by what the code is. Native time, such as
allocation, is charged to the Dart code that asked for it.

| 300 cards, mount, ms | flutter | rfw_ui | extra |
|---|---|---|---|
| Dart's maps, hashing, list iteration, string compares | 10.0 | 34.6 | **+24.6** |
| garbage collection | 19.1 | 27.8 | **+8.7** |
| rfw's own code | 0 | 6.2 | **+6.2** |
| text and the engine (`dart:ui`) | 43.8 | 47.8 | +4.0 |
| Flutter's element tree and foundation | 8.9 | 11.6 | +2.7 |
| the kit's own code | 0 | 2.4 | +2.4 |

Half of the extra is in Dart's collections: hashing, hash-map lookups and
inserts, and the list compares of key equality. Flutter's mount spends 10 ms
there; the kit's spends 35. rfw's own code and the kit's together cost less
than the collections they call into.

### Inside rfw's widget

Inclusive time, so the rows overlap: `_fetch` contains `_Key.hashCode`, and
the kit's `textStyle` is mostly the `_fetch` calls it makes.

| rfw_ui, 300 cards, mount, ms | |
|---|---|
| `_WidgetState.build`: all a remote widget does to build itself | 45.2 |
| `_WidgetState._fetch`: reading arguments | 33.1 |
| `_Key.hashCode`: hashing an argument's path | 12.9 |
| `_CurriedWidget.resolve`: following references to the value | 8.0 |
| `_WidgetState.childList`: expanding a `...for` | 7.3 |
| `_CurriedWidget._listLookup`: finding item *i* | 3.2 |
| `_CurriedWidget._bindLoopVariable`: copying a row's description | 2.6 |
| kit, `UiDecoder.textStyle` | 10.3 |
| kit, `UiResolver.of`: the theme, per widget | 4.0 |
| kit, `uiKeyOf`: looking for a `key` argument | 3.8 |
| creating the extra `StatefulElement` per widget | 0.8 |
| `_CurriedWidget.build`: the `_Widget` itself, and a new `DynamicContent` for it (line 1015) | 0.8 |

Flutter's equivalent of the first row is `FlutterCard.build`: 1.5 ms for all
300 cards on a mount, and 0.5 ms on a data change.

## The mechanism

Line numbers are in rfw 1.1.4's `lib/src/flutter/runtime.dart`.

### 1. An argument is a lookup, not a field

rfw parses `Text(text: args.title)` into a description: a map,
`{text: <reference to args.title>}`. Every widget a remote file builds is
rfw's `_Widget` (line 1138), and its state is the `DataSource` that the
widget's Dart builder reads from. When the kit's `Text` builder asks for
`source.v<String>(['text'])`, `_fetch` (line 1406):

1. builds a `_Key` of the section and the path `['text']`;
2. looks it up in the widget's `_argsCache`. `_Key.hashCode` (line 1536) is
   `Object.hash(section, Object.hashAll(parts))`, computed again on every
   call, and `==` compares the two paths element by element;
3. on a miss, `resolve` walks the description (`_resolveFrom`, line 834).
   `text` is a reference to the card's `args.title`. That is a reference to
   the loop's `item.title`, which is a key in a map from `data`, which holds
   the string;
4. adds the key to every data subscription the walk touched (a set insert,
   so another hash), and stores the result (a third hash).

Flutter's `Text(item.title)` does none of this. The compiler has already
turned it into loads from objects in hand.

### 2. Absent arguments are looked up too

A decoder cannot ask which arguments a widget was given. rfw's `DataSource`
(line 83) answers questions about one path at a time and has no way to list
a map's keys. So a builder asks about every argument it supports, and a number
or colour that can come in more than one form is asked about once per form.

Reads per widget, counted by calling each builder with a `DataSource` that
counts:

| widget in the card | rfw core | rfw_ui |
|---|---|---|
| `Text` with a style (2 fields set) | 37 | 51–53 |
| `Padding` | 8 | 41 |
| `Icon` | 7 | 22 |
| `Card` | 10 | 28 |
| a `Row` or `Column` | 7 | 15 |
| **per card** | **168** | **302** |
| **per 300-card mount** | **50,400** | **90,600** |

Of the kit's 302, 65 are `key`: five reads for each of the card's 13 widgets,
for an argument none of them is given. Most of the rest are the 25 fields of
a text style and the nine sides of a padding, nearly all of them absent. They
cost less than the count suggests, because a path read a second time is a
cache hit, but a hit still builds and hashes a key. The kit also builds fewer
remote widgets per card than rfwCore: a button's label is part of the button,
not a remote `Text` of its own. Between more reads, mostly hits, and fewer
widgets, the two land level.

### 3. Each row of a list is a copy

`...for item in data.items: FeedCard(...)` is one entry in the column's
children. `childList` (line 1311) first asks how long the expanded list is,
and then asks for each child `i` by its own path. For each one,
`_listLookup` (line 759) walks the data list from the start to `i`. rfw's own
comment above it says this is O(N²). `_bindLoopVariable` (line 677) then
copies the card's whole description, every argument map of every widget in
it, with `item` filled in.

At 300 cards this is 7.3 ms. At 1,000 it is 28.9 ms, and `_listLookup` grows
from 3.2 to 13.7 ms, 4.3 times for 3.3 times the rows. The quadratic part is
real but cheap per step. It matters at thousands of rows, not hundreds.

### 4. A data change repeats the lookups

`data.update('items', …)`:

1. deep-copies the new list into the `DynamicContent` (`content.dart`,
   line 176). Here that is too small to show in the profile;
2. notifies the column's widget, which depends on `data.items` as a whole
   because its loop read it;
3. the column rebuilds, and `childList` binds every row again, so each row is
   given a **new** description object;
4. each row's `_WidgetState.didUpdateWidget` (line 1173) compares the new
   description to the old by identity. It is not the same object, so the
   widget calls `_unsubscribe()` (line 1251), which drops every subscription
   and clears `_argsCache`;
5. the same happens to every widget inside the row, because their
   descriptions were copied too. Every argument of every widget is looked up
   again from nothing, and each widget is given a new `DynamicContent` for
   its builder scope as well (line 1015), even when the scope is empty.

On a data change the kit spends 26.8 ms in `_fetch`, against 33.1 ms on a
first mount: four fifths of a first build's lookup time, spent again. `_unsubscribe`
appears in the update profile and not in the mount one. Flutter's `setState`
rebuild only re-runs `build` methods with new values, 23.1 ms of build in
all.

Garbage collection shows it too: 0.6 ms in Flutter's update, 5.9–7.5 ms in
rfw's. The keys, lists and copied descriptions of the old frame are all
garbage now.

### 5. The cache stays

The live heap with the screen mounted, after a full GC:

| | flutter | rfw_ui |
|---|---|---|
| 300 cards | 63.5 MB | 77.8 MB (rfwCore 77.1) |
| 1,000 cards | 180.5 MB | 227.2 MB |
| live `_Key` objects, 1,000 cards | 0 | 172,019 |
| live lists (`_List`, `_GrowableList`), 1,000 cards | 463,006 | 848,719 |
| live maps (`_Map`), 1,000 cards | 157,475 | 245,511 |

rfw keeps about 47 KB more per card than Flutter, at both sizes. That's the
argument caches, with about 172 keys per card: one for every path a widget
read, absent ones included, each with its own list of path parts. It's also
the copy of the card's description that each row is bound to, a map per
widget. All of it stays for as long as the widget is mounted. Nothing leaks,
since it all goes when the widget does
([lifecycle-and-memory.md](lifecycle-and-memory.md)). But a bigger live heap
means more for the collector to mark. Garbage collection
during a 1,000-card mount is 104 ms with rfw against 44 ms with Flutter, which
is most of why the gap grows from 1.48× at 300 cards to 1.67× at 1,000.

## Proof: hash each key once

If the hashing is the cost, computing it once should take it away. A copy of
rfw 1.1.4 with `_Key`'s hash computed in its constructor:

```dart
// before
_Key(this.section, this.parts) : assert(_isValidKey(parts), '$parts is not a valid key');
@override
int get hashCode => Object.hash(section, Object.hashAll(parts));

// after
_Key(this.section, this.parts) : hashCode = Object.hash(section, Object.hashAll(parts)), assert(_isValidKey(parts), '$parts is not a valid key');
@override
final int hashCode;
```

| median ms | rfw 1.1.4 | key hashed once | saved |
|---|---|---|---|
| rfwCore, mount, 300 cards | 150.2 | 126.6 | 23.6 (16%) |
| rfw_ui, mount, 300 cards | 152.7 | 136.0 | 16.7 (11%) |
| rfw_ui, data change, 300 cards | 93.4 | 69.5 | 23.9 (26%) |
| `_fetch`, inside the rfw_ui mount | 33.1 | 24.3 | 8.8 |

The earlier batch, measured the same way, gave 147 → 131 ms for the kit's
mount and 85 → 69 ms for its data change (means rather than medians). Nothing
else differs between the two copies of rfw, and `_Key.hashCode` drops out of
the profile. The hash it computes is the same, so nothing a widget sees
changes. rfw's own test suite gives the same result against the patched copy as
against the original: 128 pass, and the same 7 are skipped.

## What can be done, and by whom

| Change | Where | What it saves |
|---|---|---|
| Hash a `_Key` once | rfw, the two lines above | **Shipped** in `third_party/rfw`, which every package here uses through `dependency_overrides`. 11% of a mount and 19–26% of a data change in the runs above; 8% and 18% again with stock and patched runs taking turns. Still worth sending to `flutter/packages`, after which the copy can go. |
| Keep a row's cache when its description has not changed | rfw: compare descriptions by value, or reuse a row's bound description while its item is unchanged | Most of the 26.8 ms of lookups a data change repeats. *Not measured.* |
| Let a decoder list the keys it was given | rfw's `DataSource` | The kit's probes for absent arguments, most of its 302 reads per card. *Not measured.* |
| Walk the list once, not once per item | rfw `_listLookup` (its own TODO) | 3.2 ms at 300 cards, 13.7 ms at 1,000 |
| Bind a list's rows only as they scroll in | the kit: `ListView`, `GridView` and the sliver lists read `children` a row at a time | **Shipped.** A 10,000-row `ListView` mounts in 5.0 ms instead of 562.7 (Flutter 4.9). A `Column` still binds every row. |
| Read `key` in fewer than five reads | the kit, `uiKeyOf` | at most 3.8 ms of 153. rfw's `DataSource` cannot tell an absent key from a present one in fewer reads, so this waits for a runtime of our own. |
| Build the theme resolver once per theme, not per widget | the kit, `UiResolver.of` | **Tried: no gain.** Its 4.0 ms is `Theme.of` itself (three inherited lookups and registering the dependency), which every Material widget pays too. With a cached resolver the mount measured 187.2 and 188.4 ms against 191.3 and 187.7 without, so it was not kept. |
| Use `ListView`, rfw `state` for screen-only values, and short data lists | the app; see [performance.md](performance.md) | A `ListView` builds only the visible rows, so the mount is a few rows rather than 300 |

The kit's own two rows together are under 8 ms of a 153 ms frame. The rfw
rows are where the gap to Flutter is.
