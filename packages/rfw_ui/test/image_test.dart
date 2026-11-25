import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// What an `Image` holds in memory, and what it shows before and instead of
/// the picture.
///
/// A photograph is decoded at its own size unless something says otherwise:
/// a 3000x2000 one in an 80px avatar holds about 24 MB of pixels rather than
/// about 0.1 MB, and a list of them is how a phone runs out of memory. When
/// the widget is given a box, that box is what it decodes to.
const LibraryName _main = LibraryName(<String>['main']);

Future<void> _mount(WidgetTester tester, String source, {DynamicContent? data}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: data ?? DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
        ),
      ),
    ),
  );
}

Finder _inScreen(Type type) => find.descendant(of: find.byType(UiRemoteWidget), matching: find.byType(type));

ImageProvider _provider(WidgetTester tester) => tester.widget<Image>(_inScreen(Image)).image;

void main() {
  group('what it decodes', () {
    testWidgets('an Image with a box decodes at the box times the pixel ratio', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _mount(tester, 'widget root = Image(source: "pictures/a.png", width: 80, height: 60);');
      final ImageProvider provider = _provider(tester);
      expect(provider, isA<ResizeImage>());
      final ResizeImage resized = provider as ResizeImage;
      expect(resized.width, 240);
      expect(resized.height, 180);
      expect(resized.allowUpscaling, isFalse, reason: 'a small picture is not blown up to fill the cache');
      expect(resized.imageProvider, isA<AssetImage>());
    });

    testWidgets('an Image with no box is the provider it always was', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Image(source: "pictures/a.png");');
      expect(_provider(tester), isA<AssetImage>());
    });

    testWidgets('one side alone is enough to cap that side', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await _mount(tester, 'widget root = Image(source: "pictures/a.png", width: 50);');
      final ResizeImage resized = _provider(tester) as ResizeImage;
      expect(resized.width, 100);
      expect(resized.height, isNull);
    });

    testWidgets('cacheWidth and cacheHeight win over the box', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _mount(tester, 'widget root = Image(source: "pictures/a.png", width: 80, height: 80, cacheWidth: 32);');
      final ResizeImage resized = _provider(tester) as ResizeImage;
      expect(resized.width, 32, reason: 'written down, it is taken as it is, not scaled');
      expect(resized.height, isNull);
    });

    testWidgets('a network image is capped the same way', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await _mount(tester, 'widget root = Image(source: "https://example.com/a.png", width: 40, height: 40);');
      final ResizeImage resized = _provider(tester) as ResizeImage;
      expect(resized.width, 80);
      expect(resized.imageProvider, isA<NetworkImage>());
    });
  });

  group('what it shows', () {
    testWidgets('a placeholder stands in until the picture arrives', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Image(source: "pictures/missing.png", width: 60, height: 60, '
        'placeholder: Text(text: "loading"));',
      );
      expect(find.text('loading'), findsOneWidget);
    });

    testWidgets('an error widget shows when the picture never arrives', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Image(source: "pictures/missing.png", width: 60, height: 60, '
        'error: Text(text: "gone"));',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('gone'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'a missing picture is remote data, not a crash');
    });

    testWidgets('with no error widget it keeps the space, as it always did', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Image(source: "pictures/missing.png", width: 60, height: 60);');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(_inScreen(Image), findsOneWidget);
    });
  });
}
