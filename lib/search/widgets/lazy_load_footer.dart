import 'package:flutter/material.dart';

/// Bottom indicator for the lazily growing result list.
///
/// Shows a spinner while the next batch is in flight, a tappable
/// "load more" action while more results remain (scrolling to the bottom
/// triggers the same action automatically), and a completion line once
/// every batch is loaded.
class LazyLoadFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final int loadedCount;
  final VoidCallback? onLoadMore;

  const LazyLoadFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadedCount,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: isLoadingMore
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('جارٍ تحميل المزيد...'),
              ],
            )
          : hasMore
              ? TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: const Text('عرض المزيد من النتائج'),
                )
              : Text(
                  'تم تحميل جميع النتائج ($loadedCount)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
    );
  }
}
