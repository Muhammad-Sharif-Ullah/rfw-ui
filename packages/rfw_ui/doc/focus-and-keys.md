# Focus and keys

## Moving between inputs

**"Next" on the keyboard goes to the next field by itself.** Give a field
`textInputAction: "next"` and Flutter moves the focus on when it is
submitted, exactly as in Dart:

```
TextField(decoration: { labelText: "Email" }, textInputAction: "next"),
TextField(decoration: { labelText: "Password" }, textInputAction: "done", obscureText: true),
```

**To send it somewhere in particular**, give the target a `key` and point
the field's `onSubmitted` at `ui.focus`:

```
TextField(decoration: { labelText: "Email" }, textInputAction: "next",
  onSubmitted: event "ui.focus" { key: "code" }),
TextField(decoration: { labelText: "Name" }),
TextField(key: "code", decoration: { labelText: "Code" }),
```

The actions:

| Action | Does |
|---|---|
| `ui.focus { key }` | Focuses the widget with that key. For a text field, that's its own focus node. For anything else, such as a button, switch or list tile, it's the outermost focusable widget under the key. |
| `ui.unfocus { }` | Takes the focus from whatever has it, which closes the keyboard. Put it on the last field's `onSubmitted`. |
| `ui.focusNext { }` / `ui.focusPrevious { }` | Moves along the traversal order, as Tab and Shift-Tab do. |
| `ui.scrollTo { key, alignment, duration, curve }` | Scrolls every scroll view around the keyed widget until it is in view. `alignment` runs from 0 (leading edge) to 1. |

**To change the order** Tab and "next" follow, use a group:

```
FocusTraversalGroup(policy: "ordered", child: Column(children: [
  FocusTraversalOrder(order: 1, child: TextField(textInputAction: "next")),
  FocusTraversalOrder(order: 3, child: TextField()),
  FocusTraversalOrder(order: 2, child: TextField(textInputAction: "next")),
]))
```

`policy` is `"readingOrder"` (the default), `"widgetOrder"` or `"ordered"`.
`ExcludeFocus(excluding: true, child: ...)` takes everything inside out of
focus entirely.

**Limits.**

- `ui.focus` and `ui.scrollTo` look a key up in the tree the event came from
  (the screen, or one dialog), then in the trees that opened it.
- A widget that has not been built cannot be found. A row far down a lazy
  `ListView` does not exist until it scrolls near the screen, so
  `ui.scrollTo` cannot reach it. Use a `SingleChildScrollView` for a form
  that jumps around.
- `autofocus: true` works as in Flutter, on the first build.

## Keys

**Every widget takes `key`.** It's a string, a number, or a list joined into
one (`key: ["row-", item.id]`), because rfw has no way to join strings
itself.

```
Column(children: [
  ...for item in data.todos:
    CheckboxListTile(key: item.id, title: item.title, value: item.done,
      onChanged: event "toggleTodo" { id: item.id }),
])
```

It does what a key does in Flutter:

- **State moves with its item.** rfw builds every child without a key, so
  without one, a reordered list keeps each row's state in place. Text typed
  into the first row's field stays in the first row while the items move
  under it. With a key it moves with its item. Inside one screen or dialog a
  key is a `GlobalKey`, which is what lets a row's state follow it when rfw's
  own unkeyed wrapper stays put.
- **A new key is a fresh widget.** Change a field's key and it starts empty.
- **`ui.focus` and `ui.scrollTo` find widgets by it.**
- **Tests can find it.**
  `find.byWidgetPredicate((w) => UiKey.matches(w.key, 'email'))`.

**Rules.**

- **Unique within one screen or one dialog.** Two widgets with the same key in
  one tree is the same error it is in Flutter ("Multiple widgets used the
  same GlobalKey"). A dialog may reuse a name its screen uses.
- **A remote widget passes it on.** `widget TodoRow = Card(key: args.key, ...)`
  keys the card. A remote widget's own `state` belongs to rfw, and rfw keeps
  that by position, not by key.
- **Under a plain `RemoteWidget`** (not `UiRemoteWidget`) a key is a
  `ValueKey`. It still resets state when it changes and can still be found in
  a test, but it cannot move state between rows.

All of this is covered by `test/keys_focus_test.dart`. It includes a check
that state really does stay put without a key and really does move with one:
it fails if the key is a plain `ValueKey`.
