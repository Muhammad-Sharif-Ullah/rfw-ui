import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';
import 'state.dart';

/// Motion: widgets that move a layer and leave what is under it alone.
///
/// Everything here obeys one rule. The child is built by the remote library
/// **once**, into a `Widget` the builder closes over, and that same object is
/// handed to Flutter's `*Transition` widgets as their `child:`. Those are
/// render-object widgets: they listen to the animation and mark themselves
/// for paint, and never rebuild their child. So a frame of a running
/// animation costs one paint of one layer, whatever the remote subtree under
/// it is -- and rfw's per-argument map lookups (doc/why-slower.md) are paid
/// once, not sixty times a second.
///
/// The two effects Flutter has no render-object transition for, `blur` and
/// `tint`, go through `AnimatedBuilder`, whose `child:` argument captures the
/// subtree in exactly the same way.

/// One entry of an `effects:` list, decoded.
sealed class UiEffect {
  const UiEffect();

  /// [t] has the widget's curve already applied.
  Widget wrap(Animation<double> t, Widget child);
}

class UiFadeEffect extends UiEffect {
  const UiFadeEffect(this.from, this.to);

  final double from;
  final double to;

  @override
  Widget wrap(Animation<double> t, Widget child) =>
      FadeTransition(opacity: t.drive(Tween<double>(begin: from, end: to)), child: child);
}

class UiScaleEffect extends UiEffect {
  const UiScaleEffect(this.from, this.to, this.alignment);

  final double from;
  final double to;
  final Alignment alignment;

  @override
  Widget wrap(Animation<double> t, Widget child) => ScaleTransition(
    scale: t.drive(Tween<double>(begin: from, end: to)),
    alignment: alignment,
    child: child,
  );
}

/// Moves by a fraction of the child's own size, as `SlideTransition` does:
/// `{ x: 0, y: 0.2 }` starts a fifth of its height below where it lands.
class UiSlideEffect extends UiEffect {
  const UiSlideEffect(this.from, this.to);

  final Offset from;
  final Offset to;

  @override
  Widget wrap(Animation<double> t, Widget child) =>
      SlideTransition(position: t.drive(Tween<Offset>(begin: from, end: to)), child: child);
}

/// Turns, not radians: 1 is all the way round, as `RotationTransition` takes.
class UiRotateEffect extends UiEffect {
  const UiRotateEffect(this.from, this.to, this.alignment);

  final double from;
  final double to;
  final Alignment alignment;

  @override
  Widget wrap(Animation<double> t, Widget child) => RotationTransition(
    turns: t.drive(Tween<double>(begin: from, end: to)),
    alignment: alignment,
    child: child,
  );
}

/// Flutter has no render-object transition for a blur, so this one goes
/// through [AnimatedBuilder] -- whose `child:` argument captures the subtree
/// exactly as a transition's does, so the filter rebuilds each frame and the
/// child does not.
///
/// The filter is switched off rather than set to zero, which is what Flutter's
/// own documentation asks for: a no-op filter still costs a saveLayer. The
/// widget stays in the tree either way, because taking it out would reparent
/// the child and force the subtree to be built again.
class UiBlurEffect extends UiEffect {
  const UiBlurEffect(this.from, this.to, this.tileMode);

  final double from;
  final double to;
  final TileMode tileMode;

  @override
  Widget wrap(Animation<double> t, Widget child) {
    final Animation<double> sigma = t.drive(Tween<double>(begin: from, end: to));
    return AnimatedBuilder(
      animation: sigma,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double s = sigma.value;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: math.max(s, 0.01), sigmaY: math.max(s, 0.01), tileMode: tileMode),
          enabled: s > 0.01,
          child: child,
        );
      },
    );
  }
}

/// A colour laid over the child, from one to another.
class UiTintEffect extends UiEffect {
  const UiTintEffect(this.from, this.to, this.blendMode);

  final Color from;
  final Color to;
  final BlendMode blendMode;

  @override
  Widget wrap(Animation<double> t, Widget child) => AnimatedBuilder(
    animation: t,
    child: child,
    builder: (BuildContext context, Widget? child) => ColorFiltered(
      colorFilter: ColorFilter.mode(Color.lerp(from, to, t.value) ?? to, blendMode),
      child: child,
    ),
  );
}

