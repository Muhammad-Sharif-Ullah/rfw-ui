import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

import '../decode/decoder.dart' show UiKeysSource;
import '../decode/resolver.dart';
import '../library.dart' show buildUiWidget;
import '../widgets/args.dart' show UiItemsSource;
import '../widgets/spec.dart' show UiWidget;
import 'cells.dart';
import 'eval.dart';
import 'runtime.dart';

/// One remote widget tree on a [UiRuntime]: what [UiRuntime.build] returns.
class UiScreen extends StatefulWidget {
  const UiScreen({
    super.key,
    required this.runtime,
    required this.widget,
    required this.data,
    required this.onEvent,
    required this.generation,
  });

  final UiRuntime runtime;
  final FullyQualifiedWidgetName widget;
  final DynamicContent data;
  final RemoteEventHandler onEvent;

  /// The runtime's [UiRuntime.generation] when this was made: a new one means
  /// new libraries.
  final int generation;

  @override
  State<UiScreen> createState() => _UiScreenState();
}

/// What every widget of one screen shares.
class _Screen {
  _Screen(this.runtime, this.library, this.cells, this.onEvent);

  UiRuntime runtime;

  /// The library of the screen's root: where a name is looked up when
  /// nothing nearer says.
  LibraryName library;
  UiCells cells;
  RemoteEventHandler onEvent;

  /// The screen's theme, looked up once: what kit widgets resolve tokens
  /// against, rather than each looking the theme up.
  UiResolver? resolver;

  // Kept until the theme, the data or the libraries change, when every widget
  // is built afresh. See [reset].
  Env? rootEnv;
  ConstructorCall? rootCall;
  Expando<bool> _constant = Expando<bool>('constant');
  Expando<Widget> _trustedConstants = Expando<Widget>('constant widget');
  Expando<Widget> _constants = Expando<Widget>('constant widget');

  /// Forgets what was kept: the next build makes every widget anew, so each
  /// element builds again, and drops the rows it kept.
  void reset() {
    rootEnv = null;
    rootCall = null;
    _constant = Expando<bool>('constant');
    _trustedConstants = Expando<Widget>('constant widget');
    _constants = Expando<Widget>('constant widget');
  }

  /// The widgets built once for this screen, by whether they may take its
  /// theme (see [_Reader.trusted]).
  Expando<Widget> constants({required bool trusted}) => trusted ? _trustedConstants : _constants;

  /// Whether [value], written in [library], reads nothing that can change: no
  /// reference, loop, switch, builder, state or remote widget anywhere in it.
  /// A call that does is built once and reused, as Dart's `const` is.
  bool isConstant(Object? value, LibraryName library) {
    switch (value) {
      case ConstructorCall call:
        return _constant[call] ??=
            runtime.targetOf(call, library) is UiLocalTarget &&
            call.arguments.values.every((Object? v) => isConstant(v, library));
      case DynamicMap map:
        return map.values.every((Object? v) => isConstant(v, library));
      case DynamicList list:
        return list.every((Object? v) => isConstant(v, library));
      case EventHandler handler:
        return handler.eventArguments.values.every((Object? v) => isConstant(v, library));
      case Reference() || Loop() || Switch() || WidgetBuilderDeclaration() || SetStateHandler():
        return false;
      default:
        return true;
    }
  }
}

class _UiScreenState extends State<UiScreen> implements UiDependent {
  late final _Screen _screen = _Screen(widget.runtime, widget.widget.library, UiCells(widget.data), widget.onEvent);
  ThemeData? _theme;

  @override
  void didUpdateWidget(UiScreen old) {
    super.didUpdateWidget(old);
    _screen
      ..runtime = widget.runtime
      ..library = widget.widget.library
      ..onEvent = widget.onEvent;
    // New data, or new libraries, whose references are new objects: what
    // was read is read again, into new cells, by widgets made anew.
    if (!identical(old.data, widget.data) || old.generation != widget.generation || old.widget != widget.widget) {
      _screen.cells.dispose();
      _screen.cells = UiCells(widget.data);
      _screen.reset();
    }
  }

