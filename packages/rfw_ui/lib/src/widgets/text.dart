import 'package:flutter/material.dart';

import 'args.dart';
import 'spec.dart';

/// Text, with the theme's type scale reachable by name.
///
/// `style: "titleLarge"` is the theme's titleLarge; `style: { base:
/// "titleLarge", fontWeight: "bold" }` is `titleLarge.copyWith(fontWeight:
/// bold)`. A map without `base` is a plain TextStyle, exactly as rfw reads it,
/// so existing files keep working.
final List<UiWidget> textWidgets = <UiWidget>[
  UiWidget(
    'Text',
    group: UiGroup.text,
    doc: 'A run of text. `style` takes a theme style by name, or `{ base: "<name>", ...overrides }` for its copyWith.',
    params: <UiParam>[
      p('text', 'String', 'The text; a list of strings is joined, as in rfw.'),
      p('style', 'TextStyle'),
      e('textAlign', TextAlign.values),
      e('textDirection', TextDirection.values),
      p('softWrap', 'bool'),
      e('overflow', TextOverflow.values),
      p('textScaleFactor', 'double'),
      p('maxLines', 'int'),
      p('semanticsLabel', 'String'),
      e('textWidthBasis', TextWidthBasis.values),
      p('selectionColor', 'Color'),
    ],
    build: (UiArgs a) => Text(
      _text(a, ['text']),
      style: a.textStyle(const ['style']),
      textAlign: a.enumValue(TextAlign.values, const ['textAlign']),
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      softWrap: a.boolean(const ['softWrap']),
      overflow: a.enumValue(TextOverflow.values, const ['overflow']),
      textScaler: _scaler(a.number(const ['textScaleFactor'])),
      maxLines: a.integer(const ['maxLines']),
      semanticsLabel: a.string(const ['semanticsLabel']),
      textWidthBasis: a.enumValue(TextWidthBasis.values, const ['textWidthBasis']),
      selectionColor: a.color(const ['selectionColor']),
    ),
    example: 'Text(text: "Welcome back.", style: { base: "displaySmall", fontWeight: "bold", letterSpacing: -1, color: "primary" })',
  ),
  UiWidget(
    'RichText',
    group: UiGroup.text,
    doc: 'Text in several styles: `spans: [{ text: "Hello " }, { text: "world", style: { base: "bodyLarge", fontWeight: "bold" } }]`. '
        'A span may nest `children` of its own.',
    params: <UiParam>[
      p('spans', 'List<Map>', 'Each `{ text, style, children }`.'),
      p('style', 'TextStyle', 'The style every span starts from.'),
      e('textAlign', TextAlign.values),
      e('textDirection', TextDirection.values),
      p('softWrap', 'bool'),
      e('overflow', TextOverflow.values),
      p('textScaleFactor', 'double'),
      p('maxLines', 'int'),
      p('semanticsLabel', 'String'),
      p('selectionColor', 'Color'),
    ],
    build: (UiArgs a) => Text.rich(
      TextSpan(children: _spans(a, ['spans'])),
      style: a.textStyle(const ['style']),
      textAlign: a.enumValue(TextAlign.values, const ['textAlign']),
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      softWrap: a.boolean(const ['softWrap']),
      overflow: a.enumValue(TextOverflow.values, const ['overflow']),
      textScaler: _scaler(a.number(const ['textScaleFactor'])),
      maxLines: a.integer(const ['maxLines']),
      semanticsLabel: a.string(const ['semanticsLabel']),
      selectionColor: a.color(const ['selectionColor']),
    ),
    example: 'RichText(style: "bodyLarge", spans: [{ text: "By continuing you accept the " }, '
        '{ text: "terms", style: { color: "primary", decoration: "underline" } }, { text: "." }])',
  ),
  UiWidget(
    'SelectableText',
    group: UiGroup.text,
    doc: 'Text the person can select and copy.',
    params: <UiParam>[
      p('text', 'String'),
      p('style', 'TextStyle'),
      e('textAlign', TextAlign.values),
      e('textDirection', TextDirection.values),
      p('textScaleFactor', 'double'),
      p('maxLines', 'int'),
      p('minLines', 'int'),
      p('showCursor', 'bool', null, 'false'),
      p('cursorColor', 'Color'),
      p('cursorWidth', 'double', null, '2'),
      p('onTap', 'event'),
    ],
    build: (UiArgs a) => SelectableText(
      _text(a, ['text']),
      style: a.textStyle(const ['style']),
      textAlign: a.enumValue(TextAlign.values, const ['textAlign']),
      textDirection: a.enumValue(TextDirection.values, const ['textDirection']),
      textScaler: _scaler(a.number(const ['textScaleFactor'])),
      maxLines: a.integer(const ['maxLines']),
      minLines: a.integer(const ['minLines']),
      showCursor: a.boolean(const ['showCursor']) ?? false,
      cursorColor: a.color(const ['cursorColor']),
      cursorWidth: a.number(const ['cursorWidth']) ?? 2,
      onTap: a.onTap(const ['onTap']),
    ),
  ),
  UiWidget(
    'DefaultTextStyle',
    group: UiGroup.text,
    doc: 'Sets the style of all Text below it, merged over the one already in scope. Changes animate.',
    params: <UiParam>[
      p('style', 'TextStyle'),
      e('textAlign', TextAlign.values),
      p('softWrap', 'bool', null, 'true'),
      e('overflow', TextOverflow.values, null, 'clip'),
      p('maxLines', 'int'),
      e('textWidthBasis', TextWidthBasis.values, null, 'parent'),
      p('duration', 'Duration'),
      p('curve', 'Curve'),
      p('onEnd', 'event'),
      p('child', 'Widget'),
    ],
    build: (UiArgs a) => AnimatedDefaultTextStyle(
      style: DefaultTextStyle.of(a.context).style.merge(a.textStyle(const ['style'])),
      textAlign: a.enumValue(TextAlign.values, const ['textAlign']),
      softWrap: a.boolean(const ['softWrap']) ?? true,
      overflow: a.enumValue(TextOverflow.values, const ['overflow']) ?? TextOverflow.clip,
      maxLines: a.integer(const ['maxLines']),
      textWidthBasis: a.enumValue(TextWidthBasis.values, const ['textWidthBasis']) ?? TextWidthBasis.parent,
      duration: a.animDuration(const ['duration']),
      curve: a.animCurve(const ['curve']),
      onEnd: a.onTap(const ['onEnd']),
      child: a.child(const ['child']),
    ),
  ),
];

/// A string, or rfw's list of strings joined.
String _text(UiArgs a, List<Object> key) {
  final String? text = a.string(key);
  if (text != null) {
    return text;
  }
  return (a.strings(key) ?? const <String>[]).join();
}

TextScaler? _scaler(double? factor) => factor == null ? null : TextScaler.linear(factor);

List<InlineSpan> _spans(UiArgs a, List<Object> key) {
  return a.list<InlineSpan>(key, (List<Object> k) {
        final String? plain = a.string(k);
        if (plain != null) {
          return TextSpan(text: plain);
        }
        return TextSpan(
          text: a.string(<Object>[...k, 'text']),
          style: a.textStyle(<Object>[...k, 'style']),
          children: a.source.isList(<Object>[...k, 'children']) ? _spans(a, <Object>[...k, 'children']) : null,
          semanticsLabel: a.string(<Object>[...k, 'semanticsLabel']),
        );
      }) ??
      const <InlineSpan>[];
}
