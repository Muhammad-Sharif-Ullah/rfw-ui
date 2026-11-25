import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

/// Mounts [chart] keyed "chart" in a 100 x 50 box and returns its data.
Future<DynamicContent> _chart(WidgetTester tester, String chart, {Map<String, Object?> data = const <String, Object?>{}}) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\nwidget root = Center(child: SizedBox(width: 100, height: 50, child: $chart));'));
  addTearDown(runtime.dispose);
  final DynamicContent content = DynamicContent(data);
  await tester.pumpWidget(
    MaterialApp(home: UiRemoteWidget(runtime: runtime, data: content, widget: const FullyQualifiedWidgetName(_main, 'root'))),
  );
  await tester.pump();
  return content;
}

RenderObject _painted(WidgetTester tester) => tester.renderObject(
  find.descendant(of: find.byWidgetPredicate((Widget w) => UiKey.matches(w.key, 'chart')), matching: find.byType(CustomPaint)).first,
);

/// The paths [object] draws, in order.
List<Path> _paths(WidgetTester tester, RenderObject object) {
  final List<Path> paths = <Path>[];
  expect(object, paints..everything((Symbol method, List<dynamic> arguments) {
    if (method == #drawPath) {
      paths.add(arguments[0] as Path);
    }
    return true;
  }));
  return paths;
}

void main() {
  testWidgets('a line chart runs from the first point to the last, low at the bottom', (WidgetTester tester) async {
    await _chart(tester, 'LineChart(key: "chart", points: [0, 10], color: "#0000FF")');
    final PathMetric line = _paths(tester, _painted(tester)).single.computeMetrics().single;
    expect(line.getTangentForOffset(0)!.position, const Offset(0, 50));
    expect(line.getTangentForOffset(line.length)!.position, const Offset(100, 0));
  });

  testWidgets('a smooth line still passes through every point', (WidgetTester tester) async {
    await _chart(tester, 'LineChart(key: "chart", points: [0, 10, 0], smooth: true)');
    final PathMetric line = _paths(tester, _painted(tester)).single.computeMetrics().single;
    double closest = double.infinity;
    for (double d = 0; d <= line.length; d += 0.25) {
      closest = math.min(closest, (line.getTangentForOffset(d)!.position - const Offset(50, 0)).distance);
    }
    expect(closest, lessThan(0.5));
  });

  testWidgets('a line chart with a fill shades the area under the line', (WidgetTester tester) async {
    await _chart(tester, 'LineChart(key: "chart", points: [0, 10], fill: "#330000FF")');
    final List<Path> paths = _paths(tester, _painted(tester));
    expect(paths, hasLength(2));
    expect(paths.first.contains(const Offset(90, 45)), isTrue);
    expect(paths.first.contains(const Offset(10, 5)), isFalse);
  });

  testWidgets('bars stand on zero, each as tall as its value', (WidgetTester tester) async {
    await _chart(tester, 'BarChart(key: "chart", values: [1, 2], gap: 0, color: "#00FF00")');
    expect(
      _painted(tester),
      paints
        ..rect(rect: const Rect.fromLTWH(0, 25, 50, 25), color: const Color(0xFF00FF00))
        ..rect(rect: const Rect.fromLTWH(50, 0, 50, 50), color: const Color(0xFF00FF00)),
    );
  });

  testWidgets('a pie of two equal values is two halves', (WidgetTester tester) async {
    await _chart(tester, 'PieChart(key: "chart", values: [1, 1], colors: ["#FF0000", "#0000FF"])');
    expect(
      _painted(tester),
      paints
        ..arc(sweepAngle: math.pi, color: const Color(0xFFFF0000))
        ..arc(sweepAngle: math.pi, color: const Color(0xFF0000FF)),
    );
  });

  testWidgets('no values paint nothing, and throw nothing', (WidgetTester tester) async {
    await _chart(tester, 'BarChart(key: "chart", values: [])');
    expect(tester.takeException(), isNull);
    expect(_painted(tester), paintsNothing);
  });

  testWidgets('points from data repaint when the data changes', (WidgetTester tester) async {
    final DynamicContent data = await _chart(
      tester,
      'LineChart(key: "chart", points: data.prices)',
      data: <String, Object?>{'prices': <Object?>[0, 10]},
    );
    expect(_paths(tester, _painted(tester)).single.computeMetrics().single.getTangentForOffset(0)!.position, const Offset(0, 50));
    data.update('prices', <Object?>[10, 0]);
    await tester.pump();
    expect(_paths(tester, _painted(tester)).single.computeMetrics().single.getTangentForOffset(0)!.position, Offset.zero);
  });
}
