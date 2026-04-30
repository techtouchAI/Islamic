extension ArabicStringNormalization on String {
  /// Normalizes Arabic text by removing diacritics and unifying variations of Alef, Teh Marbuta, and Alef Maksura.
  String normalizeArabic() {
    return replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }
}
