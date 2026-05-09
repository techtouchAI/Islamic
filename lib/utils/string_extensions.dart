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
    try {
      if (this.length > 10000) return this;
      String result = this.trim();
      if (result.toLowerCase().startsWith('html')) {
        result = result.substring(4).trim();
      }
      result = result.replaceAll('\uFDFA', '(صلى الله عليه وآله)');
      result = result.replaceAll('\uFDFB', '(جل جلاله)');
      result = result.replaceAll('!', '(عليه السلام)');
      result = result.replaceAll('<html>', '');
      result = result.replaceAll('//', '');
      result = result.replaceAll(RegExp(r'<\/?p>', caseSensitive: false), ' ');
      result = result.replaceAll(RegExp(r'<br>', caseSensitive: false), ' ');
      result = result.replaceAll(RegExp(r'<[^>]*>'), '');
      result = result.replaceAll(RegExp(r'\s+'), ' ');
      return result.trim();
    } catch (e) {
      return this;
    }
  }
}
