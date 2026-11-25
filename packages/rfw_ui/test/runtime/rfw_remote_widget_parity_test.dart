// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copied from third_party/rfw/test/remote_widget_test.dart (rfw 1.1.4) to run rfw's own
// runtime tests against UiRuntime: `Runtime()` is `UiRuntime()`, and nothing
// else changed but the skips, each with its reason.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';
import 'package:rfw_ui/rfw_ui.dart' show UiRuntime;

void main() {
  testWidgets('RemoteWidget', (WidgetTester tester) async {
    final runtime1 = UiRuntime()
      ..update(const LibraryName(<String>['core']), createCoreWidgets())
      ..update(
        const LibraryName(<String>['test']),
        parseLibraryFile('''
        import core;
        widget root = Placeholder();
      '''),
      );
    addTearDown(runtime1.dispose);
    final runtime2 = UiRuntime()
      ..update(const LibraryName(<String>['core']), createCoreWidgets())
      ..update(
        const LibraryName(<String>['test']),
        parseLibraryFile('''
        import core;
        widget root = Container();
      '''),
      );
    addTearDown(runtime2.dispose);
    final data = DynamicContent();
    await tester.pumpWidget(
      RemoteWidget(
        runtime: runtime1,
        data: data,
        widget: const FullyQualifiedWidgetName(LibraryName(<String>['test']), 'root'),
      ),
    );
    expect(find.byType(RemoteWidget), findsOneWidget);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(Container), findsNothing);

    await tester.pumpWidget(
      RemoteWidget(
        runtime: runtime2,
        data: data,
        widget: const FullyQualifiedWidgetName(LibraryName(<String>['test']), 'root'),
      ),
    );
    expect(find.byType(RemoteWidget), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Container), findsOneWidget);
  });
}
