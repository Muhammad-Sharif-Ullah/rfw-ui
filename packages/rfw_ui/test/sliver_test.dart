import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The slivers a complex scrolling screen is built from.
const LibraryName _main = LibraryName(<String>['main']);
const LibraryName _test = LibraryName(<String>['test']);

/// How many times each `Count(id: ...)` has built.
final Map<String, int> _builds = <String, int>{};

final List<(String, DynamicMap)> _events = <(String, DynamicMap)>[];

/// The last number each `Probe(id:, value:)` was given.
final Map<String, double> _values = <String, double>{};

final LocalWidgetLibrary _testWidgets = LocalWidgetLibrary(<String, LocalWidgetBuilder>{
  'Count': (BuildContext context, DataSource source) {
    final String id = source.v<String>(<Object>['id']) ?? '';
    _builds[id] = (_builds[id] ?? 0) + 1;
    return const Placeholder();
  },
  // Records what a builder handed it, which is easier to read back than a
  // widget's size when the widget may be scrolled out of view.
  'Probe': (BuildContext context, DataSource source) {
    _values[source.v<String>(<Object>['id']) ?? ''] = source.v<double>(<Object>['value']) ?? -1;
    return const SizedBox(height: 40);
  },
});

Future<void> _mount(WidgetTester tester, String source, {DynamicContent? data}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_test, _testWidgets)
    ..update(_main, parseLibraryFile('import ui; import test;\n$source'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UiRemoteWidget(
          runtime: runtime,
          data: data ?? DynamicContent(),
          widget: const FullyQualifiedWidgetName(_main, 'root'),
          onEvent: (String name, DynamicMap args) => _events.add((name, args)),
        ),
      ),
    ),
  );
}

Finder _inScreen(Type type) => find.descendant(of: find.byType(UiRemoteWidget), matching: find.byType(type));

Future<void> _scroll(WidgetTester tester, double by) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -by));
  await tester.pump();
}

