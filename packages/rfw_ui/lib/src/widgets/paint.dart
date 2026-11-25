import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../decode/svg_path.dart';
import 'args.dart';
import 'spec.dart';

/// `CustomPaint`, and the charts drawn the same way.
final List<UiWidget> paintWidgets = <UiWidget>[
  UiWidget(
    'CustomPaint',
    group: UiGroup.paint,
    doc: 'Draws a list of shapes: `shapes: [{ shape: .circle, center: [50, 50], radius: 40, color: .primary }]`. '
        'Coordinates are in pixels from the top left, or in `viewBox` units, scaled to fit as in SVG. '
        'Without `width` and `height` it is its child\'s size, or else as small as its parent allows: inside a '
        'Column that is nothing, so give it a size, a child, or a parent that sizes it (SizedBox, Expanded).',
    params: <UiParam>[
      p('width', 'double'),
      p('height', 'double'),
      p('viewBox', 'List<double>', '`[x, y, width, height]`: the coordinates the shapes are written in, scaled to fit the painted size.'),
      p('shapes', 'List<Shape>'),
      p('child', 'Widget', 'Painted over; when given, it decides the size.'),
    ],
    build: (UiArgs a) => CustomPaint(
      size: Size(a.number(<Object>['width']) ?? 0, a.number(<Object>['height']) ?? 0),
      painter: UiShapePainter(shapes(a, <Object>['shapes']), viewBox: _viewBox(a, <Object>['viewBox'])),
      child: a.optionalChild(<Object>['child']),
    ),
    example: 'CustomPaint(width: 120, height: 120, viewBox: [0, 0, 100, 100], shapes: ['
        '{ shape: .circle, center: [50, 50], radius: 45, color: .surfaceContainerHighest }, '
        '{ shape: .arc, center: [50, 50], radius: 45, start: -90, sweep: 250, stroke: 8, cap: .round, color: .primary }, '
        '{ shape: .path, d: "M30 52 L45 66 L72 36", stroke: 6, cap: .round, join: .round, color: .primary }])',
  ),
  UiWidget(
    'LineChart',
    group: UiGroup.paint,
    doc: 'A line through `points`, first to last across the width, the lowest at the bottom. '
        'Give it a width inside a Row.',
    params: <UiParam>[
      p('points', 'List<double>'),
      p('color', 'Color', null, 'primary'),
      p('strokeWidth', 'double', null, '2'),
      p('fill', 'Color', 'Shades the area under the line.'),
      p('smooth', 'bool', 'A curve through every point instead of straight segments.', 'false'),
      p('min', 'double', 'The value at the bottom.', 'the lowest point'),
      p('max', 'double', 'The value at the top.', 'the highest point'),
      p('height', 'double', null, '160'),
    ],
    build: (UiArgs a) => _sized(
      a,
      UiLineChartPainter(
        points: _numbers(a, <Object>['points']),
        color: a.color(<Object>['color']) ?? a.resolve.colorScheme.primary,
        strokeWidth: a.number(<Object>['strokeWidth']) ?? 2,
        fill: a.color(<Object>['fill']),
        smooth: a.boolean(<Object>['smooth']) ?? false,
        min: a.number(<Object>['min']),
        max: a.number(<Object>['max']),
      ),
    ),
    example: 'LineChart(points: [3, 5, 4, 8, 6, 9], fill: "primary/15", smooth: true, height: 80)',
  ),
  UiWidget(
    'BarChart',
    group: UiGroup.paint,
    doc: 'A bar for each of `values`, standing on zero; negative values hang below it.',
    params: <UiParam>[
      p('values', 'List<double>'),
      p('color', 'Color', null, 'primary'),
      p('gap', 'double', 'Space between bars.', '4'),
      p('barRadius', 'double', null, '0'),
      p('min', 'double', null, 'zero, or the lowest value'),
      p('max', 'double', null, 'zero, or the highest value'),
      p('height', 'double', null, '160'),
    ],
    build: (UiArgs a) => _sized(
      a,
      UiBarChartPainter(
        values: _numbers(a, <Object>['values']),
        color: a.color(<Object>['color']) ?? a.resolve.colorScheme.primary,
        gap: a.number(<Object>['gap']) ?? 4,
        radius: a.number(<Object>['barRadius']) ?? 0,
        min: a.number(<Object>['min']),
        max: a.number(<Object>['max']),
      ),
    ),
    example: 'BarChart(values: [4, 7, 3, 9, 5], barRadius: 4, height: 80)',
  ),
  UiWidget(
    'PieChart',
    group: UiGroup.paint,
    doc: 'A slice for each of `values`, clockwise from twelve o\'clock. `hole` makes it a ring.',
    params: <UiParam>[
      p('values', 'List<double>'),
      p('colors', 'List<Color>', 'Repeated when there are more values than colours.', 'the scheme\'s primary, secondary and tertiary roles'),
      p('hole', 'double', 'From 0, a pie, to under 1, a thin ring.', '0'),
      p('gap', 'double', 'Degrees between slices.', '0'),
      p('size', 'double', null, '160'),
    ],
    build: (UiArgs a) {
      final ColorScheme scheme = a.resolve.colorScheme;
      final double size = a.number(<Object>['size']) ?? 160;
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: UiPieChartPainter(
            values: _numbers(a, <Object>['values']),
            colors: a.list<Color>(<Object>['colors'], a.color) ??
                <Color>[scheme.primary, scheme.secondary, scheme.tertiary, scheme.primaryContainer, scheme.secondaryContainer, scheme.tertiaryContainer],
            hole: (a.number(<Object>['hole']) ?? 0).clamp(0, 0.95),
            gap: a.number(<Object>['gap']) ?? 0,
          ),
        ),
      );
    },
    example: 'PieChart(values: [3, 2, 1], hole: 0.6, gap: 2, size: 96)',
  ),
];

