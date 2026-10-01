import 'arabic_normalizer.dart';
import 'content_sanitizer.dart';

extension ArabicStringNormalization on String {
  String normalizeArabic() => ArabicNormalizer.normalize(this);

  String toEasternArabic() {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = this;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}

extension HtmlStringFormatting on String {
  /// One tag-free line of a CMS payload; see [ContentSanitizer.snippet].
  String cleanSnippet({int? maxLength}) =>
      ContentSanitizer.snippet(this, maxLength: maxLength);
}