void main() {
  setUp(() {
    _builds.clear();
    _events.clear();
    _values.clear();
  });

  group('SliverPersistentHeader', () {
    testWidgets('with a child it collapses between its two extents', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPersistentHeader(minExtent: 60, maxExtent: 200, pinned: true, child: Placeholder()),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).height, 200);
      await _scroll(tester, 70);
      expect(tester.getSize(_inScreen(Placeholder)).height, 130);
      await _scroll(tester, 200);
      expect(tester.getSize(_inScreen(Placeholder)).height, 60, reason: 'pinned, it stops at its minimum');
    });

    testWidgets('with a child it is built once, however far it is scrolled', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPersistentHeader(minExtent: 60, maxExtent: 200, pinned: true, child: Count(id: "h")),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(_builds['h'], 1);
      for (int i = 0; i < 12; i += 1) {
        await _scroll(tester, 10);
      }
      expect(_builds['h'], 1, reason: 'a child header collapses without rebuilding');
    });

    testWidgets('a builder is given the shrink offset and how far along it is', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPersistentHeader(minExtent: 60, maxExtent: 160,
            builder: (h) => Align(alignment: .topLeft, child: SizedBox(width: h.shrinkOffset, height: 8, child: Placeholder()))),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).width, 0);
      await _scroll(tester, 50);
      expect(tester.getSize(_inScreen(Placeholder)).width, 50);
    });

    testWidgets('t runs 0 to 1 across the collapse, which rfw cannot divide for itself', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPersistentHeader(minExtent: 60, maxExtent: 160, pinned: true,
            builder: (h) => Align(alignment: .topLeft, child: SizedBox(width: h.t, height: 8, child: Placeholder()))),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).width, 0);
      await _scroll(tester, 50);
      expect(tester.getSize(_inScreen(Placeholder)).width, closeTo(0.5, 0.001));
      await _scroll(tester, 300);
      expect(tester.getSize(_inScreen(Placeholder)).width, 1);
    });

    testWidgets('with neither a child nor a builder it takes its space and draws nothing', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPersistentHeader(minExtent: 40, maxExtent: 40),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]);
      ''');
      expect(tester.takeException(), isNull);
    });
  });

  group('SliverResizingHeader and SliverLayoutBuilder', () {
    testWidgets('SliverResizingHeader shrinks between its extents', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverResizingHeader(minExtent: 50, maxExtent: 150, child: Placeholder()),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).height, 150);
      await _scroll(tester, 60);
      expect(tester.getSize(_inScreen(Placeholder)).height, 90);
    });

    testWidgets('SliverLayoutBuilder is given the scroll offset and the cross axis', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverLayoutBuilder(builder: (s) => SliverToBoxAdapter(child: Probe(id: "s", value: s.scrollOffset))),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ]);
      ''');
      expect(_values['s'], 0);
      await _scroll(tester, 25);
      expect(_values['s'], 25);
    });

    testWidgets('SliverLayoutBuilder names the width class, as LayoutBuilder does', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverLayoutBuilder(builder: (s) => SliverToBoxAdapter(child: Text(text: s.breakpoint))),
        ]);
      ''');
      expect(find.text('medium'), findsOneWidget, reason: 'the test window is 800 wide');
    });
  });

  group('the rest of the slivers', () {
    testWidgets('SliverCrossAxisExpanded gives a sliver a flex in its group', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [SliverCrossAxisGroup(slivers: [
          SliverCrossAxisExpanded(flex: 1, sliver: SliverToBoxAdapter(child: SizedBox(height: 40, child: Placeholder()))),
          SliverCrossAxisExpanded(flex: 3, sliver: SliverToBoxAdapter(child: SizedBox(height: 40))),
        ])]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).width, 800 / 4);
    });

    testWidgets('SliverConstrainedCrossAxis caps the cross axis', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverConstrainedCrossAxis(maxExtent: 120,
            sliver: SliverToBoxAdapter(child: SizedBox(height: 40, child: Placeholder()))),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder)).width, 120);
    });

    testWidgets('SliverPrototypeExtentList sizes every row to its prototype', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverPrototypeExtentList(prototypeItem: SizedBox(height: 44), children: [
            SizedBox(child: Placeholder()), SizedBox(child: Placeholder()),
          ]),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder).first).height, 44);
    });

    testWidgets('SliverVariedExtentList sizes row n to extents n', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverVariedExtentList(extents: [30, 90], children: [
            SizedBox(child: Placeholder()), SizedBox(child: Placeholder()),
          ]),
        ]);
      ''');
      expect(tester.getSize(_inScreen(Placeholder).first).height, 30);
      expect(tester.getSize(_inScreen(Placeholder).last).height, 90);
    });

    testWidgets('SliverAnimatedOpacity fades on a data change', (WidgetTester tester) async {
      final DynamicContent data = DynamicContent(<String, Object?>{'o': 1.0});
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverAnimatedOpacity(opacity: data.o, duration: 300,
            sliver: SliverToBoxAdapter(child: SizedBox(height: 40, child: Placeholder()))),
        ]);
      ''', data: data);
      expect(tester.widget<SliverAnimatedOpacity>(_inScreen(SliverAnimatedOpacity)).opacity, 1);
      data.update('o', 0.0);
      await tester.pump();
      expect(tester.widget<SliverAnimatedOpacity>(_inScreen(SliverAnimatedOpacity)).opacity, 0);
    });

    testWidgets('SliverIgnorePointer swallows a tap', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverIgnorePointer(sliver: SliverToBoxAdapter(child: SizedBox(height: 60,
            child: GestureDetector(onTap: event "tapped" { }, child: ColoredBox(color: .primary))))),
        ]);
      ''');
      await tester.tap(_inScreen(ColoredBox), warnIfMissed: false);
      await tester.pump();
      expect(_events, isEmpty);
    });

    testWidgets('SliverOffstage takes no space', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverOffstage(sliver: SliverToBoxAdapter(child: SizedBox(height: 300))),
          SliverToBoxAdapter(child: SizedBox(height: 40, child: Placeholder())),
        ]);
      ''');
      expect(tester.getTopLeft(_inScreen(Placeholder)).dy, 0);
    });

    testWidgets('SliverReorderableList fires onReorder', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverReorderableList(onReorder: event "reorder" { }, children: [
            SizedBox(key: "a", height: 60, child: Center(child: Text(text: "A"))),
            SizedBox(key: "b", height: 60, child: Center(child: Text(text: "B"))),
            SizedBox(key: "c", height: 60, child: Center(child: Text(text: "C"))),
          ]),
        ]);
      ''');
      expect(find.text('A'), findsOneWidget);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('A')));
      await tester.pump(const Duration(milliseconds: 600));
      for (int i = 0; i < 8; i += 1) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_events.map(((String, DynamicMap) e) => e.$1).toList(), <String>['reorder']);
    });

    testWidgets('CupertinoSliverRefreshControl fires onRefresh when pulled', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(physics: .bouncing, slivers: [
          CupertinoSliverRefreshControl(onRefresh: event "refresh" { }),
          SliverToBoxAdapter(child: SizedBox(height: 1200)),
        ]);
      ''');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 250), touchSlopY: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_events.map(((String, DynamicMap) e) => e.$1).toList(), <String>['refresh']);
      await tester.pumpAndSettle();
    });
  });

  group('NestedScrollView', () {
    testWidgets('tabs under a collapsing app bar each keep their own offset', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = DefaultTabController(length: 2, child: NestedScrollView(
          headerSlivers: [
            SliverOverlapAbsorber(sliver: SliverAppBar(
              pinned: true, expandedHeight: 160, forceElevated: true,
              bottom: TabBar(tabs: [Tab(text: "One"), Tab(text: "Two")]),
            )),
          ],
          body: TabBarView(children: [
            CustomScrollView(slivers: [
              SliverOverlapInjector(),
              SliverToBoxAdapter(child: SizedBox(height: 1200, child: Align(alignment: .topLeft, child: SizedBox(height: 20, child: Placeholder())))),
            ]),
            CustomScrollView(slivers: [
              SliverOverlapInjector(),
              SliverToBoxAdapter(child: SizedBox(height: 1200)),
            ]),
          ]),
        ));
      ''');
      expect(find.text('One'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('an absorber and an injector with no NestedScrollView do not throw', (WidgetTester tester) async {
      await _mount(tester, '''
        widget root = CustomScrollView(slivers: [
          SliverOverlapAbsorber(sliver: SliverToBoxAdapter(child: SizedBox(height: 40, child: Placeholder()))),
          SliverOverlapInjector(),
        ]);
      ''');
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_inScreen(Placeholder)).height, 40);
    });
  });
}