  @override
  void dispose() {
    _screen.cells.dispose();
    super.dispose();
  }

  @override
  void dependencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void noteCell(UiCell cell) {}

  @override
  Widget build(BuildContext context) {
    // The screen's one theme lookup, which also builds it again when the
    // theme changes. Compared by value: Theme.of can hand back an equal theme
    // that is a new object.
    final ThemeData theme = Theme.of(context);
    if (theme != _theme) {
      _theme = theme;
      _screen
        ..resolver = UiResolver.fromTheme(theme)
        ..reset();
    }
    return _Reader(_screen, this, trusted: true).root(widget.widget);
  }
}

/// Reads values for one widget as it builds, and builds the widgets they
/// describe. What it reads of `data.*` and `state.*` is noted against
/// [dependent].
class _Reader extends UiEvaluator {
  _Reader(this.screen, this.dependent, {required this.trusted});

  final _Screen screen;

  /// Who builds again when what is read changes; null for a read that is not
  /// part of a build, such as an event's arguments.
  final UiDependent? dependent;

  /// Whether the widgets this builds are under the screen's theme: nothing
  /// but kit widgets between them and the screen. Another local widget may
  /// set a theme of its own, so below one, kit widgets look theirs up.
  final bool trusted;

  /// How many `data.*` and `state.*` values this has read.
  int reads = 0;

  @override
  Object readData(List<Object> parts) {
    reads += 1;
    return screen.cells.read(parts, dependent);
  }

  @override
  Object readState(Env env, List<Object> parts) {
    reads += 1;
    return _stateOf(env).read(parts, dependent);
  }

  static UiStateStore _stateOf(Env env) =>
      env.state ?? (throw const RemoteFlutterWidgetsException('Reference to state value did not correspond to any stateful remote widget.'));

  /// The screen's root widget, [name], called with no arguments.
  Widget root(FullyQualifiedWidgetName name) {
    final UiTarget target = screen.runtime.target(name.library, name.widget);
    switch (target) {
      case UiRemoteTarget():
        return _expand(target, screen.rootEnv ??= Env.root.forWidget(target.declaration, target.library, const <String, Object?>{}));
      case UiLocalTarget():
        return _local(screen.rootCall ??= ConstructorCall(name.widget, const <String, Object?>{}), Env.root, target);
      case UiMissingTarget():
        return uiErrorWidget(target.message);
    }
  }

  /// The widget [call] makes, written in [env].
  Widget callWidget(ConstructorCall call, Env env) {
    final UiTarget target = screen.runtime.targetOf(call, env.library ?? screen.library);
    return switch (target) {
      UiRemoteTarget() => _remote(target, call.arguments, env),
      UiLocalTarget() => _local(call, env, target),
      UiMissingTarget() => uiErrorWidget(target.message),
    };
  }

  Widget _local(ConstructorCall call, Env env, UiLocalTarget target) {
    if (screen.isConstant(call, env.library ?? screen.library)) {
      return screen.constants(trusted: trusted)[call] ??= _LocalWidget(call, env, target, screen, trusted: trusted);
    }
    return _LocalWidget(call, env, target, screen, trusted: trusted);
  }

  /// A remote widget's body, with [arguments] written in [env].
  Widget _remote(UiRemoteTarget target, DynamicMap arguments, Env env) {
    if (env.calls(target.declaration)) {
      return uiErrorWidget('Widget loop: Tried to call ${target.fullName} constructor reentrantly.');
    }
    return _expand(target, env.forWidget(target.declaration, target.library, arguments));
  }

  /// A remote widget's body, read in [body]. Without state it adds no element
  /// of its own: its body's widgets are built in its place. With state, one
  /// element holds it.
  Widget _expand(UiRemoteTarget target, Env body) {
    if (target.declaration.initialState != null) {
      return _StatefulRemote(target, body, screen, trusted: trusted);
    }
    return _body(target.declaration.root, body, target.fullName);
  }

  Widget _body(Object root, Env env, FullyQualifiedWidgetName fullName) {
    final Bound at = resolve(root, env);
    final Object? node = at.value;
    if (node is ConstructorCall) {
      return callWidget(node, at.env);
    }
    return uiErrorWidget('Switch in $fullName did not resolve to a widget (got $node).');
  }
}

