import 'dart:async';

import 'package:flutter/material.dart';

import 'scope.dart';

/// A value an input keeps for itself, seeded from its argument and re-synced
/// whenever that argument changes.
///
/// rfw inputs are usually "controlled": the remote file passes `value:` from
/// data and writes the new value back with an event. That round trip only
/// works when something is on the other end, and in a preview -- or with a
/// literal `value: true` -- there is not. So the input shows its own value at
/// once and reports it, and when the data it was given does change, the data
/// wins. Bound or unbound, a switch you tap moves.
class UiValue<T> extends StatefulWidget {
  const UiValue({
    super.key,
    required this.value,
    required this.initial,
    required this.onChanged,
    required this.builder,
    this.equals,
  });

  /// What the remote file passed; null when it passed nothing.
  final T? value;

  /// What to start from when [value] is null.
  final T initial;

  final ValueChanged<T>? onChanged;

  /// Builds the input. The callback is null when [onChanged] is, which is how
  /// Flutter inputs know to draw themselves disabled.
  final Widget Function(BuildContext context, T value, ValueChanged<T>? onChanged) builder;

  /// How to tell a new [value] from the old one, for values -- sets, lists --
  /// that are rebuilt equal but not identical every time the remote widget is.
  final bool Function(T a, T b)? equals;

  @override
  State<UiValue<T>> createState() => _UiValueState<T>();
}

class _UiValueState<T> extends State<UiValue<T>> {
  late T _value = widget.value ?? widget.initial;

  @override
  void didUpdateWidget(UiValue<T> old) {
    super.didUpdateWidget(old);
    final T? incoming = widget.value;
    final T? previous = old.value;
    if (incoming == null) {
      return;
    }
    final bool same = previous != null && (widget.equals?.call(incoming, previous) ?? incoming == previous);
    if (!same) {
      _value = incoming;
    }
  }

  void _set(T value) {
    setState(() => _value = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value, widget.onChanged == null ? null : _set);
}

/// A [TextEditingController] owned for a remote text field, kept in step with
/// the field's `value` argument without fighting the person typing: the text
/// is only replaced when the argument changes to something the field does not
/// already say.
///
/// And the field's [FocusNode], registered under the field's key when it has
/// one, so `ui.focus { key }` can move the cursor into it.
class UiTextController extends StatefulWidget {
  const UiTextController({super.key, required this.value, this.id, required this.builder});

  final String? value;

  /// The field's `key`, if it has one.
  final String? id;

  final Widget Function(BuildContext context, TextEditingController controller, FocusNode focusNode) builder;

  @override
  State<UiTextController> createState() => _UiTextControllerState();
}

class _UiTextControllerState extends State<UiTextController> {
  late final TextEditingController _controller = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(UiTextController old) {
    super.didUpdateWidget(old);
    final String? incoming = widget.value;
    if (incoming != null && incoming != old.value && incoming != _controller.text) {
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiFocusable(
    id: widget.id,
    builder: (BuildContext context, FocusNode node) => widget.builder(context, _controller, node),
  );
}

/// Any controller a widget needs for as long as it is on screen: created once,
/// disposed with the widget.
class UiOwned<C extends ChangeNotifier> extends StatefulWidget {
  const UiOwned({super.key, required this.create, required this.builder});

  final C Function() create;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<UiOwned<C>> createState() => _UiOwnedState<C>();
}

class _UiOwnedState<C extends ChangeNotifier> extends State<UiOwned<C>> {
  late final C _controller = widget.create();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// An [AnimationController] owned for a remote widget: created once, started
/// after its delay, and disposed with the widget.
///
/// The builder is handed the controller as a plain [Animation], and what it
/// wraps around the child must be a widget that *listens* to that animation
/// rather than one that rebuilds from it -- `FadeTransition` and the rest.
/// The child is built by the remote library once, before this widget exists,
/// and passed down untouched; see `widgets/motion.dart`.
///
/// When the person has asked their device to stop moving things
/// ([MediaQueryData.disableAnimations]) no ticker is started at all and the
/// animation holds at its end, so the screen is still and costs nothing.
class UiTicker extends StatefulWidget {
  const UiTicker({
    super.key,
    required this.duration,
    required this.builder,
    this.delay = Duration.zero,
    this.index = 0,
    this.stagger = Duration.zero,
    this.repeat = 0,
    this.reverse = false,
    this.playing = true,
    this.onEnd,
  });

  final Duration duration;

  /// Waited out before the first play. A row in a list adds [stagger] times
  /// its [index] to it, which is how a list staggers: rfw cannot multiply,
  /// so the multiplication is here.
  final Duration delay;
  final int index;
  final Duration stagger;

  /// How many times it plays. 0 and 1 play once; a negative number repeats
  /// for as long as the widget is on screen.
  final int repeat;

  /// Each play runs forward and then back again.
  final bool reverse;

  /// False stops it where it stands; true again carries on from there.
  final bool playing;

  /// Called when the last play finishes. A repeating animation has no last
  /// play, so it never calls this.
  final VoidCallback? onEnd;

  final Widget Function(BuildContext context, Animation<double> t) builder;

  @override
  State<UiTicker> createState() => _UiTickerState();
}

class _UiTickerState extends State<UiTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener(_onStatus);
  Timer? _waiting;
  bool _attached = false;
  bool _still = false;
  int _played = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool still = MediaQuery.disableAnimationsOf(context);
    if (!_attached || still != _still) {
      _attached = true;
      _still = still;
      _restart();
    }
  }

  @override
  void didUpdateWidget(UiTicker old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.repeat != old.repeat || widget.reverse != old.reverse) {
      _played = 0;
      if (widget.playing && !_still) {
        _play();
      }
      return;
    }
    if (widget.playing != old.playing) {
      if (widget.playing) {
        if (!_still) {
          _play();
        }
      } else {
        _waiting?.cancel();
        _waiting = null;
        _controller.stop();
      }
    }
  }

