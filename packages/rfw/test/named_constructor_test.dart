// Not part of rfw 1.1.4: see PATCHES.md, "`Name.ctor(` is one call name".

// This file is hand-formatted.

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

ConstructorCall root(String source) => parseLibraryFile(source).widgets.single.root as ConstructorCall;

void main() {
  test('a name, a dot and a name, then a bracket, is one call name', () {
    final ConstructorCall call = root('widget a = ListView.builder(items: []);');
    expect(call.name, 'ListView.builder');
    expect(call.arguments, <String, Object>{'items': <Object>[]});
  });

  test('works where a widget is an argument, and inside a builder', () {
    final ConstructorCall call = root('widget a = b(child: PageView.builder(itemBuilder: (m) => GridView.builder()));');
    final ConstructorCall child = call.arguments['child']! as ConstructorCall;
    expect(child.name, 'PageView.builder');
    expect(((child.arguments['itemBuilder']! as WidgetBuilderDeclaration).widget as ConstructorCall).name, 'GridView.builder');
  });

  test('is an error with a space on either side of the dot', () {
    void fails(String source) {
      expect(() => parseLibraryFile(source), throwsA(isA<ParserException>()
          .having((ParserException e) => e.line, 'line', 1)
          .having((ParserException e) => e.column, 'column', greaterThan(0))));
    }
    fails('widget a = ListView .builder();');
    fails('widget a = ListView. builder();');
  });

  test('takes one dot only', () {
    expect(() => parseLibraryFile('widget a = A.b.c();'), throwsA(isA<ParserException>()));
  });

  test('leaves references and dot values as they were', () {
    final ConstructorCall call = root(
      'widget a = b(c: args.x, d: data.a.b, e: [...for item in data.items: f(g: item.title)], h: .center);',
    );
    expect(call.arguments['c'], isA<ArgsReference>().having((ArgsReference r) => r.parts, 'parts', <Object>['x']));
    expect(call.arguments['d'], isA<DataReference>().having((DataReference r) => r.parts, 'parts', <Object>['a', 'b']));
    final Loop loop = (call.arguments['e']! as DynamicList).single! as Loop;
    expect((loop.output as ConstructorCall).arguments['g'],
        isA<LoopReference>().having((LoopReference r) => r.parts, 'parts', <Object>['title']));
    expect(call.arguments['h'], 'center');
  });

  test('survives the binary format', () {
    final RemoteWidgetLibrary decoded = decodeLibraryBlob(encodeLibraryBlob(parseLibraryFile('widget a = ListView.separated();')));
    expect((decoded.widgets.single.root as ConstructorCall).name, 'ListView.separated');
  });
}
