// What a remote file's values mean, read where they are written.
//
// rfw's Runtime binds every argument into a copy of the widget it is passed
// to ("currying"), and copies every row of a list again for its loop
// variable. Here nothing is copied: a value is read from the parsed model
// itself, and a reference is followed through an [Env], which says what
// `args`, a loop variable and a builder's argument hold where the value was
// written.

import 'package:rfw/formats.dart';

import 'cells.dart';

/// Where a value is read: the arguments of the remote widget whose body it is
/// in, where those arguments were written, the loop items and builder
/// arguments in scope, the widget and library it is in, and the state that
/// `state.*` reads.
final class Env {
  const Env._(this.args, this.argsEnv, this.loops, this.builderArgs, this.declaration, this.library, this.state);

  /// Outside every widget: what plain data is read in.
  static const Env root = Env._(<String, Object?>{}, null, <Bound>[], <String, Bound>{}, null, null, null);

  /// What `args.*` reads.
  final DynamicMap args;

  /// Where [args] were written, so what they refer to is read there.
  final Env? argsEnv;

  /// The loop items in scope, innermost last: a [LoopReference] counts back
  /// from the end.
  final List<Bound> loops;

  /// What each builder argument in scope holds, by its name.
  final Map<String, Bound> builderArgs;

  /// The remote widget whose body this is.
  final WidgetDeclaration? declaration;

  /// The library [declaration] is in: where the names it calls are found.
  final LibraryName? library;

  /// The state of the nearest widget with state that this is inside, as
  /// rfw finds it: a widget without state reads its caller's.
  final UiStateStore? state;

  /// The body of [declaration], called with [arguments] written here.
  ///
  /// Loops and builder arguments do not reach into another widget's body: a
  /// file can name only those it can see.
  Env forWidget(WidgetDeclaration declaration, LibraryName library, DynamicMap arguments) =>
      Env._(arguments, this, const <Bound>[], const <String, Bound>{}, declaration, library, state);

  /// One row of a loop: [item], which is read in [itemEnv].
  Env withLoop(Object? item, Env itemEnv) =>
      Env._(args, argsEnv, <Bound>[...loops, Bound(item, itemEnv)], builderArgs, declaration, library, state);

  /// Inside a builder, `(name) => ...`, whose argument holds [value].
  Env withBuilderArg(String name, Bound value) =>
      Env._(args, argsEnv, loops, <String, Bound>{...builderArgs, name: value}, declaration, library, state);

  /// The body of a widget with state, which `state.*` there reads.
  Env withState(UiStateStore store) => Env._(args, argsEnv, loops, builderArgs, declaration, library, store);

  /// Whether [widget]'s body is already being read, here or in what called
  /// it: calling it again would never end.
  bool calls(WidgetDeclaration widget) {
    for (Env? env = this; env != null; env = env.argsEnv) {
      if (identical(env.declaration, widget)) {
        return true;
      }
    }
    return false;
  }
}

/// A value and the environment it is read in.
final class Bound {
  const Bound(this.value, this.env);

  final Object? value;
  final Env env;
}

/// One entry of a list, its loops counted row by row.
final class UiListEntry {
  const UiListEntry(this.value, this.env, {this.loop, this.itemIndex = -1, this.item});

  /// The entry as written: a loop's output, or the entry itself.
  final Object? value;

  /// What [value] is read in; for a loop's row, with its item in scope.
  final Env env;

  /// The loop the row is of, or null for an entry written on its own.
  final Loop? loop;

  /// The row's place in [loop]'s items.
  final int itemIndex;

  /// The row's item, as its list holds it.
  final Object? item;
}

/// Reads values of the parsed model: follows references, takes switches'
/// cases, and counts and indexes lists through their loops.
///
/// What `data.*` and `state.*` hold comes from [readData] and [readState],
/// so a runtime can note who read what.
abstract class UiEvaluator {
  /// The data at [parts], or [missing].
  Object readData(List<Object> parts);

  /// The state at [parts] of the stateful widget [env] is in, or [missing].
  Object readState(Env env, List<Object> parts);

  /// [value] in [env], with references followed and switches taken until a
  /// value that is neither: a primitive, a map, a list, a call, a handler,
  /// a builder, or [missing].
  Bound resolve(Object? value, Env env) {
    while (true) {
      switch (value) {
        case ArgsReference r:
          final Env caller = env.argsEnv ?? Env.root;
          if (r.parts.isEmpty) {
            return Bound(env.args, caller);
          }
          final Object first = r.parts.first;
          if (!env.args.containsKey(first)) {
            return Bound(missing, caller);
          }
          return walk(env.args[first], caller, r.parts, 1);
        case DataReference r:
          return Bound(readData(r.parts), Env.root);
        case StateReference r:
          return Bound(readState(env, r.parts), Env.root);
        case LoopReference r:
          final int at = env.loops.length - 1 - r.loop;
          if (at < 0) {
            return Bound(missing, env);
          }
          final Bound item = env.loops[at];
          return walk(item.value, item.env, r.parts, 0);
        case WidgetBuilderArgReference r:
          final Bound? arg = env.builderArgs[r.argumentName];
          if (arg == null) {
            return Bound(missing, env);
          }
          return walk(arg.value, arg.env, r.parts, 0);
        case Switch s:
          final Object? key = resolve(s.input, env).value;
          if (s.outputs.containsKey(key)) {
            value = s.outputs[key];
          } else if (s.outputs.containsKey(null)) {
            value = s.outputs[null];
          } else {
            return Bound(missing, env);
          }
        default:
          return Bound(value, env);
      }
    }
  }