/// A remote widget declared with state, `widget X { open: false } = ...`:
/// its state, and its body built with that state in scope.
class _StatefulRemote extends StatefulWidget {
  const _StatefulRemote(this.target, this.env, this.screen, {required this.trusted});

  final UiRemoteTarget target;

  /// Its body's environment, not yet holding its state.
  final Env env;
  final _Screen screen;
  final bool trusted;

  @override
  State<_StatefulRemote> createState() => _StatefulRemoteState();

  @override
  String toStringShort() => target.declaration.name;
}

class _StatefulRemoteState extends State<_StatefulRemote> implements UiDependent {
  late UiStateStore _store = UiStateStore(widget.target.declaration.initialState!);

  // What its body's root read: let go of when it goes, so a cell of the
  // screen's data does not keep a widget long gone from the screen.
  final List<UiCell> _cells = <UiCell>[];

  @override
  void didUpdateWidget(_StatefulRemote old) {
    super.didUpdateWidget(old);
    // A different declaration -- the library was updated -- starts afresh,
    // as on rfw.
    if (!identical(old.target.declaration, widget.target.declaration)) {
      _store.dispose();
      _store = UiStateStore(widget.target.declaration.initialState!);
    }
  }

  @override
  void dispose() {
    for (final UiCell cell in _cells) {
      cell.dependents.remove(this);
    }
    _store.dispose();
    super.dispose();
  }

  @override
  void dependencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void noteCell(UiCell cell) => _cells.add(cell);

  @override
  Widget build(BuildContext context) =>
      _Reader(widget.screen, this, trusted: widget.trusted)._body(widget.target.declaration.root, widget.env.withState(_store), widget.target.fullName);
}

/// A widget a local library builds: [call], written in [env].
class _LocalWidget extends Widget {
  const _LocalWidget(this.call, this.env, this.target, this.screen, {required this.trusted});

  final ConstructorCall call;
  final Env env;
  final UiLocalTarget target;
  final _Screen screen;

  /// Whether it is under its screen's theme; see [_Reader.trusted].
  final bool trusted;

  @override
  Element createElement() => _LocalElement(this);

  @override
  String toStringShort() => call.name;
}

/// Builds a [_LocalWidget] with its library's builder, and builds again when
/// data it read changes.
class _LocalElement extends ComponentElement implements UiDependent {
  _LocalElement(_LocalWidget super.widget);

  // Made when first needed: most widgets read no data and build no list.
  List<UiCell>? _cells;

  /// The rows of each loop or builder it has built, by row: a row whose item
  /// is unchanged is the same widget, and Flutter skips it.
  Map<Object, List<_Row?>>? _rows;

  @override
  Widget build() {
    final _LocalWidget local = widget as _LocalWidget;
    final _Source source = _Source(local, this);
    final UiWidget? kit = local.target.kit;
    final UiResolver? resolver = local.screen.resolver;
    if (kit != null && local.trusted && resolver != null) {
      return buildUiWidget(kit, this, source, resolve: resolver);
    }
    return local.target.builder(this, source);
  }

  @override
  void update(_LocalWidget newWidget) {
    final _LocalWidget old = widget as _LocalWidget;
    // Built again in full below, so what it reads is noted again; and rows
    // made in other surroundings are not these surroundings' rows.
    _forget();
    if (!identical(old.call, newWidget.call) || !identical(old.env, newWidget.env) || old.trusted != newWidget.trusted) {
      _rows = null;
    }
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    _forget();
    _rows = null;
    super.unmount();
  }

  void _forget() {
    final List<UiCell>? cells = _cells;
    if (cells == null) {
      return;
    }
    for (final UiCell cell in cells) {
      cell.dependents.remove(this);
    }
    _cells = null;
  }

  @override
  void dependencyChanged() {
    if (mounted) {
      markNeedsBuild();
    }
  }

  @override
  void noteCell(UiCell cell) => (_cells ??= <UiCell>[]).add(cell);
}

