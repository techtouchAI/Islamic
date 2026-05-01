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
