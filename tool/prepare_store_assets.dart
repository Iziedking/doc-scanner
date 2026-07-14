// Generates the Play Console graphics from the extracted emblem. Run after
// prepare_brand_assets.dart with: dart run tool/prepare_store_assets.dart
//
// Outputs to docs/store-assets/:
//   play-icon-512.png          the 512 store icon
//   feature-graphic-1024x500.png  emblem centered on brand black

import 'dart:io';

import 'package:image/image.dart' as img;

const int bgR = 0x0B, bgG = 0x0B, bgB = 0x0D;

void main() {
  final icon = img.decodePng(File('assets/icon/icon.png').readAsBytesSync());
  final emblem = img.decodePng(File('assets/brand/emblem.png').readAsBytesSync());
  if (icon == null || emblem == null) {
    stderr.writeln('Run tool/prepare_brand_assets.dart first.');
    exit(1);
  }

  Directory('docs/store-assets').createSync(recursive: true);

  final store512 = img.copyResize(icon,
      width: 512, height: 512, interpolation: img.Interpolation.cubic);
  File('docs/store-assets/play-icon-512.png')
      .writeAsBytesSync(img.encodePng(store512));

  final feature = img.Image(width: 1024, height: 500);
  img.fill(feature, color: img.ColorRgb8(bgR, bgG, bgB));
  final target = 360; // emblem height inside the 500 tall canvas
  final scale = target / emblem.height;
  final resized = img.copyResize(
    emblem,
    width: (emblem.width * scale).round(),
    height: target,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    feature,
    resized,
    dstX: (1024 - resized.width) ~/ 2,
    dstY: (500 - target) ~/ 2,
  );
  File('docs/store-assets/feature-graphic-1024x500.png')
      .writeAsBytesSync(img.encodePng(feature));

  stdout.writeln('Store assets written to docs/store-assets');
}
