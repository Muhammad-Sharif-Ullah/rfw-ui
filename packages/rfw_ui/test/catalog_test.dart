import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// The catalog is what the studio shows on hover, so it is only worth having
/// if it is true. These tests hold every widget to its own documentation.
void main() {
  test('widget names are unique', () {
    final Set<String> seen = <String>{};
    final List<String> twice = <String>[
      for (final UiWidget w in uiWidgets)
        if (!seen.add(w.name)) w.name,
    ];
    expect(twice, isEmpty);
  });

  test('every widget is documented, and so is every parameter type', () {
    for (final UiWidget w in uiWidgets) {
      expect(w.doc.trim(), isNotEmpty, reason: w.name);
      for (final UiParam param in w.params) {
        final bool known = uiTypes.containsKey(param.type) || param.values != null || param.type.startsWith('List<');
        expect(known, isTrue, reason: '${w.name}.${param.name} is a ${param.type}, which uiTypes does not describe');
      }
    }
  });

  testWidgets('every builder reads exactly the parameters it declares', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    final List<String> problems = <String>[];
    for (final UiWidget w in uiWidgets) {
      final _Recorder recorder = _Recorder();
      try {
        w.build(UiArgs(context, recorder));
      } catch (error) {
        problems.add('${w.name}: building from no arguments threw $error');
        continue;
      }
      final Set<String> declared = <String>{for (final UiParam param in w.params) param.name};
      final Set<String> undeclared = recorder.read.difference(declared);
      // A widget builder may be called only when Flutter lays the widget out
      // (LayoutBuilder's), which this one build does not reach.
      final Set<String> unread = declared
          .difference(recorder.read)
          .difference(<String>{for (final UiParam param in w.params) if (param.type == 'Builder' || param.type == 'ItemBuilder') param.name});
      if (undeclared.isNotEmpty) {
        problems.add('${w.name} reads ${undeclared.join(', ')} but does not declare it');
      }
      if (unread.isNotEmpty) {
        problems.add('${w.name} declares ${unread.join(', ')} but never reads it');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  for (final UiWidget w in uiWidgets.where((UiWidget w) => w.example != null)) {
    testWidgets('the ${w.name} example renders', (WidgetTester tester) async {
      final Runtime runtime = createUiRuntime()
        ..update(uiLibraryName, createUiWidgets())
        ..update(
          const LibraryName(<String>['example']),
          parseLibraryFile('import ui;\nwidget root = ${w.example};'),
        );
      addTearDown(runtime.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: DynamicContent(),
              widget: const FullyQualifiedWidgetName(LibraryName(<String>['example']), 'root'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    }, skip: w.needsUiRuntime && const String.fromEnvironment('RFW_RUNTIME') == 'rfw');
  }
}

/// A [DataSource] with nothing in it that notes every top-level key asked
/// for -- a `.builder` widget's items too.
class _Recorder implements DataSource, UiItemsSource {
  final Set<String> read = <String>{};

  void _note(List<Object> key) {
    if (key.isNotEmpty && key.first is String) {
      read.add(key.first as String);
    }
  }

  @override
  T? v<T extends Object>(List<Object> argsKey) {
    _note(argsKey);
    return null;
  }

  @override
  bool isList(List<Object> argsKey) {
    _note(argsKey);
    return false;
  }

  @override
  int length(List<Object> argsKey) {
    _note(argsKey);
    return 0;
  }

  @override
  bool isMap(List<Object> argsKey) {
    _note(argsKey);
    return false;
  }

  @override
  Widget child(List<Object> argsKey) {
    _note(argsKey);
    return const SizedBox();
  }

  @override
  Widget? optionalChild(List<Object> argsKey) {
    _note(argsKey);
    return null;
  }

  @override
  List<Widget> childList(List<Object> argsKey) {
    _note(argsKey);
    return const <Widget>[];
  }

  @override
  Widget builder(List<Object> argsKey, DynamicMap builderArg) {
    _note(argsKey);
    return const SizedBox();
  }

  @override
  Widget? optionalBuilder(List<Object> argsKey, DynamicMap builderArg) {
    _note(argsKey);
    return null;
  }

  @override
  VoidCallback? voidHandler(List<Object> argsKey, [DynamicMap? extraArguments]) {
    _note(argsKey);
    return null;
  }

  @override
  T? handler<T extends Function>(List<Object> argsKey, HandlerGenerator<T> generator) {
    _note(argsKey);
    return null;
  }

  @override
  int itemCount(List<Object> itemsKey, List<Object> countKey) {
    _note(itemsKey);
    _note(countKey);
    return 0;
  }

  @override
  Widget buildItem(List<Object> itemsKey, List<Object> builderKey, int index) {
    _note(builderKey);
    return const SizedBox();
  }
}