/// A row as last built: its item, where the item is read, and its widget.
final class _Row {
  const _Row(this.item, this.itemEnv, this.widget);

  final Object? item;
  final Env itemEnv;
  final Widget widget;
}

/// rfw's [DataSource], answered from the call's own arguments, as rfw's
/// Runtime answers it.
class _Source extends _Reader implements DataSource, UiItemsSource, UiKeysSource {
  _Source(this.local, this.element) : super(local.screen, element, trusted: local.trusted && local.target.kit != null);

  final _LocalWidget local;
  final _LocalElement element;

  FullyQualifiedWidgetName get _fullName => local.target.fullName;

  Bound _at(List<Object> key) => walk(local.call.arguments, local.env, key, 0);

  // Marks a path that meets a reference, a loop, a switch or a list, which
  // only the full walk can follow.
  static const Object _walk = Object();

  /// The value at [key] when the path runs through what this call wrote
  /// alone; null when nothing was written there; [_walk] when it has to be
  /// followed. Most of what a builder asks after -- the fifty paths of a
  /// styled Text -- was never written, and costs a map lookup and nothing
  /// allocated.
  Object? _literal(List<Object> key) {
    Object? value = local.call.arguments;
    for (final Object part in key) {
      if (value is DynamicMap) {
        value = value[part];
      } else if (value == null || value is String || value is num || value is bool) {
        return null;
      } else {
        return _walk;
      }
    }
    return value is Reference || value is Loop || value is Switch || value is DynamicList ? _walk : value;
  }

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    final Object? literal = _literal(argsKey);
    final Object? value = identical(literal, _walk) ? _at(argsKey).value : literal;
    return value is T ? value : null;
  }

  @override
  bool isList(List<Object> argsKey) {
    final Object? literal = _literal(argsKey);
    return identical(literal, _walk) && _at(argsKey).value is DynamicList;
  }

  @override
  bool isMap(List<Object> argsKey) {
    final Object? literal = _literal(argsKey);
    return identical(literal, _walk) ? _at(argsKey).value is DynamicMap : literal is DynamicMap;
  }

  @override
  Iterable<String>? keysAt(List<Object> key) {
    final Object? literal = _literal(key);
    final Object? value = identical(literal, _walk) ? _at(key).value : literal;
    return value is DynamicMap ? value.keys : null;
  }

  @override
  int length(List<Object> argsKey) {
    if (!identical(_literal(argsKey), _walk)) {
      return 0;
    }
    final Bound at = _at(argsKey);
    final Object? value = at.value;
    return value is DynamicList ? listLength(value, at.env) : 0;
  }

  @override
  Widget child(List<Object> argsKey) {
    final Object? literal = _literal(argsKey);
    if (literal is ConstructorCall) {
      return callWidget(literal, local.env);
    }
    if (literal == null) {
      return uiErrorWidget('Not a widget at $argsKey (got $missing) for $_fullName.');
    }
    final (Widget? widget, Object? got) = _childAt(argsKey);
    return widget ?? uiErrorWidget('Not a widget at $argsKey (got $got) for $_fullName.');
  }

  @override
  Widget? optionalChild(List<Object> argsKey) {
    final Object? literal = _literal(argsKey);
    if (literal == null) {
      return null;
    }
    if (literal is ConstructorCall) {
      return callWidget(literal, local.env);
    }
    return _childAt(argsKey).$1;
  }

  /// The widget at [argsKey], and what is there when it is not one. A row of
  /// a list, `children.3`, as a lazy list asks for it, is kept as a row is.
  (Widget?, Object?) _childAt(List<Object> argsKey) {
    final Object? last = argsKey.isEmpty ? null : argsKey.last;
    if (last is int) {
      final Bound list = walk(local.call.arguments, local.env, argsKey, 0, argsKey.length - 1);
      final Object? value = list.value;
      if (value is DynamicList) {
        final UiListEntry? entry = listEntry(value, list.env, last);
        return entry == null ? (null, missing) : _entryWidget(entry);
      }
    }
    final Bound at = _at(argsKey);
    final Object? value = at.value;
    return value is ConstructorCall ? (callWidget(value, at.env), value) : (null, value);
  }

  @override
  List<Widget> childList(List<Object> argsKey) {
    if (_literal(argsKey) == null) {
      return const <Widget>[];
    }
    final Bound at = _at(argsKey);
    final Object? value = at.value;
    if (value is DynamicList) {
      return <Widget>[
        for (final UiListEntry entry in listEntries(value, at.env))
          if (_entryWidget(entry) case (final Widget? widget, final Object? got))
            widget ?? uiErrorWidget('Not a widget at $argsKey (got $got) for $_fullName.'),
      ];
    }
    if (value == missing) {
      return const <Widget>[];
    }
    return <Widget>[uiErrorWidget('Not a widget list at $argsKey (got $value) for $_fullName.')];
  }

  /// The widget of one list entry, and what the entry is when it is not one.
  ///
  /// A loop's row whose item is the same as last time's -- and which read no
  /// data or state as it was made, so nothing but its item decides what it
  /// is -- is last time's widget.
  (Widget?, Object?) _entryWidget(UiListEntry entry) {
    final Loop? loop = entry.loop;
    if (loop == null) {
      return _entryWidgetAfresh(entry);
    }
    return _kept(loop, entry.itemIndex, entry.item, entry.env.loops.last.env, () => _entryWidgetAfresh(entry));
  }

  /// Row [index] of the loop or builder [node], whose item is [item], read in
  /// [itemEnv]: last time's widget when that row's item was the same and
  /// making it read no data or state, else what [make] makes.
  (Widget?, Object?) _kept(Object node, int index, Object? item, Env itemEnv, (Widget?, Object?) Function() make) {
    final List<_Row?> rows = (element._rows ??= Map<Object, List<_Row?>>.identity())[node] ??= <_Row?>[];
    final _Row? last = index < rows.length ? rows[index] : null;
    if (last != null && identical(last.itemEnv, itemEnv) && uiSameItem(last.item, item)) {
      return (last.widget, null);
    }
    final int before = reads;
    final (Widget? widget, Object? got) = make();
    while (rows.length <= index) {
      rows.add(null);
    }
    rows[index] = widget != null && reads == before ? _Row(item, itemEnv, widget) : null;
    return (widget, got);
  }

  (Widget?, Object?) _entryWidgetAfresh(UiListEntry entry) {
    final Bound at = resolve(entry.value, entry.env);
    final Object? node = at.value;
    return node is ConstructorCall ? (callWidget(node, at.env), node) : (null, node);
  }

  @override
  Widget builder(List<Object> argsKey, DynamicMap builderArg) => _build(argsKey, builderArg, optional: false)!;

  @override
  Widget? optionalBuilder(List<Object> argsKey, DynamicMap builderArg) => _build(argsKey, builderArg, optional: true);

  Widget? _build(List<Object> argsKey, DynamicMap builderArg, {required bool optional}) {
    if (optional && _literal(argsKey) == null) {
      return null;
    }
    final Bound at = _at(argsKey);
    final Object? value = at.value;
    if (value is! WidgetBuilderDeclaration) {
      return optional ? null : uiErrorWidget('Not a builder at $argsKey (got ${_describe(value, at.env)}) for $_fullName.');
    }
    final Env inside = at.env.withBuilderArg(value.argumentName, Bound(builderArg, Env.root));
    final Bound body = resolve(value.widget, inside);
    final Object? node = body.value;
    if (node is ConstructorCall) {
      return callWidget(node, body.env);
    }
    final FullyQualifiedWidgetName where = FullyQualifiedWidgetName(inside.library ?? screen.library, '');
    return uiErrorWidget('Switch in $where did not resolve to a widget (got $node).');
  }

  /// [value] as rfw's messages name it: a call by the widget it reaches.
  String _describe(Object? value, Env env) {
    if (value is! ConstructorCall) {
      return '$value';
    }
    return switch (screen.runtime.target(env.library ?? screen.library, value.name)) {
      UiRemoteTarget(:final FullyQualifiedWidgetName fullName, :final WidgetDeclaration declaration) =>
        '$fullName ${declaration.initialState ?? "{}"} ${value.arguments}',
      UiLocalTarget(:final FullyQualifiedWidgetName fullName) => '$fullName {} ${value.arguments}',
      UiMissingTarget() => '$value',
    };
  }

  // --------------------------------------------------- the .builder widgets

  /// Where `items` is, when something was written there.
  Bound? _items(List<Object> itemsKey) => _literal(itemsKey) == null ? null : _at(itemsKey);

  @override
  int itemCount(List<Object> itemsKey, List<Object> countKey) {
    final int? count = v<int>(countKey) ?? v<double>(countKey)?.round();
    final Bound? items = _items(itemsKey);
    if (items == null) {
      return count == null || count < 0 ? 0 : count;
    }
    final Object? list = items.value;
    final int n = list is DynamicList ? listLength(list, items.env) : 0;
    return count == null ? n : (count < 0 ? 0 : (count < n ? count : n));
  }

  @override
  Widget buildItem(List<Object> itemsKey, List<Object> builderKey, int index) {
    final Bound at = _at(builderKey);
    final Object? builder = at.value;
    if (builder is! WidgetBuilderDeclaration) {
      return uiErrorWidget('Not a builder at $builderKey (got ${_describe(builder, at.env)}) for $_fullName.');
    }
    final Bound? items = _items(itemsKey);
    final Object? item;
    final Env itemEnv;
    if (items == null) {
      item = index;
      itemEnv = Env.root;
    } else {
      final Object? list = items.value;
      final UiListEntry? entry = list is DynamicList ? listEntry(list, items.env, index) : null;
      if (entry == null) {
        // Asked for a row the list no longer has, as it shrinks.
        return const SizedBox.shrink();
      }
      item = entry.value;
      itemEnv = entry.env;
    }
    final (Widget? widget, Object? got) = _kept(builder, index, item, itemEnv, () {
      final Env inside = at.env.withBuilderArg(builder.argumentName, Bound(item, itemEnv));
      final Bound body = resolve(builder.widget, inside);
      final Object? node = body.value;
      return node is ConstructorCall ? (callWidget(node, body.env), node) : (null, node);
    });
    final FullyQualifiedWidgetName where = FullyQualifiedWidgetName(at.env.library ?? screen.library, '');
    return widget ?? uiErrorWidget('Switch in $where did not resolve to a widget (got $got).');
  }

  @override
  VoidCallback? voidHandler(List<Object> argsKey, [DynamicMap? extraArguments]) {
    return handler<VoidCallback>(argsKey, (HandlerTrigger trigger) => () => trigger(extraArguments));
  }

  @override
  T? handler<T extends Function>(List<Object> argsKey, HandlerGenerator<T> generator) {
    if (_literal(argsKey) == null) {
      return null;
    }
    final Bound at = _at(argsKey);
    final Object? value = at.value;
    final Iterable<UiListEntry> written = switch (value) {
      AnyEventHandler() => <UiListEntry>[UiListEntry(value, at.env)],
      DynamicList() => listEntries(value, at.env),
      _ => const <UiListEntry>[],
    };
    final List<Bound> handlers = <Bound>[
      for (final UiListEntry entry in written)
        if (resolve(entry.value, entry.env) case final Bound h when h.value is AnyEventHandler) h,
    ];
    if (handlers.isEmpty) {
      return null;
    }
    final _Screen screen = this.screen;
    return generator(([DynamicMap? extraArguments]) {
      // Read when it fires, not each time the widget builds: the same values,
      // since a widget builds again when what it read changes.
      final _Reader now = _Reader(screen, null, trusted: false);
      for (final Bound handler in handlers) {
        final Object? h = handler.value;
        if (h is EventHandler) {
          DynamicMap arguments = now.materialize(h.eventArguments, handler.env)! as DynamicMap;
          if (extraArguments != null) {
            arguments = DynamicMap.fromEntries(arguments.entries.followedBy(extraArguments.entries));
          }
          screen.onEvent(h.eventName, arguments);
        } else if (h is SetStateHandler) {
          _Reader._stateOf(handler.env).set(h.stateReference.parts, now.materialize(h.value, handler.env) ?? missing);
        }
      }
    });
  }
}
