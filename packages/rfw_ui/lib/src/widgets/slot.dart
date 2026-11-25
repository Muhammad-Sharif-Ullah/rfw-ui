import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

/// A place that wants a [PreferredSizeWidget] -- `Scaffold.appBar`,
/// `AppBar.bottom`, `CupertinoPageScaffold.navigationBar` -- filled by a remote
/// widget.
///
/// rfw hands a local widget its children wrapped in its own widget, so a
/// Scaffold cannot see that its app bar is an AppBar, let alone how tall one
/// with a TabBar under it is. rfw's own Scaffold guesses 56 pixels. Here the
/// widget inside reports its real size with [UiSlot.report], and the slot
/// takes that size from the next frame on; a slot nothing reports into keeps
/// the size it started with.
class UiSlot extends StatelessWidget implements ObstructingPreferredSizeWidget {
  const UiSlot({super.key, required this.size, required this.child});

  final UiSlotSize size;
  final Widget child;

  @override
  Size get preferredSize => size.value.size;

  @override
  bool shouldFullyObstruct(BuildContext context) => size.value.obstructs;

  @override
  Widget build(BuildContext context) => _UiSlotScope(size: size, child: child);

  /// Tells the slot [context] is in what size [widget] wants. Called by the
  /// builders of widgets that are usually put in one; harmless anywhere else.
  static void report(BuildContext context, PreferredSizeWidget widget, {bool? obstructs}) {
    final _UiSlotScope? scope = context.getInheritedWidgetOfExactType<_UiSlotScope>();
    scope?.size.report(SlotValue(widget.preferredSize, obstructs ?? scope.size.value.obstructs));
  }
}

/// A slot's size, and whether what fills it is opaque (which is all a
/// Cupertino scaffold needs to know to decide whether content goes under it).
@immutable
class SlotValue {
  const SlotValue(this.size, [this.obstructs = true]);

  final Size size;
  final bool obstructs;

  @override
  bool operator ==(Object other) => other is SlotValue && other.size == size && other.obstructs == obstructs;

  @override
  int get hashCode => Object.hash(size, obstructs);
}

class UiSlotSize extends ValueNotifier<SlotValue> {
  UiSlotSize(super.value);

  bool _disposed = false;

  /// Takes [next] after this frame: a report arrives while the tree is being
  /// built, when nothing may be marked dirty.
  void report(SlotValue next) {
    if (next == value) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!_disposed) {
        value = next;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _UiSlotScope extends InheritedWidget {
  const _UiSlotScope({required this.size, required super.child});

  final UiSlotSize size;

  @override
  bool updateShouldNotify(_UiSlotScope old) => old.size != size;
}

/// Owns the [UiSlotSize]s a widget's slots need and rebuilds when any of them
/// changes.
class UiSlots extends StatefulWidget {
  const UiSlots({super.key, required this.initial, required this.builder});

  /// The starting value of each slot, by name.
  final Map<String, SlotValue> initial;

  /// Builds the widget, wrapping whatever goes in slot `name` with
  /// `slot(name, child)`.
  final Widget Function(BuildContext context, UiSlot Function(String name, Widget child) slot) builder;

  @override
  State<UiSlots> createState() => _UiSlotsState();
}

class _UiSlotsState extends State<UiSlots> {
  late final Map<String, UiSlotSize> _sizes = <String, UiSlotSize>{
    for (final MapEntry<String, SlotValue> e in widget.initial.entries) e.key: UiSlotSize(e.value),
  };

  @override
  void dispose() {
    for (final UiSlotSize size in _sizes.values) {
      size.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(_sizes.values.toList()),
      builder: (BuildContext context, Widget? _) => widget.builder(
        context,
        (String name, Widget child) => UiSlot(size: _sizes[name]!, child: child),
      ),
    );
  }
}
