// Not part of rfw 1.1.4: see PATCHES.md, "A builder's argument can be read
// whole".

// This file is hand-formatted.

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

Object? inner(String source, String name) {
  final ConstructorCall call = parseLibraryFile(source).widgets.single.root as ConstructorCall;
  final WidgetBuilderDeclaration builder = call.arguments['b']! as WidgetBuilderDeclaration;
  return (builder.widget as ConstructorCall).arguments[name];
}

void main() {
  test('a builder\'s argument on its own is the whole argument', () {
    expect(inner('widget a = L(b: (m) => T(x: m));', 'x'),
        isA<WidgetBuilderArgReference>()
            .having((WidgetBuilderArgReference r) => r.argumentName, 'argumentName', 'm')
            .having((WidgetBuilderArgReference r) => r.parts, 'parts', isEmpty));
  });

  test('a builder\'s argument with parts reads as it did', () {
    expect(inner('widget a = L(b: (m) => T(x: m.title.0));', 'x'),
        isA<WidgetBuilderArgReference>().having((WidgetBuilderArgReference r) => r.parts, 'parts', <Object>['title', 0]));
  });

  test('survives the binary format', () {
    final RemoteWidgetLibrary decoded = decodeLibraryBlob(encodeLibraryBlob(parseLibraryFile('widget a = L(b: (m) => T(x: m));')));
    final WidgetBuilderDeclaration builder = (decoded.widgets.single.root as ConstructorCall).arguments['b']! as WidgetBuilderDeclaration;
    expect((builder.widget as ConstructorCall).arguments['x'],
        isA<WidgetBuilderArgReference>().having((WidgetBuilderArgReference r) => r.parts, 'parts', isEmpty));
  });
}
