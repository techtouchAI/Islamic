import 'package:flutter/material.dart';
import '../../services/mafatih_service.dart';
import '../../models/mafatih_category.dart';
import '../../models/mafatih_article.dart';
import '../reader/reader_page.dart';

class MafatihSection extends StatefulWidget {
  final double fontSizeFactor;
  final double uiOpacity;

  const MafatihSection({
    super.key,
    required this.fontSizeFactor,
    required this.uiOpacity,
  });

  @override
  State<MafatihSection> createState() => _MafatihSectionState();
}

class _MafatihSectionState extends State<MafatihSection> {
  Future<List<MafatihCategory>>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = MafatihService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MafatihCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ أثناء تحميل البيانات: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد أقسام متوفرة'));
        }

        final categories = snapshot.data!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DefaultTabController(
          length: categories.length,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : const Color(0xFFFDFBF7),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                  tabs: categories.map((cat) {
                    return Tab(text: cat.title);
                  }).toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: categories.map((cat) {
                    return _MafatihCategoryList(
                      categoryId: cat.id,
                      fontSizeFactor: widget.fontSizeFactor,
                      uiOpacity: widget.uiOpacity,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MafatihCategoryList extends StatefulWidget {
  final int categoryId;
  final double fontSizeFactor;
  final double uiOpacity;

  const _MafatihCategoryList({
    required this.categoryId,
    required this.fontSizeFactor,
    required this.uiOpacity,
  });

  @override
  State<_MafatihCategoryList> createState() => _MafatihCategoryListState();
}

class _MafatihCategoryListState extends State<_MafatihCategoryList> {
  Future<List<MafatihArticle>>? _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = MafatihService.getArticles(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MafatihArticle>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد نصوص في هذا القسم'));
        }

        final articles = snapshot.data!;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: articles.length,
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            final article = articles[index];
            final title = article.title;
            final text = article.text;

            return Card(
              color: Theme.of(context)
                  .cardColor
                  .withValues(alpha: widget.uiOpacity),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 * widget.fontSizeFactor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'amiri',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderPage(
                        title: title,
                        content: text,
                        fontSizeFactor: widget.fontSizeFactor,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