  /// The value at [parts], from [from] on (and up to [end]), of [value] read
  /// in [env].
  Bound walk(Object? value, Env env, List<Object> parts, int from, [int? end]) {
    Bound at = resolve(value, env);
    for (int i = from; i < (end ?? parts.length); i += 1) {
      final Object part = parts[i];
      final Object? v = at.value;
      if (v is DynamicMap) {
        if (part is! String || !v.containsKey(part)) {
          return Bound(missing, at.env);
        }
        at = resolve(v[part], at.env);
      } else if (v is DynamicList) {
        if (part is! int) {
          return Bound(missing, at.env);
        }
        final UiListEntry? entry = listEntry(v, at.env, part);
        if (entry == null) {
          return Bound(missing, at.env);
        }
        at = resolve(entry.value, entry.env);
      } else {
        return Bound(missing, at.env);
      }
    }
    return at;
  }

  /// How many entries [list] has, each loop counted by its rows.
  int listLength(List<Object?> list, Env env) {
    if (!_hasLoops(list)) {
      return list.length;
    }
    int n = 0;
    for (final Object? entry in list) {
      if (entry is Loop) {
        final Bound items = resolve(entry.input, env);
        final Object? value = items.value;
        n += value is DynamicList ? listLength(value, items.env) : 0;
      } else {
        n += 1;
      }
    }
    return n;
  }

  /// Entry [index] of [list], or null past its end.
  UiListEntry? listEntry(List<Object?> list, Env env, int index) {
    if (index < 0) {
      return null;
    }
    if (!_hasLoops(list)) {
      return index < list.length ? UiListEntry(list[index], env) : null;
    }
    int remaining = index;
    for (final Object? entry in list) {
      if (entry is Loop) {
        final Bound items = resolve(entry.input, env);
        final Object? value = items.value;
        if (value is! DynamicList) {
          continue;
        }
        final int n = listLength(value, items.env);
        if (remaining < n) {
          return _row(entry, env, listEntry(value, items.env, remaining)!, remaining);
        }
        remaining -= n;
      } else if (remaining == 0) {
        return UiListEntry(entry, env);
      } else {
        remaining -= 1;
      }
    }
    return null;
  }

  /// Every entry of [list], in order.
  Iterable<UiListEntry> listEntries(List<Object?> list, Env env) sync* {
    for (final Object? entry in list) {
      if (entry is! Loop) {
        yield UiListEntry(entry, env);
        continue;
      }
      final Bound items = resolve(entry.input, env);
      final Object? value = items.value;
      if (value is! DynamicList) {
        continue;
      }
      int i = 0;
      for (final UiListEntry item in listEntries(value, items.env)) {
        yield _row(entry, env, item, i);
        i += 1;
      }
    }
  }

  UiListEntry _row(Loop loop, Env env, UiListEntry item, int index) => UiListEntry(
    loop.output,
    env.withLoop(item.value, item.env),
    loop: loop,
    itemIndex: index,
    item: item.value,
  );

  /// [value] in [env] as plain data: maps, lists and primitives, references
  /// followed and loops expanded all the way down, as an event's arguments
  /// are handed over. Calls and handlers are left as they are.
  Object? materialize(Object? value, Env env) {
    final Bound at = resolve(value, env);
    final Object? v = at.value;
    // Data and state hold plain values already.
    if (identical(at.env, Env.root)) {
      return v;
    }
    if (v is DynamicMap) {
      return <String, Object?>{
        for (final MapEntry<String, Object?> e in v.entries) e.key: materialize(e.value, at.env),
      };
    }
    if (v is DynamicList) {
      return <Object?>[for (final UiListEntry e in listEntries(v, at.env)) materialize(e.value, e.env)];
    }
    return v;
  }
}

final Expando<bool> _loopy = Expando<bool>('has loops');

/// Whether [list] holds a loop: data never does, so its rows are indexed
/// straight away. Remembered per list, since a list does not change.
bool _hasLoops(List<Object?> list) => _loopy[list] ??= list.any((Object? entry) => entry is Loop);

/// Whether [a] and [b] are the same item: equal plain data all the way down,
/// with numbers of the same type, or the very same node of the parsed model.
bool uiSameItem(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map<String, Object?>) {
    if (b is! Map<String, Object?> || a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, Object?> e in a.entries) {
      if (!b.containsKey(e.key) || !uiSameItem(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?>) {
    if (b is! List<Object?> || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i += 1) {
      if (!uiSameItem(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  if (a is BlobNode || b is BlobNode) {
    return false;
  }
  if (a is num || b is num) {
    return a.runtimeType == b.runtimeType && a == b;
  }
  return a == b;
}
