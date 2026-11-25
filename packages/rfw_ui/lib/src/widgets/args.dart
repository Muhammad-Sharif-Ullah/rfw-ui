import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../decode/decoder.dart';
import '../decode/resolver.dart';
import 'scope.dart' show uiKeyOf;

/// A widget's remote arguments, as its builder reads them.
///
/// Everything [UiDecoder] reads, against the theme in scope, plus what only a
/// widget has: children, handlers, and the shorthands that keep remote files
/// short -- a string where a widget is expected is `Text`, an icon name where
/// an icon widget is expected is `Icon`.
class UiArgs extends UiDecoder {
  /// Reads tokens through [resolve] when given, else through the theme in
  /// scope. A runtime that knows every widget of a screen shares one theme
  /// can look it up once and pass it, rather than each widget looking it up.
  UiArgs(this.context, DataSource source, {this.key, UiResolver? resolve}) : super(source, resolve ?? UiResolver.of(context));

  final BuildContext context;

  /// The widget's `key`, read once by the library for every widget alike (see
  /// [uiKeyOf]); an input registers its focus node under it.
  final String? key;

  // ------------------------------------------------------------- children

  Widget child(List<Object> key) => source.child(key);

  Widget? optionalChild(List<Object> key) => source.optionalChild(key);

  List<Widget> children(List<Object> key) => source.childList(key);

  /// The list of widgets at [key], built one at a time as a scroll view asks
  /// for them, so a row that is never scrolled to is never built or bound.
  /// Null when there is no list at [key].
  UiLazyChildren? lazyChildren(List<Object> key) => source.isList(key) ? UiLazyChildren._(source, key) : null;

  /// The rows of a `.builder` widget: its `items`, at most `itemCount` of
  /// them -- or, with no items, `itemCount` rows -- each built by
  /// `itemBuilder` from its item, or its index.
  ///
  /// Null on a runtime whose [DataSource] cannot hand a builder an item:
  /// rfw's, which hands a local widget only numbers, strings and flags.
  UiItems? items() {
    final Object s = source;
    return s is UiItemsSource ? UiItems._(s) : null;
  }

  /// What the widget builder at [key] -- `builder: (size) => ...` -- builds,
  /// with [scope] as what its argument holds.
  Widget builder(List<Object> key, Map<String, Object?> scope) => source.builder(key, scope);

  /// The same, null when the file wrote no builder there.
  Widget? optionalBuilder(List<Object> key, Map<String, Object?> scope) => source.optionalBuilder(key, scope);

  /// A widget, or a string as `Text`.
  Widget? label(List<Object> key, {TextStyle? style}) {
    final String? text = string(key);
    if (text != null) {
      return Text(text, style: style);
    }
    return source.optionalChild(key);
  }

  /// A widget, or an icon name as `Icon`.
  Widget? iconOrChild(List<Object> key, {double? size, Color? color}) {
    final String? name = string(key);
    if (name != null) {
      final IconData? data = iconNamed(name);
      return data == null ? null : Icon(data, size: size, color: color);
    }
    return source.optionalChild(key);
  }

  // ------------------------------------------------------------- handlers

  VoidCallback? onTap(List<Object> key) => source.voidHandler(key);

  /// A handler that receives a value: an event gets `{ value: ... }` merged
  /// into its arguments. rfw's `set state` handlers ignore arguments, which is
  /// why two-way binding goes through `event "ui.set"` instead.
  ValueChanged<T>? onValue<T>(List<Object> key) {
    return source.handler<ValueChanged<T>>(
      key,
      (HandlerTrigger trigger) => (T value) => trigger(<String, Object?>{'value': encodeValue(value)}),
    );
  }

  /// A handler that receives a map of values.
  ValueChanged<Map<String, Object?>>? onValues(List<Object> key) {
    return source.handler<ValueChanged<Map<String, Object?>>>(
      key,
      (HandlerTrigger trigger) => (Map<String, Object?> values) =>
          trigger(<String, Object?>{for (final MapEntry<String, Object?> e in values.entries) e.key: encodeValue(e.value)}),
    );
  }

  // ------------------------------------------------------------ animation

  /// [duration], else the [AnimationDefaults] in scope -- rfw's own widgets
  /// animate implicitly, and these keep doing so.
  Duration animDuration(List<Object> key) => duration(key) ?? AnimationDefaults.durationOf(context);

