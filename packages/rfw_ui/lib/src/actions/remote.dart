import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

import '../runtime/runtime.dart';
import '../widgets/scope.dart';
import 'actions.dart';
import 'store.dart';

/// A [RemoteWidget] whose `ui.*` events work: dialogs, sheets, snack bars,
/// pickers, `ui.set` into its data, `ui.themeMode`.
///
/// Use it where you would use RemoteWidget. Every event that is not `ui.*`
/// reaches [onEvent] exactly as RemoteWidget would deliver it, so an app's
/// own event handling does not change.
class UiRemoteWidget extends StatefulWidget {
  const UiRemoteWidget({
    super.key,
    required this.runtime,
    required this.data,
    required this.widget,
    this.onEvent,
    this.store,
  });

  final Runtime runtime;
  final DynamicContent data;
  final FullyQualifiedWidgetName widget;
  final UiEventHandler? onEvent;

  /// Where `ui.set` writes. Pass one to seed values or read them back; one is
  /// made over [data] otherwise.
  final UiStore? store;

  @override
  State<UiRemoteWidget> createState() => _UiRemoteWidgetState();
}

class _UiRemoteWidgetState extends State<UiRemoteWidget> {
  late UiActions _actions = _create();

  UiActions _create() => UiActions(
    runtime: widget.runtime,
    library: widget.widget.library,
    store: widget.store ?? UiStore(widget.data),
    // Read through the widget, so a new handler takes effect without a new
    // dispatcher -- and without forgetting what ui.set has written.
    onEvent: (String name, DynamicMap args) => widget.onEvent?.call(name, args),
  )..modalBuilder = _prepareModal;

  /// Where dialogs and sheets are built: a runtime of their own, holding the
  /// screen's libraries and one more per modal depth.
  ///
  /// Registering a library makes every remote widget of a runtime rebuild. On
  /// the screen's runtime that is the whole screen, behind the dialog, every
  /// time one opens -- 100 ms over a screen of 300 cards, against 5 for a
  /// dialog in plain Flutter (doc/performance.md). Here it is only the dialogs.
  Runtime? _modals;

  @override
  void initState() {
    super.initState();
    widget.runtime.addListener(_syncModals);
  }

  @override
  void didUpdateWidget(UiRemoteWidget old) {
    super.didUpdateWidget(old);
    if (widget.runtime != old.runtime) {
      old.runtime.removeListener(_syncModals);
      widget.runtime.addListener(_syncModals);
      _syncModals();
    }
    if (widget.runtime != old.runtime ||
        widget.data != old.data ||
        widget.store != old.store ||
        widget.widget.library != old.widget.library) {
      _actions = _create();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_syncModals);
    _modals?.dispose();
    super.dispose();
  }

  /// Gives the modals' runtime every library the screen's has, so a dialog
  /// sees the same widgets -- and an edit to them -- that the screen does.
  void _syncModals() {
    final Runtime? modals = _modals;
    if (modals == null) {
      return;
    }
    final Map<LibraryName, WidgetLibrary> held = modals.libraries;
    for (final MapEntry<LibraryName, WidgetLibrary> entry in widget.runtime.libraries.entries) {
      if (!identical(held[entry.key], entry.value)) {
        modals.update(entry.key, entry.value);
      }
    }
  }

  /// A one-widget library per modal depth -- `ui.modal.0` for a dialog opened
  /// from the screen, `ui.modal.1` for one opened from that dialog -- calling
  /// the named widget with its args. Reusing a name per depth keeps the
  /// runtime from collecting a library for every dialog ever opened.
  WidgetBuilder _prepareModal(String name, DynamicMap args, int depth, UiScopeData? opener) {
    final LibraryName library = LibraryName(<String>['ui', 'modal', '$depth']);
    final bool fresh = _modals == null;
    // The screen's kind of runtime, so a dialog builds as the screen does.
    final Runtime runtime = _modals ??= widget.runtime is UiRuntime ? UiRuntime() : Runtime();
    if (fresh) {
      _syncModals();
    }
    runtime.update(
      library,
      RemoteWidgetLibrary(
        <Import>[Import(widget.widget.library)],
        <WidgetDeclaration>[WidgetDeclaration('root', null, ConstructorCall(name, args))],
      ),
    );
    final UiActions actions = _actions;
    final DynamicContent data = widget.data;
    return (BuildContext context) => _UiHost(
      actions: actions,
      depth: depth + 1,
      opener: opener,
      runtime: runtime,
      data: data,
      widget: FullyQualifiedWidgetName(library, 'root'),
    );
  }

  @override
  Widget build(BuildContext context) => _UiHost(
    actions: _actions,
    depth: 0,
    runtime: widget.runtime,
    data: widget.data,
    widget: widget.widget,
  );
}

/// One remote tree -- the screen, or a modal -- with its events dispatched
/// from its own context, so `ui.pop` pops the route it is in, and its own
/// [UiScope], so its keys are its own.
class _UiHost extends StatefulWidget {
  const _UiHost({
    required this.actions,
    required this.depth,
    this.opener,
    required this.runtime,
    required this.data,
    required this.widget,
  });

  final UiActions actions;
  final int depth;

  /// The tree that opened this one, for a modal.
  final UiScopeData? opener;

  final Runtime runtime;
  final DynamicContent data;
  final FullyQualifiedWidgetName widget;

  @override
  State<_UiHost> createState() => _UiHostState();
}

class _UiHostState extends State<_UiHost> {
  // Held for the life of the tree: every key in it is equal by this object,
  // so a new one would be a new key for every widget, and a fresh state.
  late final UiScopeData _scope = UiScopeData(parent: widget.opener);

  @override
  Widget build(BuildContext context) => UiScope(
    data: _scope,
    child: RemoteWidget(
      runtime: widget.runtime,
      data: widget.data,
      widget: widget.widget,
      onEvent: (String name, DynamicMap args) =>
          widget.actions.dispatch(context, name, args, depth: widget.depth, scope: _scope),
    ),
  );
}
