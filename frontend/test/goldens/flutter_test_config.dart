import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test under `test/goldens/` (flutter_test's per-directory
/// hook): it loads the fonts the app really draws with, so a golden shows
/// words and icons instead of the test font's boxes (#226).
///
/// Nothing is fetched. The app names `Roboto` (`AppTheme`) and bundles no font
/// of its own — on the web the engine supplies Roboto — so the files come from
/// the pinned Flutter SDK, which ships them in
/// `bin/cache/artifacts/material_fonts/`: the same bytes here and on CI, since
/// both install exactly `environment.flutter`. The icon fonts (Material Icons,
/// Font Awesome) are the app's own assets, listed in the test bundle's
/// `FontManifest.json`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadRoboto();
  await _loadBundledFonts();
  await testMain();
}

/// The SDK's `material_fonts` directory. `FLUTTER_ROOT` is set by
/// `flutter test`; the tester binary's own path is the fallback, since it
/// lives under the same `bin/cache/artifacts/`.
Directory _materialFonts() {
  final root = Platform.environment['FLUTTER_ROOT'];
  final artifacts = root != null
      ? '$root/bin/cache/artifacts'
      : File(Platform.resolvedExecutable).parent.parent.parent.path;
  return Directory('$artifacts/material_fonts');
}

Future<void> _loadRoboto() async {
  final dir = _materialFonts();
  final files = dir.existsSync()
      ? dir
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'/Roboto-\w+\.ttf$').hasMatch(f.path))
          .toList()
      : <File>[];
  if (files.isEmpty) {
    throw StateError('No Roboto in ${dir.path}: the goldens would draw boxes. '
        'Run `flutter precache` so the SDK fetches its material fonts.');
  }
  final loader = FontLoader('Roboto');
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _loadBundledFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json'))
      as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
