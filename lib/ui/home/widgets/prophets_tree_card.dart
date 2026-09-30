import 'package:flutter/material.dart';

import '../../../theme/app_card_theme.dart';

/// Home doorway to the `prophets_tree` section.
///
/// The backdrop is drawn, not shipped as an asset: one trunk carrying the
/// messengers (gold), the prophets (emerald), the imams (blue) and the
/// infallibles of the Prophet's house (rose and red). The card spans the full
/// width of the two-column home grid — the width of two tiles — and stays
/// shorter than a tile, so it reads as a door rather than as one more entry.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.cardColor.contrastTextColor;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.cardColor.withValues(alpha: uiOpacity),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: _LineageTreePainter(
            cardColor: theme.cardColor,
            foreground: foreground,
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.account_tree,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
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

/// Painted backdrop of [ProphetsTreeCard]: a lineage tree whose nodes are the
/// messengers, the prophets and the infallibles, faded out under the text.
class _LineageTreePainter extends CustomPainter {
  const _LineageTreePainter({
    required this.cardColor,
    required this.foreground,
  });

  final Color cardColor;
  final Color foreground;

  /// Node colours of the tree, matching the palette of the tree content.
  static const Color _messenger = Color(0xFFFBBF24);
  static const Color _prophet = Color(0xFF34D399);
  static const Color _imam = Color(0xFF60A5FA);
  static const Color _lady = Color(0xFFF472B6);
  static const Color _martyr = Color(0xFFF87171);

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry is authored in a unit square whose origin is the bottom centre
    // of the card, so the tree scales with the card instead of being cropped.
    Offset at(double x, double y) =>
        Offset(x * size.width, (1 - y) * size.height);

    final Paint branch = Paint()
      ..color = foreground.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    void link(
      double fx,
      double fy,
      double tx,
      double ty,
      double cx,
      double cy,
    ) {
      final from = at(fx, fy);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(
          at(cx, cy).dx,
          at(cx, cy).dy,
          at(tx, ty).dx,
          at(tx, ty).dy,
        );
      canvas.drawPath(path, branch);
    }

    void node(double x, double y, Color color, {double radius = 0.075}) {
      final center = at(x, y);
      final glow = radius * 2.8 * size.height;
      canvas.drawCircle(
        center,
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: glow)),
      );
      canvas.drawCircle(
        center,
        radius * size.height,
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }

    // Trunk, three pairs of branches, and the crown of messengers. Every
    // coordinate stays inside the unit square so no node is cropped away.
    link(0.5, 0.02, 0.5, 0.88, 0.45, 0.45);
    link(0.5, 0.55, 0.12, 0.62, 0.3, 0.55);
    link(0.5, 0.55, 0.88, 0.62, 0.7, 0.55);
    link(0.5, 0.32, 0.05, 0.38, 0.26, 0.3);
    link(0.5, 0.32, 0.95, 0.38, 0.74, 0.3);
    link(0.5, 0.12, 0.18, 0.14, 0.33, 0.1);
    link(0.5, 0.12, 0.82, 0.14, 0.67, 0.1);

    node(0.5, 0.88, _messenger);
    node(0.12, 0.62, _prophet);
    node(0.88, 0.62, _prophet);
    node(0.05, 0.38, _imam);
    node(0.95, 0.38, _imam);
    node(0.18, 0.14, _lady);
    node(0.82, 0.14, _martyr);

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

  @override
  bool shouldRepaint(covariant _LineageTreePainter oldDelegate) =>
      oldDelegate.cardColor != cardColor ||
      oldDelegate.foreground != foreground;
}
