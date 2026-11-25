import 'package:rfw/rfw.dart';

/// Something that read a [UiCell] while it built, and builds again when the
/// cell's value changes: a widget's element, or a screen.
abstract interface class UiDependent {
  /// A cell this read has a new value.
  void dependencyChanged();

  /// This now depends on [cell]: it is told once per cell, so it can let go
  /// of the cell when it is gone.
  void noteCell(UiCell cell);
}

/// One path of a [DynamicContent], read by one or more widgets.
///
/// The cell holds the value and is the content's one subscriber for the path.
/// When the value changes, every widget that read it builds again, and no
/// other.
final class UiCell {
  UiCell._(this.parts);

  final List<Object> parts;
  late Object value;
  final Set<UiDependent> dependents = <UiDependent>{};

  void _changed(Object next) {
    value = next;
    for (final UiDependent dependent in dependents.toList()) {
      dependent.dependencyChanged();
    }
  }
}

/// The [UiCell]s of one [DynamicContent] that one screen reads: one for each
/// reference in the parsed file, found by the reference's own `parts` list.
class UiCells {
  UiCells(this.content);

  final DynamicContent content;

  final Map<List<Object>, UiCell> _cells = Map<List<Object>, UiCell>.identity();
  bool _disposed = false;

  /// The value at [parts], or `missing`. [reader], when given, builds again
  /// when it changes.
  Object read(List<Object> parts, UiDependent? reader) {
    if (_disposed) {
      // An event fired after its screen went: the value as it is now.
      void ignore(Object _) {}
      final Object value = content.subscribe(parts, ignore);
      content.unsubscribe(parts, ignore);
      return value;
    }
    UiCell? cell = _cells[parts];
    if (cell == null) {
      cell = _cells[parts] = UiCell._(parts);
      cell.value = content.subscribe(parts, cell._changed);
    }
    if (reader != null && cell.dependents.add(reader)) {
      reader.noteCell(cell);
    }
    return cell.value;
  }

  /// Stops listening to [content].
  void dispose() {
    for (final UiCell cell in _cells.values) {
      content.unsubscribe(cell.parts, cell._changed);
      cell.dependents.clear();
    }
    _cells.clear();
    _disposed = true;
  }
}

/// The state of one widget declared with state, `widget X { open: false }`:
/// read through cells as data is, and written by `set state`.
class UiStateStore {
  UiStateStore(DynamicMap initialState)
    : _store = deepClone(initialState)! as DynamicMap,
      _content = DynamicContent() {
    _content.updateAll(_store);
    _cells = UiCells(_content);
  }

  final DynamicMap _store;
  final DynamicContent _content;
  late final UiCells _cells;

  /// The state at [parts], or `missing`. [reader], when given, builds again
  /// when it changes.
  Object read(List<Object> parts, UiDependent? reader) => _cells.read(parts, reader);

  /// Writes [value] at [parts], which must already be there, as rfw's
  /// `set state` does; everything that read what changed builds again.
  void set(List<Object> parts, Object value) {
    Object current = _store;
    for (int index = 0; index < parts.length; index += 1) {
      final Object part = parts[index];
      final bool last = index == parts.length - 1;
      if (current is DynamicMap && part is String && current.containsKey(part)) {
        if (last) {
          current[part] = value;
        } else {
          current = current[part]!;
        }
      } else if (current is DynamicList && part is int && part >= 0 && part < current.length) {
        if (last) {
          current[part] = value;
        } else {
          current = current[part]!;
        }
      } else {
        throw RemoteFlutterWidgetsException('${parts.join(".")} does not identify existing state.');
      }
    }
    _content.updateAll(_store);
  }

  void dispose() => _cells.dispose();
}
