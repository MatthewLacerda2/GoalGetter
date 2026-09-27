/// The hubs (#231): each kind of thing has one home under `lib/`, and nothing
/// defines it anywhere else. CLAUDE.md's hub map lists them, beside the
/// backend's; `tool/frontend_linter.dart` runs these rules on every file
/// under `lib/`.
///
/// Every rule reads what a file *does* — what it imports, which type it
/// handles, which constructor it calls, what it declares — never what
/// something is called: #212 rejected name checks for passing whatever was
/// named differently. The hub is where a file sits, which is what the rules
/// compare against.
///
///  * `http-outside-api`: the HTTP package is imported only by `lib/core/api/`,
///    the transport (`ApiClient`), which adds the session, the refresh and
///    the timeouts to every call;
///  * `api-outside-data`: the backend is called — `ApiClient`, `ApiRoute`,
///    the client's provider — only from a `data/` layer: a feature's `data/`,
///    or `lib/core/api/` itself;
///  * `json-outside-domain`: a JSON map is read in `domain/`, where a model's
///    `fromJson` turns it into a type, written in `data/` as a request body,
///    and handled nowhere else but the transport;
///  * `route-outside-router`: a route is declared in `lib/app/router/` (and
///    the dev menu's in `lib/app/dev/`);
///  * `data-defines-api-only`: a feature's `data/<feature>_api.dart` declares
///    its API class and nothing else — a model it returns is in `domain/`;
///  * `cross-feature-presentation`: a widget or a screen is imported only by
///    its own feature (and the router): what two features draw with lives in
///    `lib/core/widgets/`.
library;

import 'dart_source.dart';
import 'project_rules.dart';

/// The transport, and the only folder that may speak HTTP.
const String apiDir = 'lib/core/api/';

/// The files that call the backend. Importing one is calling it: they hold the
/// client, the list of calls, and the provider that hands the client out.
const Set<String> apiCallFiles = {
  'lib/core/api/api_client.dart',
  'lib/core/api/api_route.dart',
  'lib/core/api/api_providers.dart',
};

/// The router and the dev menu: the only folders that declare a route.
const List<String> routerDirs = ['lib/app/router/', 'lib/app/dev/'];

/// Packages that speak HTTP.
final RegExp _httpImport = RegExp(
  r'''(?:^|\n)\s*(?:import|export)\s+['"]package:(?:http|dio)/''',
);

/// A JSON value, as the code handles one: the map type a decoded object is,
/// or the codec itself.
final RegExp _json = RegExp(
  r'\bMap<\s*String\s*,\s*(?:dynamic|Object\?)\s*>|\bjson(?:Decode|Encode)\b'
  r'|\bjson\.(?:decode|encode)\b',
);

/// Constructing a route or a router.
final RegExp _route = RegExp(
  r'\b(?:GoRoute|ShellRoute|StatefulShellRoute|GoRouter)\s*(?:\.\w+\s*)?\(',
);

/// What a file declares at the top level (on stripped source).
final RegExp _declaration = RegExp(
  r'^(?:(?:abstract|sealed|final|base|interface|mixin)\s+)*'
  r'(class|enum|typedef|extension|mixin)\b',
  multiLine: true,
);

/// `lib/features/<feature>/<layer>/…`
final RegExp _featurePath = RegExp('^lib/features/([^/]+)/([^/]+)/');

/// `lib/features/<feature>/presentation/(screens|widgets)/…`
final RegExp _drawnPath = RegExp(
  '^lib/features/([^/]+)/presentation/(?:screens|widgets)/',
);

String _normal(String path) => path.replaceAll(r'\', '/');

/// The feature [path] belongs to and the layer folder it is in, or nulls.
(String?, String?) _featureLayer(String path) {
  final match = _featurePath.firstMatch(_normal(path));
  return (match?.group(1), match?.group(2));
}

bool _inDataLayer(String path) =>
    _normal(path).startsWith(apiDir) || _featureLayer(path).$2 == 'data';

Violation _at(String source, int index, String rule, String message) =>
    Violation(lineAt(source, index), rule, message);

List<Violation> httpOutsideApi(String path, String source) => [
  if (!_normal(path).startsWith(apiDir))
    for (final match in _httpImport.allMatches(source))
      _at(
        source,
        match.end,
        'http-outside-api',
        'HTTP is spoken by lib/core/api/ only: call the backend through a '
            "feature's data/ API, which sends with ApiClient",
      ),
];

List<Violation> apiOutsideData(String path, String source) => [
  if (!_inDataLayer(path))
    for (final (end, target) in directiveTargets(_normal(path), source))
      if (apiCallFiles.contains(target))
        _at(
          source,
          end,
          'api-outside-data',
          "The backend is called from a data/ layer ('$target'): add the "
              "call to a feature's data/<feature>_api.dart, or to "
              'lib/core/api/, and call that',
        ),
];

List<Violation> jsonOutsideDomain(String path, String stripped) {
  final layer = _featureLayer(path).$2;
  if (_normal(path).startsWith(apiDir) ||
      layer == 'domain' ||
      layer == 'data') {
    return const [];
  }
  return [
    for (final match in _json.allMatches(stripped))
      _at(
        stripped,
        match.start,
        'json-outside-domain',
        "JSON is read into a model by its fromJson, in a feature's domain/, "
            'and written as a request body in its data/: pass the model',
      ),
  ];
}

List<Violation> routeOutsideRouter(String path, String stripped) => [
  if (!routerDirs.any(_normal(path).startsWith))
    for (final match in _route.allMatches(stripped))
      _at(
        stripped,
        match.start,
        'route-outside-router',
        'Routes are declared in lib/app/router/ (app_router.dart); '
            'navigate with AppRoutes from anywhere else',
      ),
];

List<Violation> dataDefinesApiOnly(String path, String stripped) {
  if (_featureLayer(path).$2 != 'data') return const [];
  final declarations = _declaration.allMatches(stripped).toList();
  final classes = declarations.where((m) => m.group(1) == 'class').length;
  if (classes == 1 && declarations.length == 1) return const [];
  final at = declarations.length > 1 ? declarations[1].start : 0;
  return [
    _at(
      stripped,
      at,
      'data-defines-api-only',
      "A feature's data/ file declares its API class and nothing else: a "
          "model it returns lives in the feature's domain/",
    ),
  ];
}

List<Violation> crossFeaturePresentation(String path, String source) {
  final feature = _featureLayer(path).$1;
  if (feature == null) return const [];
  return [
    for (final (end, target) in directiveTargets(_normal(path), source))
      if (_drawnPath.firstMatch(target)?.group(1) case final other?
          when other != feature)
        _at(
          source,
          end,
          'cross-feature-presentation',
          'A widget two features draw with lives in lib/core/widgets/ '
              "('$target' belongs to the $other feature): move it there",
        ),
  ];
}

/// Every rule of this file on one file under `lib/`.
List<Violation> hubViolations(String path, String source, String stripped) => [
  ...httpOutsideApi(path, source),
  ...apiOutsideData(path, source),
  ...jsonOutsideDomain(path, stripped),
  ...routeOutsideRouter(path, stripped),
  ...dataDefinesApiOnly(path, stripped),
  ...crossFeaturePresentation(path, source),
];
