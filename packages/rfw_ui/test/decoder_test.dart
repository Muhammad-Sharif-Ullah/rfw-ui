import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart' show DataSource, HandlerGenerator;
import 'package:rfw_ui/rfw_ui.dart';

/// Decoding is tested over a [MapSource], which is the same [DataSource] a
/// theme document is read through: what a remote widget's arguments resolve
/// to and what a map holds are, to a decoder, the same thing.
void main() {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
  final TextTheme text = Typography.material2021().black;
  const UiTokens tokens = UiTokens(
    colors: <String, Color>{'success': Color(0xFF00AA00)},
    textStyles: <String, TextStyle>{'hero': TextStyle(fontSize: 40)},
  );
  final UiResolver resolve = UiResolver(colorScheme: scheme, textTheme: text, tokens: tokens);

  UiDecoder decoder(Map<String, Object?> values) => UiDecoder(MapSource(values), resolve);

  group('numbers', () {
    test('an int is a double wherever a double is asked for', () {
      // rfw's own decoders read `16` as nothing, because the text format parses
      // it as an int and `v<double>` will not widen. Authors write `16`.
      expect(decoder(<String, Object?>{'w': 16}).number(<Object>['w']), 16.0);
      expect(decoder(<String, Object?>{'w': 16.5}).number(<Object>['w']), 16.5);
    });

    test('a spacing token is a number', () {
      expect(decoder(<String, Object?>{'gap': 'md'}).spacing(<Object>['gap']), 16.0);
      expect(decoder(<String, Object?>{'gap': 'nope'}).spacing(<Object>['gap']), isNull);
    });
  });

  group('colors', () {
    test('an ARGB int, as rfw has it', () {
      expect(decoder(<String, Object?>{'c': 0xFF112233}).color(<Object>['c']), const Color(0xFF112233));
    });

    test('a role of the colour scheme, by name', () {
      expect(decoder(<String, Object?>{'c': 'primary'}).color(<Object>['c']), scheme.primary);
      expect(decoder(<String, Object?>{'c': 'onSurfaceVariant'}).color(<Object>['c']), scheme.onSurfaceVariant);
      expect(decoder(<String, Object?>{'c': 'surfaceContainerHighest'}).color(<Object>['c']), scheme.surfaceContainerHighest);
    });

    test('a role with an opacity, in percent', () {
      final Color? c = decoder(<String, Object?>{'c': 'primary/50'}).color(<Object>['c']);
      expect(c, scheme.primary.withValues(alpha: 0.5));
    });

    test('a custom colour from the tokens', () {
      expect(decoder(<String, Object?>{'c': 'success'}).color(<Object>['c']), const Color(0xFF00AA00));
    });

    test('hex strings, with and without alpha', () {
      expect(decoder(<String, Object?>{'c': '#112233'}).color(<Object>['c']), const Color(0xFF112233));
      expect(decoder(<String, Object?>{'c': '#80112233'}).color(<Object>['c']), const Color(0x80112233));
    });

    test('names that are not colours are nothing, not black', () {
      expect(decoder(<String, Object?>{'c': 'primery'}).color(<Object>['c']), isNull);
      expect(decoder(<String, Object?>{'c': '#12'}).color(<Object>['c']), isNull);
    });
  });

  group('text styles', () {
    test('a name is a style of the text theme', () {
      expect(decoder(<String, Object?>{'s': 'titleLarge'}).textStyle(<Object>['s']), text.titleLarge);
    });

    test('`base` plus overrides is copyWith', () {
      final TextStyle? style = decoder(<String, Object?>{
        's': <String, Object?>{'base': 'titleLarge', 'fontWeight': 'bold', 'letterSpacing': -1, 'color': 'primary'},
      }).textStyle(<Object>['s']);
      expect(style, text.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: -1, color: scheme.primary));
    });

    test('a style the theme document named is a base too', () {
      final TextStyle? style = decoder(<String, Object?>{
        's': <String, Object?>{'base': 'hero', 'fontWeight': 600},
      }).textStyle(<Object>['s']);
      expect(style!.fontSize, 40);
      expect(style.fontWeight, FontWeight.w600);
    });

    test('a map without a base is a plain style, as in rfw', () {
      final TextStyle? style = decoder(<String, Object?>{
        's': <String, Object?>{'fontSize': 38, 'fontWeight': 'bold', 'color': 0xFF17141D},
      }).textStyle(<Object>['s']);
      expect(style, const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF17141D)));
    });

    test('an unknown name is nothing', () {
      expect(decoder(<String, Object?>{'s': 'titleHuge'}).textStyle(<Object>['s']), isNull);
    });

    // A source that can list a map's keys is asked after those alone: the
    // other dozen a style may have are not read at all.
    final Map<String, Object?> written = <String, Object?>{
      's': <String, Object?>{'base': 'bodySmall', 'fontSize': 14, 'color': 'primary', 'decoration': 'underline'},
    };

    test('a style map is read for the keys it was written with, when the source can list them', () {
      final _Counting source = _Counting(MapSource(written), listsKeys: true);
      final TextStyle? style = UiDecoder(source, resolve).textStyle(<Object>['s']);
      expect(style?.fontSize, 14);
      expect(source.reads, lessThan(20));
    });

    test('and is the same style when the source cannot', () {
      final _Counting listing = _Counting(MapSource(written), listsKeys: true);
      final _Counting not = _Counting(MapSource(written), listsKeys: false);
      expect(UiDecoder(listing, resolve).textStyle(<Object>['s']), UiDecoder(not, resolve).textStyle(<Object>['s']));
      expect(not.reads, greaterThan(listing.reads));
    });
  });

  group('geometry', () {
    test('edge insets: a number, a token, a list or a map', () {
      expect(decoder(<String, Object?>{'p': 8}).edgeInsets(<Object>['p']), const EdgeInsets.all(8));
      expect(decoder(<String, Object?>{'p': 'lg'}).edgeInsets(<Object>['p']), const EdgeInsets.all(24));
      expect(
        decoder(<String, Object?>{'p': <Object?>[1, 2]}).edgeInsets(<Object>['p']),
        const EdgeInsetsDirectional.fromSTEB(1, 2, 1, 2),
      );
      expect(
        decoder(<String, Object?>{'p': <String, Object?>{'horizontal': 'md', 'top': 4}}).edgeInsets(<Object>['p']),
        const EdgeInsetsDirectional.only(start: 16, end: 16, top: 4),
      );
    });

    test('border radius: a number, a token or a map of corners', () {
      expect(decoder(<String, Object?>{'r': 12}).borderRadius(<Object>['r']), BorderRadius.circular(12));
      expect(decoder(<String, Object?>{'r': 'md'}).borderRadius(<Object>['r']), BorderRadius.circular(8));
      expect(
        decoder(<String, Object?>{'r': <String, Object?>{'top': 'lg'}}).borderRadius(<Object>['r']),
        const BorderRadiusDirectional.vertical(top: Radius.circular(16)),
      );
    });

    test("border radius still reads rfw's own list of radii", () {
      expect(
        decoder(<String, Object?>{'r': <Object?>[<String, Object?>{'x': 4.0}]}).borderRadius(<Object>['r']),
        const BorderRadiusDirectional.all(Radius.circular(4)),
      );
    });

    test('alignment: a name or rfw map', () {
      expect(decoder(<String, Object?>{'a': 'bottomRight'}).alignment(<Object>['a']), Alignment.bottomRight);
      expect(decoder(<String, Object?>{'a': 'centerStart'}).alignment(<Object>['a']), AlignmentDirectional.centerStart);
      expect(decoder(<String, Object?>{'a': <String, Object?>{'x': 0, 'y': 1}}).alignment(<Object>['a']), Alignment.bottomCenter);
    });

    test('a size: a map, a pair or one number for both', () {
      expect(decoder(<String, Object?>{'s': <String, Object?>{'width': 10, 'height': 20}}).size(<Object>['s']), const Size(10, 20));
      expect(decoder(<String, Object?>{'s': <Object?>[10, 20]}).size(<Object>['s']), const Size(10, 20));
      expect(decoder(<String, Object?>{'s': 48}).size(<Object>['s']), const Size(48, 48));
    });
  });

  group('borders, decorations and shapes', () {
    test('a border side takes a colour token', () {
      expect(
        decoder(<String, Object?>{'b': <String, Object?>{'color': 'outline', 'width': 2}}).borderSide(<Object>['b']),
        BorderSide(color: scheme.outline, width: 2),
      );
    });

    test('a box border: one side for all, or a map of sides', () {
      expect(
        decoder(<String, Object?>{'b': <String, Object?>{'color': 'outline'}}).border(<Object>['b']),
        Border.all(color: scheme.outline),
      );
      expect(
        decoder(<String, Object?>{
          'b': <String, Object?>{'bottom': <String, Object?>{'color': 'primary', 'width': 2}},
        }).border(<Object>['b']),
        Border(bottom: BorderSide(color: scheme.primary, width: 2)),
      );
    });

    test('a decoration is a box unless it says otherwise', () {
      final Decoration? d = decoder(<String, Object?>{
        'd': <String, Object?>{
          'color': 'surfaceContainer',
          'borderRadius': 'lg',
          'boxShadow': <Object?>[<String, Object?>{'color': 'shadow/20', 'blurRadius': 8, 'offset': <String, Object?>{'x': 0, 'y': 2}}],
        },
      }).decoration(<Object>['d']);
      expect(
        d,
        BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(color: scheme.shadow.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
      );
    });

    test('a gradient takes colour tokens', () {
      final Gradient? g = decoder(<String, Object?>{
        'g': <String, Object?>{'type': 'linear', 'colors': <Object?>['primary', 'tertiary'], 'begin': 'topLeft', 'end': 'bottomRight'},
      }).gradient(<Object>['g']);
      expect(g, LinearGradient(colors: <Color>[scheme.primary, scheme.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight));
    });

    test('a shape: a name, or a map with a radius and side', () {
      expect(decoder(<String, Object?>{'s': 'stadium'}).shape(<Object>['s']), const StadiumBorder());
      expect(decoder(<String, Object?>{'s': 'circle'}).shape(<Object>['s']), const CircleBorder());
      expect(
        decoder(<String, Object?>{'s': <String, Object?>{'type': 'rounded', 'borderRadius': 'md', 'side': <String, Object?>{'color': 'outline'}}}).shape(<Object>['s']),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: scheme.outline)),
      );
      // A bare number is the commonest case: a rounded rectangle of that radius.
      expect(decoder(<String, Object?>{'s': 12}).shape(<Object>['s']), RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
    });
  });

  group('state properties', () {
    test('one value is the value in every state', () {
      final WidgetStateProperty<Color?>? p = decoder(<String, Object?>{'c': 'primary'}).stateColor(<Object>['c']);
      expect(p!.resolve(<WidgetState>{}), scheme.primary);
      expect(p.resolve(<WidgetState>{WidgetState.disabled}), scheme.primary);
    });

    test('a map picks by state, disabled first', () {
      final WidgetStateProperty<Color?>? p = decoder(<String, Object?>{
        'c': <String, Object?>{'default': 'primary', 'selected': 'tertiary', 'disabled': 'outline'},
      }).stateColor(<Object>['c']);
      expect(p!.resolve(<WidgetState>{}), scheme.primary);
      expect(p.resolve(<WidgetState>{WidgetState.selected}), scheme.tertiary);
      expect(p.resolve(<WidgetState>{WidgetState.selected, WidgetState.disabled}), scheme.outline);
    });

    test('a button style reads colours, padding and shape', () {
      final ButtonStyle? style = decoder(<String, Object?>{
        'b': <String, Object?>{
          'backgroundColor': 'primary',
          'foregroundColor': 'onPrimary',
          'padding': <String, Object?>{'horizontal': 'lg', 'vertical': 'sm'},
          'shape': 'stadium',
          'minimumSize': <Object?>[64, 48],
          'textStyle': 'labelLarge',
        },
      }).buttonStyle(<Object>['b']);
      expect(style!.backgroundColor!.resolve(<WidgetState>{}), scheme.primary);
      expect(style.foregroundColor!.resolve(<WidgetState>{}), scheme.onPrimary);
      expect(style.padding!.resolve(<WidgetState>{}), const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 8));
      expect(style.shape!.resolve(<WidgetState>{}), const StadiumBorder());
      expect(style.minimumSize!.resolve(<WidgetState>{}), const Size(64, 48));
      expect(style.textStyle!.resolve(<WidgetState>{}), text.labelLarge);
    });
  });

  group('icons', () {
    test('a Material icon by name', () {
      expect(decoder(<String, Object?>{'i': 'home'}).icon(<Object>['i']), Icons.home);
      expect(decoder(<String, Object?>{'i': 'favorite_border'}).icon(<Object>['i']), Icons.favorite_border);
    });

    test('a Cupertino icon by prefixed name', () {
      expect(decoder(<String, Object?>{'i': 'cupertino.heart_fill'}).icon(<Object>['i']), CupertinoIcons.heart_fill);
    });

    test("rfw's own icon map still works", () {
      expect(
        decoder(<String, Object?>{'i': <String, Object?>{'icon': 0xe318, 'fontFamily': 'MaterialIcons'}}).icon(<Object>['i']),
        const IconData(0xe318, fontFamily: 'MaterialIcons'),
      );
    });
  });

  group('enums and durations', () {
    test('an enum by its name', () {
      expect(decoder(<String, Object?>{'a': 'spaceBetween'}).enumValue(MainAxisAlignment.values, <Object>['a']), MainAxisAlignment.spaceBetween);
      expect(decoder(<String, Object?>{'a': 'nope'}).enumValue(MainAxisAlignment.values, <Object>['a']), isNull);
    });

    test('a duration in milliseconds', () {
      expect(decoder(<String, Object?>{'d': 250}).duration(<Object>['d']), const Duration(milliseconds: 250));
    });
  });

  test('a button\'s text style that names no font takes the theme\'s button font', () {
    final ThemeData theme = ThemeData(fontFamily: 'Inter');
    final UiDecoder d = UiDecoder(
      MapSource(<String, Object?>{
        'plain': <String, Object?>{'textStyle': <String, Object?>{'fontSize': 15}},
        'named': <String, Object?>{'textStyle': <String, Object?>{'fontSize': 15, 'fontFamily': 'Mono'}},
      }),
      UiResolver(colorScheme: theme.colorScheme, textTheme: theme.textTheme, theme: theme),
    );
    expect(d.buttonStyle(<Object>['plain'])!.textStyle!.resolve(<WidgetState>{})!.fontFamily, 'Inter');
    expect(d.buttonStyle(<Object>['named'])!.textStyle!.resolve(<WidgetState>{})!.fontFamily, 'Mono');
    // A Text's own style still inherits from the text around it.
    expect(d.textStyle(<Object>['plain', 'textStyle'])!.fontFamily, isNull);
  });

  testWidgets('UiArgs reads tokens through a resolver it is given, rather than the theme in scope', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (BuildContext c) => SizedBox(key: ObjectKey(context = c)))));
    final UiArgs given = UiArgs(context, const MapSource(<String, Object?>{'c': 'primary'}), resolve: resolve);
    expect(given.color(<Object>['c']), scheme.primary);
    expect(identical(given.resolve, resolve), isTrue);
    final UiArgs found = UiArgs(context, const MapSource(<String, Object?>{'c': 'primary'}));
    expect(found.color(<Object>['c']), Theme.of(context).colorScheme.primary);
  });
}