/// A band of light that travels across the child: the skeleton loader, and
/// the sheen over a button.
///
/// It sweeps from entirely before the child to entirely after it, so with
/// `repeat: -1` the band leaves one side as it enters the other.
class UiShimmerEffect extends UiEffect {
  const UiShimmerEffect(this.color, this.width, this.angle);

  final Color color;

  /// Half the band's width, as a fraction of the child.
  final double width;

  /// Turns clockwise from left-to-right.
  final double angle;

  @override
  Widget wrap(Animation<double> t, Widget child) => AnimatedBuilder(
    animation: t,
    child: child,
    builder: (BuildContext context, Widget? child) {
      final double travel = -1 - width + t.value * (2 + 2 * width);
      final double dx = math.cos(angle * 2 * math.pi);
      final double dy = math.sin(angle * 2 * math.pi);
      final Alignment begin = Alignment((travel - width) * dx, (travel - width) * dy);
      final Alignment end = Alignment((travel + width) * dx, (travel + width) * dy);
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect bounds) => LinearGradient(
          begin: begin,
          end: end,
          colors: <Color>[color.withAlpha(0), color, color.withAlpha(0)],
        ).createShader(bounds),
        child: child,
      );
    },
  );
}

/// The `effects` of an [Animate] or a `ScrollTransition`, decoded. An entry
/// whose `effect` is not a name known here is left out, so a typo is a
/// missing effect rather than a broken screen; `checkUiLibrary` is what
/// reports it.
List<UiEffect> effectsOf(UiArgs a, List<Object> key) {
  return a.list<UiEffect>(key, (List<Object> k) {
        List<Object> at(String name) => <Object>[...k, name];
        double from(double fallback) => a.number(at('from')) ?? fallback;
        double to(double fallback) => a.number(at('to')) ?? fallback;
        Alignment alignment() => a.absoluteAlignment(at('alignment')) ?? Alignment.center;
        switch (a.string(at('effect'))) {
          case 'fade':
            return UiFadeEffect(from(0), to(1));
          case 'scale':
            return UiScaleEffect(from(0), to(1), alignment());
          case 'slide':
            return UiSlideEffect(a.offset(at('from')) ?? Offset.zero, a.offset(at('to')) ?? Offset.zero);
          case 'rotate':
            return UiRotateEffect(from(0), to(0), alignment());
          case 'blur':
            return UiBlurEffect(
              from(0),
              to(0),
              a.enumValue(TileMode.values, at('tileMode')) ?? TileMode.decal,
            );
          case 'tint':
            return UiTintEffect(
              a.color(at('from')) ?? const Color(0x00000000),
              a.color(at('to')) ?? const Color(0x00000000),
              a.enumValue(BlendMode.values, at('blendMode')) ?? BlendMode.srcATop,
            );
          case 'shimmer':
            return UiShimmerEffect(
              a.color(at('color')) ?? const Color(0x66FFFFFF),
              a.number(at('width')) ?? 0.35,
              a.number(at('angle')) ?? 0,
            );
        }
        return null;
      }) ??
      const <UiEffect>[];
}

/// [effects] around [child], the first of them outermost.
Widget applyEffects(List<UiEffect> effects, Animation<double> t, Widget child) {
  Widget out = child;
  for (int i = effects.length - 1; i >= 0; i -= 1) {
    out = effects[i].wrap(t, out);
  }
  return out;
}

/// The names [effectsOf] knows, for the catalog and for `checkUiLibrary`.
const List<String> effectNames = <String>['fade', 'scale', 'slide', 'rotate', 'blur', 'tint', 'shimmer'];

/// How an `AnimatedSwitcher` brings the new child in and takes the old one
/// out. A slide comes from the side it is named for.
const Map<String, Offset> _switchSlides = <String, Offset>{
  'slideUp': Offset(0, 0.25),
  'slideDown': Offset(0, -0.25),
  'slideLeft': Offset(0.25, 0),
  'slideRight': Offset(-0.25, 0),
};

Widget _switchTransition(String name, Widget child, Animation<double> t) {
  final Offset? from = _switchSlides[name];
  if (from != null) {
    return SlideTransition(
      position: t.drive(Tween<Offset>(begin: from, end: Offset.zero)),
      child: FadeTransition(opacity: t, child: child),
    );
  }
  return switch (name) {
    'scale' => ScaleTransition(scale: t, child: FadeTransition(opacity: t, child: child)),
    'rotate' => RotationTransition(turns: t.drive(Tween<double>(begin: 0.9, end: 1)), child: FadeTransition(opacity: t, child: child)),
    _ => FadeTransition(opacity: t, child: child),
  };
}

