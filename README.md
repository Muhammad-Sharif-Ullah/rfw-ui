# rfw-ui

Two Flutter packages, used together:

- **`packages/rfw`** — [Remote Flutter Widgets](https://pub.dev/packages/rfw) 1.1.4 with
  changes of our own. Every change and its reason is in
  [`packages/rfw/PATCHES.md`](packages/rfw/PATCHES.md).
- **`packages/rfw_ui`** — a UI kit for rfw: the widgets rfw leaves out, theme tokens instead of
  repeated styles, actions for dialogs, sheets and pickers, and a `ThemeData` that is data.

## Using it in an app

`rfw_ui` depends on `rfw` by relative path, which pub resolves to a git dependency pinned at the
commit it was fetched from. So an app that also imports `package:rfw` itself must pin **both**
dependencies to the **same** commit, or version solving fails:

```yaml
dependencies:
  rfw:
    git:
      url: https://github.com/Muhammad-Sharif-Ullah/rfw-ui.git
      ref: <commit sha>
      path: packages/rfw
  rfw_ui:
    git:
      url: https://github.com/Muhammad-Sharif-Ullah/rfw-ui.git
      ref: <commit sha>
      path: packages/rfw_ui
```

Bump both at once:

```sh
SHA=$(git ls-remote https://github.com/Muhammad-Sharif-Ullah/rfw-ui main | cut -f1)
sed -i '' "s/ref: [0-9a-f]\{40\}/ref: $SHA/g" pubspec.yaml && flutter pub get
```

To track a branch instead, point both at `ref: main` and add a `dependency_overrides` entry for
`rfw` with the same git coordinates; the override collapses the two refs onto one.

While working on the kit itself, override it with a local path and drop the override before
committing:

```yaml
dependency_overrides:
  rfw_ui:
    path: packages/rfw_ui
```

## Licenses

`packages/rfw` is BSD-3-Clause, Copyright 2013 The Flutter Authors. `packages/rfw_ui` is
BSD-3-Clause, Copyright 2026 ASG Security.
