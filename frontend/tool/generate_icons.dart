/// Every app icon, on every platform, generated from one source image (#179).
///
/// Run from `frontend/`:
///
///     dart run tool/generate_icons.dart
///
/// The source is `assets/icon/app_icon.png`: square, full-bleed (no rounded
/// corners and no transparency - every platform applies its own mask), with
/// the GG inside the circle of radius 40% of the width, the safe zone a
/// maskable icon promises never to crop. Replace that file and re-run this;
/// no size is drawn by hand.
///
/// Why a script and not `flutter_launcher_icons`: that package writes a 16 px
/// `favicon.png` with no option to change it, and a sharp tab icon needs at
/// least 32. Everything else it would do is a resize and a file name, which
/// is what this file is. The Android adaptive-icon XML and its background
/// colour are committed beside the PNGs this writes, since they name the
/// files rather than depend on the art.
library;

import 'dart:io';

import 'package:image/image.dart';

const _source = 'assets/icon/app_icon.png';

/// The adaptive foreground layer is 108 dp; the source fills 84 dp of it, so
/// the launcher's mask (at most 72 dp) always lands inside the art and the GG
/// (within 40% of the source's width, so 34 dp across) inside the 66 dp safe
/// zone. The ring outside the art shows `ic_launcher_background` (#2D9D78).
const _adaptiveArtDp = 84;
const _adaptiveLayerDp = 108;

/// Android density buckets and their scale over mdpi.
const _androidDensities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  final bytes = File(_source).readAsBytesSync();
  final source = decodePng(bytes);
  if (source == null || source.width != source.height) {
    stderr.writeln('$_source must be a square PNG.');
    exitCode = 1;
    return;
  }
  // Whatever an editor embedded in the source stays out of every output.
  source.textData = null;

  _web(source);
  _android(source);
  _ios(source);
  _macos(source);
  _windows(source);
}

/// [source] at [size] x [size], averaged down or cubic up.
Image _resized(Image source, int size) => copyResize(
  source,
  width: size,
  height: size,
  interpolation: size < source.width
      ? Interpolation.average
      : Interpolation.cubic,
);

void _png(String path, Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(image, level: 9));
  stdout.writeln('${image.width}x${image.height}  $path');
}

/// The manifest's four icons and the tab favicon. The source is already
/// maskable-safe, so the maskable icons are the same pixels.
void _web(Image source) {
  _png('web/favicon.png', _resized(source, 32));
  for (final size in [192, 512]) {
    final icon = _resized(source, size);
    _png('web/icons/Icon-$size.png', icon);
    _png('web/icons/Icon-maskable-$size.png', icon);
  }
}

/// The legacy square launcher icon (48 dp) and the adaptive foreground layer
/// (108 dp) at every density.
void _android(Image source) {
  const res = 'android/app/src/main/res';
  _androidDensities.forEach((bucket, scale) {
    _png(
      '$res/mipmap-$bucket/ic_launcher.png',
      _resized(source, (48 * scale).round()),
    );

    final layer = (_adaptiveLayerDp * scale).round();
    final art = (_adaptiveArtDp * scale).round();
    final foreground = Image(width: layer, height: layer, numChannels: 4);
    compositeImage(
      foreground,
      _resized(source, art),
      dstX: (layer - art) ~/ 2,
      dstY: (layer - art) ~/ 2,
    );
    _png('$res/drawable-$bucket/ic_launcher_foreground.png', foreground);
  });
}

/// Every PNG the iOS asset catalogue already names, at the size its name
/// says (`Icon-App-83.5x83.5@2x.png` is 167 px). No alpha: the App Store
/// refuses an icon that has it.
void _ios(Image source) {
  final pattern = RegExp(r'^Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$');
  const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  for (final file in Directory(dir).listSync().whereType<File>()) {
    final match = pattern.firstMatch(file.uri.pathSegments.last);
    if (match == null) continue;
    final size = (double.parse(match[1]!) * int.parse(match[2]!)).round();
    _png(file.path, _resized(source, size).convert(numChannels: 3));
  }
}

void _macos(Image source) {
  const dir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
  for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
    _png('$dir/app_icon_$size.png', _resized(source, size));
  }
}

void _windows(Image source) {
  const path = 'windows/runner/resources/app_icon.ico';
  final sizes = [16, 32, 48, 256];
  File(path).writeAsBytesSync(
    IcoEncoder().encodeImages([for (final s in sizes) _resized(source, s)]),
  );
  stdout.writeln('${sizes.join('/')}  $path');
}