/// Flutter's `AnimatedIcons`, by the name a remote file writes.
const Map<String, AnimatedIconData> animatedIcons = <String, AnimatedIconData>{
  'add_event': AnimatedIcons.add_event,
  'arrow_menu': AnimatedIcons.arrow_menu,
  'close_menu': AnimatedIcons.close_menu,
  'ellipsis_search': AnimatedIcons.ellipsis_search,
  'event_add': AnimatedIcons.event_add,
  'home_menu': AnimatedIcons.home_menu,
  'list_view': AnimatedIcons.list_view,
  'menu_arrow': AnimatedIcons.menu_arrow,
  'menu_close': AnimatedIcons.menu_close,
  'menu_home': AnimatedIcons.menu_home,
  'pause_play': AnimatedIcons.pause_play,
  'play_pause': AnimatedIcons.play_pause,
  'search_ellipsis': AnimatedIcons.search_ellipsis,
  'view_list': AnimatedIcons.view_list,
};

/// Widgets that move.
final List<UiWidget> motionWidgets = <UiWidget>[
  UiWidget(
    'Animate',
    group: UiGroup.motion,
    doc: 'Moves its child on a clock: `Animate(effects: [{ effect: .fade, from: 0, to: 1 }], child: ...)`. '
        'The child is built once and only the layer around it moves, so a running animation costs a paint and '
        'no rebuild, however large the subtree is. Effects compose with the first outermost. '
        '`repeat: -1` runs for as long as it is on screen, `reverse` makes each play run back again, and '
        '`playing: data.loading` starts and stops it from data. '
        'A device set to reduce motion gets the end of the animation and no ticker at all.',
    params: <UiParam>[
      p('duration', 'Duration', null, '400ms'),
      p('delay', 'Duration', 'Waited out before the first play.'),
      p('curve', 'Curve', null, 'easeOutCubic'),
      p('repeat', 'int', 'How many times it plays. 0 and 1 play once; -1 repeats until it leaves the screen.', '0'),
      p('reverse', 'bool', 'Each play runs forward and then back again.', 'false'),
      p('playing', 'bool', 'False stops it where it stands; true again carries on from there.', 'true'),
      p('index', 'int', "This row's place in a list, for `stagger`.", '0'),
      p('stagger', 'Duration', 'Added to `delay` once per `index`, so a list comes in one row after another.'),
      p('effects', 'List<Effect>'),
      p('onEnd', 'event', 'After the last play. A repeating animation has no last play.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final Duration duration = a.duration(const <Object>['duration']) ?? const Duration(milliseconds: 400);
      final Duration delay = a.duration(const <Object>['delay']) ?? Duration.zero;
      final Curve curve = a.curve(const <Object>['curve']) ?? Curves.easeOutCubic;
      final int repeat = a.integer(const <Object>['repeat']) ?? 0;
      final bool reverse = a.boolean(const <Object>['reverse']) ?? false;
      final bool playing = a.boolean(const <Object>['playing']) ?? true;
      final int index = a.integer(const <Object>['index']) ?? 0;
      final Duration stagger = a.duration(const <Object>['stagger']) ?? Duration.zero;
      final List<UiEffect> effects = effectsOf(a, const <Object>['effects']);
      final VoidCallback? onEnd = a.onTap(const <Object>['onEnd']);
      // Built once, here, outside the builder: this is the whole point.
      final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();
      if (effects.isEmpty) {
        return child;
      }
      return UiTicker(
        duration: duration,
        delay: delay,
        index: index,
        stagger: stagger,
        repeat: repeat,
        reverse: reverse,
        playing: playing,
        onEnd: onEnd,
        builder: (BuildContext context, Animation<double> t) =>
            applyEffects(effects, curve == Curves.linear ? t : t.drive(CurveTween(curve: curve)), child),
      );
    },
    example: 'Animate(duration: 900, repeat: -1, reverse: true, curve: .easeInOut, '
        'effects: [{ effect: .scale, from: 1, to: 1.15 }], '
        'child: Icon(icon: .favorite, size: 40, color: .primary))',
  ),
  UiWidget(
    'ScrollTransition',
    group: UiGroup.motion,
    doc: 'The same effects as `Animate`, moved by the scroll view it sits in rather than by a clock: '
        '`from` and `to` are scroll offsets in pixels, across which the effects run from start to finish. '
        'A header that shrinks and fades, a parallax image, a bar that fills in. '
        'Outside the range it holds at whichever end it reached, and with no scroll view above it, at the start.',
    params: <UiParam>[
      p('from', 'double', 'The scroll offset the effects start at.', '0'),
      p('to', 'double', 'The scroll offset they finish at.', '200'),
      p('curve', 'Curve', null, 'linear'),
      p('effects', 'List<Effect>'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double from = a.number(const <Object>['from']) ?? 0;
      final double to = a.number(const <Object>['to']) ?? 200;
      final Curve curve = a.curve(const <Object>['curve']) ?? Curves.linear;
      final List<UiEffect> effects = effectsOf(a, const <Object>['effects']);
      // Built once, as Animate's is.
      final Widget child = a.optionalChild(const <Object>['child']) ?? const SizedBox.shrink();
      if (effects.isEmpty) {
        return child;
      }
      return UiScrollDriver(
        from: from,
        to: to,
        builder: (BuildContext context, Animation<double> t) =>
            applyEffects(effects, curve == Curves.linear ? t : t.drive(CurveTween(curve: curve)), child),
      );
    },
    example: 'ListView(children: ['
        'ScrollTransition(from: 0, to: 160, effects: [{ effect: .fade, from: 1, to: 0 }, '
        '{ effect: .slide, from: { x: 0, y: 0 }, to: { x: 0, y: -0.4 } }], '
        'child: SizedBox(height: 160, child: Center(child: Text(text: "Header", style: .headlineMedium)))), '
        'SizedBox(height: 900)])',
  ),
  UiWidget(
    'AnimatedSwitcher',
    group: UiGroup.motion,
    doc: 'Swaps one child for another with a transition between them. Give it a `value`: what the child is '
        'showing. When that changes, the child is a new one and the two cross over. '
        '(A `key` on the child cannot do this: rfw builds a child below the widget that was given it, so the '
        'switcher never sees the key.) '
        'The child on its way out is a live subtree, not a snapshot: it is still bound to the data it reads, so '
        'it shows the new values while it fades. Use this to bring something in and take something out, not to '
        'show two values of one thing at once.',
    params: <UiParam>[
      p('value', 'value', 'What the child is showing -- `data.tab`, `item.id`. A new one means a new child.'),
      p('duration', 'Duration', null, '300ms'),
      p('reverseDuration', 'Duration', 'For the child on its way out.'),
      p('curve', 'Curve', null, 'easeInOut'),
      p('switchOutCurve', 'Curve', 'For the child on its way out.'),
      oneOf('transition', <String>['fade', 'scale', 'rotate', 'slideUp', 'slideDown', 'slideLeft', 'slideRight'], null, 'fade'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final String transition = a.string(const <Object>['transition']) ?? 'fade';
      final Object? value = a.scalar(const <Object>['value']);
      Widget? child = a.optionalChild(const <Object>['child']);
      if (child != null && value != null) {
        child = KeyedSubtree(key: ValueKey<Object>(value), child: child);
      }
      return AnimatedSwitcher(
        duration: a.duration(const <Object>['duration']) ?? const Duration(milliseconds: 300),
        reverseDuration: a.duration(const <Object>['reverseDuration']),
        switchInCurve: a.curve(const <Object>['curve']) ?? Curves.easeInOut,
        switchOutCurve: a.curve(const <Object>['switchOutCurve']) ?? Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> t) => _switchTransition(transition, child, t),
        child: child,
      );
    },
    example: 'AnimatedSwitcher(duration: 300, transition: .scale, value: "a", '
        'child: Icon(icon: .check_circle, size: 40, color: .primary))',
  ),
  UiWidget(
    'AnimatedSize',
    group: UiGroup.motion,
    doc: 'Grows and shrinks to whatever size its child becomes, instead of jumping there. '
        'An expanding card, a panel that opens.',
    params: <UiParam>[
      p('duration', 'Duration', null, '300ms'),
      p('reverseDuration', 'Duration'),
      p('curve', 'Curve', null, 'easeInOut'),
      p('alignment', 'Alignment', null, 'center'),
      e('clipBehavior', Clip.values, null, 'hardEdge'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedSize(
      duration: a.duration(const <Object>['duration']) ?? const Duration(milliseconds: 300),
      reverseDuration: a.duration(const <Object>['reverseDuration']),
      curve: a.curve(const <Object>['curve']) ?? Curves.easeInOut,
      alignment: a.absoluteAlignment(const <Object>['alignment']) ?? Alignment.center,
      clipBehavior: a.enumValue(Clip.values, const <Object>['clipBehavior']) ?? Clip.hardEdge,
      child: a.optionalChild(const <Object>['child']),
    ),
  ),
  UiWidget(
    'AnimatedCrossFade',
    group: UiGroup.motion,
    doc: 'Cross-fades between two children and resizes between their two sizes at the same time. '
        'Both are built, so it is for two things you have, not two screens.',
    params: <UiParam>[
      p('duration', 'Duration', null, '300ms'),
      p('reverseDuration', 'Duration'),
      p('curve', 'Curve', 'For the size.', 'linear'),
      p('firstCurve', 'Curve', null, 'easeOut'),
      p('secondCurve', 'Curve', null, 'easeIn'),
      p('showFirst', 'bool', null, 'true'),
      p('alignment', 'Alignment', null, 'topCenter'),
      p('first', 'Widget'),
      p('second', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedCrossFade(
      duration: a.duration(const <Object>['duration']) ?? const Duration(milliseconds: 300),
      reverseDuration: a.duration(const <Object>['reverseDuration']),
      sizeCurve: a.curve(const <Object>['curve']) ?? Curves.linear,
      firstCurve: a.curve(const <Object>['firstCurve']) ?? Curves.easeOut,
      secondCurve: a.curve(const <Object>['secondCurve']) ?? Curves.easeIn,
      crossFadeState: (a.boolean(const <Object>['showFirst']) ?? true) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      alignment: a.alignment(const <Object>['alignment']) ?? Alignment.topCenter,
      firstChild: a.optionalChild(const <Object>['first']) ?? const SizedBox.shrink(),
      secondChild: a.optionalChild(const <Object>['second']) ?? const SizedBox.shrink(),
    ),
  ),
  UiWidget(
    'Hero',
    group: UiGroup.motion,
    doc: 'Flies its child between two screens that both have a Hero with the same `tag`: the avatar on a list '
        'row becomes the avatar on the page it opens. Without a `tag` it is simply its child.',
    params: <UiParam>[
      p('tag', 'String', 'The same string on both screens.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final String? tag = a.string(const <Object>['tag']);
      final Widget? child = a.optionalChild(const <Object>['child']);
      if (tag == null) {
        return child ?? const SizedBox.shrink();
      }
      return Hero(tag: tag, child: child ?? const SizedBox.shrink());
    },
  ),
  UiWidget(
    'AnimatedIcon',
    group: UiGroup.motion,
    doc: 'One of Flutter\'s two-state icons, drawn anywhere between its two states: `progress: 0` is the first, '
        '`1` the second. Bind `progress` to data, or put it inside an `Animate`. '
        'Names: add_event, arrow_menu, close_menu, ellipsis_search, event_add, home_menu, list_view, menu_arrow, '
        'menu_close, menu_home, pause_play, play_pause, search_ellipsis, view_list.',
    params: <UiParam>[
      oneOf('icon', animatedIcons.keys.toList()),
      p('progress', 'double', 'Between the two states, 0 to 1.', '0'),
      p('size', 'double'),
      p('color', 'Color'),
      p('semanticLabel', 'String'),
    ],
    build: (UiArgs a) {
      final AnimatedIconData? icon = animatedIcons[a.string(const <Object>['icon'])];
      final double progress = a.number(const <Object>['progress']) ?? 0;
      final double? size = a.number(const <Object>['size']);
      final Color? color = a.color(const <Object>['color']);
      final String? semanticLabel = a.string(const <Object>['semanticLabel']);
      if (icon == null) {
        return const SizedBox.shrink();
      }
      return AnimatedIcon(
        icon: icon,
        progress: AlwaysStoppedAnimation<double>(progress.clamp(0, 1)),
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    },
    example: 'AnimatedIcon(icon: .menu_close, progress: 0.5, size: 36, color: .primary)',
  ),
];