/// A chart as wide as it may be and `height` tall.
Widget _sized(UiArgs a, CustomPainter painter) => SizedBox(
  width: double.infinity,
  height: a.number(<Object>['height']) ?? 160,
  child: CustomPaint(painter: painter),
);

List<double> _numbers(UiArgs a, List<Object> key) => a.list<double>(key, a.number) ?? const <double>[];

Offset? _point(UiArgs a, List<Object> key) {
  final double? x = a.number(<Object>[...key, 0]);
  final double? y = a.number(<Object>[...key, 1]);
  return x == null || y == null ? null : Offset(x, y);
}

Rect? _rect(UiArgs a, List<Object> key) {
  final List<double> v = _numbers(a, key);
  return v.length == 4 ? Rect.fromLTWH(v[0], v[1], v[2], v[3]) : null;
}

Rect? _viewBox(UiArgs a, List<Object> key) {
  final Rect? box = _rect(a, key);
  return box == null || box.isEmpty ? null : box;
}

/// The `shapes` of a `CustomPaint`, decoded. A shape that is not one of the
/// six, or lacks what it needs, is left out.
List<UiShape> shapes(UiArgs a, List<Object> key) {
  final Color color = a.resolve.colorScheme.onSurface;
  return a.list<UiShape>(key, (List<Object> k) {
    List<Object> at(String name) => <Object>[...k, name];
    final UiInk ink = UiInk(
      color: a.color(at('color')) ?? color,
      gradient: a.gradient(at('gradient')),
      stroke: a.number(at('stroke')),
      cap: a.enumValue(StrokeCap.values, at('cap')),
      join: a.enumValue(StrokeJoin.values, at('join')),
    );
    switch (a.string(at('shape'))) {
      case 'rect':
        final Rect? rect = _rect(a, at('rect'));
        return rect == null ? null : UiRectShape(ink, rect, a.number(at('radius')) ?? 0);
      case 'circle':
        final Offset? center = _point(a, at('center'));
        final double? radius = a.number(at('radius'));
        return center == null || radius == null ? null : UiCircleShape(ink, center, radius);
      case 'line':
        final Offset? from = _point(a, at('from'));
        final Offset? to = _point(a, at('to'));
        return from == null || to == null ? null : UiLineShape(ink, from, to);
      case 'arc':
        final Offset? center = _point(a, at('center'));
        final double? radius = a.number(at('radius'));
        final double? sweep = a.number(at('sweep'));
        return center == null || radius == null || sweep == null
            ? null
            : UiArcShape(ink, center, radius, a.number(at('start')) ?? 0, sweep);
      case 'path':
        final String? d = a.string(at('d'));
        final Path? path = d == null ? null : parseSvgPath(d);
        return path == null ? null : UiPathShape(ink, d!, path);
      case 'text':
        final String? text = a.string(at('text'));
        final Offset? origin = _point(a, at('at'));
        if (text == null || origin == null) {
          return null;
        }
        // The shape's own colour, else the one its style names, else the
        // theme's: the default ink does not override a style's colour.
        final TextStyle? written = a.textStyle(at('style'));
        final TextStyle style = DefaultTextStyle.of(a.context).style.merge(written);
        return UiTextShape(
          ink,
          text,
          origin,
          style.copyWith(color: a.color(at('color')) ?? written?.color ?? color),
          Directionality.of(a.context),
        );
    }
    return null;
  }) ?? const <UiShape>[];
}

