# Importing one file from another in the RFW studio

**Yes.** A file in a studio project can import any other `.rfwtxt` or
`.rfw` file in the same project, and as many of them as it likes. The import
names the file by its path from the project root, with dots for slashes and
no extension:

| File | Import it with |
|---|---|
| `widgets/badge.rfwtxt` | `import widgets.badge;` |
| `cards.rfwtxt` | `import cards;` |
| `screens/home/header.rfw` | `import screens.home.header;` |

```
// main.rfwtxt
import ui;
import widgets.badge;
import widgets.title;

widget root = Column(children: [Title(text: "Inbox"), Badge(label: "3 new")]);
```

```
// widgets/badge.rfwtxt
import ui;

widget Badge = Chip(label: args.label);
```

## How it behaves

- **Imports are followed.** If `main` imports `cards`, and `cards` imports
  `widgets.title`, then all three are loaded.
- **Unsaved edits count.** The preview is sent every RFW file as it stands in
  the editor, so editing `widgets/badge.rfwtxt` redraws `main.rfwtxt` without
  a save.
- **Only what is imported is read.** A half-written file that nothing
  imports cannot stop the file you are looking at from rendering.
- **Problems name the file at fault.** If `cards.rfwtxt` imports a file that
  isn't there, the Problems panel says
  `cards.rfwtxt imports widgets.titel, but there is no widgets/titel.rfwtxt in this project`
  against `cards.rfwtxt`, not against the file on screen. A parse error in
  an imported file gives that file's name and line, and clicking it opens
  that file.
- **A file cannot replace the kit.** `ui`, `core.widgets` and `core.material`
  always mean the app's own libraries, so a project file named `ui.rfwtxt` is
  ignored by `import ui;`.
- **A loop is an error.** If `a` imports `b` and `b` imports `a`, rfw says so
  ("Library a indirectly depends on itself via b").

## Rules for file names

A name in an import is rfw identifiers separated by dots, so a file whose
path has a hyphen or a space (`my-card.rfwtxt`) cannot be imported. Name
shared files with letters, digits and `_`.

## Where it lives

| Piece | File |
|---|---|
| Path to library name, import resolution, the parse cache | `studio/lib/src/project.dart` |
| Registering every resolved library on the preview's runtime | `studio/lib/src/source_view.dart` |
| Sending the project's files with the shown one | `frontend/src/routes/Studio.svelte`, `frontend/src/lib/preview/StudioFrame.svelte` |
| Tests | `studio/test/project_imports_test.dart`, plus `Studio.test.ts` ("the preview is sent every RFW file", "a problem in an imported file names that file") |

## Not done

- **Editor hover and completion across files.** Monaco's hover and
  completion know the `ui` kit's widgets, but not the widgets a project file
  declares for another to import. The preview renders them correctly; the
  editor just doesn't suggest them yet.
- **The mobile app.** This is the studio preview. In the app, each library is
  whatever the app registers on its runtime, which is the app's own choice of
  names. Do the same there: `runtime.update(LibraryName(['widgets', 'badge']), library)`.
