import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// What `Animate` costs per frame, and what it frees.
///
/// The one claim the whole design rests on is that an animated frame paints a
/// layer and rebuilds nothing: the remote subtree under an `Animate` is built
/// once, whatever the animation does. Every rfw argument is a hash-map lookup
/// at build time (doc/why-slower.md), so an animation that rebuilt its child
/// would be the slowest thing in the kit. `_builds` is how that is held.
const LibraryName _main = LibraryName(<String>['main']);
const LibraryName _test = LibraryName(<String>['test']);

/// How many times each `Count(id: ...)` has built, as in
/// test/runtime/rebuild_test.dart.
final Map<String, int> _builds = <String, int>{};

final LocalWidgetLibrary _testWidgets = LocalWidgetLibrary(<String, LocalWidgetBuilder>{
  'Count': (BuildContext context, DataSource source) {
    final String id = source.v<String>(<Object>['id']) ?? '';
    _builds[id] = (_builds[id] ?? 0) + 1;
    return SizedBox(height: 80, child: Text(source.v<String>(<Object>['text']) ?? ''));
  },
});

/// Every event the screen fired, for the tests that watch `onEnd`.
final List<(String, DynamicMap)> _events = <(String, DynamicMap)>[];

Future<void> _mount(
  WidgetTester tester,
  String source, {
  DynamicContent? data,
  bool disableAnimations = false,
}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_test, _testWidgets)
    ..update(_main, parseLibraryFile('import ui; import test;\n$source'));
  addTearDown(runtime.dispose);
  final Widget remote = UiRemoteWidget(
    runtime: runtime,
    data: data ?? DynamicContent(),
    widget: const FullyQualifiedWidgetName(_main, 'root'),
    onEvent: (String name, DynamicMap args) => _events.add((name, args)),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: disableAnimations ? MediaQuery.of(context).copyWith(disableAnimations: true) : MediaQuery.of(context),
            child: remote,
          ),
        ),
      ),
    ),
  );
}

/// Only what the remote screen built: the page route's own transitions sit
/// above `UiRemoteWidget` and are not the kit's.
Finder _inScreen(Type type) => find.descendant(of: find.byType(UiRemoteWidget), matching: find.byType(type));

List<Object?> _rows(int n) => <Object?>[for (int i = 0; i < n; i += 1) <String, Object?>{'id': 'r$i'}];

