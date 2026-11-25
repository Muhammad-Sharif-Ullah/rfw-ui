import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';
import 'package:rfw_ui/src/runtime/eval.dart';

const LibraryName _lib = LibraryName(<String>['main']);

/// An evaluator over plain data, with no state.
class _Eval extends UiEvaluator {
  _Eval([this.data = const <String, Object?>{}]);

  final Map<String, Object?> data;

  @override
  Object readData(List<Object> parts) {
    Object? node = data;
    for (final Object part in parts) {
      if (node is Map<String, Object?> && node.containsKey(part)) {
        node = node[part];
      } else if (node is List<Object?> && part is int && part >= 0 && part < node.length) {
        node = node[part];
      } else {
        return missing;
      }
    }
    return node ?? missing;
  }

  @override
  Object readState(Env env, List<Object> parts) => missing;
}

/// [source]'s widgets, by name.
Map<String, WidgetDeclaration> _widgets(String source) =>
    <String, WidgetDeclaration>{for (final WidgetDeclaration w in parseLibraryFile(source).widgets) w.name: w};

/// The environment `root`'s body is read in.
Env _rootEnv(Map<String, WidgetDeclaration> widgets) => Env.root.forWidget(widgets['root']!, _lib, const <String, Object?>{});

ConstructorCall _call(Object? value) => value! as ConstructorCall;

