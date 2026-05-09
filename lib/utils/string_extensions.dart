final _diacriticsRegExp = RegExp(r'[\u064B-\u065F\u0670]');

extension ArabicStringNormalization on String {
  String normalizeArabic() {
    return replaceAll(_diacriticsRegExp, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }
}

extension HtmlStringFormatting on String {
  String cleanSnippet() {
    String s = replaceAll(RegExp(r'^html\s*', caseSensitive: false), '');

    s = s.replaceAll('\uFDFA', '(صلى الله عليه وآله)')
         .replaceAll('\uFDFB', '(جَلَّ جَلالُه)')
         .replaceAll('\uFDFD', 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ')
         .replaceAll('\uFDF2', 'اللَّهُ جَلَّ جَلالُه')
         .replaceAll(RegExp(r'[\uE000-\uF8FF]|\uFFFD'), ' '); // replace other unrenderable with space
    return s.replaceAll('<html>', '')
        .replaceAll('//', '')
        .replaceAll(RegExp(r'<\/?p>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<br>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
