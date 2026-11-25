import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import 'icons.g.dart';
import 'resolver.dart';

/// What a [DataSource] can say besides what rfw's can: which keys the map at a
/// path was written with. A decoder of a map with many optional keys -- a
/// text style, a decoration, a button style -- then asks after those alone,
/// where otherwise it asks after every key it knows. UiRuntime's sources and
/// [MapSource] can; rfw's cannot.
abstract interface class UiKeysSource {
  /// The keys of the map at [key]; null when there is no map there.
  Iterable<String>? keysAt(List<Object> key);
}

/// Turns remote data into Flutter values, resolving theme tokens on the way.
///
/// The same idea as rfw's `ArgumentDecoders`, and wherever rfw already has a
/// format this accepts it too, so a file written for rfw's own widgets reads
/// the same here. What it adds is the theme: a colour may be `"primary"`, a
/// text style may be `"titleLarge"` or `{ base: "titleLarge", ... }`, a gap
/// may be `"md"`. And a number is a number: rfw reads `16` as nothing wherever
/// it wants a double, because the text format parses it as an int.
///
/// Every method takes a key path into [source] and returns null when the value
/// there is missing or is not something it can read, so the caller's default
/// is always the one that applies -- never black, never zero.
class UiDecoder {
  const UiDecoder(this.source, this.resolve);

  final DataSource source;
  final UiResolver resolve;

  /// Which keys the map at [key] was written with, when [source] can say;
  /// null when it cannot, and every key is to be asked after.
  Iterable<String>? writtenKeys(List<Object> key) {
    final Object s = source;
    return s is UiKeysSource ? s.keysAt(key) : null;
  }

  // ------------------------------------------------------------ primitives

  String? string(List<Object> key) => source.v<String>(key);

  bool? boolean(List<Object> key) => source.v<bool>(key);

  int? integer(List<Object> key) => source.v<int>(key) ?? source.v<double>(key)?.round();

  double? number(List<Object> key) => source.v<double>(key) ?? source.v<int>(key)?.toDouble();

  /// A number, or a spacing token (`"md"`).
  double? spacing(List<Object> key) {
    final double? value = number(key);
    if (value != null) {
      return value;
    }
    final String? token = string(key);
    return token == null ? null : resolve.spacing(token);
  }

  /// A number, or a radius token (`"lg"`).
  double? radiusValue(List<Object> key) {
    final double? value = number(key);
    if (value != null) {
      return value;
    }
    final String? token = string(key);
    return token == null ? null : resolve.radius(token);
  }

