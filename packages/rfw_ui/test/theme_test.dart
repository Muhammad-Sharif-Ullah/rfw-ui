import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseDataFile, parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// A theme document in rfw's own text format, as a console would publish it.
const String _document = '''
{
  name: "Acme",
  mode: "dark",
  shared: {
    fontFamily: "Inter",
    textTheme: {
      displaySmall: { fontWeight: "bold", letterSpacing: -1 },
      titleLarge: { base: "headlineSmall", fontSize: 21 },
    },
    tokens: {
      spacing: { md: 20 },
      colors: { success: 0xFF1E8E3E },
      textStyles: { hero: { base: "displaySmall", color: "primary" } },
    },
    appBarTheme: { backgroundColor: "surfaceContainer", centerTitle: true },
    filledButtonTheme: { style: { shape: "stadium", padding: { horizontal: "lg", vertical: "md" } } },
    inputDecorationTheme: { filled: true, border: { type: "outline", borderRadius: "md" } },
  },
  light: { colorScheme: { seed: 0xFF2F6BFF } },
  dark: {
    colorScheme: { seed: 0xFF2F6BFF, surface: "#0A0A0C" },
    scaffoldBackgroundColor: "surface",
  },
}
''';

void main() {
  final UiThemeDocument doc = UiThemeDocument.decode(parseDataFile(_document));

  test('one document is a light theme, a dark theme and a mode', () {
    expect(doc.name, 'Acme');
    expect(doc.mode, ThemeMode.dark);
    expect(doc.light.brightness, Brightness.light);
    expect(doc.dark.brightness, Brightness.dark);
    // One seed, two schemes: Material grows each brightness its own tones.
    expect(doc.light.colorScheme.primary, isNot(doc.dark.colorScheme.primary));
    expect(
      doc.light.colorScheme.primary,
      ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)).primary,
    );
  });

  test('shared applies to both; a brightness overrides its own', () {
    expect(doc.light.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(doc.dark.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(doc.dark.colorScheme.surface, const Color(0xFF0A0A0C));
    expect(doc.light.colorScheme.surface, isNot(const Color(0xFF0A0A0C)));
    // A colour may name a role of the scheme it sits beside.
    expect(doc.dark.scaffoldBackgroundColor, const Color(0xFF0A0A0C));
  });

  // Sizes and line heights are not in ThemeData.textTheme at all: Theme
  // merges them in per locale (ThemeData.localize). So these are read where an
  // app reads them -- through Theme.of -- not off the decoded ThemeData.
  final TextTheme geometry = Typography.material2021().englishLike;

  testWidgets('a text style without a base is its own default, changed', (
    WidgetTester tester,
  ) async {
    final TextTheme seen = await _textThemeIn(tester, doc.light);
    expect(seen.displaySmall!.fontSize, geometry.displaySmall!.fontSize);
    expect(seen.displaySmall!.fontWeight, FontWeight.bold);
    expect(seen.displaySmall!.letterSpacing, -1);
    expect(seen.displaySmall!.fontFamily, 'Inter');
  });

  testWidgets('a text style with a base starts from that style', (
    WidgetTester tester,
  ) async {
    final TextTheme seen = await _textThemeIn(tester, doc.light);
    expect(seen.titleLarge!.fontSize, 21);
    // headlineSmall's line height, not titleLarge's own.
    expect(seen.titleLarge!.height, geometry.headlineSmall!.height);
    expect(seen.titleLarge!.fontWeight, geometry.headlineSmall!.fontWeight);
  });

  testWidgets('a named style keeps its base\'s size where it is used', (
    WidgetTester tester,
  ) async {
    late TextStyle hero;
    await tester.pumpWidget(
      MaterialApp(
        theme: doc.light,
        home: Builder(
          builder: (BuildContext context) {
            hero = UiResolver.of(context).textStyle('hero')!;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(hero.fontSize, geometry.displaySmall!.fontSize);
    expect(hero.fontWeight, FontWeight.bold);
    expect(hero.color, doc.light.colorScheme.primary);
  });

  test('component themes read tokens of the theme they are in', () {
    expect(
      doc.light.appBarTheme.backgroundColor,
      doc.light.colorScheme.surfaceContainer,
    );
    expect(
      doc.dark.appBarTheme.backgroundColor,
      doc.dark.colorScheme.surfaceContainer,
    );
    expect(doc.light.appBarTheme.centerTitle, isTrue);
    final ButtonStyle style = doc.light.filledButtonTheme.style!;
    expect(style.shape!.resolve(<WidgetState>{}), const StadiumBorder());
    expect(
      style.padding!.resolve(<WidgetState>{}),
      const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 20),
    );
    final InputDecorationThemeData input = doc.light.inputDecorationTheme;
    expect(input.filled, isTrue);
    expect(input.border, isA<OutlineInputBorder>());
  });

  test('tokens merge over the defaults and travel as a ThemeExtension', () {
    final UiTokens tokens = doc.light.extension<UiTokens>()!;
    expect(tokens.spacing['md'], 20);
    expect(tokens.spacing['sm'], UiTokens.defaultSpacing['sm']);
    expect(tokens.colors['success'], const Color(0xFF1E8E3E));
    // A named style is kept as its base and its overrides, and resolved
    // where it is used, so the base brings the locale's sizes with it.
    expect(tokens.textStyleBases['hero'], 'displaySmall');
    expect(tokens.textStyles['hero']!.color, doc.light.colorScheme.primary);
    expect(
      doc.dark.extension<UiTokens>()!.textStyles['hero']!.color,
      doc.dark.colorScheme.primary,
    );
  });

  test('a document with no brightness sections is the same theme in both', () {
    final UiThemeDocument flat = UiThemeDocument.decode(
      parseDataFile(
        '{ colorScheme: { seed: 0xFF00696E }, fontFamily: "Inter" }',
      ),
    );
    expect(flat.light.brightness, Brightness.light);
    expect(flat.dark.brightness, Brightness.dark);
    expect(flat.dark.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(flat.mode, ThemeMode.system);
  });

  test('problems names the keys the decoder does not know', () {
    final List<String> problems = UiThemeDocument.problems(
      parseDataFile('''
      {
        light: { appBarTheme: { backgroundColour: 0xFF000000 }, colourScheme: {} },
        shared: { fontFamily: "Inter" },
        theme: {},
      }
    '''),
    );
    expect(
      problems,
      unorderedEquals(<String>[
        'theme',
        'light.appBarTheme.backgroundColour',
        'light.colourScheme',
      ]),
    );
    expect(UiThemeDocument.problems(parseDataFile(_document)), isEmpty);
  });

  test('every component theme reads exactly the keys it lists', () {
    final List<String> wrong = <String>[];
    for (final MapEntry<String, ThemeComponent> entry
        in themeComponents.entries) {
      final _Recorder recorder = _Recorder(entry.key);
      entry.value.build(
        UiDecoder(
          recorder,
          UiResolver(
            colorScheme: const ColorScheme.light(),
            textTheme: const TextTheme(),
          ),
        ),
        <Object>[entry.key],
      );
      final Set<String> listed = entry.value.keys.toSet();
      final Set<String> unlisted = recorder.read.difference(listed);
      final Set<String> unread = listed.difference(recorder.read);
      if (unlisted.isNotEmpty) {
        wrong.add(
          '${entry.key} reads ${unlisted.join(', ')} but does not list it',
        );
      }
      if (unread.isNotEmpty) {
        wrong.add('${entry.key} lists ${unread.join(', ')} but never reads it');
      }
    }
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  testWidgets('a remote Text reaches the theme document\'s named style', (
    WidgetTester tester,
  ) async {
    final Runtime runtime = createUiRuntime()
      ..update(uiLibraryName, createUiWidgets())
      ..update(
        const LibraryName(<String>['main']),
        parseLibraryFile('''
        import ui;
        widget root = Column(children: [
          Text(text: "Welcome back.", style: "hero"),
          Text(text: "Tighter", style: { base: "hero", letterSpacing: -2 }),
          Padding(padding: "md", child: SizedBox(width: 1, height: 1)),
        ]);
      '''),
      );
    addTearDown(runtime.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: doc.light,
        home: Scaffold(
          body: RemoteWidget(
            runtime: runtime,
            data: DynamicContent(),
            widget: const FullyQualifiedWidgetName(
              LibraryName(<String>['main']),
              'root',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Text welcome = tester.widget<Text>(find.text('Welcome back.'));
    expect(welcome.style!.fontSize, geometry.displaySmall!.fontSize);
    expect(welcome.style!.fontWeight, FontWeight.bold);
    expect(welcome.style!.color, doc.light.colorScheme.primary);
    final Text tighter = tester.widget<Text>(find.text('Tighter'));
    expect(tighter.style!.letterSpacing, -2);
    expect(tighter.style!.fontSize, geometry.displaySmall!.fontSize);
    expect(tighter.style!.color, doc.light.colorScheme.primary);
    final Padding padding = tester.widget<Padding>(
      find
          .ancestor(
            of: find.byType(SizedBox).last,
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, const EdgeInsets.all(20));
  });

  testWidgets(
    'a ScopedTheme reaches Cupertino widgets too, not only Material ones',
    (WidgetTester tester) async {
      // Flutter's own Theme reuses any CupertinoTheme above it, so under an app
      // in its own theme, Cupertino widgets would keep the app's colours.
      late CupertinoThemeData cupertino;
      late ThemeData material;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8BFF3C),
              brightness: Brightness.dark,
            ),
          ),
          home: ScopedTheme(
            data: doc.light,
            child: Builder(
              builder: (BuildContext context) {
                cupertino = CupertinoTheme.of(context);
                material = Theme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(material.colorScheme.primary, doc.light.colorScheme.primary);
      expect(cupertino.primaryColor, doc.light.colorScheme.primary);
      expect(cupertino.brightness, Brightness.light);
    },
  );

  testWidgets('the controller switches what the app shows', (
    WidgetTester tester,
  ) async {
    final UiThemeController controller = UiThemeController(
      document: doc,
      mode: ThemeMode.light,
    );
    addTearDown(controller.dispose);
    late Brightness seen;
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          theme: controller.light,
          darkTheme: controller.dark,
          themeMode: controller.mode,
          themeAnimationDuration: Duration.zero,
          home: Builder(
            builder: (BuildContext context) {
              seen = Theme.of(context).brightness;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen, Brightness.light);
    controller.toggle(seen);
    await tester.pumpAndSettle();
    expect(seen, Brightness.dark);
    controller.load(UiThemeDocument.decode(parseDataFile('{ mode: "light" }')));
    await tester.pumpAndSettle();
    expect(
      seen,
      Brightness.dark,
      reason: 'a new document does not undo a choice',
    );
  });

  // A role named by another is this document's, not the seed's: change the
  // primary and everything that names it follows.
  test('a colour role may name another role of the same document', () {
    final ColorScheme s = decodeThemeData(<String, Object?>{
      'colorScheme': <String, Object?>{
        'seed': 0xFF6750A4,
        'primary': 0xFF112233,
        'surfaceTint': 'primary',
        'primaryFixed': 'primary/50',
        'inversePrimary': '#FF445566',
      },
    }).colorScheme;
    expect(s.surfaceTint, const Color(0xFF112233));
    expect(s.primaryFixed, const Color(0xFF112233).withValues(alpha: 0.5));
    expect(s.inversePrimary, const Color(0xFF445566));
  });

  // "The font every style uses unless it names another": a button's text
  // style that names none takes the theme's, where ThemeData alone would
  // leave it to the platform.
  test('a component theme\'s text style takes the theme\'s font', () {
    final ThemeData theme = decodeThemeData(<String, Object?>{
      'fontFamily': 'Inter',
      'filledButtonTheme': <String, Object?>{
        'style': <String, Object?>{
          'textStyle': <String, Object?>{'fontSize': 16},
        },
      },
      'chipTheme': <String, Object?>{
        'labelStyle': <String, Object?>{'fontFamily': 'Mono'},
      },
    });
    expect(
      theme.filledButtonTheme.style!.textStyle!
          .resolve(<WidgetState>{})!
          .fontFamily,
      'Inter',
    );
    expect(theme.chipTheme.labelStyle!.fontFamily, 'Mono');
    // With no font in the theme, a button's style still falls back to the
    // base theme's button font rather than the platform's: a button style
    // replaces its default instead of merging with it.
    final ThemeData plain = decodeThemeData(<String, Object?>{
      'filledButtonTheme': <String, Object?>{
        'style': <String, Object?>{
          'textStyle': <String, Object?>{'fontSize': 16},
        },
      },
    });
    expect(
      plain.filledButtonTheme.style!.textStyle!
          .resolve(<WidgetState>{})!
          .fontFamily,
      ThemeData().textTheme.labelLarge?.fontFamily,
    );
  });
}

/// The text theme [theme] gives a widget, sizes and all.
Future<TextTheme> _textThemeIn(WidgetTester tester, ThemeData theme) async {
  late TextTheme seen;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (BuildContext context) {
          seen = Theme.of(context).textTheme;
          return const SizedBox();
        },
      ),
    ),
  );
  return seen;
}

/// A [MapSource] that notes the keys asked for one level under [component].
class _Recorder extends MapSource {
  _Recorder(this.component)
    : super(<String, Object?>{component: <String, Object?>{}});

  final String component;
  final Set<String> read = <String>{};

  void _note(List<Object> key) {
    if (key.length > 1 && key.first == component && key[1] is String) {
      read.add(key[1] as String);
    }
  }

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    _note(argsKey);
    return super.v<T>(argsKey);
  }

  @override
  bool isMap(List<Object> argsKey) {
    _note(argsKey);
    return super.isMap(argsKey);
  }

  @override
  bool isList(List<Object> argsKey) {
    _note(argsKey);
    return super.isList(argsKey);
  }
}
