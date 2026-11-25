import 'package:rfw/rfw.dart';

/// Values a remote file writes into its own data, by dotted path.
///
/// rfw's `set state.x = ...` cannot see the value an input reports -- a set
/// state handler ignores its arguments -- so a switch cannot write where it
/// is on through it. The `ui.set` action can: it writes `{ value }` into the
/// [DynamicContent] the remote widget reads `data.*` from, and every widget
/// bound to that path rebuilds.
///
/// `DynamicContent` can be written but not read, so the store keeps its own
/// copy of each root it has written. It owns the roots it writes; an app that
/// also writes one of them with `content.update` should do it through [set]
/// instead, or the two will each think they know what is there.
class UiStore {
  UiStore(this.content);

  final DynamicContent content;
  final Map<String, Object?> _roots = <String, Object?>{};

  /// The value at [path] (`"form.email"`, `"items.0.done"`), if this store
  /// wrote it.
  Object? get(String path) {
    Object? node = _roots;
    for (final String part in _split(path)) {
      if (node is Map<String, Object?>) {
        node = node[part];
      } else if (node is List<Object?>) {
        final int? index = int.tryParse(part);
        node = index != null && index >= 0 && index < node.length ? node[index] : null;
      } else {
        return null;
      }
    }
    return node;
  }

  /// Writes [value] at [path], creating maps on the way. Null removes it.
  void set(String path, Object? value) {
    final List<String> parts = _split(path);
    if (parts.isEmpty) {
      return;
    }
    final String root = parts.first;
    if (parts.length == 1) {
      _roots[root] = value;
    } else {
      _roots[root] = _with(_roots[root], parts.sublist(1), value);
    }
    final Object? written = _roots[root];
    if (written == null) {
      _roots.remove(root);
    }
    // DynamicContent cannot forget a root (`missing` trips an assertion in
    // its deep clone), so a cleared root is an empty map: a widget asking for
    // a string, a number or a flag there finds none, which is what unset means.
    content.update(root, written ?? const <String, Object?>{});
  }

  /// Writes every entry of [values] as its own path.
  void setAll(Map<String, Object?> values) {
    for (final MapEntry<String, Object?> entry in values.entries) {
      set(entry.key, entry.value);
    }
  }

  static Object? _with(Object? node, List<String> path, Object? value) {
    final String head = path.first;
    final List<String> rest = path.sublist(1);
    if (node is List<Object?>) {
      final int? index = int.tryParse(head);
      if (index != null && index >= 0 && index < node.length) {
        final List<Object?> copy = List<Object?>.of(node);
        copy[index] = rest.isEmpty ? value : _with(copy[index], rest, value);
        return copy;
      }
    }
    final Map<String, Object?> copy = node is Map<String, Object?> ? Map<String, Object?>.of(node) : <String, Object?>{};
    final Object? next = rest.isEmpty ? value : _with(copy[head], rest, value);
    if (next == null) {
      copy.remove(head);
    } else {
      copy[head] = next;
    }
    return copy;
  }

  static List<String> _split(String path) =>
      path.split('.').where((String part) => part.isNotEmpty).toList(growable: false);
}
