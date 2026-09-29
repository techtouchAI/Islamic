import 'package:aldhakereen/search/search_ranking.dart';
import 'package:aldhakereen/search/models/search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact title outranks content regardless of source', () {
    const quran = ContentItem(
      id: 'q1', title: 'القرآن', subtitle: '', content: 'دعاء',
      sectionId: 'quran', sectionName: 'القرآن',
    );
    const dua = ContentItem(
      id: 'd1', title: 'دعاء', subtitle: '', content: '',
      sectionId: 'dua', sectionName: 'الأدعية',
    );
    expect(SearchRanking.compareNormalized(dua, quran, 'دعاء'), lessThan(0));
  });
}
