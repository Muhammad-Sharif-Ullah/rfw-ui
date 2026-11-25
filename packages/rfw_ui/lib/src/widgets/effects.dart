import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../decode/svg_path.dart';
import 'args.dart';
import 'spec.dart';

/// Compositing effects: blur, masks, filters and clips.
///
/// Each of these makes the compositor do work the rest of the kit does not,
/// and `BackdropFilter` makes a great deal of it. Each widget here is shaped
/// so that the cheap way to write it is also the right one: a blur of nothing
/// is switched off rather than drawn, a `borderRadius` puts the clip that
/// bounds a backdrop filter's cost inside the widget, and a mask or filter
/// with nothing to do is simply its child.

/// Scaled to fit and centred in [size], as SVG's default
/// `preserveAspectRatio` does -- the same transform `UiShapePainter` uses.
@immutable
class UiPathClipper extends CustomClipper<Path> {
  const UiPathClipper(this.d, this.path, this.viewBox);

  /// The path data, kept so that [shouldReclip] can compare without walking
  /// the parsed path.
  final String d;
  final Path path;
  final Rect? viewBox;

  @override
  Path getClip(Size size) {
    final Rect? box = viewBox;
    if (box == null || box.isEmpty) {
      return path;
    }
    final double scale = math.min(size.width / box.width, size.height / box.height);
    final Matrix4 matrix = Matrix4.identity()
      ..translateByDouble(
        (size.width - box.width * scale) / 2 - box.left * scale,
        (size.height - box.height * scale) / 2 - box.top * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    return path.transform(matrix.storage);
  }

  @override
  bool shouldReclip(UiPathClipper old) => old.d != d || old.viewBox != viewBox;
}

/// `[x, y, width, height]`.
Rect? _viewBox(UiArgs a, List<Object> key) {
  final List<double>? values = a.list<double>(key, a.number);
  return values != null && values.length == 4 ? Rect.fromLTWH(values[0], values[1], values[2], values[3]) : null;
}

/// The colour matrix for a saturation of [s]: 1 leaves the child alone, 0
/// greys it, and above 1 pushes it further. The weights are the luminance
/// ones every implementation uses.
ColorFilter _saturation(double s) {
  const double lr = 0.2126;
  const double lg = 0.7152;
  const double lb = 0.0722;
  return ColorFilter.matrix(<double>[
    lr + (1 - lr) * s, lg - lg * s, lb - lb * s, 0, 0, //
    lr - lr * s, lg + (1 - lg) * s, lb - lb * s, 0, 0, //
    lr - lr * s, lg - lg * s, lb + (1 - lb) * s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

final List<UiWidget> effectWidgets = <UiWidget>[
  UiWidget(
    'BackdropFilter',
    group: UiGroup.effect,
    doc: 'Blurs whatever is painted behind it -- frosted glass. '
        'In Flutter it blurs its whole layer, which without a clip is the screen; this one clips to its own '
        'bounds, so a 48-pixel bar blurs a 48-pixel bar. `borderRadius` makes that clip a rounded one, and '
        '`clip: false` gives Flutter\'s own behaviour back. The clip is also what bounds the cost: this is the '
        'most expensive widget in Flutter. '
        'A `child` is painted over the blur, so a glass panel is this with a translucent Container '
        'inside it. Several of them over one background should sit in a `BackdropGroup` with `grouped: true`, '
        'which reads the background once for all of them instead of once each.',
    params: <UiParam>[
      p('blur', 'double', 'The blur radius on both axes.', '0'),
      p('blurX', 'double', 'Overrides `blur` across.'),
      p('blurY', 'double', 'Overrides `blur` down.'),
      e('tileMode', TileMode.values, 'What is sampled past the edge.', 'clamp'),
      p('borderRadius', 'BorderRadius', 'Makes the clip a rounded rectangle.'),
      p('clip', 'bool', 'Clips the blur to this widget. False blurs the whole layer, as Flutter does.', 'true'),
      e('blendMode', BlendMode.values, 'How the blurred backdrop meets what is under it.', 'srcOver'),
      p('grouped', 'bool', 'Share one read of the backdrop with the other filters in the enclosing BackdropGroup.', 'false'),
      p('child', 'Widget', 'Painted over the blur.'),
    ],
    build: (UiArgs a) {
      final double blur = a.number(const <Object>['blur']) ?? 0;
      final double x = a.number(const <Object>['blurX']) ?? blur;
      final double y = a.number(const <Object>['blurY']) ?? blur;
      final TileMode tileMode = a.enumValue(TileMode.values, const <Object>['tileMode']) ?? TileMode.clamp;
      final BorderRadiusGeometry? borderRadius = a.borderRadius(const <Object>['borderRadius']);
      final bool clip = a.boolean(const <Object>['clip']) ?? true;
      final BlendMode blendMode = a.enumValue(BlendMode.values, const <Object>['blendMode']) ?? BlendMode.srcOver;
      final bool grouped = a.boolean(const <Object>['grouped']) ?? false;
      final Widget? child = a.optionalChild(const <Object>['child']);
      // A zero-sigma filter still costs a saveLayer; Flutter asks for the
      // switch instead, and the widget stays in the tree either way.
      final bool enabled = x > 0 || y > 0;
      final ui.ImageFilter filter = ui.ImageFilter.blur(
        sigmaX: math.max(x, 0.01),
        sigmaY: math.max(y, 0.01),
        tileMode: tileMode,
      );
      final Widget filtered = grouped
          ? BackdropFilter.grouped(filter: filter, blendMode: blendMode, enabled: enabled, child: child)
          : BackdropFilter(filter: filter, blendMode: blendMode, enabled: enabled, child: child);
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius, child: filtered);
      }
      return clip ? ClipRect(child: filtered) : filtered;
    },
    example: 'Stack(children: ['
        'Container(width: 220, height: 140, decoration: { gradient: { type: .linear, colors: [.primary, .tertiary] } }), '
        'Positioned(left: 20, top: 40, width: 180, height: 60, child: BackdropFilter(blur: 14, borderRadius: .lg, '
        'child: Container(decoration: { color: "surface/40", borderRadius: .lg }, '
        'child: Center(child: Text(text: "Frosted")))))])',
  ),
  UiWidget(
    'BackdropGroup',
    group: UiGroup.effect,
    doc: 'Reads the background once for every `BackdropFilter(grouped: true)` under it, rather than once each. '
        'A screen with a blurred bar and a blurred card over one image should have this around both.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => BackdropGroup(child: a.child(const <Object>['child'])),
  ),
  UiWidget(
    'ImageFiltered',
    group: UiGroup.effect,
    doc: 'Blurs the child itself, rather than what is behind it: glows, soft shadows, an out-of-focus photograph.',
    params: <UiParam>[
      p('blur', 'double', 'The blur radius on both axes.', '0'),
      p('blurX', 'double', 'Overrides `blur` across.'),
      p('blurY', 'double', 'Overrides `blur` down.'),
      e('tileMode', TileMode.values, null, 'decal'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final double blur = a.number(const <Object>['blur']) ?? 0;
      final double x = a.number(const <Object>['blurX']) ?? blur;
      final double y = a.number(const <Object>['blurY']) ?? blur;
      final TileMode tileMode = a.enumValue(TileMode.values, const <Object>['tileMode']) ?? TileMode.decal;
      final Widget? child = a.optionalChild(const <Object>['child']);
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: math.max(x, 0.01), sigmaY: math.max(y, 0.01), tileMode: tileMode),
        enabled: x > 0 || y > 0,
        child: child,
      );
    },
    example: 'Stack(alignment: .center, children: ['
        'ImageFiltered(blur: 18, child: Icon(icon: .star, size: 72, color: .primary)), '
        'Icon(icon: .star, size: 72, color: .primary)])',
  ),
  UiWidget(
    'RepaintBoundary',
    group: UiGroup.effect,
    doc: 'Gives its child a layer of its own, so repainting it does not repaint what is beside it. '
        'Worth one around an animation that sits next to something expensive and still. '
        'Not worth one in every row of a long list: each is a layer, and layers cost memory. '
        'The kit never adds one for you, as Flutter\'s own transitions do not.',
    params: <UiParam>[p('child', 'Widget')],
    build: (UiArgs a) => RepaintBoundary(child: a.optionalChild(const <Object>['child'])),
  ),
  UiWidget(
    'ShaderMask',
    group: UiGroup.effect,
    doc: 'Paints its child through a gradient: `blendMode: .srcIn` colours text with the gradient, '
        '`.dstIn` uses the gradient as transparency, which is how a list fades out at its edges. '
        'Without a `gradient` it is simply its child.',
    params: <UiParam>[
      p('gradient', 'Gradient'),
      e('blendMode', BlendMode.values, null, 'srcIn'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final Gradient? gradient = a.gradient(const <Object>['gradient']);
      final BlendMode blendMode = a.enumValue(BlendMode.values, const <Object>['blendMode']) ?? BlendMode.srcIn;
      final Widget? child = a.optionalChild(const <Object>['child']);
      if (gradient == null) {
        return child ?? const SizedBox.shrink();
      }
      return ShaderMask(
        shaderCallback: gradient.createShader,
        blendMode: blendMode,
        child: child,
      );
    },
    example: 'ShaderMask(gradient: { type: .linear, colors: [.primary, .tertiary] }, '
        'child: Text(text: "Gradient", style: { base: .headlineLarge, color: "white" }))',
  ),
  UiWidget(
    'ColorFiltered',
    group: UiGroup.effect,
    doc: 'Recolours its child. `saturation: 0` is the grey a disabled or spent thing wants, without a second '
        'asset; `color` with a `blendMode` tints it. With neither it is simply its child.',
    params: <UiParam>[
      p('color', 'Color'),
      e('blendMode', BlendMode.values, null, 'srcATop'),
      p('saturation', 'double', '1 leaves it alone, 0 greys it, above 1 pushes it. Wins over `color`.'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final Color? color = a.color(const <Object>['color']);
      final BlendMode blendMode = a.enumValue(BlendMode.values, const <Object>['blendMode']) ?? BlendMode.srcATop;
      final double? saturation = a.number(const <Object>['saturation']);
      final Widget? child = a.optionalChild(const <Object>['child']);
      if (saturation != null) {
        return ColorFiltered(colorFilter: _saturation(saturation), child: child);
      }
      if (color == null) {
        return child ?? const SizedBox.shrink();
      }
      return ColorFiltered(colorFilter: ColorFilter.mode(color, blendMode), child: child);
    },
    example: 'Row(spacing: "md", children: ['
        'Icon(icon: .photo, size: 48, color: .primary), '
        'ColorFiltered(saturation: 0, child: Icon(icon: .photo, size: 48, color: .primary))])',
  ),
  UiWidget(
    'ClipPath',
    group: UiGroup.effect,
    doc: 'Clips its child to a shape: a `shape` (`.stadium`, `.circle`, a map), or `path`, SVG path data in a '
        '`viewBox` scaled to fit as `CustomPaint` scales its shapes. With neither it is simply its child.',
    params: <UiParam>[
      p('shape', 'ShapeBorder'),
      p('path', 'String', 'SVG path data: M L H V C S Q T Z. Not arcs.'),
      p('viewBox', 'List<double>', '`[x, y, width, height]`: the coordinates `path` is written in.'),
      e('clipBehavior', Clip.values, null, 'antiAlias'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) {
      final ShapeBorder? shape = a.shape(const <Object>['shape']);
      final String? d = a.string(const <Object>['path']);
      final Rect? viewBox = _viewBox(a, const <Object>['viewBox']);
      final Clip clipBehavior = a.enumValue(Clip.values, const <Object>['clipBehavior']) ?? Clip.antiAlias;
      final Widget? child = a.optionalChild(const <Object>['child']);
      if (shape != null) {
        return ClipPath(clipper: ShapeBorderClipper(shape: shape), clipBehavior: clipBehavior, child: child);
      }
      final Path? path = d == null ? null : parseSvgPath(d);
      if (path == null) {
        return child ?? const SizedBox.shrink();
      }
      return ClipPath(clipper: UiPathClipper(d!, path, viewBox), clipBehavior: clipBehavior, child: child);
    },
    example: 'ClipPath(path: "M50 0 L100 100 L0 100 Z", viewBox: [0, 0, 100, 100], '
        'child: Container(width: 120, height: 120, decoration: { color: .primaryContainer }))',
  ),
];
