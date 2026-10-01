import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/app_card_theme.dart';

/// Home doorway to the `prophets_tree` section.
///
/// The backdrop is drawn, not shipped as an asset: an elegant Islamic scene
/// in fine gold linework — a mihrab arch framing an onion dome, two slender
/// minarets, a crescent and eight-pointed stars in the sky, an arabesque
/// vine and a pointed-arch arcade along the base. The scene is faded out
/// under the text, which starts on the right in the app's RTL layout. The
/// card spans the full width of the two-column home grid — the width of two
/// tiles — and stays shorter than a tile, so it reads as a door rather than
/// as one more entry.
class ProphetsTreeCard extends StatelessWidget {
  const ProphetsTreeCard({
    super.key,
    required this.title,
    required this.uiOpacity,
    required this.onTap,
  });

  final String title;
  final double uiOpacity;
  final VoidCallback onTap;

  /// What the section holds, in the order its entries are listed.
  static const String subtitle =
      'الرسل والأنبياء · الأئمة الاثني عشر · الفروع النبوية';

  /// Identifies the painted backdrop, so a test can address the lineage tree
  /// itself instead of whichever `CustomPaint` happens to come first.
  static const Key backdropKey = Key('prophetsTreeBackdrop');

  /// The gold of the section, matching `sections.prophets_tree.color` in the
  /// content document and the gold accents of the app's design language.
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.cardColor.contrastTextColor;
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.cardColor.withValues(alpha: uiOpacity),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Color.lerp(
            theme.colorScheme.outlineVariant,
            gold,
            0.6,
          )!
              .withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          key: backdropKey,
          painter: _SacredScenePainter(
            cardColor: theme.cardColor,
            isDark: isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: isDark ? 0.22 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(Icons.account_tree, size: 20, color: gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left,
                  color: foreground.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painted backdrop of [ProphetsTreeCard]: a sacred scene drawn with fine
/// gold linework, faded out under the text side of the card.
///
/// Every element is constructed in fractions of the card size, so the scene
/// scales with the card instead of being cropped: the architecture is sized
/// against the card height (the card is much wider than it is tall), while
/// the sky elements and the vine are positioned across the width.
class _SacredScenePainter extends CustomPainter {
  const _SacredScenePainter({required this.cardColor, required this.isDark});

  final Color cardColor;
  final bool isDark;

  /// The gold of the scene, the accent colour of the app's design language.
  static const Color _gold = Color(0xFFD4AF37);

  /// Emerald of the arabesque vine, a quiet second voice beside the gold.
  static const Color _emerald = Color(0xFF34D399);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Ink weights scale with the card height but stay crisp on small cards.
    double stroke = h * 0.021;
    if (stroke < 1.1) stroke = 1.1;
    if (stroke > 2.0) stroke = 2.0;
    final double fine = stroke * 0.72;

    // Dark cards carry slightly stronger ink so the scene keeps its depth.
    final double lineAlpha = isDark ? 0.62 : 0.50;
    final double softAlpha = isDark ? 0.38 : 0.30;
    final double fillAlpha = isDark ? 0.14 : 0.10;

    final Paint goldLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = _gold.withValues(alpha: lineAlpha);
    final Paint goldSoft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fine
      ..strokeCap = StrokeCap.round
      ..color = _gold.withValues(alpha: softAlpha);
    final Paint goldWash = Paint()
      ..style = PaintingStyle.fill
      ..color = _gold.withValues(alpha: fillAlpha);
    final Paint goldBody = Paint()
      ..style = PaintingStyle.fill
      ..color = _gold.withValues(alpha: isDark ? 0.55 : 0.48);
    final Paint vine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fine
      ..strokeCap = StrokeCap.round
      ..color = _emerald.withValues(alpha: isDark ? 0.42 : 0.34);

    // A warm glow gathers the scene on the side away from the text.
    final glowCenter = Offset(0.21 * w, 0.52 * h);
    final glowRadius = 0.66 * h;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: isDark ? 0.13 : 0.09),
            _gold.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: glowRadius),
        ),
    );

    // A pointed-arch arcade runs along the base of the card, faint enough to
    // read as texture under the text side.
    final archWidth = 0.24 * h;
    final archHeight = 0.32 * h;
    final arcadeStep = 0.115 * w;
    final arcadePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fine
      ..color = _gold.withValues(alpha: isDark ? 0.20 : 0.14);
    for (double x = arcadeStep / 2; x < w; x += arcadeStep) {
      canvas.drawPath(
        _pointedArch(Offset(x, h), archWidth, archHeight),
        arcadePaint,
      );
    }

    // The mihrab arch frames the dome at the heart of the scene.
    canvas.drawPath(
      _pointedArch(Offset(0.30 * w, 0.97 * h), 0.70 * h, 0.76 * h),
      goldSoft,
    );

    // The onion dome, its finial and its base line.
    final domeBase = Offset(0.30 * w, 0.83 * h);
    final dome = _onionDome(domeBase, 0.37 * h, 0.34 * h);
    canvas.drawPath(dome, goldWash);
    canvas.drawPath(dome, goldLine);
    final domeTipY = domeBase.dy - 0.34 * h;
    canvas.drawLine(
      Offset(domeBase.dx, domeTipY),
      Offset(domeBase.dx, domeTipY - 0.085 * h),
      goldLine,
    );
    canvas.drawCircle(
      Offset(domeBase.dx, domeTipY - 0.105 * h),
      stroke * 0.85,
      goldBody,
    );
    canvas.drawLine(
      Offset(0.155 * w, 0.83 * h),
      Offset(0.445 * w, 0.83 * h),
      goldSoft,
    );

    // Two slender minarets guard the composition on either side.
    _minaret(canvas, 0.105 * w, size, goldLine, goldSoft, goldBody);
    _minaret(canvas, 0.495 * w, size, goldLine, goldSoft, goldBody);

    // The crescent rides the sky between the arch and the right minaret.
    canvas.drawPath(
        _crescent(Offset(0.405 * w, 0.19 * h), 0.088 * h), goldBody);

    // Eight-pointed stars scatter across the upper sky.
    canvas.drawPath(
        _eightPointStar(Offset(0.515 * w, 0.24 * h), 0.058 * h), goldSoft);
    canvas.drawPath(
        _eightPointStar(Offset(0.185 * w, 0.155 * h), 0.042 * h), goldSoft);
    canvas.drawPath(
      _eightPointStar(Offset(0.625 * w, 0.58 * h), 0.072 * h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fine
        ..color = _gold.withValues(alpha: isDark ? 0.26 : 0.18),
    );

    // An arabesque vine flows from the architecture towards the text side,
    // carrying leaves and buds; the scrim below lets it recede there.
    final vinePath = Path()
      ..moveTo(0.545 * w, 0.96 * h)
      ..cubicTo(
        0.60 * w,
        1.00 * h,
        0.645 * w,
        0.82 * h,
        0.70 * w,
        0.72 * h,
      )
      ..cubicTo(
        0.755 * w,
        0.62 * h,
        0.83 * w,
        0.62 * h,
        0.90 * w,
        0.50 * h,
      );
    canvas.drawPath(vinePath, vine);
    _leaf(canvas, Offset(0.655 * w, 0.80 * h), 0.075 * h, -2.4, vine);
    _leaf(canvas, Offset(0.775 * w, 0.635 * h), 0.070 * h, -0.5, vine);
    for (final bud in [
      Offset(0.585 * w, 0.945 * h),
      Offset(0.735 * w, 0.665 * h),
      Offset(0.885 * w, 0.525 * h),
    ]) {
      canvas.drawCircle(bud, fine * 0.9, vine);
    }

    // The text starts on the right in the app's right-to-left layout, so the
    // drawing is faded out there and left visible on the other side.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            cardColor.withValues(alpha: 0.94),
            cardColor.withValues(alpha: 0.55),
            cardColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.78],
        ).createShader(Offset.zero & size),
    );
  }

  /// An onion dome standing on [base]: the sides bulge slightly beyond the
  /// base width before gathering to a point, as on mosque domes.
  Path _onionDome(Offset base, double width, double height) {
    final half = width / 2;
    return Path()
      ..moveTo(base.dx - half, base.dy)
      ..cubicTo(
        base.dx - half - width * 0.16,
        base.dy - height * 0.46,
        base.dx - width * 0.20,
        base.dy - height * 0.84,
        base.dx,
        base.dy - height,
      )
      ..cubicTo(
        base.dx + width * 0.20,
        base.dy - height * 0.84,
        base.dx + half + width * 0.16,
        base.dy - height * 0.46,
        base.dx + half,
        base.dy,
      )
      ..close();
  }

  /// A pointed (ogee-style) arch standing on [base], the shape of a mihrab
  /// niche: the shoulders rise straight before meeting in a point.
  Path _pointedArch(Offset base, double width, double height) {
    final half = width / 2;
    return Path()
      ..moveTo(base.dx - half, base.dy)
      ..cubicTo(
        base.dx - half,
        base.dy - height * 0.60,
        base.dx - width * 0.17,
        base.dy - height * 0.82,
        base.dx,
        base.dy - height,
      )
      ..cubicTo(
        base.dx + width * 0.17,
        base.dy - height * 0.82,
        base.dx + half,
        base.dy - height * 0.60,
        base.dx + half,
        base.dy,
      );
  }

  /// A slender minaret at horizontal position [x]: tapered shaft, balcony
  /// ring, a small dome cap and a finial crowned with a bead.
  void _minaret(
    Canvas canvas,
    double x,
    Size size,
    Paint line,
    Paint soft,
    Paint body,
  ) {
    final double h = size.height;
    final double baseY = 0.97 * h;
    final double topY = 0.34 * h;
    final double halfBase = 0.040 * h;
    final double halfTop = 0.030 * h;

    canvas.drawLine(
        Offset(x - halfBase, baseY), Offset(x - halfTop, topY), line);
    canvas.drawLine(
        Offset(x + halfBase, baseY), Offset(x + halfTop, topY), line);

    final double balconyY = topY + (baseY - topY) * 0.16;
    canvas.drawLine(
      Offset(x - halfTop * 1.7, balconyY),
      Offset(x + halfTop * 1.7, balconyY),
      soft,
    );

    final cap = _onionDome(Offset(x, topY), halfTop * 3.1, halfTop * 2.7);
    canvas.drawPath(cap, body);

    final double tipY = topY - halfTop * 2.7;
    canvas.drawLine(Offset(x, tipY), Offset(x, tipY - 0.045 * h), soft);
    canvas.drawCircle(
        Offset(x, tipY - 0.060 * h), line.strokeWidth * 0.8, body);
  }

  /// A crescent opening towards the upper right, built as the difference of
  /// two circles.
  Path _crescent(Offset center, double radius) {
    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final inner = Path()
      ..addOval(
        Rect.fromCircle(
          center: center + Offset(radius * 0.38, -radius * 0.18),
          radius: radius * 0.78,
        ),
      );
    return Path.combine(PathOperation.difference, outer, inner);
  }

  /// An eight-pointed star (khatam): two squares sharing a centre, one
  /// rotated by half a right angle, drawn as a single stroked path.
  Path _eightPointStar(Offset center, double radius) {
    final path = Path();
    for (var square = 0; square < 2; square++) {
      final rotation = pi / 4 + square * pi / 4;
      for (var i = 0; i < 4; i++) {
        final angle = rotation + i * pi / 2;
        final point = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
    }
    return path;
  }

  /// A small leaf of the arabesque vine: a teardrop drawn with two quadratic
  /// curves, turned by [angle] radians around its stem at [base].
  void _leaf(
    Canvas canvas,
    Offset base,
    double length,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticTo(length * 0.5, -length * 0.42, length, 0)
      ..quadraticTo(length * 0.5, length * 0.42, 0, 0)
      ..close();
    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredScenePainter oldDelegate) =>
      oldDelegate.cardColor != cardColor || oldDelegate.isDark != isDark;
}
