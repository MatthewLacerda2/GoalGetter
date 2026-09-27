/// The rules about where a file sits and which layer it may import: the part
/// of the house rules that is about the shape of `lib/`, not the text of one
/// file. `tool/frontend_linter.dart` runs them on every file under `lib/`.
///
/// **The layers point one way.** `lib/core/` is what every feature is built
/// on and never imports `lib/app/`, the router and the screens it wires
/// together. Inside a feature (#222):
///
///  * `data/<feature>_api.dart` talks HTTP;
///  * `domain/` holds the models every other layer passes around;
///  * `presentation/controllers/` holds the state of a screen and calls the
///    API — the only folder of `presentation/` that imports a `data/` file;
///  * `presentation/screens/<name>_screen.dart` is the page a route builds,
///    named after its class; it watches a controller and draws what it says;
///  * `presentation/widgets/` is everything else a screen is drawn with,
///    including the tables and formatters that turn a domain value into
///    what the student reads.
///
/// A screen that calls the API itself keeps its state in `setState`, where no
/// test reaches it without a widget. The folder a file is in is what the rules
/// read, never its name.
library;

import 'dart_source.dart';
import 'project_rules.dart';

/// The app layer: the router and the screens it wires together. Nothing under
/// `lib/core/` may import it.
const String appDir = 'lib/app/';

/// What every feature is built on.
const String coreDir = 'lib/core/';

/// The dev menu and its invented student: nothing a student runs may reach it.
const String devDir = 'lib/app/dev/';

/// The one thing that may cross out of [devDir]: the list of routes the router
/// spreads behind `if (AppConfig.devMenu)`.
final RegExp _devImport = RegExp(
  r'''^import\s+['"][^'"]*dev_routes\.dart['"]\s+show\s+devRoutes\s*;$''',
);

/// The three folders a feature's `presentation/` holds.
const List<String> presentationFolders = ['controllers', 'screens', 'widgets'];

/// `lib/features/<feature>/presentation/<rest>`: the feature and the rest.
final RegExp _presentationPath = RegExp(
  r'^lib/features/([^/]+)/presentation/(.+)$',
);

/// `lib/features/<feature>/data/…`
final RegExp _dataPath = RegExp('^lib/features/[^/]+/data/');

String _normal(String path) => path.replaceAll(r'\', '/');

/// True when [path] may define a widget named after a failure.
bool isCoreFile(String path) => _normal(path).contains(coreDir);

/// Imports from a file under [coreDir] that reach into [appDir]. Read from the
/// raw source, since the URI is a string the stripped source blanks.
List<Violation> coreImportsApp(String path, String source) => [
  if (isCoreFile(path))
    for (final (end, target) in directiveTargets(path, source))
      if (target.startsWith(appDir))
        Violation(
          lineAt(source, end),
          'core-imports-app',
          'lib/core/ is what the app is built on and may not import '
              "lib/app/ ('$target'): expose state the app listens to",
        ),
];

/// True when [path] may write user-facing strings in Dart and name a fixture.
bool isDevFile(String path) => _normal(path).contains(devDir);

/// Directives outside [devDir] that reach into it, other than
/// `import '…/dev_routes.dart' show devRoutes;`.
///
/// The `DevFixtures` name rule reads names, so a `typedef Fx = DevFixtures`
/// (or a re-export, or a top-level `final` holding a fixture) in `lib/app/dev/`
/// would carry the invented student out under another name. Only
/// `devRoutes` crossing the boundary makes every such alias unreachable: the
/// importer cannot see a name the `show` does not list.
List<Violation> devImports(String path, String source) => [
  if (!isDevFile(path))
    for (final (end, target, text) in directiveUses(_normal(path), source))
      if (target.startsWith(devDir) && !_devImport.hasMatch(text))
        Violation(
          lineAt(source, end),
          'no-dev-fixture',
          'lib/app/dev/ is reached only as '
              "`import '.../dev_routes.dart' show devRoutes;`: the dev menu "
              'and its fixtures stay out of what a student runs',
        ),
];

/// Imports of a feature's `data/` from a screen or a widget: anything under
/// `presentation/` but its `controllers/`.
List<Violation> presentationImportsData(String path, String source) {
  final rest = _presentationPath.firstMatch(_normal(path))?.group(2);
  if (rest == null || rest.startsWith('controllers/')) return const [];
  return [
    for (final (end, target) in directiveTargets(_normal(path), source))
      if (_dataPath.hasMatch(target))
        Violation(
          lineAt(source, end),
          'presentation-imports-data',
          "A screen or a widget does not reach the API ('$target'): a "
              'controller under presentation/controllers/ calls it and holds '
              'the state, and the screen watches the controller',
        ),
  ];
}

/// A file under a feature's `presentation/` that is not in one of the
/// [presentationFolders].
List<Violation> presentationLayout(String path) {
  final rest = _presentationPath.firstMatch(_normal(path))?.group(2);
  if (rest == null) return const [];
  final folder = rest.contains('/') ? rest.substring(0, rest.indexOf('/')) : '';
  if (presentationFolders.contains(folder)) return const [];
  return const [
    Violation(
      0,
      'presentation-layout',
      "A feature's presentation/ holds controllers/, screens/ and widgets/ "
          '(tool/layer_rules.dart says which is which): move this file into '
          'the one it belongs to',
    ),
  ];
}

/// Every rule of this file on one file.
List<Violation> layerViolations(String path, String source) => [
  ...coreImportsApp(path, source),
  ...devImports(path, source),
  ...presentationImportsData(path, source),
  ...presentationLayout(path),
];
