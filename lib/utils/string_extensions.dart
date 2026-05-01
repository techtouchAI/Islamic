extension ArabicStringNormalization on String {
  static final _diacriticsRegex = RegExp(r'[\u064B-\u0652]');

  String normalizeArabic() {
    return replaceAll(_diacriticsRegex, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }
}
