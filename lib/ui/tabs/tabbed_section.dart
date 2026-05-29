import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/app_drawer.dart'; // For _CountBadge
import '../dynamic_list/dynamic_list_section.dart';

class TabbedSection extends StatelessWidget {
  final List<String> tabs;
  final List<String> sectionKeys;

  const TabbedSection({
    super.key,
    required this.tabs,
    required this.sectionKeys,
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty || sectionKeys.isEmpty) {
      return const Center(child: Text('لا يوجد محتوى متوفر'));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              isScrollable: tabs.length > 3,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: sectionKeys
                  .map<Widget>(
                    (key) => DynamicListSection(
                      title: '',
                      sectionKey: key,
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
