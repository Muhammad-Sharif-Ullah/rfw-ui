import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

import 'decoder.dart' show UiKeysSource;

/// A [DataSource] over a plain decoded map.
///
/// What `parseDataFile`, `decodeDataBlob` and `jsonDecode` hand back is a map
/// of maps, lists and scalars, and a widget's resolved arguments are the same
/// shape. Reading both through one interface is what lets the theme document
/// and a remote widget share every decoder in [UiDecoder] -- a colour token in
/// `appBarTheme` and one in `AppBar(backgroundColor:)` are one code path.
///
/// It holds data only: there are no widgets in a map and no handlers to call,
/// so asking for either is a programming error rather than a missing value.
class MapSource implements DataSource, UiKeysSource {
  const MapSource(this.root);

  final Map<String, Object?> root;

  Object? _at(List<Object> key) {
    Object? node = root;
    for (final Object part in key) {
      if (part is String && node is Map) {
        node = node[part];
      } else if (part is int && node is List) {
        node = part >= 0 && part < node.length ? node[part] : null;
      } else {
        return null;
      }
    }
    return node;
  }

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    final Object? value = _at(argsKey);
    return value is T ? value : null;
  }

  @override
  bool isList(List<Object> argsKey) => _at(argsKey) is List;

  @override
  bool isMap(List<Object> argsKey) => _at(argsKey) is Map;

  @override
  Iterable<String>? keysAt(List<Object> key) {
    final Object? value = _at(key);
    return value is Map<String, Object?> ? value.keys : null;
  }

  @override
  int length(List<Object> argsKey) {
    final Object? value = _at(argsKey);
    return value is List ? value.length : 0;
  }

  @override
  Widget child(List<Object> argsKey) => throw _noWidgets(argsKey);

  @override
  Widget? optionalChild(List<Object> argsKey) => throw _noWidgets(argsKey);

  @override
  List<Widget> childList(List<Object> argsKey) => throw _noWidgets(argsKey);

  @override
  Widget builder(List<Object> argsKey, DynamicMap builderArg) => throw _noWidgets(argsKey);

  @override
  Widget? optionalBuilder(List<Object> argsKey, DynamicMap builderArg) => throw _noWidgets(argsKey);

  @override
  VoidCallback? voidHandler(List<Object> argsKey, [DynamicMap? extraArguments]) => null;

  @override
  T? handler<T extends Function>(List<Object> argsKey, HandlerGenerator<T> generator) => null;

  UnsupportedError _noWidgets(List<Object> key) =>
      UnsupportedError('MapSource holds data, not widgets (asked for ${key.join('.')})');
}
