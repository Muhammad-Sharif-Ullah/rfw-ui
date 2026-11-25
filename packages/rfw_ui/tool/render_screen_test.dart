// Renders a remote screen to a PNG with real fonts and icons, and lists what
// is wrong with it first -- for a person, or an agent, to look at beside the
// design it was built from.
//
//   cd packages/rfw_ui
//   RFW_SCREEN=/abs/screen.rfwtxt RFW_OUT=/abs/screen.png flutter test tool/render_screen_test.dart
//
// Optional:
//   RFW_THEME=/abs/theme.rfwtxt   a theme: a UiThemeDocument ({ shared, light,
//                                 dark }) or one side of one, as .rfwtxt,
//                                 .json or .rfw; the app's look otherwise
//   RFW_MODE=light|dark           which side to render (default light)
//   RFW_DATA=/abs/data.json       what `data.*` reads
//   RFW_ROOT=root                 the widget to render (default root, else the first)
//   RFW_SIZE=390x844              logical size of the screen (default 390x844)
//   RFW_SCALE=2                   pixels per logical pixel in the PNG (default 2)
//   RFW_PLATFORM=android|ios      the platform Material adapts to (default android)
//   RFW_TAP="Delete,Open"         texts to tap, in order, before the picture
//                                 is taken: a dialog or sheet, rendered open
//   RFW_FONTS=/abs/dir            .ttf/.otf files to load; a file named
//                                 Inter-Bold.ttf is family "Inter"
//   RFW_STRICT=1                  fail when there are problems
//
// It prints one PROBLEM line per thing the catalog says is wrong -- a widget
// or argument the kit does not have, an icon or a token that names nothing
// -- and every error raised while building, then the PNG's path. Problems do
// not stop the render: a picture of what does work is worth having beside
// the list of what does not.
//
// A test only because a test is how Flutter renders without a device. It is
// in tool/, so `flutter test` on its own never runs it.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Switch;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart' hide decodeDataBlob;
import 'package:rfw_ui/rfw_ui.dart';

void main() {
  final Map<String, String> env = Platform.environment;

  testWidgets('render', (WidgetTester tester) async {
    final String? screenPath = env['RFW_SCREEN'];
    final String? outPath = env['RFW_OUT'];
    if (screenPath == null || outPath == null) {
      fail('Set RFW_SCREEN to the .rfwtxt file and RFW_OUT to the .png to write.');
    }
    final List<String> problems = <String>[];

    await tester.runAsync(() => _loadFonts(env['RFW_FONTS']));

    // ----------------------------------------------------------- the screen
    final String text = File(screenPath).readAsStringSync();
    final RemoteWidgetLibrary library;
    try {
      library = parseLibraryFile(text, sourceIdentifier: screenPath);
    } on Object catch (error) {
      _say('PROBLEM parse: $error');
      fail('$screenPath does not parse.');
    }
    final String root = env['RFW_ROOT'] ??
        (library.widgets.any((WidgetDeclaration w) => w.name == 'root') ? 'root' : library.widgets.first.name);

    // ------------------------------------------------------------ the theme
    final Brightness brightness = env['RFW_MODE'] == 'dark' ? Brightness.dark : Brightness.light;
    final TargetPlatform platform = env['RFW_PLATFORM'] == 'ios' ? TargetPlatform.iOS : TargetPlatform.android;
    // A style that names no font is drawn in the platform's on a phone, and
    // in a box-drawing test font here. So a theme that names none renders in
    // the platform's, by name: Roboto, or San Francisco's names (which are
    // Roboto too: San Francisco is not ours to ship).
    final String platformFont = platform == TargetPlatform.iOS ? '.SF Pro Text' : 'Roboto';
    ThemeData theme = ThemeData(brightness: brightness, fontFamily: platformFont);
    final String? themePath = env['RFW_THEME'];
    if (themePath != null) {
      final Map<String, Object?> doc = _readData(themePath);
      if (doc.containsKey('light') || doc.containsKey('dark') || doc.containsKey('shared')) {
        final Map<String, Object?> shared = <String, Object?>{...?(doc['shared'] as Map<String, Object?>?)};
        shared['fontFamily'] ??= platformFont;
        theme = UiThemeDocument.decode(<String, Object?>{...doc, 'shared': shared}).of(brightness);
        problems.addAll(UiThemeDocument.problems(doc).map((String p) => 'theme: $p is not a theme key'));
      } else {
        theme = decodeThemeData(<String, Object?>{'fontFamily': platformFont, ...doc}, brightness: brightness);
        problems.addAll(UiThemeDocument.problems(<String, Object?>{brightness.name: doc})
            .map((String p) => 'theme: ${p.substring(brightness.name.length + 1)} is not a theme key'));
      }
    }
    theme = theme.copyWith(platform: platform);

    // ------------------------------------------- what the catalog says is off
    problems.addAll(checkUiLibrary(library, text, theme: theme));

    // ------------------------------------------------------------- render it
    final List<String> size = (env['RFW_SIZE'] ?? '390x844').split('x');
    final Size logical = Size(double.parse(size[0]), double.parse(size[1]));
    final double scale = double.parse(env['RFW_SCALE'] ?? '2');
    tester.view.physicalSize = logical * scale;
    tester.view.devicePixelRatio = scale;
    addTearDown(tester.view.reset);

    final Runtime runtime = createUiRuntime()
      ..update(uiLibraryName, createUiWidgets())
      ..update(const LibraryName(<String>['core', 'widgets']), createCoreWidgets())
      ..update(const LibraryName(<String>['core', 'material']), createMaterialWidgets())
      ..update(const LibraryName(<String>['screen']), library);
    addTearDown(runtime.dispose);
    final DynamicContent data = DynamicContent(env['RFW_DATA'] == null ? const <String, Object?>{} : _readData(env['RFW_DATA']!));

    // A phone shows no keyboard focus ring: a test defaults to one.
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final List<String> built = <String>[];
    final FlutterExceptionHandler? was = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) => built.add(details.exceptionAsString().split('\n').first);
    final GlobalKey frame = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Builder(
            // A screen that is not a Scaffold of its own still gets the page
            // colour, as it would inside an app.
            builder: (BuildContext context) => Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: UiRemoteWidget(
                runtime: runtime,
                data: data,
                widget: FullyQualifiedWidgetName(const LibraryName(<String>['screen']), root),
                onEvent: (String name, DynamicMap args) => _say('event "$name" $args'),
              ),
            ),
          ),
        ),
      ),
    );
    // Time is advanced in steps rather than in one jump: an animation that
    // waits out a delay first (Animate's `delay`, a list's `stagger`) starts
    // on a timer, and a controller started by that timer only moves on the
    // frames that follow it. Twelve steps of 100 ms land every entrance
    // animation the kit can write. A repeating one is left wherever it is.
    for (int i = 0; i < 12; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (final String label in (env['RFW_TAP'] ?? '').split(',').map((String s) => s.trim()).where((String s) => s.isNotEmpty)) {
      final Finder target = find.text(label);
      if (target.evaluate().isEmpty) {
        problems.add('tap: no text "$label" on screen to tap');
        continue;
      }
      await tester.tap(target.first, warnIfMissed: false);
      await tester.pump();
      for (int i = 0; i < 8; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    FlutterError.onError = was;
    problems.addAll(built.toSet().map((String e) => 'build: $e'));
    if (find.byType(ErrorWidget).evaluate().isNotEmpty) {
      problems.add('build: an error box is on screen (an unresolved widget, or a builder that threw)');
    }

    final RenderRepaintBoundary boundary = frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ByteData? png = await tester.runAsync<ByteData?>(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: scale);
      final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes;
    });
    File(outPath)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());

    for (final String problem in problems) {
      _say('PROBLEM $problem');
    }
    _say('RENDERED $outPath (${logical.width.toInt()}x${logical.height.toInt()} @${scale}x, ${problems.length} problems)');
    // Whatever the screen left running -- an animation, a timer in a widget
    // -- is not this tool's to wait for.
    await tester.pumpWidget(const SizedBox());
    if (env['RFW_STRICT'] == '1') {
      expect(problems, isEmpty);
    }
  });
}

