import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

import 'decode/resolver.dart';
import 'widgets/args.dart';
import 'widgets/builders.dart';
import 'widgets/cupertino.dart';
import 'widgets/dialog.dart';
import 'widgets/effects.dart';
import 'widgets/gesture.dart';
import 'widgets/input.dart';
import 'widgets/material.dart';
import 'widgets/motion.dart';
import 'widgets/navigation.dart';
import 'widgets/paint.dart';
import 'widgets/scope.dart';
import 'widgets/sliver.dart';
import 'widgets/layout.dart';
import 'widgets/spec.dart';
import 'widgets/text.dart';

/// What a remote file imports to reach every widget here: `import ui;`.
const LibraryName uiLibraryName = LibraryName(<String>['ui']);

/// Every widget of the `ui` library, in catalog order.
final List<UiWidget> uiWidgets = List<UiWidget>.unmodifiable(<UiWidget>[
  ...layoutWidgets,
  ...textWidgets,
  ...materialWidgets,
  ...inputWidgets,
  ...navigationWidgets,
  ...dialogWidgets,
  ...cupertinoWidgets,
  ...sliverWidgets,
  ...builderWidgets,
  ...paintWidgets,
  ...motionWidgets,
  ...effectWidgets,
  ...gestureWidgets,
]);

/// The `ui` library, for `runtime.update(uiLibraryName, createUiWidgets())`.
///
/// It is a superset of rfw's `core.widgets` and `core.material`: everything
/// those have, under the same names and reading the same arguments, so a file
/// can swap its imports for `import ui;` and keep working -- and then use theme
/// tokens and the widgets rfw does not have.
///
/// Every widget takes a `key` besides its own parameters; see [UiKey].
UiWidgetLibrary createUiWidgets() => UiWidgetLibrary._(<String, UiWidget>{for (final UiWidget widget in uiWidgets) widget.name: widget});

/// The `ui` library as rfw sees it, a [LocalWidgetLibrary], which also says
/// which [UiWidget] each name is, so that a UiRuntime can build it with the
/// theme its screen looked up once.
class UiWidgetLibrary extends LocalWidgetLibrary {
  UiWidgetLibrary._(this.kit)
    : super(<String, LocalWidgetBuilder>{
        for (final UiWidget widget in kit.values)
          widget.name: (BuildContext context, DataSource source) => buildUiWidget(widget, context, source),
      });

  /// Each widget by its name.
  final Map<String, UiWidget> kit;
}

/// [widget] built from [source], reading tokens through [resolve] when given
/// and the theme in scope otherwise, and keyed by its `key`.
Widget buildUiWidget(UiWidget widget, BuildContext context, DataSource source, {UiResolver? resolve}) {
  final String? key = uiKeyOf(source);
  final Widget built = widget.build(UiArgs(context, source, key: key, resolve: resolve));
  if (key == null) {
    return built;
  }
  // Without a UiScope -- a plain RemoteWidget -- a key can still reset
  // state when it changes, and still be found by a test, but not move.
  return KeyedSubtree(key: UiScope.maybeOf(context)?.key(key) ?? ValueKey<String>(key), child: built);
}
