# rfw 1.1.4, with our changes

This is [rfw 1.1.4](https://pub.dev/packages/rfw/versions/1.1.4) from pub.dev,
under its own BSD licence ([LICENSE](LICENSE)). Its `example/`, `images/` and
coverage files are left out. Every package in this repository that uses rfw
points here with `dependency_overrides`:
`packages/rfw_ui`, `packages/rfw_ui/benchmark`, `studio` and `rfw-checking`.

Each change is listed below with why it was made. rfw's own test suite runs
against this copy: `flutter test` here gives 128 passing and 7 skipped, the
same as stock 1.1.4. Moving to a newer rfw means copying it in again and
reapplying the changes below.

## 1. Each lookup key is hashed once

`lib/src/flutter/runtime.dart`, `_Key`. The hash is computed in the
constructor and stored, where 1.1.4 recomputed
`Object.hash(section, Object.hashAll(parts))` on every `hashCode` call:

```dart
_Key(this.section, this.parts) : hashCode = Object.hash(section, Object.hashAll(parts)), assert(...);
@override
final int hashCode;
```

**Why:** each argument a widget reads builds a `_Key`, and rfw hashed it up
to three times: once for the argument cache and again for the subscription
sets. That was 12.9 ms of a 153 ms frame showing 300 cards
([`packages/rfw_ui/doc/why-slower.md`](../../packages/rfw_ui/doc/why-slower.md)).
The hash is the same value, so nothing a widget sees changes.

**Measured** (median, profile mode, M1, 300 cards, `benchmark/tool/profile.ts`):

| | rfw 1.1.4 | this copy |
|---|---|---|
| rfw_ui, mount | 152.7 ms | 136.0 ms |
| rfw_ui, data change | 93.4 ms | 69.5 ms |
| rfwCore, mount | 150.2 ms | 126.6 ms |

Measured again with this copy in place, stock and patched runs taking turns
(two rounds each), on a busier machine, so every time is higher:

| | rfw 1.1.4 | this copy |
|---|---|---|
| rfw_ui, mount | 205.4 ms | 191.3, 187.7 ms (−8%) |
| rfw_ui, data change | 113.4, 114.3 ms | 93.7, 94.0 ms (−18%) |

One stock mount run quit before it finished and isn't counted.

**Assumption:** a key's `parts` list is not changed after the key is made.
rfw never does this. A caller that did would already break stock rfw, whose
cache holds the same list.

## 2. `.name` is the string "name"

`lib/src/dart/text.dart`, `_Parser._readValue` and `_Parser._readSwitch`.
Where a value goes, a dot followed straight away by a name is that name as a
string, so these two lines parse to the same thing:

```
Text(text: "Hi", textAlign: .center, style: { base: .bodyLarge, color: .onSurfaceVariant })
Text(text: "Hi", textAlign: "center", style: { base: "bodyLarge", color: "onSurfaceVariant" })
```

- More parts with no space between them are joined by dots, for names that
  have them: `.cupertino.heart_fill` is `"cupertino.heart_fill"`.
- It works in lists, in maps' values, as a switch's case
  (`switch size.breakpoint { .compact: ..., default: ... }`), and in data
  files (`parseDataFile`).
- It isn't a map key, and a dot with a space or a number after it
  (`. center`, `.5`) is still the error it was: `Unexpected .`.

**Why:** Dart 3.10's dot shorthands read this way (`MainAxisAlignment.center`
as `.center`), and a screen full of quoted names is noisy.

**What it can't change:** in 1.1.4, a dot where a value goes is always a
parse error, so no file that parsed before parses differently now. The
parsed value is the same string as the quoted form, so the binary format and
everything after parsing (`encodeLibraryBlob`, the runtime, the widgets)
sees no difference. `test/dot_shorthand_test.dart` checks each of these
points.

## 3. `Name.ctor(` is one call name

`lib/src/dart/text.dart`, `_Parser._readConstructorCall`. A call may be named
as Flutter names a constructor: a name, a dot and a name, with nothing on
either side of the dot. The call's name is the whole string:

```
ListView.builder(items: data.messages, itemBuilder: (m) => ListTile(title: m.name))
```

parses to `ConstructorCall('ListView.builder', {...})`.

- One dot only: `A.b.c(` is an error.
- A space on either side (`ListView .builder(`, `ListView. builder(`) is an
  error with its line and column, as is a dot followed by nothing
  (`widget a = a.`), which keeps 1.1.4's exact message,
  `Expected symbol "(" but found .`.
- References are untouched: `args.x`, `data.a.b` and a loop's `item.title`
  are read before a call is, as they were.

**Why:** the `ui` kit's `.builder` widgets (`ListView.builder`,
`GridView.builder`, `PageView.builder`, ...) are named as a Flutter developer
expects. A local widget library already finds a widget by any string, so
`"ListView.builder"` needs nothing more from the runtime.

**What it can't change:** in 1.1.4 a call name followed by a dot is always a
parse error, so no file that parsed before parses differently now. Call names
are strings in the binary format, so `encodeLibraryBlob` and
`decodeLibraryBlob` carry the dotted name unchanged.
`test/named_constructor_test.dart` checks each of these points.

## 4. A builder's argument can be read whole

`lib/src/dart/text.dart`, `_Parser._readValue`. Inside a widget builder,
`(m) => ...`, the argument's name on its own is the whole argument, as a
loop's variable on its own already is:

```
ListView.builder(items: ["a", "b"], itemBuilder: (s) => Text(text: s))
```

`s` parses to `WidgetBuilderArgReference('s', [])`, and `s.title` reads as
it always did.

**Why:** a `.builder` widget hands each row's item to its builder, and a list
of strings or numbers has nothing to read but the item itself.

**What it can't change:** in 1.1.4 a builder argument with no `.part` after it
is a parse error (`Expected symbol "."`), so no file that parsed before parses
differently now. The binary format already stores a reference's parts as a
list, which may be empty. rfw's Runtime resolves an empty path to the whole
argument. `test/builder_argument_test.dart` checks the parse and the binary
round trip. With both patches here, this copy's suite is 147 passing and 7
skipped.