void main() {
  setUp(() {
    _builds.clear();
    _events.clear();
  });

  testWidgets('a running Animate builds its child once, however many frames pass', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = Animate(
        duration: 600,
        effects: [{ effect: .fade, from: 0, to: 1 }, { effect: .scale, from: 0.9, to: 1 }],
        child: Count(id: "a", text: "hello"),
      );
    ''');
    expect(_builds['a'], 1);
    expect(_inScreen(FadeTransition), findsOneWidget);
    expect(_inScreen(ScaleTransition), findsOneWidget);
    for (int i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_builds['a'], 1, reason: 'the remote subtree must be built once, whatever the animation does');
  });

  testWidgets('the first effect is the outermost', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = Animate(
        effects: [{ effect: .fade }, { effect: .scale }],
        child: Text(text: "x"),
      );
    ''');
    expect(
      find.descendant(of: _inScreen(FadeTransition), matching: find.byType(ScaleTransition)),
      findsOneWidget,
    );
  });

  testWidgets('Animate with no effects renders its child', (WidgetTester tester) async {
    await _mount(tester, 'widget root = Animate(child: Text(text: "plain"));');
    expect(find.text('plain'), findsOneWidget);
    expect(_inScreen(FadeTransition), findsNothing);
  });

  testWidgets('Animate with no child renders nothing and does not throw', (WidgetTester tester) async {
    await _mount(tester, 'widget root = Animate(effects: [{ effect: .fade }]);');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fade runs from its from to its to', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = Animate(
        duration: 1000,
        curve: .linear,
        effects: [{ effect: .fade, from: 0, to: 1 }],
        child: Text(text: "x"),
      );
    ''');
    double opacity() => tester.widget<FadeTransition>(_inScreen(FadeTransition)).opacity.value;
    expect(opacity(), closeTo(0, 0.001));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), closeTo(0.5, 0.02));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), closeTo(1, 0.001));
  });

  testWidgets('a delay holds the animation at its start', (WidgetTester tester) async {
    await _mount(tester, '''
      widget root = Animate(
        duration: 200,
        delay: 300,
        curve: .linear,
        effects: [{ effect: .fade, from: 0, to: 1 }],
        child: Text(text: "x"),
      );
    ''');
    double opacity() => tester.widget<FadeTransition>(_inScreen(FadeTransition)).opacity.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), 0, reason: 'still waiting out the delay');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), 1);
  });

  testWidgets('an Animate scrolled out of a list disposes its controller', (WidgetTester tester) async {
    // The leak tracker in test/flutter_test_config.dart fails this test if any
    // AnimationController outlives the row that made it.
    final DynamicContent data = DynamicContent(<String, Object?>{'rows': _rows(60)});
    await _mount(tester, '''
      widget Pulse = Animate(
        duration: 400,
        repeat: -1,
        reverse: true,
        effects: [{ effect: .fade, from: 0.2, to: 1 }],
        child: SizedBox(height: 80, child: Text(text: args.id)),
      );
      widget root = ListView(children: [...for r in data.rows: Pulse(id: r.id)]);
    ''', data: data);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('r0'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -2000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('r0'), findsNothing);
  });

  group('play control', () {
    /// A linear fade from 0 to 1, so opacity reads as progress.
    const String fade = '{ effect: .fade, from: 0, to: 1 }';

    double opacity(WidgetTester tester) => tester.widget<FadeTransition>(_inScreen(FadeTransition)).opacity.value;

    testWidgets('playing: false stops it where it stands', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'go': true});
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, curve: .linear, playing: data.go, effects: [$fade], child: Text(text: "x"));',
        data: data,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(tester), closeTo(0.4, 0.02));
      data.update('go', false);
      await tester.pump();
      final double held = opacity(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(tester), held, reason: 'a stopped animation does not move');
    });

    testWidgets('playing: true again carries on rather than starting over', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'go': true});
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, curve: .linear, playing: data.go, effects: [$fade], child: Text(text: "x"));',
        data: data,
      );
      await tester.pump(const Duration(milliseconds: 400));
      data.update('go', false);
      await tester.pump();
      data.update('go', true);
      await tester.pump();
      expect(opacity(tester), closeTo(0.4, 0.02), reason: 'it resumed, it did not restart');
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(tester), closeTo(0.7, 0.02));
    });

    testWidgets('a new duration while running does not jump to the start', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'ms': 1000});
      await _mount(
        tester,
        'widget root = Animate(duration: data.ms, curve: .linear, effects: [$fade], child: Text(text: "x"));',
        data: data,
      );
      await tester.pump(const Duration(milliseconds: 400));
      data.update('ms', 2000);
      await tester.pump();
      expect(opacity(tester), closeTo(0.4, 0.02));
    });

    testWidgets('index and stagger push the start back one row at a time', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Column(children: ['
        'Animate(duration: 100, curve: .linear, index: 0, stagger: 200, effects: [$fade], child: Text(text: "a")), '
        'Animate(duration: 100, curve: .linear, index: 2, stagger: 200, effects: [$fade], child: Text(text: "b"))]);',
      );
      List<double> opacities() => tester
          .widgetList<FadeTransition>(_inScreen(FadeTransition))
          .map((FadeTransition f) => f.opacity.value)
          .toList();
      expect(opacities(), <double>[0, 0]);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacities()[0], 1, reason: 'row 0 waited no time at all');
      expect(opacities()[1], 0, reason: 'row 2 waits 400ms');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacities()[1], 1);
    });

    testWidgets('repeat: -1 is still going a second later', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 200, repeat: -1, curve: .linear, effects: [$fade], child: Text(text: "x"));',
      );
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester), closeTo(0.5, 0.05));
      expect(_events, isEmpty, reason: 'a repeating animation has no last play');
    });

    testWidgets('repeat: 2 plays twice and then fires onEnd once', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 100, repeat: 2, curve: .linear, effects: [$fade], '
        'onEnd: event "done" { }, child: Text(text: "x"));',
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(_events, isEmpty, reason: 'one play down, one to go');
      await tester.pump(const Duration(milliseconds: 110));
      expect(_events.map(((String, DynamicMap) e) => e.$1).toList(), <String>['done']);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_events.length, 1, reason: 'it stopped after its second play');
    });

    testWidgets('reverse runs it back again before ending', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 100, reverse: true, curve: .linear, effects: [$fade], '
        'onEnd: event "done" { }, child: Text(text: "x"));',
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(opacity(tester), 1);
      expect(_events, isEmpty, reason: 'it has not come back yet');
      await tester.pump(const Duration(milliseconds: 110));
      expect(opacity(tester), 0);
      expect(_events.map(((String, DynamicMap) e) => e.$1).toList(), <String>['done']);
    });

    testWidgets('a device set to reduce motion gets the end, and no ticker', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, delay: 500, curve: .linear, '
        'effects: [{ effect: .fade, from: 0, to: 1 }, { effect: .scale, from: 0.5, to: 1 }], child: Text(text: "x"));',
        disableAnimations: true,
      );
      expect(opacity(tester), 1);
      expect(tester.widget<ScaleTransition>(_inScreen(ScaleTransition)).scale.value, 1);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0, reason: 'no ticker is running');
    });
  });

  group('the filter effects', () {
    testWidgets('blur, tint and shimmer still build their child once', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 600, repeat: -1, effects: ['
        '{ effect: .blur, from: 8, to: 0 }, '
        '{ effect: .tint, from: "#00000000", to: "#80FF0000" }, '
        '{ effect: .shimmer }], child: Count(id: "a", text: "hello"));',
      );
      expect(_builds['a'], 1);
      for (int i = 0; i < 30; i += 1) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_builds['a'], 1, reason: 'an AnimatedBuilder that captures its child rebuilds only itself');
    });

    testWidgets('blur raises and lowers its sigma', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, curve: .linear, effects: [{ effect: .blur, from: 10, to: 0 }], '
        'child: Text(text: "x"));',
      );
      ImageFilter filter() => tester.widget<ImageFiltered>(_inScreen(ImageFiltered)).imageFilter;
      final ImageFilter start = filter();
      await tester.pump(const Duration(milliseconds: 500));
      expect(filter(), isNot(start), reason: 'the sigma moved');
    });

    testWidgets('tint lerps between its two colours', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, curve: .linear, '
        'effects: [{ effect: .tint, from: "#00FF0000", to: "#FFFF0000" }], child: Text(text: "x"));',
      );
      expect(_inScreen(ColorFiltered), findsOneWidget);
      final ColorFilter start = tester.widget<ColorFiltered>(_inScreen(ColorFiltered)).colorFilter;
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<ColorFiltered>(_inScreen(ColorFiltered)).colorFilter, isNot(start));
    });

    testWidgets('shimmer sweeps a gradient across its child', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(duration: 1000, repeat: -1, curve: .linear, effects: [{ effect: .shimmer }], '
        'child: Text(text: "x"));',
      );
      expect(_inScreen(ShaderMask), findsOneWidget);
      final ShaderMask before = tester.widget<ShaderMask>(_inScreen(ShaderMask));
      await tester.pump(const Duration(milliseconds: 500));
      final ShaderMask after = tester.widget<ShaderMask>(_inScreen(ShaderMask));
      expect(after, isNot(same(before)), reason: 'the mask rebuilt, so the sweep moved');
    });

    testWidgets('an effect nobody knows is left out, not fatal', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = Animate(effects: [{ effect: .wobble }, { effect: .fade }], child: Text(text: "x"));',
      );
      expect(tester.takeException(), isNull);
      expect(_inScreen(FadeTransition), findsOneWidget);
    });
  });

  group('ScrollTransition', () {
    const String header =
        'ScrollTransition(from: 0, to: 100, effects: [{ effect: .fade, from: 1, to: 0 }], '
        'child: SizedBox(height: 200, child: Count(id: "a", text: "head")))';

    double opacity(WidgetTester tester) => tester.widget<FadeTransition>(_inScreen(FadeTransition)).opacity.value;

    testWidgets('fades its child as the list scrolls past its range', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView(children: [$header, SizedBox(height: 2000)]);');
      expect(opacity(tester), 1);
      await tester.drag(find.byType(Scrollable), const Offset(0, -50));
      await tester.pump();
      expect(opacity(tester), closeTo(0.5, 0.02));
      await tester.drag(find.byType(Scrollable), const Offset(0, -50));
      await tester.pump();
      expect(opacity(tester), closeTo(0, 0.02));
      // Not far enough to scroll the 200-tall header off, which would unmount it.
      await tester.drag(find.byType(Scrollable), const Offset(0, -40));
      await tester.pump();
      expect(opacity(tester), 0, reason: 'past the range it holds at the end');
    });

    testWidgets('builds its child once across a whole drag', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ListView(children: [$header, SizedBox(height: 2000)]);');
      expect(_builds['a'], 1);
      for (int i = 0; i < 10; i += 1) {
        await tester.drag(find.byType(Scrollable), const Offset(0, -8));
        await tester.pump();
      }
      expect(_builds['a'], 1, reason: 'a scroll repaints the layer; it does not rebuild the subtree');
    });

    testWidgets('with no Scrollable above it, it holds at its start', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = ScrollTransition(from: 0, to: 100, effects: [{ effect: .fade, from: 1, to: 0 }], '
        'child: Text(text: "x"));',
      );
      expect(tester.takeException(), isNull);
      expect(opacity(tester), 1);
    });

    testWidgets('with no effects it is its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = ScrollTransition(child: Text(text: "plain"));');
      expect(find.text('plain'), findsOneWidget);
      expect(_inScreen(FadeTransition), findsNothing);
    });
  });

  group('transitions', () {
    testWidgets('AnimatedSwitcher cross-fades when its child changes', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'n': 'one'});
      await _mount(
        tester,
        'widget root = AnimatedSwitcher(duration: 300, value: data.n, child: Text(text: data.n));',
        data: data,
      );
      expect(find.text('one'), findsOneWidget);
      data.update('n', 'two');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Both children are on screen while they cross over. The one on its way
      // out is a live rfw subtree, still subscribed to `data.n`, so it shows
      // the new text too -- there is no snapshot of the old one to fade.
      expect(find.text('two'), findsNWidgets(2), reason: 'the old child is still on its way out');
      expect(_inScreen(FadeTransition), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('AnimatedSwitcher takes a named transition', (WidgetTester tester) async {
      await _mount(
        tester,
        'widget root = AnimatedSwitcher(duration: 300, transition: .slideUp, child: Text(text: "x"));',
      );
      expect(_inScreen(SlideTransition), findsOneWidget);
    });

    testWidgets('AnimatedSize grows to its child', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'w': 50.0});
      await _mount(
        tester,
        'widget root = Align(alignment: .topLeft, child: AnimatedSize(duration: 300, curve: .linear, '
        'child: SizedBox(width: data.w, height: 20)));',
        data: data,
      );
      expect(tester.getSize(_inScreen(AnimatedSize)).width, 50);
      data.update('w', 150.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final double midway = tester.getSize(_inScreen(AnimatedSize)).width;
      expect(midway, greaterThan(50));
      expect(midway, lessThan(150));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(_inScreen(AnimatedSize)).width, 150);
    });

    testWidgets('AnimatedCrossFade shows whichever showFirst says', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'first': true});
      await _mount(
        tester,
        'widget root = AnimatedCrossFade(duration: 200, showFirst: data.first, '
        'first: Text(text: "A"), second: Text(text: "B"));',
        data: data,
      );
      expect(_inScreen(AnimatedCrossFade), findsOneWidget);
      expect(tester.widget<AnimatedCrossFade>(_inScreen(AnimatedCrossFade)).crossFadeState, CrossFadeState.showFirst);
      data.update('first', false);
      await tester.pump();
      expect(tester.widget<AnimatedCrossFade>(_inScreen(AnimatedCrossFade)).crossFadeState, CrossFadeState.showSecond);
    });

    testWidgets('Hero carries its tag', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Hero(tag: "avatar", child: Text(text: "x"));');
      expect(tester.widget<Hero>(_inScreen(Hero)).tag, 'avatar');
    });

    testWidgets('a Hero with no tag is simply its child', (WidgetTester tester) async {
      await _mount(tester, 'widget root = Hero(child: Text(text: "x"));');
      expect(_inScreen(Hero), findsNothing);
      expect(find.text('x'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnimatedIcon draws the named icon at its progress', (WidgetTester tester) async {
      await _mount(tester, 'widget root = AnimatedIcon(icon: .menu_close, progress: 0.5, size: 32, color: .primary);');
      final AnimatedIcon icon = tester.widget<AnimatedIcon>(_inScreen(AnimatedIcon));
      expect(icon.progress.value, 0.5);
      expect(icon.size, 32);
    });

    testWidgets('an AnimatedIcon nobody knows is nothing, not a crash', (WidgetTester tester) async {
      await _mount(tester, 'widget root = AnimatedIcon(icon: .wobble);');
      expect(tester.takeException(), isNull);
      expect(_inScreen(AnimatedIcon), findsNothing);
    });
  });
}