void _say(String line) => stdout.writeln(line);

Map<String, Object?> _readData(String path) {
  if (path.endsWith('.json')) {
    return (jsonDecode(File(path).readAsStringSync()) as Map<Object?, Object?>).cast<String, Object?>();
  }
  if (path.endsWith('.rfw') || path.endsWith('.rfwdata')) {
    return decodeDataBlob(File(path).readAsBytesSync()) as Map<String, Object?>;
  }
  return parseDataFile(File(path).readAsStringSync());
}

/// Roboto, Material's icons and Cupertino's, from the Flutter SDK and the pub
/// cache, under the families Flutter asks for -- and Roboto under the names
/// Cupertino asks for too, since San Francisco is not ours to ship. Without
/// this a test renders every glyph as a box.
Future<void> _loadFonts(String? extra) async {
  final String flutter = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final Directory material = Directory('$flutter/bin/cache/artifacts/material_fonts');
  Future<void> family(String name, Iterable<File> files) async {
    final FontLoader loader = FontLoader(name);
    for (final File file in files) {
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  if (material.existsSync()) {
    final List<File> roboto = material
        .listSync()
        .whereType<File>()
        .where((File f) => RegExp(r'/Roboto-[A-Za-z]+\.ttf$').hasMatch(f.path))
        .toList();
    for (final String name in <String>['Roboto', '.SF Pro Text', '.SF Pro Display', '.SF UI Text', '.SF UI Display', 'CupertinoSystemText', 'CupertinoSystemDisplay']) {
      await family(name, roboto);
    }
    await family('MaterialIcons', <File>[File('${material.path}/MaterialIcons-Regular.otf')]);
  } else {
    _say('PROBLEM fonts: no ${material.path}; text will render as boxes');
  }
  final Directory pub = Directory('${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}/hosted/pub.dev');
  final List<Directory> cupertino = pub.existsSync()
      ? (pub.listSync().whereType<Directory>().where((Directory d) => d.path.contains('cupertino_icons-')).toList()
          ..sort((Directory a, Directory b) => a.path.compareTo(b.path)))
      : <Directory>[];
  if (cupertino.isNotEmpty) {
    await family('packages/cupertino_icons/CupertinoIcons', <File>[File('${cupertino.last.path}/assets/CupertinoIcons.ttf')]);
  }
  if (extra != null) {
    final Map<String, List<File>> byFamily = <String, List<File>>{};
    for (final File f in Directory(extra).listSync().whereType<File>().where((File f) => RegExp(r'\.(ttf|otf)$').hasMatch(f.path))) {
      final String name = f.uri.pathSegments.last.split(RegExp(r'[-_.]')).first;
      (byFamily[name] ??= <File>[]).add(f);
    }
    for (final MapEntry<String, List<File>> e in byFamily.entries) {
      await family(e.key, e.value);
    }
  }
}
