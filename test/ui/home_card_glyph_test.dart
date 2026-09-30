import 'package:aldhakereen/ui/home/widgets/home_card_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every home section resolves to its own icon', () {
    final byKey = <String, HomeCardGlyph>{
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
    for (final entry in byKey.entries) {
      expect(
        resolveHomeCardGlyph(sectionKey: entry.key),
        entry.value,
        reason: entry.key,
      );
    }

    // The section list on the home screen is effectively a set of icons: two
    // sections must never look identical.
    expect(byKey.values.toSet(), hasLength(byKey.length));
  });

  test('category and unknown keys are handled without a generic book', () {
    expect(
      resolveHomeCardGlyph(sectionKey: 'imam_ali_cat_3'),
      HomeCardGlyph.shield,
    );
    expect(
      resolveHomeCardGlyph(sectionKey: 'dreams_cat_7'),
      HomeCardGlyph.crescent,
    );
    expect(
      resolveHomeCardGlyph(sectionKey: 'dreams'),
      HomeCardGlyph.crescent,
    );

    // Titles are only a fallback for sections the map does not know yet.
    expect(
      resolveHomeCardGlyph(
        sectionKey: 'new_section',
        title: 'أحاديث أهل البيت',
      ),
      HomeCardGlyph.hadith,
    );
    expect(
      resolveHomeCardGlyph(sectionKey: 'new_section', title: 'الأدعية العامة'),
      HomeCardGlyph.dua,
    );
    expect(
      resolveHomeCardGlyph(sectionKey: 'unknown', title: 'بلا عنوان'),
      HomeCardGlyph.bookmark,
    );
    expect(resolveHomeCardGlyph(), HomeCardGlyph.bookmark);
  });

  testWidgets('all glyphs paint as open strokes without errors',
      (tester) async {
    for (final glyph in HomeCardGlyph.values) {
      for (final size in [18.0, 26.0, 64.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: HomeCardGlyphIcon(
                glyph: glyph,
                color: const Color(0xFF0A3D33),
                size: size,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$glyph at $size');
      }
    }
  });
}
