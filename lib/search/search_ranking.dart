import '../utils/arabic_normalizer.dart';
import 'models/search_models.dart';

/// Unified relevance policy for results merged from every source
/// (JSON content, Quran ayahs and Mafatih articles).
///
/// All items are scored with exactly the same normalized word/phrase rules,
/// so the merged ordering is consistent regardless of where an item came from.
class SearchRanking {
  SearchRanking._();

  /// Relevance score of [item] for the already-normalized [normalizedQuery].
  /// Higher is better. Always >= 0; 0 means "no match signal".
  static int score(ContentItem item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return 0;
    final title =
        item.normalizedTitle ?? ArabicNormalizer.normalize(item.title);
    final content =
        item.normalizedContent ?? ArabicNormalizer.normalize(item.content);
    var score = 0;

    // Full-phrase signals (strongest).
    if (title == normalizedQuery) {
      score += 100;
    } else if (title.contains(normalizedQuery)) {
      score += 60;
    }
    if (content.contains(normalizedQuery)) score += 10;

    // Word-level signals: identical rules for every source.
    final words = normalizedQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    for (final word in words) {
      if (title == word) {
        score += 20;
      } else if (title.contains(word)) {
        score += 10;
      }
      if (content == word) {
        score += 6;
      } else if (content.contains(word)) {
        score += 3;
      }
    }

    return score;
  }

  /// Deterministic merged ordering: relevance first, then stable tie-breaks
  /// (title -> section -> id) so pagination windows never reshuffle.
  static int compareNormalized(
    ContentItem a,
    ContentItem b,
    String normalizedQuery,
  ) {
    final difference = score(
      b,
      normalizedQuery,
    ).compareTo(score(a, normalizedQuery));
    if (difference != 0) return difference;
    final title = a.title.compareTo(b.title);
    if (title != 0) return title;
    final section = a.sectionId.compareTo(b.sectionId);
    return section != 0 ? section : a.id.compareTo(b.id);
  }
}
