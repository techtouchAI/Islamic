/// Canonical form for comparing search terms. Never render this instead of the
/// original text. A different version requires rebuilding every search index.
class ArabicNormalizer {
  ArabicNormalizer._();

  static final RegExp _marks = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  static String escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  static String normalize(String value) => value
      .replaceAll(_marks, '')
      .replaceAll('\u0640', '') // Tatweel
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(_whitespace, ' ')
      .trim();
}
