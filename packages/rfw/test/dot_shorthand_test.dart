// Not part of rfw 1.1.4: see PATCHES.md, "`.name` is the string "name"".

// This file is hand-formatted.

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

Object? arg(String source, String name) {
  final RemoteWidgetLibrary library = parseLibraryFile(source);
  return (library.widgets.single.root as ConstructorCall).arguments[name];
}

void main() {
  test('a dot and a name, where a value goes, is that name as a string', () {
    expect(arg('widget a = b(c: .center);', 'c'), 'center');
  });

  test('works in a list', () {
    expect(arg('widget a = b(c: [.start, .end]);', 'c'), <Object>['start', 'end']);
  });

  test('works in a map', () {
    expect(arg('widget a = b(c: { base: .bodyLarge, color: .onSurface });', 'c'),
        <String, Object>{'base': 'bodyLarge', 'color': 'onSurface'});
  });

  test('dotted parts are joined, for names such as cupertino icons', () {
    expect(arg('widget a = b(c: .cupertino.heart_fill);', 'c'), 'cupertino.heart_fill');
  });

  test('is a switch case key', () {
    final Switch s = parseLibraryFile('widget a = switch args.s { .compact: b(), default: c() };').widgets.single.root as Switch;
    expect(s.outputs.keys, <Object?>['compact', null]);
  });

  test('works in data files', () {
    expect(parseDataFile('{ a: .b, c: [.d] }'), <String, Object>{'a': 'b', 'c': <Object>['d']});
  });

  test('leaves references as they were', () {
    final RemoteWidgetLibrary library = parseLibraryFile(
      'widget a = b(c: args.title, d: data.items.0, e: [...for item in data.items: f(g: item.title)], h: state.on);',
    );
    final DynamicMap args = (library.widgets.single.root as ConstructorCall).arguments;
    expect(args['c'], isA<ArgsReference>().having((ArgsReference r) => r.parts, 'parts', <Object>['title']));
    expect(args['d'], isA<DataReference>().having((DataReference r) => r.parts, 'parts', <Object>['items', 0]));
    expect(args['h'], isA<StateReference>().having((StateReference r) => r.parts, 'parts', <Object>['on']));
    final Loop loop = (args['e']! as DynamicList).single! as Loop;
    final Object? g = (loop.output as ConstructorCall).arguments['g'];
    expect(g, isA<LoopReference>().having((LoopReference r) => r.parts, 'parts', <Object>['title']));
  });

  test('encodes to the same bytes as the quoted string', () {
    expect(
      encodeLibraryBlob(parseLibraryFile('import ui; widget a = b(c: .center, d: [.x], e: { f: .g });')),
      encodeLibraryBlob(parseLibraryFile('import ui; widget a = b(c: "center", d: ["x"], e: { f: "g" });')),
    );
  });

  test('is an error with a space after the dot, a number, or nothing', () {
    void fails(String source) {
      expect(() => parseLibraryFile(source), throwsA(isA<ParserException>()
          .having((ParserException e) => e.message, 'message', 'Unexpected .')
          .having((ParserException e) => e.line, 'line', 1)));
    }
    fails('widget a = b(c: . center);');
    fails('widget a = b(c: .5);');
    fails('widget a = b(c: .);');
    fails('widget a = b(c: .cupertino. heart);');
  });

  test('is not a map key', () {
    expect(() => parseLibraryFile('widget a = b(c: { .d: 1 });'), throwsA(isA<ParserException>()));
  });
}