/// [MapSource], counting the values asked for, and listing a map's keys only
/// when told to.
class _Counting implements DataSource, UiKeysSource {
  _Counting(this.inner, {required this.listsKeys});

  final MapSource inner;
  final bool listsKeys;
  int reads = 0;

  @override
  Iterable<String>? keysAt(List<Object> key) => listsKeys ? inner.keysAt(key) : null;

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    reads += 1;
    return inner.v<T>(argsKey);
  }

  @override
  bool isList(List<Object> argsKey) => inner.isList(argsKey);

  @override
  bool isMap(List<Object> argsKey) => inner.isMap(argsKey);

  @override
  int length(List<Object> argsKey) => inner.length(argsKey);

  @override
  Widget child(List<Object> argsKey) => inner.child(argsKey);

  @override
  Widget? optionalChild(List<Object> argsKey) => inner.optionalChild(argsKey);

  @override
  List<Widget> childList(List<Object> argsKey) => inner.childList(argsKey);

  @override
  Widget builder(List<Object> argsKey, Map<String, Object?> builderArg) => inner.builder(argsKey, builderArg);

  @override
  Widget? optionalBuilder(List<Object> argsKey, Map<String, Object?> builderArg) => inner.optionalBuilder(argsKey, builderArg);

  @override
  VoidCallback? voidHandler(List<Object> argsKey, [Map<String, Object?>? extraArguments]) => inner.voidHandler(argsKey, extraArguments);

  @override
  T? handler<T extends Function>(List<Object> argsKey, HandlerGenerator<T> generator) => inner.handler<T>(argsKey, generator);
}
