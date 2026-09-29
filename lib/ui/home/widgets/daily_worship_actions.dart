import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class DailyWorshipActions extends StatelessWidget {
  const DailyWorshipActions(
      {super.key, required this.onNavigate, required this.visibility});
  final ValueChanged<String>? onNavigate;
  final Map<String, bool> visibility;

  static const _actions = [
    ('quran', 'القرآن الكريم', Icons.menu_book_rounded),
    ('adhkar', 'الأذكار', Icons.auto_stories_outlined),
    ('tasbih', 'المسبحة', Icons.grain_rounded),
    ('qibla', 'القبلة', Icons.explore_outlined),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final actions =
              _actions.where((a) => visibility[a.$1] ?? true).toList();
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
          final columns = largeText || constraints.maxWidth < 260 ? 1 : 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map((action) => SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 12) / columns,
                      child: Material(
                        color: AppPalette.forest,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('quick-${action.$1}'),
                          onTap: onNavigate == null
                              ? null
                              : () => onNavigate!(action.$1),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(action.$3,
                                    color: AppPalette.gold, size: 30),
                                const SizedBox(height: 14),
                                Text(action.$2,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      );
}
