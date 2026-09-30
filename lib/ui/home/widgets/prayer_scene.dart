import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../prayer_scene_period.dart';

/// Resolution-independent reconstruction of the concept's mosque skyline,
/// cropped geometric rosettes and upper-left sky. No bitmap scaling, network
/// requests or Material-icon silhouettes. All decoration is non-interactive.
class PrayerScene extends StatelessWidget {
  const PrayerScene({super.key, required this.period});
  final PrayerScenePeriod period;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: PrayerScenePainter(period: period)),
          ),
        ),
      );
}

class PrayerScenePainter extends CustomPainter {
  const PrayerScenePainter({required this.period});
  final PrayerScenePeriod period;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final day = period == PrayerScenePeriod.day;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: day
                ? const [
                    Color(0xFF2D604D),
                    Color(0xFF1A4035),
                    Color(0xFF15372E)
                  ]
                : const [
                    Color(0xFF214D3D),
                    Color(0xFF16392F),
                    Color(0xFF102B24)
                  ],
          ).createShader(rect));

    // Reference composition is 420×220. Keep architectural proportions uniform
    // at each width; pin the horizon to the bottom on tall accessibility cards.
    final scale = size.width / 420;
    final height = size.height / scale;
    canvas.scale(scale);
    if (day) {
      _sun(canvas, const Offset(72, 41));
      _cloud(canvas, const Offset(103, 57));
      _cloud(canvas, Offset(342, height * .43));
      _birds(canvas, const Offset(128, 45));
    } else {
      _moon(canvas, const Offset(72, 41), 23,
          const Color(0xFF677450).withValues(alpha: .58));
      for (final point in [
        const Offset(40, 50),
        const Offset(62, 85),
        Offset(342, height * .34),
        Offset(372, height * .52),
      ]) {
        _star(canvas, point, 2.4);
      }
    }

    // Recessed side ornament: no pattern is drawn across the prayer text.
    _rosette(canvas, Offset(12, height * .49), 38);
    _rosette(canvas, Offset(408, height * .49), 38);

    // Two receding skyline layers, as in the reference, leave the centre quiet.
    final far = day ? const Color(0xFF214B3D) : const Color(0xFF193F33);
    _mosque(canvas, 17, height + 7, 48, 99, far);
    _mosque(canvas, 403, height + 7, 48, 99, far);
    _minaret(canvas, 45, height, 10, 86, far);
    _minaret(canvas, 375, height, 10, 86, far);

    final near = day ? const Color(0xFF153C30) : const Color(0xFF0F2F26);
    _mosque(canvas, 87, height + 1, 69, 110, near);
    _mosque(canvas, 333, height + 1, 69, 110, near);
    _mosque(canvas, 22, height + 5, 27, 53, near);
    _mosque(canvas, 398, height + 5, 27, 53, near);

    // Soft horizon blends the architecture into the base, not into the text.
    final horizon = Rect.fromLTWH(0, height - 45, 420, 45);
    canvas.drawRect(
        horizon,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (day ? const Color(0xFF15372E) : const Color(0xFF102B24))
                  .withValues(alpha: 0),
              day ? const Color(0xFF15372E) : const Color(0xFF102B24),
            ],
          ).createShader(horizon));
    canvas.restore();
  }

  void _moon(Canvas canvas, Offset center, double radius, Color color) {
    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final cutout = Path()
      ..addOval(Rect.fromCircle(
        center: center + Offset(radius * .48, -radius * .24),
        radius: radius * .94,
      ));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, cutout),
        Paint()..color = color);
  }

  void _sun(Canvas canvas, Offset center) {
    final glow = Rect.fromCircle(center: center, radius: 38);
    canvas.drawCircle(
        center,
        38,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x307F915B), Color(0x007F915B)],
          ).createShader(glow));
    final paint = Paint()
      ..color = const Color(0xFFB8A66A).withValues(alpha: .5);
    canvas.drawCircle(center, 13, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + direction * 18, center + direction * 22, paint);
    }
  }

  void _cloud(Canvas canvas, Offset origin) {
    final path = Path()
      ..moveTo(origin.dx - 20, origin.dy)
      ..cubicTo(origin.dx - 22, origin.dy - 7, origin.dx - 12, origin.dy - 11,
          origin.dx - 7, origin.dy - 6)
      ..cubicTo(origin.dx - 2, origin.dy - 19, origin.dx + 15, origin.dy - 17,
          origin.dx + 17, origin.dy - 6)
      ..cubicTo(origin.dx + 31, origin.dy - 10, origin.dx + 36, origin.dy,
          origin.dx + 29, origin.dy + 3)
      ..lineTo(origin.dx - 16, origin.dy + 3)
      ..close();
    canvas.drawPath(
        path, Paint()..color = const Color(0xFF91A182).withValues(alpha: .17));
  }

  void _birds(Canvas canvas, Offset origin) {
    final paint = Paint()
      ..color = const Color(0xFF9CAA85).withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final p = origin + Offset(i * 15, -i * 5);
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 5, p.dy)
            ..quadraticBezierTo(p.dx - 2, p.dy - 2, p.dx, p.dy + 1)
            ..quadraticBezierTo(p.dx + 2, p.dy - 2, p.dx + 5, p.dy),
          paint);
    }
  }

  void _star(Canvas canvas, Offset p, double r) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..lineTo(p.dx + r * .25, p.dy - r * .25)
      ..lineTo(p.dx + r, p.dy)
      ..lineTo(p.dx + r * .25, p.dy + r * .25)
      ..lineTo(p.dx, p.dy + r)
      ..lineTo(p.dx - r * .25, p.dy + r * .25)
      ..lineTo(p.dx - r, p.dy)
      ..lineTo(p.dx - r * .25, p.dy - r * .25)
      ..close();
    canvas.drawPath(
        path, Paint()..color = const Color(0xFFBCAA71).withValues(alpha: .32));
  }

  void _rosette(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFB49E62).withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 8);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: radius * 1.38, height: radius * 1.38),
          paint);
      canvas.restore();
    }
    for (final factor in [.73, 1.15]) {
      final path = Path();
      for (var i = 0; i < 16; i++) {
        final angle = i * math.pi / 8;
        final r = radius * factor * (i.isEven ? 1 : .76);
        final p = Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path..close(), paint);
    }
    canvas.restore();
  }

  void _mosque(Canvas canvas, double x, double base, double width,
      double height, Color color) {
    final top = base - height;
    final half = width / 2;
    final shoulder = top + height * .48;
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(x - half, base)
      ..lineTo(x - half, shoulder)
      ..cubicTo(x - half * 1.12, top + height * .29, x - half * .25,
          top + height * .21, x, top + height * .08)
      ..cubicTo(x + half * .25, top + height * .21, x + half * 1.12,
          top + height * .29, x + half, shoulder)
      ..lineTo(x + half, base)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawRect(Rect.fromLTWH(x - .7, top - 6, 1.4, height * .16), paint);
    _moon(canvas, Offset(x + 1, top - 10), 6, color);
  }

  void _minaret(Canvas canvas, double x, double base, double width,
      double height, Color color) {
    final top = base - height;
    final path = Path()
      ..moveTo(x - width / 2, base)
      ..lineTo(x - width / 3, top + 16)
      ..lineTo(x - width / 2, top + 13)
      ..lineTo(x - width / 3, top + 9)
      ..lineTo(x, top)
      ..lineTo(x + width / 3, top + 9)
      ..lineTo(x + width / 2, top + 13)
      ..lineTo(x + width / 3, top + 16)
      ..lineTo(x + width / 2, base)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant PrayerScenePainter oldDelegate) =>
      oldDelegate.period != period;
}
