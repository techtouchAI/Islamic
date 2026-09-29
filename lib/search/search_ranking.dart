import '../utils/arabic_normalizer.dart';
import 'models/search_models.dart';

/// Identical score policy for results from JSON, Quran and Mafatih.
class SearchRanking {
  SearchRanking._();

  static int score(ContentItem item, String normalizedQuery) {
    final title = item.normalizedTitle ?? ArabicNormalizer.normalize(item.title);
    final content = item.normalizedContent ?? ArabicNormalizer.normalize(item.content);
    if (normalizedQuery.isEmpty) return 0;
    var score = 0;
    if (title == normalizedQuery) {
      score += 100;
    } else if (title.contains(normalizedQuery)) {
      score += 60;
    }
    if (content.contains(normalizedQuery)) score += 10;
    return score;
  }

  static int compareNormalized(
      ContentItem a, ContentItem b, String normalizedQuery) {
    final difference = score(b, normalizedQuery)
        .compareTo(score(a, normalizedQuery));
    if (difference != 0) return difference;
    final title = a.title.compareTo(b.title);
    if (title != 0) return title;
    final section = a.sectionId.compareTo(b.sectionId);
    return section != 0 ? section : a.id.compareTo(b.id);
  }
}
