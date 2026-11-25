import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_ui/rfw_ui.dart';

/// `catalog.json` and `icons.json` are what the studio's editor reads for
/// hover and completion. They are generated from the code, and this test
/// fails when either is stale:
///
///     UPDATE_CATALOG=1 flutter test test/catalog_export_test.dart
void main() {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final bool update = Platform.environment['UPDATE_CATALOG'] == '1';

  void check(String path, Object json) {
    final String expected = '${encoder.convert(json)}\n';
    final File file = File(path);
    if (update) {
      file.writeAsStringSync(expected);
      return;
    }
    expect(file.existsSync(), isTrue, reason: '$path is missing; run with UPDATE_CATALOG=1');
    expect(file.readAsStringSync(), expected, reason: '$path is stale; run with UPDATE_CATALOG=1');
  }

  test('catalog.json is current', () => check('catalog.json', uiCatalog()));
  test('icons.json is current', () => check('icons.json', uiIconNames()));
}
