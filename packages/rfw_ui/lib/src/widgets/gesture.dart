import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';
import 'state.dart';

/// Swiping, dragging, dropping, pinching and reordering.
///
/// Three of these need every child to carry a [Key], which a remote file
/// gives with `key:` on the child. Where it did not, one is supplied from the
/// row's position, so a list written without keys still works -- it just
/// cannot carry a row's state with it when the rows move.

/// Each of [children] with a key, using its own where it has one.
List<Widget> _keyed(List<Widget> children) => <Widget>[
  for (int i = 0; i < children.length; i += 1)
    if (children[i].key != null) children[i] else KeyedSubtree(key: ValueKey<int>(i), child: children[i]),
];

Widget _keyedRow(Widget row, int index) =>
    row.key != null ? row : KeyedSubtree(key: ValueKey<int>(index), child: row);

final List<UiWidget> gestureWidgets = <UiWidget>[
  UiWidget(
    'Dismissible',
    group: UiGroup.gesture,
    doc: 'A row that is swiped away. `background` shows behind it on the way out, and `secondaryBackground` '
        'when it goes the other way. `onDismissed` fires with `{ direction }` once it has gone, and the row is '
        'then out of the tree: take it out of your data there, or it comes back on the next rebuild. '
        'Give it a `key` that belongs to the row, so the right one goes.',
    params: <UiParam>[
      e('direction', DismissDirection.values, 'Which way it may be swiped.', 'horizontal'),
      p('background', 'Widget', 'Behind it as it goes start-to-end.'),
      p('secondaryBackground', 'Widget', 'Behind it as it goes end-to-start.'),
      p('onDismissed', 'event', 'Receives `{ direction }`.'),
      p('onResize', 'event'),
      p('dismissThreshold', 'double', 'How far across it must go, as a fraction of its width.', '0.4'),
      p('movementDuration', 'Duration', null, '200ms'),
      p('resizeDuration', 'Duration', 'How long the gap takes to close. Null leaves no gap.', '300ms'),
      e('behavior', HitTestBehavior.values, null, 'opaque'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final DismissDirection direction =
          a.enumValue(DismissDirection.values, const <Object>['direction']) ?? DismissDirection.horizontal;
      final Widget? background = a.optionalChild(const <Object>['background']);
      final Widget? secondaryBackground = a.optionalChild(const <Object>['secondaryBackground']);
      final ValueChanged<Map<String, Object?>>? onDismissed = a.onValues(const <Object>['onDismissed']);
      final VoidCallback? onResize = a.onTap(const <Object>['onResize']);
      final double threshold = a.number(const <Object>['dismissThreshold']) ?? 0.4;
      final Duration movementDuration = a.duration(const <Object>['movementDuration']) ?? const Duration(milliseconds: 200);
      final Duration resizeDuration = a.duration(const <Object>['resizeDuration']) ?? const Duration(milliseconds: 300);
      final HitTestBehavior behavior = a.enumValue(HitTestBehavior.values, const <Object>['behavior']) ?? HitTestBehavior.opaque;
      final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();

      Widget build(Key key) => Dismissible(
        key: key,
        direction: direction,
        background: background,
        secondaryBackground: secondaryBackground,
        onDismissed: onDismissed == null
            ? null
            : (DismissDirection went) => onDismissed(<String, Object?>{'direction': went.name}),
        onResize: onResize,
        dismissThresholds: <DismissDirection, double>{DismissDirection.horizontal: threshold, DismissDirection.vertical: threshold},
        movementDuration: movementDuration,
        resizeDuration: resizeDuration,
        behavior: behavior,
        child: child,
      );

      final String? named = a.key;
      // Flutter requires a Dismissible to have a key. Where the file gave
      // none, one is made once and kept, so the row does not reset as it goes.
      if (named != null) {
        return build(ValueKey<String>('dismiss:$named'));
      }
      return UiOwnKey(builder: (BuildContext context, Key key) => build(key));
    },
    example: 'SizedBox(height: 90, child: ListView(children: [Dismissible(key: "one", '
        'background: ColoredBox(color: .errorContainer), '
        'child: ListTile(title: "Swipe me away"))]))',
  ),
  UiWidget(
    'Draggable',
    group: UiGroup.gesture,
    doc: 'Picks its child up and carries `feedback` under the finger until it is dropped. '
        'Whatever `data` says is what a `DragTarget` it is dropped on receives.',
    params: <UiParam>[
      p('data', 'String', 'What a DragTarget receives when this is dropped on it.'),
      p('feedback', 'Widget', 'Carried under the finger.'),
      p('childWhenDragging', 'Widget', 'Left in its place while it is held.'),
      e('axis', Axis.values, 'Held to one axis.'),
      p('maxSimultaneousDrags', 'int', 'How many fingers may hold it at once. 0 stops it being dragged.'),
      p('onDragStarted', 'event'),
      p('onDragEnd', 'event'),
      p('onDragCompleted', 'event', 'It was accepted by a target.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final String data = a.string(const <Object>['data']) ?? '';
      final Widget? feedback = a.optionalChild(const <Object>['feedback']);
      final Widget? childWhenDragging = a.optionalChild(const <Object>['childWhenDragging']);
      final Axis? axis = a.enumValue(Axis.values, const <Object>['axis']);
      final int? maxSimultaneousDrags = a.integer(const <Object>['maxSimultaneousDrags']);
      final VoidCallback? onDragStarted = a.onTap(const <Object>['onDragStarted']);
      final VoidCallback? onDragEnd = a.onTap(const <Object>['onDragEnd']);
      final VoidCallback? onDragCompleted = a.onTap(const <Object>['onDragCompleted']);
      final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();
      return Draggable<String>(
        data: data,
        axis: axis,
        maxSimultaneousDrags: maxSimultaneousDrags,
        feedback: feedback ?? Opacity(opacity: 0.8, child: child),
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStarted,
        onDragEnd: onDragEnd == null ? null : (DraggableDetails details) => onDragEnd(),
        onDragCompleted: onDragCompleted,
        child: child,
      );
    },
  ),
  UiWidget(
    'DragTarget',
    group: UiGroup.gesture,
    doc: 'Takes what a `Draggable` is dropped on it. `onAccept` fires with `{ value }`, the dragged `data`.',
    params: <UiParam>[
      p('onAccept', 'event<String>', 'Receives `{ value }`: the dropped Draggable\'s `data`.'),
      p('onWillAccept', 'event<String>', 'As it comes over, before it is dropped.'),
      p('onLeave', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final ValueChanged<String>? onAccept = a.onValue<String>(const <Object>['onAccept']);
      final ValueChanged<String>? onWillAccept = a.onValue<String>(const <Object>['onWillAccept']);
      final VoidCallback? onLeave = a.onTap(const <Object>['onLeave']);
      final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();
      return DragTarget<String>(
        onAcceptWithDetails: onAccept == null ? null : (DragTargetDetails<String> d) => onAccept(d.data),
        onWillAcceptWithDetails: onWillAccept == null
            ? null
            : (DragTargetDetails<String> d) {
                onWillAccept(d.data);
                return true;
              },
        onLeave: onLeave == null ? null : (String? data) => onLeave(),
        builder: (BuildContext context, List<String?> candidates, List<Object?> rejected) => child,
      );
    },
  ),
  UiWidget(
    'InteractiveViewer',
    group: UiGroup.gesture,
    doc: 'Pinch to zoom and drag to pan whatever is inside it: a photograph, a map, a diagram. '
        'Inside a scroll view, set `panAxis` or the two fight over the drag.',
    params: <UiParam>[
      p('minScale', 'double', null, '0.8'),
      p('maxScale', 'double', null, '2.5'),
      p('panEnabled', 'bool', null, 'true'),
      p('scaleEnabled', 'bool', null, 'true'),
      e('panAxis', PanAxis.values, 'Hold panning to one axis.', 'free'),
      p('constrained', 'bool', 'False lets the child be bigger than the viewport.', 'true'),
      p('boundaryMargin', 'EdgeInsets', 'How far past the child it may be panned.'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('onInteractionEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final VoidCallback? onEnd = a.onTap(const <Object>['onInteractionEnd']);
      return InteractiveViewer(
        minScale: a.number(const <Object>['minScale']) ?? 0.8,
        maxScale: a.number(const <Object>['maxScale']) ?? 2.5,
        panEnabled: a.boolean(const <Object>['panEnabled']) ?? true,
        scaleEnabled: a.boolean(const <Object>['scaleEnabled']) ?? true,
        panAxis: a.enumValue(PanAxis.values, const <Object>['panAxis']) ?? PanAxis.free,
        constrained: a.boolean(const <Object>['constrained']) ?? true,
        boundaryMargin: a.edgeInsets(const <Object>['boundaryMargin'])?.resolve(Directionality.of(a.context)) ?? EdgeInsets.zero,
        clipBehavior: a.enumValue(Clip.values, const <Object>['clipBehavior']) ?? Clip.hardEdge,
        onInteractionEnd: onEnd == null ? null : (ScaleEndDetails details) => onEnd(),
        child: a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink(),
      );
    },
    example: 'SizedBox(height: 160, child: InteractiveViewer(maxScale: 4, '
        'child: Container(decoration: { gradient: { type: .radial, colors: [.primary, .surface] } })))',
  ),
  UiWidget(
    'ReorderableListView',
    group: UiGroup.gesture,
    doc: 'A list whose rows are dragged into a new order. `onReorder` fires with `{ oldIndex, newIndex }`, where `newIndex` is already where the row lands once it has been taken out; '
        'move the item in your data there, or the list springs back. '
        'Give every row a `key` of its own, so a row carries its state with it as it moves.',
    params: <UiParam>[
      p('onReorder', 'event', 'Receives `{ oldIndex, newIndex }`.'),
      p('padding', 'EdgeInsets'),
      e('scrollDirection', Axis.values, null, 'vertical'),
      p('reverse', 'bool', null, 'false'),
      p('shrinkWrap', 'bool', null, 'false'),
      p('physics', 'String'),
      p('buildDefaultDragHandles', 'bool', 'Flutter\'s own handles on the trailing edge.', 'true'),
      p('header', 'Widget'),
      p('footer', 'Widget'),
      p('children', 'List<Widget>'),
    ],
    build: (UiArgs a) => ReorderableListView(
      onReorderItem: _reorder(a),
      padding: a.edgeInsets(const <Object>['padding'])?.resolve(Directionality.of(a.context)),
      scrollDirection: a.enumValue(Axis.values, const <Object>['scrollDirection']) ?? Axis.vertical,
      reverse: a.boolean(const <Object>['reverse']) ?? false,
      shrinkWrap: a.boolean(const <Object>['shrinkWrap']) ?? false,
      physics: a.physics(const <Object>['physics']),
      buildDefaultDragHandles: a.boolean(const <Object>['buildDefaultDragHandles']) ?? true,
      header: a.optionalChild(const <Object>['header']),
      footer: a.optionalChild(const <Object>['footer']),
      children: _keyed(a.children(const <Object>['children'])),
    ),
  ),
  UiWidget(
    'ReorderableListView.builder',
    group: UiGroup.gesture,
    needsUiRuntime: true,
    doc: 'A `ReorderableListView` whose rows `itemBuilder` builds from `items`, each as it scrolls into view. '
        'Needs UiRuntime; on rfw\'s Runtime, write `ReorderableListView(children: [...for r in items: ...])`.',
    params: <UiParam>[
      p('onReorder', 'event', 'Receives `{ oldIndex, newIndex }`.'),
      p('padding', 'EdgeInsets'),
      e('scrollDirection', Axis.values, null, 'vertical'),
      p('reverse', 'bool', null, 'false'),
      p('shrinkWrap', 'bool', null, 'false'),
      p('physics', 'String'),
      p('buildDefaultDragHandles', 'bool', null, 'true'),
      p('header', 'Widget'),
      p('footer', 'Widget'),
      ...itemBuilderParams(),
    ],
    build: (UiArgs a) {
      final UiItems? rows = a.items();
      if (rows == null) {
        return uiNeedsUiRuntime(
          'ReorderableListView.builder',
          'ReorderableListView(children: [...for r in items: ...])',
        );
      }
      return ReorderableListView.builder(
        onReorderItem: _reorder(a),
        padding: a.edgeInsets(const <Object>['padding'])?.resolve(Directionality.of(a.context)),
        scrollDirection: a.enumValue(Axis.values, const <Object>['scrollDirection']) ?? Axis.vertical,
        reverse: a.boolean(const <Object>['reverse']) ?? false,
        shrinkWrap: a.boolean(const <Object>['shrinkWrap']) ?? false,
        physics: a.physics(const <Object>['physics']),
        buildDefaultDragHandles: a.boolean(const <Object>['buildDefaultDragHandles']) ?? true,
        header: a.optionalChild(const <Object>['header']),
        footer: a.optionalChild(const <Object>['footer']),
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) => _keyedRow(rows.build(index), index),
      );
    },
  ),
];

/// `onReorder`, which rfw cannot carry out for you: moving the item is a
/// change to the data, and the data is the app's. Flutter's `onReorderItem`
/// has already adjusted `newIndex` for the row being taken out, so the two
/// numbers are a remove and an insert as written.
ReorderCallback _reorder(UiArgs a) {
  final ValueChanged<Map<String, Object?>>? handler = a.onValues(const <Object>['onReorder']);
  return (int oldIndex, int newIndex) =>
      handler?.call(<String, Object?>{'oldIndex': oldIndex, 'newIndex': newIndex});
}
