// Line-art illustrations for onboarding, drawn in code so they stay crisp at
// any size and match the brand exactly: thin gold strokes, silver-grey
// secondary lines, nothing filled. One drawing per onboarding page.

import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum OnboardingArt { scan, organize, private }

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration(this.art, {super.key});

  final OnboardingArt art;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: switch (art) {
          OnboardingArt.scan => _ScanPainter(),
          OnboardingArt.organize => _OrganizePainter(),
          OnboardingArt.private => _PrivatePainter(),
        },
      ),
    );
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

/// A document sheet inside scanner corner brackets, with a scan line resting
/// a third of the way down.
class _ScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = _stroke(BrandColors.gold, size.width * 0.012);
    final grey = _stroke(BrandColors.textLow, size.width * 0.009);

    final w = size.width;
    final h = size.height;

    // Corner brackets of the scan frame.
    final inset = w * 0.12;
    final arm = w * 0.10;
    for (final (cx, cy, dx, dy) in [
      (inset, inset, 1.0, 1.0),
      (w - inset, inset, -1.0, 1.0),
      (inset, h - inset, 1.0, -1.0),
      (w - inset, h - inset, -1.0, -1.0),
    ]) {
      canvas.drawLine(
          Offset(cx, cy), Offset(cx + arm * dx, cy), gold);
      canvas.drawLine(
          Offset(cx, cy), Offset(cx, cy + arm * dy), gold);
    }

    // The paper, slightly rotated so it reads as a physical sheet.
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.04);
    final sheet = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset.zero, width: w * 0.42, height: h * 0.56),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(sheet, grey);

    // Text lines on the sheet.
    final left = -w * 0.15;
    for (var i = 0; i < 5; i++) {
      final y = -h * 0.18 + i * h * 0.07;
      final len = i == 4 ? w * 0.16 : w * 0.30;
      canvas.drawLine(Offset(left, y), Offset(left + len, y), grey);
    }
    canvas.restore();

    // The scan line, the only strong gold element.
    canvas.drawLine(
        Offset(w * 0.2, h * 0.42), Offset(w * 0.8, h * 0.42), gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three stacked document outlines settling into a folder tray.
class _OrganizePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = _stroke(BrandColors.gold, size.width * 0.012);
    final grey = _stroke(BrandColors.textLow, size.width * 0.009);

    final w = size.width;
    final h = size.height;

    // Two sheets behind, offset like a fanned stack.
    for (final (dx, dy) in [(-0.05, -0.06), (0.05, -0.03)]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * (0.5 + dx), h * (0.38 + dy)),
          width: w * 0.34,
          height: h * 0.42,
        ),
        Radius.circular(w * 0.02),
      );
      canvas.drawRRect(r, grey);
    }

    // The front sheet.
    final front = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.40), width: w * 0.34, height: h * 0.42),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(front, gold);

    // The folder tray they drop into.
    final tray = Path()
      ..moveTo(w * 0.18, h * 0.68)
      ..lineTo(w * 0.26, h * 0.60)
      ..lineTo(w * 0.42, h * 0.60)
      ..lineTo(w * 0.46, h * 0.66)
      ..lineTo(w * 0.82, h * 0.66)
      ..lineTo(w * 0.82, h * 0.86)
      ..lineTo(w * 0.18, h * 0.86)
      ..close();
    canvas.drawPath(tray, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A phone outline holding a document, ringed by a shield arc: everything
/// stays inside the device.
class _PrivatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = _stroke(BrandColors.gold, size.width * 0.012);
    final grey = _stroke(BrandColors.textLow, size.width * 0.009);

    final w = size.width;
    final h = size.height;

    // The phone.
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5), width: w * 0.34, height: h * 0.58),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(phone, gold);

    // The document inside it.
    final doc = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.48), width: w * 0.20, height: h * 0.26),
      Radius.circular(w * 0.015),
    );
    canvas.drawRRect(doc, grey);
    for (var i = 0; i < 3; i++) {
      final y = h * 0.42 + i * h * 0.05;
      canvas.drawLine(
          Offset(w * 0.44, y), Offset(w * 0.56, y), grey);
    }

    // Shield arcs around the phone, open at the bottom.
    final arcRect =
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.34);
    canvas.drawArc(arcRect, 3.60, 1.50, false, grey);
    canvas.drawArc(arcRect, 6.30, 1.50, false, grey);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
