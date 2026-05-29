import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/data_manager.dart';
import '../../utils/string_extensions.dart';
import '../../services/prayer_times_service.dart';
import '../../services/quran_service.dart';
import '../../services/favorites_service.dart';
import '../../models/favorite_item.dart';
import '../../sections/html_content_renderer.dart';
import '../../ui/calendar/hijri_calendar_screen.dart';
import '../../ui/qibla/qibla_screen.dart';
import '../../presentation/screens/istikhara_screen.dart';
import '../../main.dart'; // For AlDhakereenApp globals

import '../widgets/app_drawer.dart'; // For _CountBadge
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: tabs.length,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
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
