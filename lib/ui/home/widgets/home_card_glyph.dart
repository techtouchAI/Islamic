import 'package:flutter/material.dart';

/// Hand-drawn line icons for the home cards.
///
/// Every home card used to share one book icon, which made different
/// collections look identical. These glyphs are drawn on a 24 x 24 grid and
/// stroked with the card's own colour, so they follow the app theme, the accent
/// colour and the user's opacity without shipping raster assets.
///
/// Outlines are open stroked paths, never filled shapes. The geometry is
/// reviewed as PNG contact sheets before being ported here. `p.arc` takes
/// screen angles in degrees: 0 is east, 90 is south and 270 is north.
enum HomeCardGlyph {
  mushaf,
  dome,
  scroll,
  dua,
  crescent,
  kaaba,
  shield,
  hadith,
  rosette,
  beads,
  scales,
  pen,
  ark,
  guidance,
  bookmark,
}

/// Draws one entry's glyph in [color] at [size] logical pixels.
class HomeCardGlyphIcon extends StatelessWidget {
  const HomeCardGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 26,
    this.strokeWidth = 1.6,
  });

  final HomeCardGlyph glyph;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _HomeCardGlyphPainter(
            glyph: glyph,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      );
}

class _HomeCardGlyphPainter extends CustomPainter {
  const _HomeCardGlyphPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final HomeCardGlyph glyph;
  final Color color;
  final double strokeWidth;

