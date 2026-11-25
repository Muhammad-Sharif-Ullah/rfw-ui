import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

import '../library.dart' show UiWidgetLibrary;
import '../widgets/spec.dart' show UiWidget;
import 'screen.dart';

/// A [Runtime] that builds remote widgets faster than rfw's own, and the same.
///
/// Use it wherever a `Runtime()` is made; [createUiRuntime] does so unless
/// the app was built with `--dart-define=RFW_RUNTIME=rfw`. Libraries are
/// registered and listened to exactly as on rfw's: only [build] is its own.
/// It reads rfw's parsed model where rfw copies it, and a widget subscribes
/// to the data it read rather than its whole screen rebuilding. See
/// doc/runtime.md.
class UiRuntime extends Runtime {
  UiRuntime();

  final Map<LibraryName, WidgetLibrary> _libraries = <LibraryName, WidgetLibrary>{};
  final Map<FullyQualifiedWidgetName, UiTarget?> _found = <FullyQualifiedWidgetName, UiTarget?>{};
  final Set<LibraryName> _checked = <LibraryName>{};

  /// Goes up with every change of libraries: what was worked out from the
  /// old ones no longer holds.
  int get generation => _generation;
  int _generation = 0;

  @override
  void update(LibraryName name, WidgetLibrary library) {
    _libraries[name] = library;
    _forget();
    super.update(name, library);
  }

  @override
  void clearLibraries() {
    _libraries.clear();
    _forget();
    super.clearLibraries();
  }

  void _forget() {
    _found.clear();
    _checked.clear();
    _generation += 1;
  }

  @override
  Widget build(BuildContext context, FullyQualifiedWidgetName widget, DynamicContent data, RemoteEventHandler remoteEventTarget) {
    // As rfw does, the first time a library's widget is built.
    if (!_checked.contains(widget.library)) {
      _checkForImportLoops(widget.library);
      _checked.add(widget.library);
    }
    return UiScreen(runtime: this, widget: widget, data: data, onEvent: remoteEventTarget, generation: _generation);
  }

  final Expando<(int, UiTarget)> _targets = Expando<(int, UiTarget)>('targets');

  /// What [call], written in [library], calls. Worked out once per call in
  /// the file, until the libraries change.
  UiTarget targetOf(ConstructorCall call, LibraryName library) {
    final (int, UiTarget)? known = _targets[call];
    if (known != null && known.$1 == _generation) {
      return known.$2;
    }
    final UiTarget found = target(library, call.name);
    _targets[call] = (_generation, found);
    return found;
  }

  /// What [name], called in [library], is: a remote widget, a local one, or
  /// nothing, with the error to show.
  UiTarget target(LibraryName library, String name) {
    final FullyQualifiedWidgetName fullName = FullyQualifiedWidgetName(library, name);
    final UiTarget? found = _find(fullName);
    if (found != null) {
      return found;
    }
    final Set<LibraryName> missingLibraries = _findMissingLibraries(library).toSet();
    if (missingLibraries.isNotEmpty) {
      return UiMissingTarget(
        'Could not find remote widget named $name in $library, '
        'possibly because some dependencies were missing: ${missingLibraries.join(", ")}',
      );
    }
    return UiMissingTarget('Could not find remote widget named $name in $library.');
  }

  // rfw's _findConstructor: the library's own widgets, then its imports in
  // order, remembering the answer under every name it was asked by.
  UiTarget? _find(FullyQualifiedWidgetName fullName) {
    if (_found.containsKey(fullName)) {
      return _found[fullName];
    }
    UiTarget? result;
    final WidgetLibrary? library = _libraries[fullName.library];
    if (library is RemoteWidgetLibrary) {
      for (final WidgetDeclaration declaration in library.widgets) {
        if (declaration.name == fullName.widget) {
          result = UiRemoteTarget(declaration, fullName.library);
          break;
        }
      }
      if (result == null) {
        for (final Import import in library.imports) {
          result = _find(FullyQualifiedWidgetName(import.name, fullName.widget));
          if (result != null) {
            break;
          }
        }
      }
    } else if (library is LocalWidgetLibrary) {
      // rfw marks this protected, for its own Runtime; this is a runtime too.
      // ignore: invalid_use_of_protected_member
      final LocalWidgetBuilder? builder = library.findConstructor(fullName.widget);
      if (builder != null) {
        result = UiLocalTarget(builder, fullName, kit: library is UiWidgetLibrary ? library.kit[fullName.widget] : null);
      }
    }
    return _found[fullName] = result;
  }

  Iterable<LibraryName> _findMissingLibraries(LibraryName name) sync* {
    final WidgetLibrary? library = _libraries[name];
    if (library == null) {
      yield name;
      return;
    }
    if (library is RemoteWidgetLibrary) {
      for (final Import import in library.imports) {
        yield* _findMissingLibraries(import.name);
      }
    }
  }

  void _checkForImportLoops(LibraryName name, [Set<LibraryName>? visited]) {
    final WidgetLibrary? library = _libraries[name];
    if (library is! RemoteWidgetLibrary) {
      return;
    }
    visited ??= <LibraryName>{};
    visited.add(name);
    for (final Import import in library.imports) {
      final LibraryName dependency = import.name;
      if (visited.contains(dependency)) {
        final List<LibraryName> path = <LibraryName>[dependency];
        for (final LibraryName name in visited.toList().reversed) {
          if (name == dependency) {
            break;
          }
          path.add(name);
        }
        if (path.length == 1) {
          throw RemoteFlutterWidgetsException('Library $dependency depends on itself.');
        }
        throw RemoteFlutterWidgetsException('Library $dependency indirectly depends on itself via ${path.reversed.join(" which depends on ")}.');
      }
      _checkForImportLoops(dependency, visited.toSet());
    }
  }
}

/// The runtime this app's remote screens run on: [UiRuntime], or rfw's own
/// [Runtime] when the app is built with `--dart-define=RFW_RUNTIME=rfw`.
Runtime createUiRuntime() => const String.fromEnvironment('RFW_RUNTIME') == 'rfw' ? Runtime() : UiRuntime();

/// What a widget name, called in a library, is.
sealed class UiTarget {
  const UiTarget();
}

/// A widget declared in a remote library.
final class UiRemoteTarget extends UiTarget {
  const UiRemoteTarget(this.declaration, this.library);

  final WidgetDeclaration declaration;

  /// Where [declaration] is: what the names in its body are looked up in.
  final LibraryName library;

  FullyQualifiedWidgetName get fullName => FullyQualifiedWidgetName(library, declaration.name);
}

/// A widget a [LocalWidgetLibrary] builds.
final class UiLocalTarget extends UiTarget {
  const UiLocalTarget(this.builder, this.fullName, {this.kit});

  final LocalWidgetBuilder builder;
  final FullyQualifiedWidgetName fullName;

  /// The kit's widget, when [builder] is one of `createUiWidgets()`'s.
  final UiWidget? kit;
}

/// A name nothing answers to.
final class UiMissingTarget extends UiTarget {
  const UiMissingTarget(this.message);

  final String message;
}

/// rfw's error widget for a mistake in a remote file: reported, then shown.
Widget uiErrorWidget(String message) {
  final FlutterErrorDetails detail = FlutterErrorDetails(
    exception: message,
    stack: StackTrace.current,
    library: 'Remote Flutter Widgets',
  );
  FlutterError.reportError(detail);
  return ErrorWidget.builder(detail);
}
