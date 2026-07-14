// Generates the launcher icon, adaptive foreground, and splash images from
// the EMIKINGS logo photo. Run once with: dart run tool/prepare_brand_assets.dart
//
// The source is a JPG of the metallic emblem on a dark textured background.
// The emblem is far brighter than the background, so a luminance ramp turns
// darkness into transparency and lifts the mark off cleanly. The wordmark
// under the emblem is excluded by ignoring the bottom band of the image.

import 'dart:io';

import 'package:image/image.dart' as img;

const String sourcePath = 'assets/brand/logo_source.jpg';
const int lumTransparent = 64; // below this, fully transparent
const int lumOpaque = 116; // above this, fully opaque
const int lumSolid = 150; // bounding box only counts pixels this bright
const double emblemBand = 0.68; // emblem lives above this fraction of height

// Brand near-black, used for the full-bleed icon tile.
const int bgR = 0x0B, bgG = 0x0B, bgB = 0x0D;

void main() {
  final source = img.decodeJpg(File(sourcePath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not read $sourcePath');
    exit(1);
  }

  final extracted = _extractEmblem(source);
  final emblem = _cropToContent(extracted);

  File('assets/brand/emblem.png')
      .writeAsBytesSync(img.encodePng(_onSquareCanvas(emblem, 1024, 0.92)));
  File('assets/brand/splash_logo.png')
      .writeAsBytesSync(img.encodePng(_onSquareCanvas(emblem, 1024, 0.62)));

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(_onSquareCanvas(emblem, 1024, 0.56)));

  final tile = _onSquareCanvas(emblem, 1024, 0.72);
  final flattened = img.Image(width: 1024, height: 1024);
  img.fill(flattened, color: img.ColorRgb8(bgR, bgG, bgB));
  img.compositeImage(flattened, tile);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(flattened));

  stdout.writeln('Brand assets written: emblem, splash_logo, icon, foreground');
}

/// Turn the dark background transparent with a soft luminance ramp so the
/// metallic edges keep their anti-aliasing.
img.Image _extractEmblem(img.Image source) {
  final out = img.Image(
      width: source.width, height: source.height, numChannels: 4);
  final cutoffY = (source.height * emblemBand).round();

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      final lum = img.getLuminanceRgb(p.r, p.g, p.b);
      int alpha;
      if (y >= cutoffY || lum <= lumTransparent) {
        alpha = 0;
      } else if (lum >= lumOpaque) {
        alpha = 255;
      } else {
        alpha = ((lum - lumTransparent) * 255 ~/ (lumOpaque - lumTransparent));
      }
      out.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
    }
  }
  return out;
}

/// Crop to the bounding box of strongly bright pixels, with a small margin.
/// Faint texture highlights never reach [lumSolid], so they cannot stretch
/// the box even if they survive the alpha ramp.
img.Image _cropToContent(img.Image image) {
  var minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      if (p.a > 128 && img.getLuminanceRgb(p.r, p.g, p.b) >= lumSolid) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final margin = ((maxX - minX) * 0.03).round();
  minX = (minX - margin).clamp(0, image.width - 1);
  minY = (minY - margin).clamp(0, image.height - 1);
  maxX = (maxX + margin).clamp(0, image.width - 1);
  maxY = (maxY + margin).clamp(0, image.height - 1);
  return img.copyCrop(image,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

/// Center the emblem on a transparent square canvas, scaled so its longest
/// side fills [fill] of the canvas.
img.Image _onSquareCanvas(img.Image emblem, int size, double fill) {
  final target = (size * fill).round();
  final scale = target /
      (emblem.width > emblem.height ? emblem.width : emblem.height);
  final resized = img.copyResize(
    emblem,
    width: (emblem.width * scale).round(),
    height: (emblem.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - resized.width) ~/ 2,
    dstY: (size - resized.height) ~/ 2,
  );
  return canvas;
}