void main() {
  test('args are read through two remote widgets, back to where they were written', () {
    final Map<String, WidgetDeclaration> w = _widgets('''
      widget root = A(y: data.v);
      widget A = B(x: args.y);
      widget B = Text(text: args.x);
    ''');
    final _Eval eval = _Eval(<String, Object?>{'v': 'hello'});
    final Env root = _rootEnv(w);
    final Env a = root.forWidget(w['A']!, _lib, _call(w['root']!.root).arguments);
    final Env b = a.forWidget(w['B']!, _lib, _call(w['A']!.root).arguments);
    expect(eval.walk(_call(w['B']!.root).arguments, b, <Object>['text'], 0).value, 'hello');
    expect(eval.walk(_call(w['B']!.root).arguments, b, <Object>['missing'], 0).value, missing);
  });

  test('an inner loop reads the outer loop\'s variable', () {
    final Map<String, WidgetDeclaration> w = _widgets('''
      widget root = Column(children: [...for a in data.groups: Column(children: [...for b in a.items: Text(text: a.name, sub: b)])]);
    ''');
    final _Eval eval = _Eval(<String, Object?>{
      'groups': <Object?>[
        <String, Object?>{'name': 'one', 'items': <Object?>['x', 'y']},
        <String, Object?>{'name': 'two', 'items': <Object?>['z']},
      ],
    });
    final Env root = _rootEnv(w);
    final List<String> seen = <String>[];
    final Bound outer = eval.resolve(_call(w['root']!.root).arguments['children'], root);
    for (final UiListEntry group in eval.listEntries(outer.value! as List<Object?>, outer.env)) {
      final Bound inner = eval.walk(_call(group.value).arguments, group.env, <Object>['children'], 0);
      for (final UiListEntry row in eval.listEntries(inner.value! as List<Object?>, inner.env)) {
        final DynamicMap args = _call(row.value).arguments;
        seen.add('${eval.walk(args, row.env, <Object>['text'], 0).value}/${eval.walk(args, row.env, <Object>['sub'], 0).value}');
      }
    }
    expect(seen, <String>['one/x', 'one/y', 'two/z']);
  });

  test('a list counts and indexes its loops\' rows among its own entries', () {
    final Map<String, WidgetDeclaration> w = _widgets('widget root = Column(children: [A(), ...for x in data.xs: B(v: x), C()]);');
    final _Eval eval = _Eval(<String, Object?>{'xs': <Object?>['p', 'q']});
    final Env root = _rootEnv(w);
    final List<Object?> list = _call(w['root']!.root).arguments['children']! as List<Object?>;
    expect(eval.listLength(list, root), 4);
    expect(_call(eval.listEntry(list, root, 0)!.value).name, 'A');
    final UiListEntry q = eval.listEntry(list, root, 2)!;
    expect(_call(q.value).name, 'B');
    expect(q.loop, isNotNull);
    expect(q.itemIndex, 1);
    expect(q.item, 'q');
    expect(eval.walk(_call(q.value).arguments, q.env, <Object>['v'], 0).value, 'q');
    expect(_call(eval.listEntry(list, root, 3)!.value).name, 'C');
    expect(eval.listEntry(list, root, 4), isNull);
    expect(eval.listEntries(list, root).map((UiListEntry e) => _call(e.value).name), <String>['A', 'B', 'B', 'C']);
  });

  test('a switch takes its matching case, then its default, else nothing', () {
    final Map<String, WidgetDeclaration> w = _widgets('widget root = T(v: switch data.k { "a": 1, default: 2 }, w: switch data.k { "a": 1 });');
    final DynamicMap args = _call(w['root']!.root).arguments;
    final Env root = _rootEnv(w);
    expect(_Eval(<String, Object?>{'k': 'a'}).walk(args, root, <Object>['v'], 0).value, 1);
    expect(_Eval(<String, Object?>{'k': 'b'}).walk(args, root, <Object>['v'], 0).value, 2);
    expect(_Eval(<String, Object?>{'k': 'b'}).walk(args, root, <Object>['w'], 0).value, missing);
  });

  test('a builder argument is read in the environment it came from', () {
    final Map<String, WidgetDeclaration> w = _widgets('widget root = L(items: [{ title: args.t }], b: (m) => T(x: m.title, y: m));');
    final _Eval eval = _Eval();
    final Env root = Env.root.forWidget(w['root']!, _lib, const <String, Object?>{'t': 'hi'});
    final DynamicMap args = _call(w['root']!.root).arguments;
    final Bound items = eval.resolve(args['items'], root);
    final UiListEntry item = eval.listEntry(items.value! as List<Object?>, items.env, 0)!;
    final WidgetBuilderDeclaration builder = args['b']! as WidgetBuilderDeclaration;
    final Env inside = Env.root.withBuilderArg(builder.argumentName, Bound(item.value, item.env));
    expect(eval.walk(_call(builder.widget).arguments, inside, <Object>['x'], 0).value, 'hi');
    expect(eval.walk(_call(builder.widget).arguments, inside, <Object>['y'], 0).value, isA<Map<String, Object?>>());
  });

  test('materialize makes event arguments plain, loops expanded and references followed', () {
    final Map<String, WidgetDeclaration> w = _widgets('''
      widget root = Column(children: [...for item in data.items: B(onTap: event "x" { user: { id: item.id }, tags: [...for t in item.tags: t], n: data.n, k: "lit" })]);
    ''');
    final _Eval eval = _Eval(<String, Object?>{
      'n': 3,
      'items': <Object?>[
        <String, Object?>{'id': 'i1', 'tags': <Object?>['a', 'b']},
      ],
    });
    final Env root = _rootEnv(w);
    final UiListEntry row = eval.listEntry(_call(w['root']!.root).arguments['children']! as List<Object?>, root, 0)!;
    final EventHandler handler = _call(row.value).arguments['onTap']! as EventHandler;
    expect(eval.materialize(handler.eventArguments, row.env), <String, Object?>{
      'user': <String, Object?>{'id': 'i1'},
      'tags': <Object?>['a', 'b'],
      'n': 3,
      'k': 'lit',
    });
  });

  test('a path that does not fit the value is missing', () {
    final Map<String, WidgetDeclaration> w = _widgets('widget root = T(a: data.list, m: data.map);');
    final _Eval eval = _Eval(<String, Object?>{
      'list': <Object?>[1, 2],
      'map': <String, Object?>{'k': 1},
    });
    final DynamicMap args = _call(w['root']!.root).arguments;
    final Env root = _rootEnv(w);
    expect(eval.walk(args, root, <Object>['a', 'x'], 0).value, missing);
    expect(eval.walk(args, root, <Object>['a', 5], 0).value, missing);
    expect(eval.walk(args, root, <Object>['m', 'nope'], 0).value, missing);
    expect(eval.walk(args, root, <Object>['m', 0], 0).value, missing);
    expect(eval.walk(args, root, <Object>['a', 1], 0).value, 2);
  });

  test('an environment knows which widgets it is inside', () {
    final Map<String, WidgetDeclaration> w = _widgets('widget root = A(); widget A = B(); widget B = C();');
    final Env a = _rootEnv(w).forWidget(w['A']!, _lib, const <String, Object?>{});
    final Env b = a.withLoop(1, a).forWidget(w['B']!, _lib, const <String, Object?>{});
    expect(b.calls(w['A']!), isTrue);
    expect(b.calls(w['root']!), isTrue);
    expect(a.calls(w['B']!), isFalse);
  });

  group('uiSameItem', () {
    test('deep-equal maps and lists are the same item', () {
      expect(
        uiSameItem(
          <String, Object?>{'a': 1, 'b': <Object?>[<String, Object?>{'c': 'x'}]},
          <String, Object?>{'a': 1, 'b': <Object?>[<String, Object?>{'c': 'x'}]},
        ),
        isTrue,
      );
    });

    test('a changed leaf, a different shape or a different number type is not', () {
      expect(uiSameItem(<String, Object?>{'b': <Object?>['x']}, <String, Object?>{'b': <Object?>['y']}), isFalse);
      expect(uiSameItem(<Object?>[1], <String, Object?>{'0': 1}), isFalse);
      expect(uiSameItem(<String, Object?>{'a': 1}, <String, Object?>{'a': 1, 'b': 2}), isFalse);
      expect(uiSameItem(1, 1.0), isFalse);
    });

    test('a node of the parsed model is the same item only as itself', () {
      final Object node = parseLibraryFile('widget a = b(c: data.x);').widgets.single.root;
      expect(uiSameItem(node, node), isTrue);
      expect(uiSameItem(node, parseLibraryFile('widget a = b(c: data.x);').widgets.single.root), isFalse);
    });
  });
}