/// How a shape is painted: a colour or a gradient, filled, or stroked when
/// it has a stroke width.
@immutable
class UiInk {
  const UiInk({required this.color, this.gradient, this.stroke, this.cap, this.join});

  final Color color;
  final Gradient? gradient;
  final double? stroke;
  final StrokeCap? cap;
  final StrokeJoin? join;

  Paint paint(Rect bounds) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(bounds);
    }
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke!;
    }
    if (cap != null) {
      paint.strokeCap = cap!;
    }
    if (join != null) {
      paint.strokeJoin = join!;
    }
    return paint;
  }

  @override
  bool operator ==(Object other) =>
      other is UiInk && other.color == color && other.gradient == gradient && other.stroke == stroke && other.cap == cap && other.join == join;

  @override
  int get hashCode => Object.hash(color, gradient, stroke, cap, join);
}

/// One shape of a `CustomPaint`. Equal by value, so a rebuild that changes
/// nothing repaints nothing.
@immutable
sealed class UiShape {
  const UiShape(this.ink);

  final UiInk ink;

  void draw(Canvas canvas);

  List<Object?> get _props;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && other is UiShape && other.ink == ink && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hash(runtimeType, ink, Object.hashAll(_props));
}

class UiRectShape extends UiShape {
  const UiRectShape(super.ink, this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  void draw(Canvas canvas) {
    final Paint paint = ink.paint(rect);
    if (radius > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  List<Object?> get _props => <Object?>[rect, radius];
}

class UiCircleShape extends UiShape {
  const UiCircleShape(super.ink, this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  void draw(Canvas canvas) => canvas.drawCircle(center, radius, ink.paint(Rect.fromCircle(center: center, radius: radius)));

  @override
  List<Object?> get _props => <Object?>[center, radius];
}

class UiLineShape extends UiShape {
  const UiLineShape(super.ink, this.from, this.to);

  final Offset from;
  final Offset to;

  @override
  void draw(Canvas canvas) {
    final Paint paint = ink.paint(Rect.fromPoints(from, to));
    // A line has no inside to fill: without a stroke width it is a hairline
    // a pixel wide.
    paint.strokeWidth = ink.stroke ?? 1;
    canvas.drawLine(from, to, paint);
  }

  @override
  List<Object?> get _props => <Object?>[from, to];
}

class UiArcShape extends UiShape {
  const UiArcShape(super.ink, this.center, this.radius, this.start, this.sweep);

  final Offset center;
  final double radius;

  /// Degrees, clockwise from three o'clock.
  final double start;
  final double sweep;

  @override
  void draw(Canvas canvas) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    // Filled, an arc is a slice of pie; stroked, a curve.
    canvas.drawArc(rect, start * math.pi / 180, sweep * math.pi / 180, ink.stroke == null, ink.paint(rect));
  }

  @override
  List<Object?> get _props => <Object?>[center, radius, start, sweep];
}

class UiPathShape extends UiShape {
  const UiPathShape(super.ink, this.d, this.path);

  /// What the path was read from, which is what makes two paths the same.
  final String d;
  final Path path;

  @override
  void draw(Canvas canvas) => canvas.drawPath(path, ink.paint(path.getBounds()));

  @override
  List<Object?> get _props => <Object?>[d];
}

class UiTextShape extends UiShape {
  const UiTextShape(super.ink, this.text, this.origin, this.style, this.direction);

  final String text;
  final Offset origin;
  final TextStyle style;
  final TextDirection direction;

  @override
  void draw(Canvas canvas) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
    )..layout();
    painter.paint(canvas, origin);
    painter.dispose();
  }

  @override
  List<Object?> get _props => <Object?>[text, origin, style, direction];
}

/// Paints [shapes] in order, scaled from [viewBox] when there is one.
class UiShapePainter extends CustomPainter {
  const UiShapePainter(this.shapes, {this.viewBox});