  /// An enum by its name: `"spaceBetween"`.
  T? enumValue<T extends Enum>(List<T> values, List<Object> key) {
    final String? name = string(key);
    if (name == null) {
      return null;
    }
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  /// A string, number or bool -- the values a radio, a dropdown or a segment
  /// can stand for.
  Object? scalar(List<Object> key) =>
      source.v<String>(key) ?? source.v<int>(key) ?? source.v<double>(key) ?? source.v<bool>(key);

  /// Whether anything at all is at [key].
  bool has(List<Object> key) =>
      source.isMap(key) ||
      source.isList(key) ||
      source.v<String>(key) != null ||
      source.v<int>(key) != null ||
      source.v<double>(key) != null ||
      source.v<bool>(key) != null;

  /// Each element of the list at [key], decoded; null when it is not a list.
  List<T>? list<T>(List<Object> key, T? Function(List<Object> key) decode) {
    if (!source.isList(key)) {
      return null;
    }
    final int length = source.length(key);
    final List<T> out = <T>[];
    for (int index = 0; index < length; index += 1) {
      final T? value = decode(<Object>[...key, index]);
      if (value != null) {
        out.add(value);
      }
    }
    return out;
  }

  List<String>? strings(List<Object> key) => list<String>(key, string);

  Duration? duration(List<Object> key) {
    final double? ms = number(key);
    return ms == null ? null : Duration(microseconds: (ms * 1000).round());
  }

  Curve? curve(List<Object> key) => _curves[string(key)];

  /// A curve by name: `"easeInOut"`.
  static Curve? curveNamed(String? name) => _curves[name];

  // ---------------------------------------------------------------- colours

  /// An ARGB int, or a token: see [UiResolver.color].
  Color? color(List<Object> key) {
    final int? value = source.v<int>(key);
    if (value != null) {
      return Color(value);
    }
    final String? token = string(key);
    return token == null ? null : resolve.color(token);
  }

  // ------------------------------------------------------------------- text

  FontWeight? fontWeight(List<Object> key) {
    final int? numeric = integer(key);
    if (numeric != null) {
      final int index = numeric ~/ 100 - 1;
      return numeric % 100 == 0 && index >= 0 && index < FontWeight.values.length ? FontWeight.values[index] : null;
    }
    return switch (string(key)) {
      'w100' || 'thin' => FontWeight.w100,
      'w200' || 'extraLight' => FontWeight.w200,
      'w300' || 'light' => FontWeight.w300,
      'w400' || 'normal' || 'regular' => FontWeight.w400,
      'w500' || 'medium' => FontWeight.w500,
      'w600' || 'semiBold' => FontWeight.w600,
      'w700' || 'bold' => FontWeight.w700,
      'w800' || 'extraBold' => FontWeight.w800,
      'w900' || 'black' => FontWeight.w900,
      _ => null,
    };
  }

  /// A text style: a name (`"titleLarge"`, or one the theme document named),
  /// or a map. A map with `base` is that style's `copyWith` the other keys --
  /// `{ base: "titleLarge", fontWeight: "bold" }` -- and one without is a
  /// plain style, exactly as rfw reads it.
  TextStyle? textStyle(List<Object> key) {
    final String? name = string(key);
    if (name != null) {
      return resolve.textStyle(name);
    }
    if (!source.isMap(key)) {
      return null;
    }
    final String? baseName = textStyleBase(key);
    final TextStyle? base = baseName == null ? null : resolve.textStyle(baseName);
    final TextStyle overrides = textStyleOverrides(key)!;
    final TextStyle style = base == null ? overrides : base.merge(overrides);
    // A theme's own font, for a style in it that names none (see
    // UiResolver.fontFamily).
    final String? family = resolve.fontFamily;
    return family != null && style.fontFamily == null ? style.copyWith(fontFamily: family) : style;
  }

  /// The name a text style starts from: the string itself, or a map's `base`.
  String? textStyleBase(List<Object> key) => string(key) ?? string(<Object>[...key, 'base']);

  /// A text style map's own keys, without its base; an empty style for a bare
  /// name, null for anything else.
  TextStyle? textStyleOverrides(List<Object> key) {
    if (string(key) != null) {
      return const TextStyle();
    }
    if (!source.isMap(key)) {
      return null;
    }
    final Iterable<String>? written = writtenKeys(key);
    bool may(String name) => written == null || written.contains(name);
    return TextStyle(
      color: may('color') ? color(<Object>[...key, 'color']) : null,
      backgroundColor: may('backgroundColor') ? color(<Object>[...key, 'backgroundColor']) : null,
      fontSize: may('fontSize') ? number(<Object>[...key, 'fontSize']) : null,
      fontWeight: may('fontWeight') ? fontWeight(<Object>[...key, 'fontWeight']) : null,
      fontStyle: may('fontStyle') ? enumValue(FontStyle.values, <Object>[...key, 'fontStyle']) : null,
      letterSpacing: may('letterSpacing') ? number(<Object>[...key, 'letterSpacing']) : null,
      wordSpacing: may('wordSpacing') ? number(<Object>[...key, 'wordSpacing']) : null,
      textBaseline: may('textBaseline') ? enumValue(TextBaseline.values, <Object>[...key, 'textBaseline']) : null,
      height: may('height') ? number(<Object>[...key, 'height']) : null,
      leadingDistribution: may('leadingDistribution') ? enumValue(TextLeadingDistribution.values, <Object>[...key, 'leadingDistribution']) : null,
      shadows: may('shadows') ? list<Shadow>(<Object>[...key, 'shadows'], boxShadow) : null,
      decoration: may('decoration') ? textDecoration(<Object>[...key, 'decoration']) : null,
      decorationColor: may('decorationColor') ? color(<Object>[...key, 'decorationColor']) : null,
      decorationStyle: may('decorationStyle') ? enumValue(TextDecorationStyle.values, <Object>[...key, 'decorationStyle']) : null,
      decorationThickness: may('decorationThickness') ? number(<Object>[...key, 'decorationThickness']) : null,
      fontFamily: may('fontFamily') ? string(<Object>[...key, 'fontFamily']) : null,
      fontFamilyFallback: may('fontFamilyFallback') ? strings(<Object>[...key, 'fontFamilyFallback']) : null,
      overflow: may('overflow') ? enumValue(TextOverflow.values, <Object>[...key, 'overflow']) : null,
    );
  }

  /// `"underline"`, `"lineThrough"`, `"overline"`, `"none"`, or a list of them.
  TextDecoration? textDecoration(List<Object> key) {
    final List<TextDecoration>? many = list<TextDecoration>(key, textDecoration);
    if (many != null) {
      return TextDecoration.combine(many);
    }
    return switch (string(key)) {
      'underline' => TextDecoration.underline,
      'lineThrough' => TextDecoration.lineThrough,
      'overline' => TextDecoration.overline,
      'none' => TextDecoration.none,
      _ => null,
    };
  }

  // --------------------------------------------------------------- geometry

  /// A number or spacing token for every side, rfw's `[start, top, end,
  /// bottom]` list, or a map of `all`, `horizontal`, `vertical`, `top`,
  /// `bottom`, `start`, `end` (or `left` / `right`, which make it absolute).
  EdgeInsetsGeometry? edgeInsets(List<Object> key) {
    final double? all = spacing(key);
    if (all != null) {
      return EdgeInsets.all(all);
    }
    if (source.isList(key)) {
      final double? a = spacing(<Object>[...key, 0]);
      if (a == null) {
        return null;
      }
      final double? b = spacing(<Object>[...key, 1]);
      final double? c = spacing(<Object>[...key, 2]);
      final double? d = spacing(<Object>[...key, 3]);
      return EdgeInsetsDirectional.fromSTEB(a, b ?? a, c ?? a, d ?? b ?? a);
    }
    if (!source.isMap(key)) {
      return null;
    }
    double? side(String name) => spacing(<Object>[...key, name]);
    final double base = side('all') ?? 0;
    final double horizontal = side('horizontal') ?? base;
    final double vertical = side('vertical') ?? base;
    final double top = side('top') ?? vertical;
    final double bottom = side('bottom') ?? vertical;
    final double? left = side('left');
    final double? right = side('right');
    if (left != null || right != null) {
      return EdgeInsets.fromLTRB(left ?? horizontal, top, right ?? horizontal, bottom);
    }
    return EdgeInsetsDirectional.fromSTEB(side('start') ?? horizontal, top, side('end') ?? horizontal, bottom);
  }

  /// [edgeInsets] for a parameter that only takes directional insets; an
  /// absolute `left` / `right` is read as start / end.
  EdgeInsetsDirectional? directionalInsets(List<Object> key) {
    final EdgeInsetsGeometry? value = edgeInsets(key);
    if (value == null || value is EdgeInsetsDirectional) {
      return value as EdgeInsetsDirectional?;
    }
    final EdgeInsets e = value.resolve(TextDirection.ltr);
    return EdgeInsetsDirectional.fromSTEB(e.left, e.top, e.right, e.bottom);
  }

  /// A number or radius token, or `{ x, y }` for an elliptical corner.
  Radius? radius(List<Object> key) {
    final double? r = radiusValue(key);
    if (r != null) {
      return Radius.circular(r);
    }
    final double? x = number(<Object>[...key, 'x']);
    if (x == null) {
      return null;
    }
    return Radius.elliptical(x, number(<Object>[...key, 'y']) ?? x);
  }

  /// A number or radius token for every corner; a map of `all`, `top`,
  /// `bottom`, `start`, `end`, `topStart`, `topEnd`, `bottomStart`,
  /// `bottomEnd`; or rfw's list of radii.
  BorderRadiusGeometry? borderRadius(List<Object> key) {
    final double? all = radiusValue(key);
    if (all != null) {
      return BorderRadius.circular(all);
    }
    if (source.isList(key)) {
      final Radius? a = radius(<Object>[...key, 0]);
      if (a == null) {
        return null;
      }
      final Radius? b = radius(<Object>[...key, 1]);
      final Radius? c = radius(<Object>[...key, 2]);
      final Radius? d = radius(<Object>[...key, 3]);
      return BorderRadiusDirectional.only(topStart: a, topEnd: b ?? a, bottomStart: c ?? a, bottomEnd: d ?? b ?? a);
    }
    if (!source.isMap(key)) {
      return null;
    }
    Radius? corner(String name) => radius(<Object>[...key, name]);
    final Radius base = corner('all') ?? Radius.zero;
    final Radius top = corner('top') ?? base;
    final Radius bottom = corner('bottom') ?? base;
    final Radius? start = corner('start');
    final Radius? end = corner('end');
    return BorderRadiusDirectional.only(
      topStart: corner('topStart') ?? start ?? top,
      topEnd: corner('topEnd') ?? end ?? top,
      bottomStart: corner('bottomStart') ?? start ?? bottom,
      bottomEnd: corner('bottomEnd') ?? end ?? bottom,
    );
  }

  /// A name (`"center"`, `"bottomRight"`, `"centerStart"`) or rfw's
  /// `{ x, y }` / `{ start, y }` map.
  AlignmentGeometry? alignment(List<Object> key) {
    final String? name = string(key);
    if (name != null) {
      return _alignments[name];
    }
    if (!source.isMap(key)) {
      return null;
    }
    final double? y = number(<Object>[...key, 'y']);
    if (y == null) {
      return null;
    }
    final double? start = number(<Object>[...key, 'start']);
    if (start != null) {
      return AlignmentDirectional(start, y);
    }
    final double? x = number(<Object>[...key, 'x']);
    return x == null ? null : Alignment(x, y);
  }

  /// An [alignment] that must be absolute, as [Alignment] parameters are.
  Alignment? absoluteAlignment(List<Object> key) {
    final AlignmentGeometry? value = alignment(key);
    return value is Alignment ? value : value?.resolve(TextDirection.ltr);
  }

  Offset? offset(List<Object> key) {
    if (source.isList(key)) {
      final double? dx = number(<Object>[...key, 0]);
      final double? dy = number(<Object>[...key, 1]);
      return dx == null || dy == null ? null : Offset(dx, dy);
    }
    final double? x = number(<Object>[...key, 'x']);
    final double? y = number(<Object>[...key, 'y']);
    return x == null && y == null ? null : Offset(x ?? 0, y ?? 0);
  }

  /// `{ width, height }`, `[width, height]`, or one number for both.
  Size? size(List<Object> key) {
    final double? square = number(key);
    if (square != null) {
      return Size.square(square);
    }
    if (source.isList(key)) {
      final double? w = number(<Object>[...key, 0]);
      final double? h = number(<Object>[...key, 1]);
      return w == null || h == null ? null : Size(w, h);
    }
    if (!source.isMap(key)) {
      return null;
    }
    return Size(
      number(<Object>[...key, 'width']) ?? double.infinity,
      number(<Object>[...key, 'height']) ?? double.infinity,
    );
  }

  /// `{ minWidth, maxWidth, minHeight, maxHeight }`, where `width` / `height`
  /// pin both ends of their axis.
  BoxConstraints? boxConstraints(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    final double? width = spacing(<Object>[...key, 'width']);
    final double? height = spacing(<Object>[...key, 'height']);
    return BoxConstraints(
      minWidth: width ?? spacing(<Object>[...key, 'minWidth']) ?? 0,
      maxWidth: width ?? spacing(<Object>[...key, 'maxWidth']) ?? double.infinity,
      minHeight: height ?? spacing(<Object>[...key, 'minHeight']) ?? 0,
      maxHeight: height ?? spacing(<Object>[...key, 'maxHeight']) ?? double.infinity,
    );
  }

  VisualDensity? visualDensity(List<Object> key) => switch (string(key)) {
    'compact' => VisualDensity.compact,
    'comfortable' => VisualDensity.comfortable,
    'standard' => VisualDensity.standard,
    'adaptivePlatformDensity' => VisualDensity.adaptivePlatformDensity,
    _ => source.isMap(key)
        ? VisualDensity(
            horizontal: number(<Object>[...key, 'horizontal']) ?? 0,
            vertical: number(<Object>[...key, 'vertical']) ?? 0,
          )
        : null,
  };

  // ----------------------------------------------- borders, shadows, paint

  /// `{ color, width, style, strokeAlign }`; `"none"` for [BorderSide.none].
  BorderSide? borderSide(List<Object> key) {
    if (string(key) == 'none') {
      return BorderSide.none;
    }
    if (!source.isMap(key)) {
      return null;
    }
    return BorderSide(
      color: color(<Object>[...key, 'color']) ?? const Color(0xFF000000),
      width: number(<Object>[...key, 'width']) ?? 1.0,
      style: enumValue(BorderStyle.values, <Object>[...key, 'style']) ?? BorderStyle.solid,
      strokeAlign: number(<Object>[...key, 'strokeAlign']) ?? BorderSide.strokeAlignInside,
    );
  }

  /// One side for all four (`{ color, width }`), a map of `top`, `bottom`,
  /// `left`, `right` (or `start`, `end`), or rfw's list of sides.
  BoxBorder? border(List<Object> key) {
    if (source.isList(key)) {
      final BorderSide? a = borderSide(<Object>[...key, 0]);
      if (a == null) {
        return null;
      }
      final BorderSide? b = borderSide(<Object>[...key, 1]);
      final BorderSide? c = borderSide(<Object>[...key, 2]);
      final BorderSide? d = borderSide(<Object>[...key, 3]);
      return BorderDirectional(start: a, top: b ?? a, end: c ?? a, bottom: d ?? b ?? a);
    }
    if (!source.isMap(key)) {
      return null;
    }
    BorderSide? side(String name) => borderSide(<Object>[...key, name]);
    final BorderSide? start = side('start');
    final BorderSide? end = side('end');
    final BorderSide? top = side('top');
    final BorderSide? bottom = side('bottom');
    if (start != null || end != null) {
      return BorderDirectional(
        start: start ?? BorderSide.none,
        end: end ?? BorderSide.none,
        top: top ?? BorderSide.none,
        bottom: bottom ?? BorderSide.none,
      );
    }
    final BorderSide? left = side('left');
    final BorderSide? right = side('right');
    if (top != null || bottom != null || left != null || right != null) {
      return Border(
        top: top ?? BorderSide.none,
        bottom: bottom ?? BorderSide.none,
        left: left ?? BorderSide.none,
        right: right ?? BorderSide.none,
      );
    }
    return Border.fromBorderSide(borderSide(key)!);
  }

  /// `{ color, offset, blurRadius, spreadRadius, blurStyle }`.
  BoxShadow? boxShadow(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    return BoxShadow(
      color: color(<Object>[...key, 'color']) ?? const Color(0xFF000000),
      offset: offset(<Object>[...key, 'offset']) ?? Offset.zero,
      blurRadius: number(<Object>[...key, 'blurRadius']) ?? 0,
      spreadRadius: number(<Object>[...key, 'spreadRadius']) ?? 0,
      blurStyle: enumValue(BlurStyle.values, <Object>[...key, 'blurStyle']) ?? BlurStyle.normal,
    );
  }

  List<BoxShadow>? boxShadows(List<Object> key) => list<BoxShadow>(key, boxShadow);

  /// `linear`, `radial` or `sweep`, with colour tokens in `colors`.
  Gradient? gradient(List<Object> key) {
    final String? type = string(<Object>[...key, 'type']);
    final List<Color> colors = list<Color>(<Object>[...key, 'colors'], color) ?? const <Color>[];
    final List<double>? stops = list<double>(<Object>[...key, 'stops'], number);
    final TileMode tileMode = enumValue(TileMode.values, <Object>[...key, 'tileMode']) ?? TileMode.clamp;
    if (type == null || colors.length < 2) {
      return type == null ? null : ArgumentDecoders.gradient(source, key);
    }
    return switch (type) {
      'linear' => LinearGradient(
        begin: alignment(<Object>[...key, 'begin']) ?? Alignment.centerLeft,
        end: alignment(<Object>[...key, 'end']) ?? Alignment.centerRight,
        colors: colors,
        stops: stops,
        tileMode: tileMode,
      ),
      'radial' => RadialGradient(
        center: alignment(<Object>[...key, 'center']) ?? Alignment.center,
        radius: number(<Object>[...key, 'radius']) ?? 0.5,
        colors: colors,
        stops: stops,
        tileMode: tileMode,
        focal: alignment(<Object>[...key, 'focal']),
        focalRadius: number(<Object>[...key, 'focalRadius']) ?? 0,
      ),
      'sweep' => SweepGradient(
        center: alignment(<Object>[...key, 'center']) ?? Alignment.center,
        startAngle: number(<Object>[...key, 'startAngle']) ?? 0,
        endAngle: number(<Object>[...key, 'endAngle']) ?? 6.283185307179586,
        colors: colors,
        stops: stops,
        tileMode: tileMode,
      ),
      _ => ArgumentDecoders.gradient(source, key),
    };
  }

  /// A box unless `type` says otherwise: `{ color, border, borderRadius,
  /// boxShadow, gradient, image, shape }`. `type: "shape"` is a
  /// [ShapeDecoration]; any other type is handed to rfw's decoder, so the
  /// extension points rfw offers still work.
  Decoration? decoration(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    final String? type = string(<Object>[...key, 'type']);
    final Iterable<String>? written = writtenKeys(key);
    bool may(String name) => written == null || written.contains(name);
    switch (type) {
      case null:
      case 'box':
        return BoxDecoration(
          color: may('color') ? color(<Object>[...key, 'color']) : null,
          image: may('image') ? ArgumentDecoders.decorationImage(source, <Object>[...key, 'image']) : null,
          border: may('border') ? border(<Object>[...key, 'border']) : null,
          borderRadius: may('borderRadius') ? borderRadius(<Object>[...key, 'borderRadius']) : null,
          boxShadow: may('boxShadow') ? boxShadows(<Object>[...key, 'boxShadow']) : null,
          gradient: may('gradient') ? gradient(<Object>[...key, 'gradient']) : null,
          backgroundBlendMode: may('backgroundBlendMode') ? enumValue(BlendMode.values, <Object>[...key, 'backgroundBlendMode']) : null,
          shape: (may('shape') ? enumValue(BoxShape.values, <Object>[...key, 'shape']) : null) ?? BoxShape.rectangle,
        );
      case 'shape':
        return ShapeDecoration(
          color: may('color') ? color(<Object>[...key, 'color']) : null,
          image: may('image') ? ArgumentDecoders.decorationImage(source, <Object>[...key, 'image']) : null,
          gradient: may('gradient') ? gradient(<Object>[...key, 'gradient']) : null,
          shadows: may('shadows') ? boxShadows(<Object>[...key, 'shadows']) : null,
          shape: (may('shape') ? shape(<Object>[...key, 'shape']) : null) ?? const RoundedRectangleBorder(),
        );
      default:
        return ArgumentDecoders.decoration(source, key);
    }
  }

  /// An outline: `"stadium"`, `"circle"`, `"rectangle"`; a number or radius
  /// token for a rounded rectangle; or `{ type, borderRadius, side }` where
  /// type is `rounded` (the default), `stadium`, `circle`, `beveled`,
  /// `continuous` or `superellipse`.
  OutlinedBorder? shape(List<Object> key) {
    final double? r = radiusValue(key);
    if (r != null) {
      return RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    }
    final String? name = string(key);
    if (name != null) {
      return switch (name) {
        'stadium' => const StadiumBorder(),
        'circle' => const CircleBorder(),
        'rectangle' => const RoundedRectangleBorder(),
        _ => null,
      };
    }
    if (!source.isMap(key)) {
      return null;
    }
    final BorderSide side = borderSide(<Object>[...key, 'side']) ?? BorderSide.none;
    final BorderRadiusGeometry radii = borderRadius(<Object>[...key, 'borderRadius']) ?? BorderRadius.zero;
    return switch (string(<Object>[...key, 'type']) ?? 'rounded') {
      'rounded' => RoundedRectangleBorder(side: side, borderRadius: radii),
      'stadium' => StadiumBorder(side: side),
      'circle' => CircleBorder(side: side),
      'beveled' => BeveledRectangleBorder(side: side, borderRadius: radii),
      'continuous' => ContinuousRectangleBorder(side: side, borderRadius: radii),
      'superellipse' => RoundedSuperellipseBorder(side: side, borderRadius: radii),
      _ => null,
    };
  }

  /// `"outline"`, `"underline"`, `"none"`, or `{ type, borderRadius, side,
  /// gapPadding }` -- `color` and `width` are accepted as the side's.
  InputBorder? inputBorder(List<Object> key) {
    final String? name = string(key) ?? string(<Object>[...key, 'type']);
    if (name == null && !source.isMap(key)) {
      return null;
    }
    BorderSide side = borderSide(<Object>[...key, 'side']) ?? const BorderSide();
    final Color? sideColor = color(<Object>[...key, 'color']);
    final double? sideWidth = number(<Object>[...key, 'width']);
    if (sideColor != null || sideWidth != null) {
      side = side.copyWith(color: sideColor, width: sideWidth);
    }
    final BorderRadius? radii = borderRadius(<Object>[...key, 'borderRadius'])?.resolve(TextDirection.ltr);
    return switch (name ?? 'outline') {
      'none' => InputBorder.none,
      'underline' => UnderlineInputBorder(
        borderSide: side,
        borderRadius: radii ?? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
      ),
      'outline' => OutlineInputBorder(
        borderSide: side,
        borderRadius: radii ?? const BorderRadius.all(Radius.circular(4)),
        gapPadding: number(<Object>[...key, 'gapPadding']) ?? 4,
      ),
      _ => null,
    };
  }

  /// A Material icon by name (`"home"`, `"favorite_border"`), a Cupertino one
  /// with a prefix (`"cupertino.heart_fill"`), or rfw's `{ icon, fontFamily }`
  /// map.
  ///
  /// Names resolve to the SDK's own constants, which the icon tree shaker can
  /// see. rfw's map builds an IconData from a runtime codepoint, so a build
  /// that uses it still needs `--no-tree-shake-icons`; a name never does.
  IconData? icon(List<Object> key) {
    final String? name = string(key);
    if (name != null) {
      return iconNamed(name);
    }
    return source.isMap(key) ? ArgumentDecoders.iconData(source, key) : null;
  }

  /// `{ color, size, opacity, fill, weight, grade, opticalSize, shadows }`.
  IconThemeData? iconThemeData(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    List<Object> k(String name) => <Object>[...key, name];
    return IconThemeData(
      color: color(k('color')),
      size: number(k('size')),
      opacity: number(k('opacity')),
      fill: number(k('fill')),
      weight: number(k('weight')),
      grade: number(k('grade')),
      opticalSize: number(k('opticalSize')),
      shadows: boxShadows(k('shadows')),
    );
  }

  // ------------------------------------------------------- state properties

  /// A [WidgetStateProperty]: one value for every state, or a map from state
  /// to value with `default` for the rest -- `{ default: "primary", selected:
  /// "onPrimary", disabled: "outline" }`. When several states hold, the first
  /// of [stateOrder] that the map names wins.
  WidgetStateProperty<T?>? state<T>(List<Object> key, T? Function(List<Object> key) decode) {
    if (source.isMap(key) && stateOrder.any((String s) => has(<Object>[...key, s]))) {
      final Map<WidgetState, T?> byState = <WidgetState, T?>{
        for (final String s in stateOrder)
          if (s != 'default' && has(<Object>[...key, s])) _widgetStates[s]!: decode(<Object>[...key, s]),
      };
      final T? fallback = decode(<Object>[...key, 'default']);
      return WidgetStateProperty.resolveWith<T?>((Set<WidgetState> states) {
        for (final MapEntry<WidgetState, T?> entry in byState.entries) {
          if (states.contains(entry.key)) {
            return entry.value;
          }
        }
        return fallback;
      });
    }
    final T? value = decode(key);
    return value == null ? null : WidgetStatePropertyAll<T?>(value);
  }

  /// The order states are checked in when more than one holds.
  static const List<String> stateOrder = <String>[
    'disabled', 'error', 'selected', 'pressed', 'dragged', 'hovered', 'focused', 'scrolledUnder', 'default',
  ];

  static const Map<String, WidgetState> _widgetStates = <String, WidgetState>{
    'disabled': WidgetState.disabled,
    'error': WidgetState.error,
    'selected': WidgetState.selected,
    'pressed': WidgetState.pressed,
    'dragged': WidgetState.dragged,
    'hovered': WidgetState.hovered,
    'focused': WidgetState.focused,
    'scrolledUnder': WidgetState.scrolledUnder,
  };

  WidgetStateProperty<Color?>? stateColor(List<Object> key) => state<Color>(key, color);

  /// A [ButtonStyle]: every key `ButtonStyle` has, each a value or a map by
  /// state. `shape` reads [shape], `padding` reads [edgeInsets], `textStyle`
  /// reads [textStyle] (so `"labelLarge"` works), sizes read [size].
  ButtonStyle? buttonStyle(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    List<Object> k(String name) => <Object>[...key, name];
    final Iterable<String>? written = writtenKeys(key);
    bool may(String name) => written == null || written.contains(name);
    // A button's text style replaces its default rather than merging with
    // it, so one that names no font would be drawn in the platform's, not
    // the theme's. It takes the theme's button font instead.
    final String? family = resolve.fontFamily ?? resolve.theme?.textTheme.labelLarge?.fontFamily;
    TextStyle? buttonText(List<Object> at) {
      final TextStyle? style = textStyle(at);
      return style != null && style.fontFamily == null && family != null ? style.copyWith(fontFamily: family) : style;
    }

    return ButtonStyle(
      textStyle: may('textStyle') ? state<TextStyle>(k('textStyle'), buttonText) : null,
      backgroundColor: may('backgroundColor') ? stateColor(k('backgroundColor')) : null,
      foregroundColor: may('foregroundColor') ? stateColor(k('foregroundColor')) : null,
      overlayColor: may('overlayColor') ? stateColor(k('overlayColor')) : null,
      shadowColor: may('shadowColor') ? stateColor(k('shadowColor')) : null,
      surfaceTintColor: may('surfaceTintColor') ? stateColor(k('surfaceTintColor')) : null,
      iconColor: may('iconColor') ? stateColor(k('iconColor')) : null,
      elevation: may('elevation') ? state<double>(k('elevation'), number) : null,
      padding: may('padding') ? state<EdgeInsetsGeometry>(k('padding'), edgeInsets) : null,
      minimumSize: may('minimumSize') ? state<Size>(k('minimumSize'), size) : null,
      fixedSize: may('fixedSize') ? state<Size>(k('fixedSize'), size) : null,
      maximumSize: may('maximumSize') ? state<Size>(k('maximumSize'), size) : null,
      iconSize: may('iconSize') ? state<double>(k('iconSize'), number) : null,
      side: may('side') ? state<BorderSide>(k('side'), borderSide) : null,
      shape: may('shape') ? state<OutlinedBorder>(k('shape'), shape) : null,
      visualDensity: may('visualDensity') ? visualDensity(k('visualDensity')) : null,
      tapTargetSize: may('tapTargetSize') ? enumValue(MaterialTapTargetSize.values, k('tapTargetSize')) : null,
      alignment: may('alignment') ? alignment(k('alignment')) : null,
      enableFeedback: may('enableFeedback') ? boolean(k('enableFeedback')) : null,
    );
  }

  static const Map<String, AlignmentGeometry> _alignments = <String, AlignmentGeometry>{
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
    'topStart': AlignmentDirectional.topStart,
    'topEnd': AlignmentDirectional.topEnd,
    'centerStart': AlignmentDirectional.centerStart,
    'centerEnd': AlignmentDirectional.centerEnd,
    'bottomStart': AlignmentDirectional.bottomStart,
    'bottomEnd': AlignmentDirectional.bottomEnd,
  };

  static const Map<String?, Curve> _curves = <String?, Curve>{
    'linear': Curves.linear,
    'decelerate': Curves.decelerate,
    'ease': Curves.ease,
    'easeIn': Curves.easeIn,
    'easeOut': Curves.easeOut,
    'easeInOut': Curves.easeInOut,
    'easeInSine': Curves.easeInSine,
    'easeOutSine': Curves.easeOutSine,
    'easeInOutSine': Curves.easeInOutSine,
    'easeInCubic': Curves.easeInCubic,
    'easeOutCubic': Curves.easeOutCubic,
    'easeInOutCubic': Curves.easeInOutCubic,
    'easeInOutCubicEmphasized': Curves.easeInOutCubicEmphasized,
    'easeInQuart': Curves.easeInQuart,
    'easeOutQuart': Curves.easeOutQuart,
    'easeInOutQuart': Curves.easeInOutQuart,
    'easeInBack': Curves.easeInBack,
    'easeOutBack': Curves.easeOutBack,
    'easeInOutBack': Curves.easeInOutBack,
    'fastOutSlowIn': Curves.fastOutSlowIn,
    'fastLinearToSlowEaseIn': Curves.fastLinearToSlowEaseIn,
    'fastEaseInToSlowEaseOut': Curves.fastEaseInToSlowEaseOut,
    'linearToEaseOut': Curves.linearToEaseOut,
    'easeInToLinear': Curves.easeInToLinear,
    'slowMiddle': Curves.slowMiddle,
    'bounceIn': Curves.bounceIn,
    'bounceOut': Curves.bounceOut,
    'bounceInOut': Curves.bounceInOut,
    'elasticIn': Curves.elasticIn,
    'elasticOut': Curves.elasticOut,
    'elasticInOut': Curves.elasticInOut,
  };
}

/// An icon by the name a remote file uses: see [UiDecoder.icon].
IconData? iconNamed(String name) {
  const String cupertino = 'cupertino.';
  if (name.startsWith(cupertino)) {
    return cupertinoIcons[name.substring(cupertino.length)];
  }
  return materialIcons[name];
}

/// The names [UiDecoder.curve] knows.
Iterable<String> get curveNames => UiDecoder._curves.keys.whereType<String>();
