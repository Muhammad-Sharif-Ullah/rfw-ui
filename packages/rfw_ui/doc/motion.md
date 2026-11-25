# Motion and effects

How a remote screen animates, what a running animation costs, and the rules
the widgets follow so that it stays cheap.

## The one rule

**An animated frame paints a layer and rebuilds nothing.**

Everything in `motion.dart` is built around it. In rfw, building a widget
means resolving every argument of every widget under it: a key is built and
hashed and a hash map searched, per argument, per widget
([why-slower.md](why-slower.md)). A naive animation that rebuilt its subtree
sixty times a second would pay all of that sixty times a second, and the
larger the subtree the worse it would get.

So `Animate` and `ScrollTransition` build their child **once**, outside the
builder, and hand that one widget to Flutter's own render-object transitions:

```dart
// motion.dart, in Animate's build
final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();
return UiTicker(
  ...,
  builder: (BuildContext context, Animation<double> t) => applyEffects(effects, t, child),
);
```

`applyEffects` wraps that same `child` in `FadeTransition`,
`ScaleTransition`, `SlideTransition`, `RotationTransition`, or an
`AnimatedBuilder` with the child passed as `child:` for the filter effects.
Each of those listens to the animation and marks itself for **paint**, not
for build. The remote subtree's elements are never revisited.

The measured result is in [performance.md](performance.md#motion): sixty
cards, each with a shimmer running, build in the same time as the same
screen written in Dart by hand, and neither drops a frame -- on an M1 Mac,
on an iPhone and on an Android phone.

## `Animate`: motion on a clock

```
Animate(
  duration: 900,
  repeat: -1,
  reverse: true,
  curve: .easeInOut,
  effects: [{ effect: .scale, from: 1, to: 1.15 }],
  child: Icon(icon: .favorite, size: 40, color: .primary),
)
```

- `repeat: -1` runs for as long as the widget is on screen; `0` and `1` play
  once; `n` plays n times and then fires `onEnd`.
- `reverse: true` makes each play run forward and back again.
- `playing: data.loading` starts and stops it from data, where it stands.
- `delay`, with `index` and `stagger`, is how a list comes in one row after
  another: the delay of a row is `delay + stagger * index`. rfw cannot
  multiply, so the multiplication happens in Dart from two declared
  arguments.

### The effects

| `effect` | Arguments | Wraps the child in |
|---|---|---|
| `.fade` | `from`, `to` | `FadeTransition` |
| `.scale` | `from`, `to`, `alignment` | `ScaleTransition` |
| `.slide` | `from`, `to` (offsets in fractions of the child) | `SlideTransition` |
| `.rotate` | `from`, `to` (turns), `alignment` | `RotationTransition` |
| `.blur` | `from`, `to` (sigma), `tileMode` | `ImageFiltered`, switched off at zero |
| `.tint` | `from`, `to` (colours), `blendMode` | `ColorFiltered` |
| `.shimmer` | `color`, `width`, `angle` | `ShaderMask` with a travelling gradient |

Effects compose, first outermost:
`effects: [{ effect: .fade, ... }, { effect: .slide, ... }]` fades and slides
at once. An unknown effect name is dropped rather than throwing, as every
other decoder in the kit does.

### Reduced motion

A device set to reduce motion (`MediaQuery.disableAnimationsOf`) gets the
**end** of the animation and no ticker at all: `UiTicker` holds its value at
1 and never starts. Nothing in the tree moves, and no frames are scheduled.
`test/motion_test.dart` asserts that after the first pump there are no
transient callbacks — that is, no ticker running.

## `ScrollTransition`: motion driven by the scroll

The same effect list, driven by the scroll view it sits in instead of by a
clock:

```
ScrollTransition(
  from: 0, to: 160,
  effects: [{ effect: .fade, from: 1, to: 0 }, { effect: .slide, from: { x: 0, y: 0 }, to: { x: 0, y: -0.4 } }],
  child: ...,
)
```

`from` and `to` are scroll offsets in pixels. `UiScrollDriver` listens to the
nearest `Scrollable`'s position, writes the clamped progress into a
`ValueNotifier` seen as an `Animation<double>`, and removes the listener in
`dispose()`. Outside the range it holds at the end it reached; with no
scroll view above it, at the start. A header built this way never rebuilds
while the list scrolls past it.

## `BackdropFilter`: the one that bites

In Flutter, `BackdropFilter` blurs **its whole layer**, which without a clip
is the screen. It is also the most expensive widget in the framework.

The kit's version clips to its own bounds. A 48-pixel bar blurs 48 pixels:

```
Positioned(top: 0, left: 0, right: 0, child: BackdropFilter(blur: 12, child: SizedBox(height: 48)))
```

`borderRadius` makes that clip a rounded one, and `clip: false` gives
Flutter's behaviour back for the rare screen that wants it. Several filters
over one background belong in a `BackdropGroup` with `grouped: true`, which
reads the backdrop once for all of them instead of once each.

## What owns what

| Object | Owner | Freed |
|---|---|---|
| `AnimationController` of an `Animate` | `UiTicker` state | its `dispose()` |
| The delay `Timer` | `UiTicker` state | its `dispose()`, cancelled |
| The scroll listener of a `ScrollTransition` | `UiScrollDriver` state | its `dispose()`, removed first |
| `TransformationController` of an `InteractiveViewer` | `UiOwned` state | its `dispose()` |

Every one of those is covered by the leak tracker, which all of
`flutter test` runs under ([lifecycle-and-memory.md](lifecycle-and-memory.md)).

## The transitions that are not `Animate`

`AnimatedSwitcher`, `AnimatedSize`, `AnimatedCrossFade`, `Hero` and
`AnimatedIcon` are Flutter's own, with their arguments exposed. One
rfw-specific caveat, documented on the widget and asserted in its test:

**`AnimatedSwitcher`'s outgoing child is a live subtree, not a snapshot.**
rfw builds a widget's child below the widget it was handed, so the kit
cannot see a `key:` written on the child; `AnimatedSwitcher` takes an
explicit `value` instead, and wraps the child in a `KeyedSubtree` keyed by
it. The child that is fading out is still bound to the same data, so while
it fades it shows the *new* value. Use it for a swap of position or shape,
not to show the old text beside the new.