  Curve animCurve(List<Object> key) => curve(key) ?? AnimationDefaults.curveOf(context);

  // --------------------------------------------------------- other values

  /// A URL, or an asset name.
  ///
  /// With a [cacheWidth] or a [cacheHeight] the picture is decoded at that
  /// size and no larger, which is what keeps a photograph from holding its
  /// own megapixels in an eighty-pixel box. It is never upscaled: a picture
  /// smaller than the box is decoded as it is.
  ImageProvider? image(List<Object> key, {int? cacheWidth, int? cacheHeight}) {
    final String? value = string(key);
    if (value == null || value.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(value);
    final ImageProvider provider = uri != null && uri.hasScheme ? NetworkImage(value) : AssetImage(value);
    if (cacheWidth == null && cacheHeight == null) {
      return provider;
    }
    return ResizeImage(provider, width: cacheWidth, height: cacheHeight, allowUpscaling: false);
  }

  DateTime? date(List<Object> key) {
    final String? value = string(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  /// `"never"`, `"always"`, `"bouncing"`, `"clamping"` or `"page"`.
  ScrollPhysics? physics(List<Object> key) => switch (string(key)) {
    'never' => const NeverScrollableScrollPhysics(),
    'always' => const AlwaysScrollableScrollPhysics(),
    'bouncing' => const BouncingScrollPhysics(),
    'clamping' => const ClampingScrollPhysics(),
    'page' => const PageScrollPhysics(),
    _ => null,
  };

  /// Pixels a scroll view lays out beyond its visible edge.
  ScrollCacheExtent? cacheExtent(List<Object> key) {
    final double? pixels = number(key);
    return pixels == null ? null : ScrollCacheExtent.pixels(pixels);
  }

  /// `{ crossAxisCount | maxCrossAxisExtent, mainAxisSpacing,
  /// crossAxisSpacing, childAspectRatio, mainAxisExtent }`.
  SliverGridDelegate? gridDelegate(List<Object> key) {
    if (!source.isMap(key)) {
      return null;
    }
    final double mainAxisSpacing = spacing(<Object>[...key, 'mainAxisSpacing']) ?? 0;
    final double crossAxisSpacing = spacing(<Object>[...key, 'crossAxisSpacing']) ?? 0;
    final double childAspectRatio = number(<Object>[...key, 'childAspectRatio']) ?? 1;
    final double? mainAxisExtent = number(<Object>[...key, 'mainAxisExtent']);
    final double? maxExtent = number(<Object>[...key, 'maxCrossAxisExtent']);
    if (maxExtent != null) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
        mainAxisExtent: mainAxisExtent,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: integer(<Object>[...key, 'crossAxisCount']) ?? 2,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      mainAxisExtent: mainAxisExtent,
    );
  }

  TextInputType? keyboardType(List<Object> key) => switch (string(key)) {
    'text' => TextInputType.text,
    'multiline' => TextInputType.multiline,
    'number' => TextInputType.number,
    'decimal' => const TextInputType.numberWithOptions(decimal: true),
    'phone' => TextInputType.phone,
    'datetime' => TextInputType.datetime,
    'emailAddress' || 'email' => TextInputType.emailAddress,
    'url' => TextInputType.url,
    'visiblePassword' => TextInputType.visiblePassword,
    'name' => TextInputType.name,
    'streetAddress' => TextInputType.streetAddress,
    'none' => TextInputType.none,
    _ => null,
  };

  /// A list of `"digitsOnly"`, `"singleLine"`, `{ allow: "<regex>" }` or
  /// `{ deny: "<regex>" }`.
  List<TextInputFormatter>? inputFormatters(List<Object> key) {
    return list<TextInputFormatter>(key, (List<Object> k) {
      switch (string(k)) {
        case 'digitsOnly':
          return FilteringTextInputFormatter.digitsOnly;
        case 'singleLine':
          return FilteringTextInputFormatter.singleLineFormatter;
      }
      final String? allow = string(<Object>[...k, 'allow']);
      if (allow != null) {
        return FilteringTextInputFormatter.allow(RegExp(allow));
      }
      final String? deny = string(<Object>[...k, 'deny']);
      return deny == null ? null : FilteringTextInputFormatter.deny(RegExp(deny));
    });
  }

  /// An [InputDecoration]. `"none"` is no decoration at all; a missing one is
  /// Flutter's default, themed by `inputDecorationTheme`.
  InputDecoration? inputDecoration(List<Object> key) {
    if (string(key) == 'none') {
      return null;
    }
    if (!source.isMap(key)) {
      return const InputDecoration();
    }
    List<Object> k(String name) => <Object>[...key, name];
    final Iterable<String>? written = writtenKeys(key);
    bool may(String name) => written == null || written.contains(name);
    return InputDecoration(
      icon: may('icon') ? iconOrChild(k('icon')) : null,
      iconColor: may('iconColor') ? color(k('iconColor')) : null,
      label: may('label') ? source.optionalChild(k('label')) : null,
      labelText: may('labelText') ? string(k('labelText')) : null,
      labelStyle: may('labelStyle') ? textStyle(k('labelStyle')) : null,
      floatingLabelStyle: may('floatingLabelStyle') ? textStyle(k('floatingLabelStyle')) : null,
      helperText: may('helperText') ? string(k('helperText')) : null,
      helperStyle: may('helperStyle') ? textStyle(k('helperStyle')) : null,
      helperMaxLines: may('helperMaxLines') ? integer(k('helperMaxLines')) : null,
      hintText: may('hintText') ? string(k('hintText')) : null,
      hintStyle: may('hintStyle') ? textStyle(k('hintStyle')) : null,
      hintMaxLines: may('hintMaxLines') ? integer(k('hintMaxLines')) : null,
      errorText: may('errorText') ? string(k('errorText')) : null,
      errorStyle: may('errorStyle') ? textStyle(k('errorStyle')) : null,
      errorMaxLines: may('errorMaxLines') ? integer(k('errorMaxLines')) : null,
      floatingLabelBehavior: may('floatingLabelBehavior') ? enumValue(FloatingLabelBehavior.values, k('floatingLabelBehavior')) : null,
      isCollapsed: may('isCollapsed') ? boolean(k('isCollapsed')) : null,
      isDense: may('isDense') ? boolean(k('isDense')) : null,
      contentPadding: may('contentPadding') ? edgeInsets(k('contentPadding')) : null,
      prefixIcon: may('prefixIcon') ? iconOrChild(k('prefixIcon')) : null,
      prefixIconColor: may('prefixIconColor') ? color(k('prefixIconColor')) : null,
      prefixIconConstraints: may('prefixIconConstraints') ? boxConstraints(k('prefixIconConstraints')) : null,
      prefix: may('prefix') ? source.optionalChild(k('prefix')) : null,
      prefixText: may('prefixText') ? string(k('prefixText')) : null,
      prefixStyle: may('prefixStyle') ? textStyle(k('prefixStyle')) : null,
      suffixIcon: may('suffixIcon') ? iconOrChild(k('suffixIcon')) : null,
      suffixIconColor: may('suffixIconColor') ? color(k('suffixIconColor')) : null,
      suffixIconConstraints: may('suffixIconConstraints') ? boxConstraints(k('suffixIconConstraints')) : null,
      suffix: may('suffix') ? source.optionalChild(k('suffix')) : null,
      suffixText: may('suffixText') ? string(k('suffixText')) : null,
      suffixStyle: may('suffixStyle') ? textStyle(k('suffixStyle')) : null,
      counterText: may('counterText') ? string(k('counterText')) : null,
      counterStyle: may('counterStyle') ? textStyle(k('counterStyle')) : null,
      filled: may('filled') ? boolean(k('filled')) : null,
      fillColor: may('fillColor') ? color(k('fillColor')) : null,
      focusColor: may('focusColor') ? color(k('focusColor')) : null,
      hoverColor: may('hoverColor') ? color(k('hoverColor')) : null,
      border: may('border') ? inputBorder(k('border')) : null,
      enabledBorder: may('enabledBorder') ? inputBorder(k('enabledBorder')) : null,
      focusedBorder: may('focusedBorder') ? inputBorder(k('focusedBorder')) : null,
      errorBorder: may('errorBorder') ? inputBorder(k('errorBorder')) : null,
      focusedErrorBorder: may('focusedErrorBorder') ? inputBorder(k('focusedErrorBorder')) : null,
      disabledBorder: may('disabledBorder') ? inputBorder(k('disabledBorder')) : null,
      enabled: (may('enabled') ? boolean(k('enabled')) : null) ?? true,
      alignLabelWithHint: may('alignLabelWithHint') ? boolean(k('alignLabelWithHint')) : null,
      constraints: may('constraints') ? boxConstraints(k('constraints')) : null,
    );
  }
}

/// Rows a scroll view builds one at a time, as they come into view.
abstract interface class UiRows {
  /// How many rows there are.
  int get length;

  /// Row [index].
  Widget build(int index);
}

/// A remote list of widgets, read a row at a time. See [UiArgs.lazyChildren].
class UiLazyChildren implements UiRows {
  UiLazyChildren._(this._source, this._key) : length = _source.length(_key);

  final DataSource _source;
  final List<Object> _key;

  /// How many widgets the list has, a loop's rows counted one by one.
  @override
  final int length;

  @override
  Widget build(int index) => _source.child(<Object>[..._key, index]);
}

/// What a runtime's [DataSource] does besides rfw's: hand a builder the
/// items of a list, as the `.builder` widgets need. UiRuntime's does.
abstract interface class UiItemsSource {
  /// How many rows: the items at [itemsKey], at most the number at
  /// [countKey]; or, with nothing written at [itemsKey], that number.
  int itemCount(List<Object> itemsKey, List<Object> countKey);

  /// Row [index], built by the builder at [builderKey] from item [index] of
  /// [itemsKey]; or from [index] itself, with nothing written at [itemsKey].
  Widget buildItem(List<Object> itemsKey, List<Object> builderKey, int index);
}

/// The rows of a `.builder` widget. See [UiArgs.items].
class UiItems implements UiRows {
  UiItems._(this._source) : length = _source.itemCount(_items, const <Object>['itemCount']);

  static const List<Object> _items = <Object>['items'];

  final UiItemsSource _source;

  @override
  final int length;

  /// Row [index], built by `itemBuilder`.
  @override
  Widget build(int index) => buildWith(const <Object>['itemBuilder'], index);

  /// Row [index]'s item built by the builder at [builderKey] instead, such as
  /// `separatorBuilder`.
  Widget buildWith(List<Object> builderKey, int index) => _source.buildItem(_items, builderKey, index);
}

/// What a `.builder` widget shows on a runtime that cannot hand its builder
/// an item -- rfw's -- reported as a mistake in a remote file is.
Widget uiNeedsUiRuntime(String widget, String instead) {
  final FlutterErrorDetails detail = FlutterErrorDetails(
    exception: "$widget needs UiRuntime. On rfw's Runtime, write $instead.",
    stack: StackTrace.current,
    library: 'rfw_ui',
  );
  FlutterError.reportError(detail);
  return ErrorWidget.builder(detail);
}

/// A value as an rfw event argument: rfw carries strings, numbers, bools,
/// maps and lists, so dates travel as ISO strings, times as `"HH:mm"` and sets
/// as lists.
Object? encodeValue(Object? value) {
  return switch (value) {
    null || String() || int() || double() || bool() => value,
    DateTime() => _isoDate(value),
    TimeOfDay() => '${_two(value.hour)}:${_two(value.minute)}',
    DateTimeRange() => <String, Object?>{'start': _isoDate(value.start), 'end': _isoDate(value.end)},
    RangeValues() => <String, Object?>{'start': value.start, 'end': value.end},
    Map<String, Object?>() => <String, Object?>{
      for (final MapEntry<String, Object?> e in value.entries) e.key: encodeValue(e.value),
    },
    Iterable<Object?>() => <Object?>[for (final Object? v in value) encodeValue(v)],
    _ => value.toString(),
  };
}

/// A date alone when it has no time of day, so a date picker's answer reads
/// `"2026-10-23"` and not `"2026-10-23T00:00:00.000"`.
String _isoDate(DateTime d) {
  final bool midnight = d.hour == 0 && d.minute == 0 && d.second == 0 && d.millisecond == 0 && d.microsecond == 0;
  if (!midnight) {
    return d.toIso8601String();
  }
  return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');
