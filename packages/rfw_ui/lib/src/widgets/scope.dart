import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

/// The identity a remote file gives a widget: `key: "email"`, `key: item.id`.
///
/// Inside one remote tree -- the screen, or one dialog -- a key names one
/// widget, and it is a [GlobalKey]. rfw builds every child unkeyed, so on its
/// own a reordered list hands each row the state of whichever row used to be
/// in its place: the text typed into a field stays put while the items move.
/// Under a key the state moves with its item, the way it does in Flutter. A
/// key that changes is a new widget, with fresh state.
///
/// Keys are equal by tree and value, so the same key built twice is the same
/// key and nothing has to be kept to remember it. Two trees -- a screen and
/// the dialog over it -- can use the same names without colliding.
@optionalTypeArgs
class UiKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const UiKey._(this._scope, this.value) : super.constructor();

  final Object _scope;

  /// What the remote file wrote.
  final String value;

  /// Whether [key] is the one a remote file wrote as [value], with or without
  /// a [UiScope] above it. For tests:
  /// `find.byWidgetPredicate((Widget w) => UiKey.matches(w.key, 'email'))`.
  static bool matches(Key? key, String value) =>
      (key is UiKey && key.value == value) || key == ValueKey<String>(value);

  @override
  bool operator ==(Object other) => other is UiKey && identical(other._scope, _scope) && other.value == value;

  @override
  int get hashCode => Object.hash(identityHashCode(_scope), value);

  @override
  String toString() => '[UiKey $value]';
}

/// The `key` a remote file gave a widget, as a string: a string, a number or
/// a flag as written, or a list joined -- `key: ["row-", item.id]` -- since
/// rfw has no way to join strings itself.
String? uiKeyOf(DataSource source) {
  const List<Object> at = <Object>['key'];
  if (source.isList(at)) {
    final StringBuffer joined = StringBuffer();
    for (int i = 0; i < source.length(at); i += 1) {
      final String? part = _scalar(source, <Object>[...at, i]);
      if (part != null) {
        joined.write(part);
      }
    }
    return joined.isEmpty ? null : joined.toString();
  }
  return _scalar(source, at);
}

// One type at a time: rfw's `v` asserts that it is asked for a scalar type.
String? _scalar(DataSource source, List<Object> at) =>
    source.v<String>(at) ?? source.v<int>(at)?.toString() ?? source.v<double>(at)?.toString() ?? source.v<bool>(at)?.toString();

/// What the widgets of one remote tree share: their keys, and the inputs
/// `ui.focus` can reach by key.
///
/// [UiRemoteWidget] gives the screen one and every dialog or sheet it opens
/// another, whose [parent] is the tree that opened it -- so a name is looked
/// up where the action fired first, and then in its openers.
class UiScopeData {
  UiScopeData({this.parent});

  final UiScopeData? parent;

  final Map<String, FocusNode> _inputs = <String, FocusNode>{};

  /// The key [value] stands for in this tree.
  UiKey key(String value) => UiKey<State<StatefulWidget>>._(this, value);

  /// Where the widget keyed [value] is on screen, here or in an opener.
  BuildContext? find(String value) {
    for (UiScopeData? scope = this; scope != null; scope = scope.parent) {
      final BuildContext? context = scope.key(value).currentContext;
      if (context != null) {
        return context;
      }
    }
    return null;
  }

  /// What `ui.focus { key: value }` focuses: the input of that key, or else
  /// the first focusable widget under the widget of that key -- a button, a
  /// switch, a list tile.
  FocusNode? focusNode(String value) {
    for (UiScopeData? scope = this; scope != null; scope = scope.parent) {
      final FocusNode? input = scope._inputs[value];
      if (input != null) {
        return input;
      }
    }
    final BuildContext? context = find(value);
    return context == null ? null : _firstFocusable(context as Element);
  }

  void _register(String value, FocusNode node) => _inputs[value] = node;

  void _unregister(String value, FocusNode node) {
    if (identical(_inputs[value], node)) {
      _inputs.remove(value);
    }
  }

  /// The outermost focusable widget at or under [root] -- a list tile rather
  /// than the checkbox inside it. Found from the focus tree, whose nodes know
  /// the element that owns them, so nothing is looked up through a context
  /// outside of a build.
  static FocusNode? _firstFocusable(Element root) {
    FocusNode? best;
    int bestDepth = 1 << 30;
    for (final FocusNode node in FocusManager.instance.rootScope.descendants) {
      final BuildContext? owner = node.context;
      if (owner == null || node is FocusScopeNode || !node.canRequestFocus || node.skipTraversal) {
        continue;
      }
      int depth = 0;
      bool under = identical(owner, root);
      if (!under) {
        owner.visitAncestorElements((Element ancestor) {
          depth += 1;
          under = identical(ancestor, root);
          return !under;
        });
      }
      if (under && depth < bestDepth) {
        best = node;
        bestDepth = depth;
      }
    }
    return best;
  }
}

/// Puts a [UiScopeData] where the widgets of one remote tree can find it.
class UiScope extends InheritedWidget {
  const UiScope({super.key, required this.data, required super.child});

  final UiScopeData data;

  static UiScopeData? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<UiScope>()?.data;

  @override
  bool updateShouldNotify(UiScope old) => !identical(old.data, data);
}

/// A [FocusNode] for an input, owned for as long as the input is on screen
/// and, when it has a key, registered under it for `ui.focus`.
class UiFocusable extends StatefulWidget {
  const UiFocusable({super.key, required this.id, required this.builder});

  /// The input's `key`, or null when it has none.
  final String? id;

  final Widget Function(BuildContext context, FocusNode node) builder;

  @override
  State<UiFocusable> createState() => _UiFocusableState();
}

class _UiFocusableState extends State<UiFocusable> {
  late final FocusNode _node = FocusNode(debugLabel: widget.id);
  UiScopeData? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final UiScopeData? scope = UiScope.maybeOf(context);
    if (!identical(scope, _scope)) {
      _unregister(widget.id);
      _scope = scope;
      _register(widget.id);
    }
  }

  @override
  void didUpdateWidget(UiFocusable old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _unregister(old.id);
      _register(widget.id);
    }
  }

  void _register(String? id) {
    if (id != null) {
      _scope?._register(id, _node);
    }
  }

  void _unregister(String? id) {
    if (id != null) {
      _scope?._unregister(id, _node);
    }
  }

  @override
  void dispose() {
    _unregister(widget.id);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _node);
}
