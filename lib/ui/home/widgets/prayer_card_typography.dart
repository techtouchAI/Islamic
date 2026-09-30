import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Local fonts only. The concept is a raster image without font metadata:
/// Cairo supplies the rounded heading; OmarNaskh supplies the reference-like
/// curved Eastern Arabic numerals instead of Cairo's square digit shapes.
abstract final class PrayerCardTypography {
  static const date = TextStyle(
    fontFamily: 'Cairo', fontSize: 13, height: 1.5,
    fontWeight: FontWeight.w500, color: Color(0xFFF5F1DC),
  );
  static const title = TextStyle(
    fontFamily: 'Cairo', fontSize: 34, height: 1.5,
    fontWeight: FontWeight.w500, color: Color(0xFFD9BE76),
  );
  static const countdown = TextStyle(
    fontFamily: 'OmarNaskh', fontSize: 48, height: 1.25,
    fontWeight: FontWeight.w500, color: Color(0xFFFFFBEA),
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const caption = TextStyle(
    fontFamily: 'Cairo', fontSize: 16, height: 1.5,
    fontWeight: FontWeight.w400, color: Color(0xFFF5F1DC),
  );
}
