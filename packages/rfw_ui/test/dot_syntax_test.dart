import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

const LibraryName _main = LibraryName(<String>['main']);

Future<void> _pump(WidgetTester tester, String root) async {
  final Runtime runtime = createUiRuntime()
    ..update(uiLibraryName, createUiWidgets())
    ..update(_main, parseLibraryFile('import ui;\nwidget root = $root;'));
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: UiRemoteWidget(runtime: runtime, data: DynamicContent(), widget: const FullyQualifiedWidgetName(_main, 'root')),
    ),
  );
}

void main() {
  testWidgets('a screen written with dots builds what its quoted form builds', (WidgetTester tester) async {
    const String dotted = 'Column(mainAxisAlignment: .center, children: [Text(text: "Hi", textAlign: .end, '
        'style: { base: .titleLarge, color: .primary, fontWeight: .bold }), Icon(icon: .cupertino.heart_fill)])';
    final String quoted = dotted.replaceAllMapped(RegExp(r'\.([a-zA-Z_][\w.]*)'), (Match m) => '"${m[1]}"');

    Map<String, Object?> built() {
      final Text text = tester.widget<Text>(find.text('Hi'));
      return <String, Object?>{
        'column': tester.widget<Flex>(find.byType(Flex)).mainAxisAlignment,
        'align': text.textAlign,
        'style': text.style,
        'icon': tester.widget<Icon>(find.byType(Icon)).icon,
      };
    }

    await _pump(tester, dotted);
    final Map<String, Object?> fromDots = built();
    await _pump(tester, quoted);
    expect(built(), fromDots);
    expect(fromDots['align'], TextAlign.end);
    expect(fromDots['column'], MainAxisAlignment.center);
  });
}
