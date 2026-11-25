import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Every widget test in this package runs under Flutter's leak tracker.
///
/// A [ChangeNotifier] -- a text controller, a focus node, a scroll or page
/// controller -- that is created and never disposed fails the test that made
/// it, and so does one that is disposed but still held after the test ends.
/// The kit makes these for remote widgets on their behalf, so this is the
/// check that it also cleans them up. See doc/lifecycle-and-memory.md.
FutureOr<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      // Flutter's own test helpers make a few on the way; they are not ours.
      .withIgnored(createdByTestHelpers: true)
      .withTrackedAll();
  await testMain();
}