  /// Back to the beginning and off again, for a change that invalidates where
  /// the animation had got to: the first build, or reduced motion going on or
  /// off.
  void _restart() {
    _waiting?.cancel();
    _waiting = null;
    _played = 0;
    if (_still) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    if (!widget.playing) {
      return;
    }
    final Duration delay = widget.delay + widget.stagger * widget.index;
    if (delay > Duration.zero) {
      _waiting = Timer(delay, () {
        _waiting = null;
        if (mounted && widget.playing) {
          _play();
        }
      });
    } else {
      _play();
    }
  }

  /// Off from wherever it stands.
  void _play() {
    if (widget.repeat < 0) {
      _controller.repeat(reverse: widget.reverse);
    } else {
      _controller.forward(from: _controller.value);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (widget.repeat < 0 || !widget.playing) {
      return;
    }
    final int plays = widget.repeat < 1 ? 1 : widget.repeat;
    if (widget.reverse) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _played += 1;
        if (_played < plays) {
          _controller.forward();
        } else {
          widget.onEnd?.call();
        }
      }
    } else if (status == AnimationStatus.completed) {
      _played += 1;
      if (_played < plays) {
        _controller.forward(from: 0);
      } else {
        widget.onEnd?.call();
      }
    }
  }

  @override
  void dispose() {
    _waiting?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller.view);
}

/// A [Key] of its own, for a widget Flutter requires one of -- `Dismissible`
/// -- that the remote file did not name.
///
/// Made once and kept, so the widget below keeps its state across rebuilds; a
/// fresh `UniqueKey()` on every build would reset it on every frame.
class UiOwnKey extends StatefulWidget {
  const UiOwnKey({super.key, required this.builder});

  final Widget Function(BuildContext context, Key key) builder;

  @override
  State<UiOwnKey> createState() => _UiOwnKeyState();
}

class _UiOwnKeyState extends State<UiOwnKey> {
  final UniqueKey _key = UniqueKey();

  @override
  Widget build(BuildContext context) => widget.builder(context, _key);
}

/// A [ValueNotifier] seen as an [Animation], so the same `*Transition`
/// widgets that a clock drives can be driven by anything else.
///
/// It has no status of its own: a scroll offset never completes.
class UiDrivenAnimation extends Animation<double> {
  UiDrivenAnimation(this._source);

  final ValueNotifier<double> _source;

  @override
  void addListener(VoidCallback listener) => _source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _source.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  double get value => _source.value;
}

/// How far the enclosing scroll view has scrolled across [from]..[to], as a
/// number from 0 to 1, for as long as the widget is on screen.
///
/// A [ScrollPosition] is a [Listenable], so the transitions the builder puts
/// around the child repaint as the list moves and nothing rebuilds. With no
/// scroll view above it the value holds at 0 and nothing is listened to.
class UiScrollDriver extends StatefulWidget {
  const UiScrollDriver({super.key, required this.from, required this.to, required this.builder});

  final double from;
  final double to;
  final Widget Function(BuildContext context, Animation<double> t) builder;

  @override
  State<UiScrollDriver> createState() => _UiScrollDriverState();
}

class _UiScrollDriverState extends State<UiScrollDriver> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  late final UiDrivenAnimation _animation = UiDrivenAnimation(_progress);
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_read);
      _position = position;
      _position?.addListener(_read);
      _read();
    }
  }

  @override
  void didUpdateWidget(UiScrollDriver old) {
    super.didUpdateWidget(old);
    if (widget.from != old.from || widget.to != old.to) {
      _read();
    }
  }

  void _read() {
    final ScrollPosition? position = _position;
    if (position == null || !position.hasPixels) {
      _progress.value = 0;
      return;
    }
    final double span = widget.to - widget.from;
    _progress.value = span == 0 ? 0 : ((position.pixels - widget.from) / span).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _position?.removeListener(_read);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _animation);
}

/// A refresh that lasts as long as [hold]: an rfw event is fire-and-forget,
/// so there is nothing to await, and a spinner that vanished at once would
/// tell the person nothing had happened.
Future<void> Function() heldRefresh(VoidCallback? fire, Duration hold) {
  return () {
    fire?.call();
    return Future<void>.delayed(hold);
  };
}
