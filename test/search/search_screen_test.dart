import 'package:aldhakereen/search/models/search_models.dart';
import 'package:aldhakereen/search/repositories/search_repository.dart';
import 'package:aldhakereen/search/screens/search_screen.dart';
import 'package:aldhakereen/search/widgets/search_result_tile.dart';
import 'package:aldhakereen/services/search_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Programmable repository driving the SearchScreen through every state of
/// the strict contract (Loading / Success / Empty / Error / partial).
class _FakeSearchRepository implements SearchRepository {
  SearchState Function(int call)? onSearch;
  SearchState Function(int call)? onLoadMore;
  int searchCalls = 0;
  int loadMoreCalls = 0;
  bool _hasMore = false;

  @override
  bool get hasMore => _hasMore;

  @override
  Future<SearchState> search({
    required String query,
    required String category,
    required List<ContentItem> contentItems,
  }) async {
    searchCalls++;
    final state = onSearch?.call(searchCalls) ?? const SearchEmpty();
    _hasMore = state is SearchSuccess && state.hasMore;
    return state;
  }

  @override
  Future<SearchState> loadMore({
    required List<ContentItem> contentItems,
  }) async {
    loadMoreCalls++;
    final state = onLoadMore?.call(loadMoreCalls) ??
        SearchSuccess(items: const [], hasMore: false);
    _hasMore = state is SearchSuccess && state.hasMore;
    return state;
  }

  @override
  void reset() {}
}

void main() {
  ContentItem item(String id, {String section = 'dua'}) => ContentItem(
        id: id,
        title: 'ذكر $id',
        subtitle: '',
        content: 'محتوى $id',
        sectionId: section,
        sectionName: 'الأدعية',
        category: 'dua',
        normalizedTitle: 'ذكر $id',
        normalizedContent: 'محتوى $id',
        normalizedCategory: 'dua',
      );

  Future<void> pumpScreen(
    WidgetTester tester,
    SearchRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SearchScreen(fontSizeFactor: 1, repository: repository),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> runQuery(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  setUp(() {
    // Opening the screen requires a built index; results themselves are
    // driven by the injected repository.
    SearchEngine.instance.setMockIndex([]);
  });

  testWidgets('shows the idle prompt before any query', (tester) async {
    await pumpScreen(tester, _FakeSearchRepository());
    expect(find.text('ابدأ البحث الآن...'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders success results with the loaded-count header', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch =
        (_) => SearchSuccess(items: [item('a'), item('b')], hasMore: false);

    await pumpScreen(tester, repo);
    await runQuery(tester, 'ذكر');

    expect(find.byType(SearchResultTile), findsNWidgets(2));
    expect(find.textContaining('تم العثور على 2'), findsOneWidget);
    expect(repo.searchCalls, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('partial failure keeps results and offers a Retry banner', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch = (_) => SearchSuccess(
          items: [item('a')],
          hasMore: false,
          failedSources: {SearchSource.quran},
        );

    await pumpScreen(tester, repo);
    await runQuery(tester, 'ذكر');

    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.textContaining('تعذر البحث في'), findsOneWidget);
    expect(find.textContaining('القرآن'), findsWidgets);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('full failure shows the error state and Retry recovers', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch = (call) => call == 1
        ? const SearchError(
            message: 'تعذر إكمال البحث. يرجى المحاولة مجددًا.',
          )
        : SearchSuccess(items: [item('a')], hasMore: false);

    await pumpScreen(tester, repo);
    await runQuery(tester, 'ذكر');

    expect(find.text('تعذر إكمال البحث. يرجى المحاولة مجددًا'), findsOneWidget);
    expect(find.byType(SearchResultTile), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();

    expect(repo.searchCalls, 2);
    expect(find.byType(SearchResultTile), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the empty state for a query without matches', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch = (_) => const SearchEmpty();

    await pumpScreen(tester, repo);
    await runQuery(tester, 'غير موجود');

    expect(find.text('لا توجد نتائج'), findsOneWidget);
    expect(find.text('جرب البحث بكلمات مختلفة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping the lazy-load footer fetches the next batch', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch = (_) => SearchSuccess(
          items: [for (var i = 1; i <= 3; i++) item('b1-$i')],
          hasMore: true,
        );
    repo.onLoadMore = (_) => SearchSuccess(
          items: [
            for (var i = 1; i <= 3; i++) item('b1-$i'),
            for (var i = 1; i <= 3; i++) item('b2-$i'),
          ],
          hasMore: false,
        );

    await pumpScreen(tester, repo);
    await runQuery(tester, 'ذكر');

    // Short list: the footer stays on screen and is tappable.
    expect(find.text('عرض المزيد من النتائج'), findsOneWidget);
    expect(find.textContaining('3+'), findsOneWidget);

    await tester.tap(find.text('عرض المزيد من النتائج'));
    await tester.pump();
    await tester.pump();

    expect(repo.loadMoreCalls, 1);
    expect(find.textContaining('6 نتيجة'), findsOneWidget);
    expect(find.text('عرض المزيد من النتائج'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scrolling to the bottom auto-fetches the next batch', (
    tester,
  ) async {
    final repo = _FakeSearchRepository();
    repo.onSearch = (_) => SearchSuccess(
          items: [for (var i = 1; i <= 20; i++) item('b1-$i')],
          hasMore: true,
        );
    repo.onLoadMore = (_) => SearchSuccess(
          items: [
            for (var i = 1; i <= 20; i++) item('b1-$i'),
            for (var i = 1; i <= 20; i++) item('b2-$i'),
          ],
          hasMore: false,
        );

    await pumpScreen(tester, repo);
    await runQuery(tester, 'ذكر');
    expect(find.textContaining('20+'), findsOneWidget);

    // Long list: dragging past the threshold triggers the scroll listener.
    await tester.drag(
      find.byType(SearchResultTile).first,
      const Offset(0, -2000),
    );
    await tester.pump();
    await tester.pump();

    expect(repo.loadMoreCalls, 1);
    expect(find.textContaining('40 نتيجة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