  final List<UiShape> shapes;
  final Rect? viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? box = viewBox;
    if (box != null) {
      // Scaled to fit and centred, as SVG's default preserveAspectRatio does.
      final double scale = math.min(size.width / box.width, size.height / box.height);
      canvas.save();
      final Offset shift = Offset(
        (size.width - box.width * scale) / 2 - box.left * scale,
        (size.height - box.height * scale) / 2 - box.top * scale,
      );
      if (shift != Offset.zero) {
        canvas.translate(shift.dx, shift.dy);
      }
      canvas.scale(scale, scale);
    }
    for (final UiShape shape in shapes) {
      shape.draw(canvas);
    }
    if (box != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(UiShapePainter old) => old.viewBox != viewBox || !listEquals(old.shapes, shapes);
}

/// Where [value] sits between [low] (the bottom, [height]) and [high] (the
/// top, 0); the middle when they are equal.
double _y(double value, double low, double high, double height) =>
    high == low ? height / 2 : height - (value - low) / (high - low) * height;

class UiLineChartPainter extends CustomPainter {
  const UiLineChartPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.fill,
    this.smooth = false,
    this.min,
    this.max,
  });

  final List<double> points;
  final Color color;
  final double strokeWidth;
  final Color? fill;
  final bool smooth;
  final double? min;
  final double? max;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final double low = min ?? points.reduce(math.min);
    final double high = max ?? points.reduce(math.max);
    final List<Offset> at = <Offset>[
      for (int i = 0; i < points.length; i += 1)
        Offset(
          points.length == 1 ? size.width / 2 : i * size.width / (points.length - 1),
          _y(points[i], low, high, size.height),
        ),
    ];
    final Path line = Path()..moveTo(at.first.dx, at.first.dy);
    for (int i = 1; i < at.length; i += 1) {
      if (smooth) {
        // Catmull-Rom through each point, as cubic Béziers.
        final Offset p0 = at[math.max(i - 2, 0)];
        final Offset p1 = at[i - 1];
        final Offset p2 = at[i];
        final Offset p3 = at[math.min(i + 1, at.length - 1)];
        final Offset c1 = p1 + (p2 - p0) / 6;
        final Offset c2 = p2 - (p3 - p1) / 6;
        line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      } else {
        line.lineTo(at[i].dx, at[i].dy);
      }
    }
    if (fill != null) {
      final Path area = Path.from(line)
        ..lineTo(at.last.dx, size.height)
        ..lineTo(at.first.dx, size.height)
        ..close();
      canvas.drawPath(area, Paint()..color = fill!);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(UiLineChartPainter old) =>
      !listEquals(old.points, points) ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.fill != fill ||
      old.smooth != smooth ||
      old.min != min ||
      old.max != max;
}

class UiBarChartPainter extends CustomPainter {
  const UiBarChartPainter({required this.values, required this.color, required this.gap, required this.radius, this.min, this.max});

  final List<double> values;
  final Color color;
  final double gap;
  final double radius;
  final double? min;
  final double? max;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final double low = min ?? math.min(0, values.reduce(math.min));
    final double high = max ?? math.max(0, values.reduce(math.max));
    final double slot = size.width / values.length;
    final double zero = _y(0.clamp(low, high).toDouble(), low, high, size.height);
    final Paint paint = Paint()..color = color;
    for (int i = 0; i < values.length; i += 1) {
      final double y = _y(values[i], low, high, size.height);
      final Rect bar = Rect.fromLTRB(i * slot + gap / 2, math.min(y, zero), (i + 1) * slot - gap / 2, math.max(y, zero));
      if (radius > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(radius)), paint);
      } else {
        canvas.drawRect(bar, paint);
      }
    }
  }

  @override
  bool shouldRepaint(UiBarChartPainter old) =>
      !listEquals(old.values, values) || old.color != color || old.gap != gap || old.radius != radius || old.min != min || old.max != max;
}

class UiPieChartPainter extends CustomPainter {
  const UiPieChartPainter({required this.values, required this.colors, required this.hole, required this.gap});

  final List<double> values;
  final List<Color> colors;

  /// The hole's share of the radius: 0 is a pie.
  final double hole;

  /// Degrees between slices.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (double sum, double v) => sum + math.max(v, 0));
    if (total <= 0 || colors.isEmpty) {
      return;
    }
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2;
    final double thickness = radius * (1 - hole);
    final double gapAngle = values.length > 1 ? gap * math.pi / 180 : 0;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i += 1) {
      final double sweep = math.max(values[i], 0) / total * 2 * math.pi;
      final Paint paint = Paint()..color = colors[i % colors.length];
      final double drawn = math.max(sweep - gapAngle, 0);
      if (hole > 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius - thickness / 2), start + gapAngle / 2, drawn, false, paint);
      } else {
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start + gapAngle / 2, drawn, true, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(UiPieChartPainter old) =>
      !listEquals(old.values, values) || !listEquals(old.colors, colors) || old.hole != hole || old.gap != gap;
}