  /// The artwork is authored on this square and scaled to the requested size.
  static const double _grid = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final build = _glyphOutlines[glyph];
    if (build == null) return;
    final scale = size.shortestSide / _grid;
    if (scale <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Stroke stays in logical pixels at every size, so a glyph looks the same
      // at 18, 26 or 64 pixels.
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final pen = _Pen();
    build(pen);
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(pen.path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HomeCardGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Minimal path builder with degree-based ellipse arcs.
class _Pen {
  /// Radians per degree (`pi / 180`), as a literal so this leaf widget needs
  /// neither `dart:math` nor a runtime conversion.
  static const double _degreesToRadians = 0.017453292519943295;

  final Path path = Path();

  void move(double x, double y) => path.moveTo(x, y);

  void line(double x, double y) => path.lineTo(x, y);

  void quad(double cx, double cy, double x, double y) {
    path.quadraticBezierTo(cx, cy, x, y);
  }

  void cubic(
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double x,
    double y,
  ) {
    path.cubicTo(c1x, c1y, c2x, c2y, x, y);
  }

  void arc(double cx, double cy, double r, double from, double to) {
    arcOval(cx, cy, r, r, from, to);
  }

  void arcOval(
    double cx,
    double cy,
    double rx,
    double ry,
    double from,
    double to,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    final startRadians = from * _degreesToRadians;
    final sweepRadians = (to - from) * _degreesToRadians;
    path.arcTo(rect, startRadians, sweepRadians, false);
  }

  void close() => path.close();
}

/// Stroke-only outline for every glyph; verified by rasterising the same
/// coordinate list before it was ported.
final Map<HomeCardGlyph, void Function(_Pen)> _glyphOutlines = {
  HomeCardGlyph.mushaf: (p) {
    p.move(12, 8.6);
    p.line(12, 17.6);
    p.move(12, 8.6);
    p.quad(8.4, 6.9, 4.6, 8.2);
    p.line(4.6, 17);
    p.quad(8.4, 15.7, 12, 17.6);
    p.move(12, 8.6);
    p.quad(15.6, 6.9, 19.4, 8.2);
    p.line(19.4, 17);
    p.quad(15.6, 15.7, 12, 17.6);
    p.move(12, 3.2);
    p.quad(12.27, 4.43, 13.5, 4.7);
    p.quad(12.27, 4.97, 12, 6.2);
    p.quad(11.73, 4.97, 10.5, 4.7);
    p.quad(11.73, 4.43, 12, 3.2);
    p.close();
  },
  HomeCardGlyph.dome: (p) {
    p.move(8.2, 11.7);
    p.arc(12, 11.7, 3.8, 180, 360);
    p.move(5.7, 11.7);
    p.line(18.3, 11.7);
    p.move(6.9, 11.7);
    p.line(6.9, 18.6);
    p.line(17.1, 18.6);
    p.line(17.1, 11.7);
    p.move(10.2, 18.6);
    p.line(10.2, 16);
    p.arc(12, 16, 1.8, 180, 360);
    p.line(13.8, 18.6);
    p.move(12, 7.9);
    p.line(12, 5.6);
    p.move(12, 3.8);
    p.arc(12, 4.6, 0.8, -90, 90);
    p.arc(12, 4.6, 0.8, 90, 270);
    p.move(5.5, 11.7);
    p.arc(6.3, 11.7, 0.8, 180, 360);
    p.move(16.5, 11.7);
    p.arc(17.3, 11.7, 0.8, 180, 360);
  },
  HomeCardGlyph.scroll: (p) {
    p.move(7.7, 6.5);
    p.line(16.3, 6.5);
    p.move(7.7, 17.6);
    p.line(16.3, 17.6);
    p.move(7.7, 6.5);
    p.line(7.7, 17.6);
    p.move(16.3, 6.5);
    p.line(16.3, 17.6);
    p.move(10, 10.4);
    p.line(14, 10.4);
    p.move(10, 13);
    p.line(14, 13);
    p.move(11, 15.4);
    p.line(13, 15.4);
    p.move(5.9, 6.5);
    p.arc(6.9, 6.5, 1, 180, 360);
    p.line(16.1, 6.5);
    p.arc(17.1, 6.5, 1, 180, 360);
    p.move(5.9, 17.6);
    p.arc(6.9, 17.6, 1, 180, 360);
    p.line(16.1, 17.6);
    p.arc(17.1, 17.6, 1, 180, 360);
  },
  HomeCardGlyph.dua: (p) {
    p.move(5.6, 19.4);
    p.line(18.4, 19.4);
    p.move(6.8, 19.4);
    p.line(6.8, 11.6);
    p.cubic(6.8, 7.6, 9.1, 5.4, 12, 5.4);
    p.cubic(14.9, 5.4, 17.2, 7.6, 17.2, 11.6);
    p.line(17.2, 19.4);
    p.move(12, 6);
    p.line(12, 8.8);
    p.move(10.4, 8.8);
    p.line(13.6, 8.8);
    p.line(12.9, 12.2);
    p.line(11.1, 12.2);
    p.close();
    p.move(12, 12.4);
    p.arc(12, 13, 0.6, -90, 90);
    p.arc(12, 13, 0.6, 90, 270);
  },
  HomeCardGlyph.crescent: (p) {
    p.move(16.4, 7.5);
    p.arc(11.2, 12, 6.87677, -40.8724, -319.128);
    p.arc(13.8, 12, 5.19711, 59.9816, 300.018);
    p.move(18.2, 4.6);
    p.quad(18.434, 5.666, 19.5, 5.9);
    p.quad(18.434, 6.134, 18.2, 7.2);
    p.quad(17.966, 6.134, 16.9, 5.9);
    p.quad(17.966, 5.666, 18.2, 4.6);
    p.close();
    p.move(19.4, 10.28);
    p.arc(19.4, 10.9, 0.62, -90, 90);
    p.arc(19.4, 10.9, 0.62, 90, 270);
  },
  HomeCardGlyph.kaaba: (p) {
    p.move(6.6, 6.9);
    p.line(17.4, 6.9);
    p.line(17.4, 18.3);
    p.line(6.6, 18.3);
    p.close();
    p.move(6.6, 10.3);
    p.line(17.4, 10.3);
    p.move(6.6, 11.5);
    p.line(17.4, 11.5);
    p.move(12.1, 18.3);
    p.line(12.1, 13.7);
    p.line(15.2, 13.7);
    p.line(15.2, 18.3);
    p.move(4.4, 19.5);
    p.line(19.6, 19.5);
  },
  HomeCardGlyph.shield: (p) {
    p.move(12, 3.9);
    p.cubic(14.6, 5.3, 17.2, 6, 19.5, 6.2);
    p.line(19.5, 12.5);
    p.cubic(19.5, 16.7, 16.3, 19.4, 12, 20.4);
    p.cubic(7.7, 19.4, 4.5, 16.7, 4.5, 12.5);
    p.line(4.5, 6.2);
    p.cubic(6.8, 6, 9.4, 5.3, 12, 3.9);
    p.close();
    p.move(8.7, 11.2);
    p.line(12, 14.3);
    p.line(15.3, 11.2);
  },
  HomeCardGlyph.hadith: (p) {
    p.move(8, 5.6);
    p.line(16, 5.6);
    p.arc(16, 8.2, 2.6, -90, 0);
    p.line(18.6, 12.8);
    p.arc(16, 12.8, 2.6, 0, 90);
    p.line(10.6, 15.4);
    p.line(8.6, 18.6);
    p.line(8, 15.4);
    p.arc(8, 12.8, 2.6, 90, 180);
    p.line(5.4, 8.2);
    p.arc(8, 8.2, 2.6, 180, 270);
    p.move(9.2, 9.4);
    p.line(14.8, 9.4);
    p.move(9.2, 12.1);
    p.line(12.9, 12.1);
  },
  HomeCardGlyph.rosette: (p) {
    p.move(7.4, 7);
    p.line(16.6, 7);
    p.line(16.6, 15.8);
    p.line(7.4, 15.8);
    p.close();
    p.move(12, 5.1);
    p.line(18.3, 11.4);
    p.line(12, 17.7);
    p.line(5.7, 11.4);
    p.close();
    p.move(12, 10.05);
    p.arc(12, 11.4, 1.35, -90, 90);
    p.arc(12, 11.4, 1.35, 90, 270);
  },
  HomeCardGlyph.beads: (p) {
    p.move(12, 3.54);
    p.arc(12, 4.2, 0.66, -90, 90);
    p.arc(12, 4.2, 0.66, 90, 270);
    p.move(15.1, 4.37064);
    p.arc(15.1, 5.03064, 0.66, -90, 90);
    p.arc(15.1, 5.03064, 0.66, 90, 270);
    p.move(17.3694, 6.64);
    p.arc(17.3694, 7.3, 0.66, -90, 90);
    p.arc(17.3694, 7.3, 0.66, 90, 270);
    p.move(18.2, 9.74);
    p.arc(18.2, 10.4, 0.66, -90, 90);
    p.arc(18.2, 10.4, 0.66, 90, 270);
    p.move(17.3694, 12.84);
    p.arc(17.3694, 13.5, 0.66, -90, 90);
    p.arc(17.3694, 13.5, 0.66, 90, 270);
    p.move(15.1, 15.1094);
    p.arc(15.1, 15.7694, 0.66, -90, 90);
    p.arc(15.1, 15.7694, 0.66, 90, 270);
    p.move(12, 15.94);
    p.arc(12, 16.6, 0.66, -90, 90);
    p.arc(12, 16.6, 0.66, 90, 270);
    p.move(8.9, 15.1094);
    p.arc(8.9, 15.7694, 0.66, -90, 90);
    p.arc(8.9, 15.7694, 0.66, 90, 270);
    p.move(6.63064, 12.84);
    p.arc(6.63064, 13.5, 0.66, -90, 90);
    p.arc(6.63064, 13.5, 0.66, 90, 270);
    p.move(5.8, 9.74);
    p.arc(5.8, 10.4, 0.66, -90, 90);
    p.arc(5.8, 10.4, 0.66, 90, 270);
    p.move(6.63064, 6.64);
    p.arc(6.63064, 7.3, 0.66, -90, 90);
    p.arc(6.63064, 7.3, 0.66, 90, 270);
    p.move(8.9, 4.37064);
    p.arc(8.9, 5.03064, 0.66, -90, 90);
    p.arc(8.9, 5.03064, 0.66, 90, 270);
    p.move(12, 16.6);
    p.line(12, 18.1);
    p.move(11.1, 18.1);
    p.line(12.9, 18.1);
    p.line(12, 20.7);
    p.close();
  },
  HomeCardGlyph.scales: (p) {
    p.move(12, 4.3);
    p.line(12, 19);
    p.move(8.7, 19.2);
    p.line(15.3, 19.2);
    p.move(5, 7.4);
    p.line(19, 7.4);
    p.move(5, 7.4);
    p.line(6.7, 11);
    p.arc(5, 11, 1.7, 0, 180);
    p.line(5, 7.4);
    p.move(19, 7.4);
    p.line(20.7, 11);
    p.arc(19, 11, 1.7, 0, 180);
    p.line(19, 7.4);
    p.move(12, 2.7);
    p.arc(12, 3.5, 0.8, -90, 90);
    p.arc(12, 3.5, 0.8, 90, 270);
  },
  HomeCardGlyph.pen: (p) {
    p.move(17.4, 4.9);
    p.line(11.2, 11.1);
    p.move(18.9, 6.4);
    p.line(12.7, 12.6);
    p.move(17.4, 4.9);
    p.line(18.9, 6.4);
    p.move(11.2, 11.1);
    p.line(12.7, 12.6);
    p.move(11.2, 11.1);
    p.line(8.1, 15.5);
    p.line(12.7, 12.6);
    p.move(11.1, 13.2);
    p.line(10.2, 14.1);
    p.move(6.2, 18.4);
    p.cubic(9, 17.7, 12.4, 17.7, 16.2, 18.6);
  },
  HomeCardGlyph.ark: (p) {
    p.move(4.6, 13.4);
    p.line(19.4, 13.4);
    p.line(17.4, 17.2);
    p.quad(12, 18.8, 6.6, 17.2);
    p.close();
    p.move(12, 13.4);
    p.line(12, 6.4);
    p.move(12, 7.2);
    p.cubic(14.4, 8.6, 16, 10.6, 16.4, 12.6);
    p.line(12, 12.6);
    p.close();
    p.move(3.6, 20.7);
    p.quad(6.1, 19.4, 8.6, 20.7);
    p.quad(11.1, 22, 13.6, 20.7);
    p.quad(16.1, 19.4, 18.6, 20.7);
  },
  HomeCardGlyph.guidance: (p) {
    p.move(12, 13.2);
    p.line(12, 19.4);
    p.move(12, 13.2);
    p.quad(8.6, 11.6, 5, 12.6);
    p.line(5, 18.6);
    p.quad(8.6, 17.6, 12, 19.4);
    p.move(12, 13.2);
    p.quad(15.4, 11.6, 19, 12.6);
    p.line(19, 18.6);
    p.quad(15.4, 17.6, 12, 19.4);
    p.move(12, 9.8);
    p.line(12, 4.4);
    p.move(9.9, 6.4);
    p.line(12, 4.2);
    p.line(14.1, 6.4);
  },
  HomeCardGlyph.bookmark: (p) {
    p.move(7.6, 4.6);
    p.line(16.4, 4.6);
    p.line(16.4, 20.2);
    p.line(12, 16.6);
    p.line(7.6, 20.2);
    p.close();
  },
};


/// Picks the glyph that matches a home card.
///
/// The section key is authoritative because it is stable; the title is only a
/// fallback for keys added later to the content document. Unknown entries fall
/// back to a bookmark rather than a generic book, so a new section never looks
/// like a duplicate of the Quran card.
HomeCardGlyph resolveHomeCardGlyph({String? sectionKey, String? title}) {
  // Category keys such as `imam_ali_cat_3` resolve by trimming trailing
  // segments until a known section key is found.
  var candidate = (sectionKey ?? '').trim().toLowerCase();
  while (candidate.isNotEmpty) {
    final byKey = _glyphBySectionKey[candidate];
    if (byKey != null) return byKey;
    final separator = candidate.lastIndexOf('_');
    if (separator <= 0) break;
    candidate = candidate.substring(0, separator);
  }

  final normalized = (title ?? '')
      .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  for (final entry in _glyphByTitleKeyword) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return HomeCardGlyph.bookmark;
}

const Map<String, HomeCardGlyph> _glyphBySectionKey = {
  'quran': HomeCardGlyph.mushaf,
  'visits': HomeCardGlyph.dome,
  'sahifa_sajjadiya': HomeCardGlyph.scroll,
  'duas': HomeCardGlyph.dua,
  'dreams': HomeCardGlyph.crescent,
  'stories': HomeCardGlyph.kaaba,
  'imam_ali': HomeCardGlyph.shield,
  'hadith': HomeCardGlyph.hadith,
  'names_allah': HomeCardGlyph.rosette,
  'adhkar': HomeCardGlyph.beads,
  'fatawa': HomeCardGlyph.scales,
  'fatawa.m': HomeCardGlyph.pen,
  'prophets_stories': HomeCardGlyph.ark,
  'istikhara': HomeCardGlyph.guidance,
};

/// Checked in order; the first keyword found in the title wins.
const List<MapEntry<String, HomeCardGlyph>> _glyphByTitleKeyword = [
  // `خيرة` first: the istikhara title also contains "القرآن".
  MapEntry('خيره', HomeCardGlyph.guidance),
  MapEntry('قران', HomeCardGlyph.mushaf),
  MapEntry('زيار', HomeCardGlyph.dome),
  MapEntry('صحيفه', HomeCardGlyph.scroll),
  MapEntry('دعاء', HomeCardGlyph.dua),
  MapEntry('ادعيه', HomeCardGlyph.dua),
  MapEntry('حلم', HomeCardGlyph.crescent),
  MapEntry('احلام', HomeCardGlyph.crescent),
  MapEntry('حج', HomeCardGlyph.kaaba),
  MapEntry('كعبه', HomeCardGlyph.kaaba),
  MapEntry('علي', HomeCardGlyph.shield),
  MapEntry('احاديث', HomeCardGlyph.hadith),
  MapEntry('حديث', HomeCardGlyph.hadith),
  MapEntry('اسماء', HomeCardGlyph.rosette),
  MapEntry('تسبيح', HomeCardGlyph.beads),
  MapEntry('اذكار', HomeCardGlyph.beads),
  MapEntry('استفتاء', HomeCardGlyph.scales),
  MapEntry('فتاوي', HomeCardGlyph.scales),
  MapEntry('فتوى', HomeCardGlyph.scales),
  MapEntry('انبياء', HomeCardGlyph.ark),
  MapEntry('نبي', HomeCardGlyph.ark),
];
