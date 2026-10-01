import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../widgets/app_drawer.dart'; // For CountBadge
import '../dynamic_list/dynamic_list_section.dart'; // For DynamicListSection

class TabbedSection extends StatelessWidget {
  final List<String> tabs;
  final List<String> sectionKeys;
  final double fontSizeFactor;
  final double uiOpacity;
  const TabbedSection({
    super.key,
    required this.tabs,
    required this.sectionKeys,
    required this.fontSizeFactor,
    required this.uiOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
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
              indicatorColor: scheme.primary,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              tabs: List.generate(
                tabs.length,
                (i) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tabs[i]),
                      const SizedBox(width: 12),
                      CountBadge(
                        count: DataManager.getItems(sectionKeys[i]).length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: sectionKeys
                  .map(
                    (key) => DynamicListSection(
                      title: '',
                      sectionKey: key,
                      fontSizeFactor: fontSizeFactor,
                      uiOpacity: uiOpacity,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
