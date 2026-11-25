/// A UI kit for Remote Flutter Widgets.
///
/// `import ui;` in a remote file reaches every widget here; register them with
/// `runtime.update(uiLibraryName, createUiWidgets())`. Theme tokens resolve
/// through [UiResolver]; dialogs, sheets and pickers are `ui.*` events that
/// [UiRemoteWidget] carries out; and a whole light-and-dark theme is one
/// [UiThemeDocument].
library;

export 'src/actions/actions.dart' show UiAction, UiActions, UiEventHandler, uiActions;
export 'src/actions/remote.dart';
export 'src/actions/store.dart';
export 'src/decode/decoder.dart' show UiDecoder, UiKeysSource, curveNames, iconNamed;
export 'src/decode/map_source.dart';
export 'src/decode/resolver.dart';
export 'src/catalog.dart';
export 'src/check.dart';
export 'src/library.dart' hide buildUiWidget;
export 'src/runtime/runtime.dart' show UiRuntime, createUiRuntime;
export 'src/theme/theme_data_decoder.dart' show ThemeComponent, decodeThemeData, themeComponents, themeDataKeys;
export 'src/theme/theme_document.dart';
export 'src/theme/theme_schema.dart' show uiThemeSchema, uiThemeSchemaVersion;
export 'src/theme/tokens.dart';
export 'src/widgets/args.dart' show UiArgs, UiItems, UiItemsSource, UiLazyChildren, UiRows, encodeValue, uiNeedsUiRuntime;
export 'src/widgets/scope.dart' show UiFocusable, UiKey, UiScope, UiScopeData, uiKeyOf;
export 'src/widgets/spec.dart' show UiGroup, UiParam, UiWidget, keyParam, uiTypes;
