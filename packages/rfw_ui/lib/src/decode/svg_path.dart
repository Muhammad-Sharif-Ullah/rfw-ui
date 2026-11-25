import 'dart:ui';

final RegExp _token = RegExp(r'([MmLlHhVvCcSsQqTtZzAa])|([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)|([\s,]+)|(.)');

/// A [Path] from SVG path data, the `d` of an SVG `<path>`: moves, lines,
/// cubic and quadratic curves with their smooth forms (`S`, `T`), and closes,
/// absolute and relative.
///
/// Null for anything else, so a shape that cannot be drawn as written is not
/// drawn at all rather than drawn wrong: arcs (`A`), a stray character, a
/// command short of numbers, or data that does not start with a move.
Path? parseSvgPath(String d) {
  final List<Object> tokens = <Object>[];
  for (final RegExpMatch m in _token.allMatches(d)) {
    if (m[1] != null) {
      tokens.add(m[1]!);
    } else if (m[2] != null) {
      tokens.add(double.parse(m[2]!));
    } else if (m[4] != null) {
      return null;
    }
  }
  if (tokens.isEmpty || (tokens.first != 'M' && tokens.first != 'm')) {
    return null;
  }

  final Path path = Path();
  Offset current = Offset.zero;
  Offset start = Offset.zero;
  // The second control point of the last cubic, and the control point of the
  // last quadratic, which S and T reflect. Null after any other command.
  Offset? cubic;
  Offset? quad;
  String? command;
  int i = 0;

  double? number() => i < tokens.length && tokens[i] is double ? tokens[i++] as double : null;

  while (i < tokens.length) {
    if (tokens[i] is String) {
      command = tokens[i] as String;
      i += 1;
    } else if (command == null) {
      return null;
    }
    final String c = command;
    final bool relative = c == c.toLowerCase();
    Offset? point() {
      final double? x = number();
      final double? y = number();
      if (x == null || y == null) {
        return null;
      }
      return relative ? current + Offset(x, y) : Offset(x, y);
    }

    switch (c.toUpperCase()) {
      case 'M':
        final Offset? p = point();
        if (p == null) {
          return null;
        }
        path.moveTo(p.dx, p.dy);
        current = start = p;
        // Pairs after a move's first are lines.
        command = relative ? 'l' : 'L';
        cubic = quad = null;
      case 'L':
        final Offset? p = point();
        if (p == null) {
          return null;
        }
        path.lineTo(p.dx, p.dy);
        current = p;
        cubic = quad = null;
      case 'H':
        final double? x = number();
        if (x == null) {
          return null;
        }
        current = Offset(relative ? current.dx + x : x, current.dy);
        path.lineTo(current.dx, current.dy);
        cubic = quad = null;
      case 'V':
        final double? y = number();
        if (y == null) {
          return null;
        }
        current = Offset(current.dx, relative ? current.dy + y : y);
        path.lineTo(current.dx, current.dy);
        cubic = quad = null;
      case 'C':
        final Offset? c1 = point();
        final Offset? c2 = point();
        final Offset? p = point();
        if (c1 == null || c2 == null || p == null) {
          return null;
        }
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
        current = p;
        cubic = c2;
        quad = null;
      case 'S':
        final Offset c1 = cubic == null ? current : current * 2 - cubic;
        final Offset? c2 = point();
        final Offset? p = point();
        if (c2 == null || p == null) {
          return null;
        }
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
        current = p;
        cubic = c2;
        quad = null;
      case 'Q':
        final Offset? q = point();
        final Offset? p = point();
        if (q == null || p == null) {
          return null;
        }
        path.quadraticBezierTo(q.dx, q.dy, p.dx, p.dy);
        current = p;
        quad = q;
        cubic = null;
      case 'T':
        final Offset q = quad == null ? current : current * 2 - quad;
        final Offset? p = point();
        if (p == null) {
          return null;
        }
        path.quadraticBezierTo(q.dx, q.dy, p.dx, p.dy);
        current = p;
        quad = q;
        cubic = null;
      case 'Z':
        path.close();
        current = start;
        // Numbers straight after a close belong to no command.
        command = null;
        cubic = quad = null;
      default:
        return null;
    }
  }
  return path;
}
