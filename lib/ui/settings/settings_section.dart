import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/data_manager.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroup(
            context,
            'المظهر',
            [
              _buildSwitchItem(
                context,
                title: 'الوضع الليلي',
                value: isDark,
                onChanged: (v) => context.read<SettingsProvider>().toggleTheme(),
              ),
              const Divider(),
              _buildSliderItem(
                context,
                title: 'حجم الخط',
                value: provider.fontSizeFactor,
                min: 0.8,
                max: 2.0,
                onChanged: (v) => context.read<SettingsProvider>().setFontSizeFactor(v),
              ),
              const Divider(),
              _buildSliderItem(
                context,
                title: 'شفافية الواجهة',
                value: provider.uiOpacity,
                min: 0.1,
                max: 1.0,
                onChanged: (v) => context.read<SettingsProvider>().setUiOpacity(v),
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text('اللون الأساسي:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  Colors.blue,
                  Colors.green,
                  Colors.teal,
                  Colors.red,
                  Colors.orange,
                  Colors.purple,
                  Colors.brown,
                ]
                    .map(
                      (c) => GestureDetector(
                        onTap: () => context.read<SettingsProvider>().setPrimaryColor(c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 18,
                          child: provider.primaryColor.toARGB32() == c.toARGB32()
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('لون البطاقات:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  Colors.white,
                  const Color(0xFFF0F0F0),
                  const Color(0xFFE8F5E9),
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE3F2FD),
                  const Color(0xFFF3E5F5),
                  const Color(0xFFFCE4EC),
                  const Color(0xFFFFF8E1),
                  Colors.black,
                  const Color(0xFF1E1E1E),
                ]
                    .map(
                      (c) => GestureDetector(
                        onTap: () => context.read<SettingsProvider>().setCardColor(c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: provider.cardColor.toARGB32() == c.toARGB32()
                              ? Icon(
                                  Icons.check,
                                  color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          _buildGroup(
            context,
            'الخلفية',
            [
              ListTile(
                title: const Text('اختيار خلفية من الجهاز'),
                trailing: const Icon(Icons.image),
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    context.read<SettingsProvider>().setBackgroundImagePath(image.path);
                    context.read<SettingsProvider>().setSelectedBase64Bg(null);
                  }
                },
              ),
              if (provider.backgroundImagePath != null || provider.selectedBase64Bg != null) ...[
                const Divider(),
                ListTile(
                  title: const Text('إزالة الخلفية المخصصة', style: TextStyle(color: Colors.red)),
                  trailing: const Icon(Icons.delete, color: Colors.red),
                  onTap: () {
                    context.read<SettingsProvider>().setBackgroundImagePath(null);
                    context.read<SettingsProvider>().setSelectedBase64Bg(null);
                  },
                ),
              ],
            ],
          ),
          _buildGroup(
            context,
            'أقسام الشاشة الرئيسية',
            [
              _visToggle(context, 'show_daily_dua', 'دعاء اليوم'),
              _visToggle(context, 'show_today_visit', 'زيارة اليوم'),
              _visToggle(context, 'show_today_prayer', 'صلاة اليوم'),
              _visToggle(context, 'show_taqeebat', 'تعقيبات الصلاة'),
              _visToggle(context, 'show_quran_shortcuts', 'اختصارات السور'),
            ],
          ),
          _buildGroup(
            context,
            'التقويم',
            [
              Row(
                children: [
                  const Expanded(child: Text('تعديل التاريخ الهجري:')),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      context.read<SettingsProvider>().setHijriAdjustment(provider.hijriAdjustment - 1);
                    },
                  ),
                  Text(
                    '${provider.hijriAdjustment > 0 ? '+' : ''}${provider.hijriAdjustment}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      context.read<SettingsProvider>().setHijriAdjustment(provider.hijriAdjustment + 1);
                    },
                  ),
                ],
              ),
              const Center(
                child: Text(
                  'يتم تطبيقه على تقويم الصفحة الرئيسية فقط',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String title, List<Widget> children) {
    final provider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: provider.primaryColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: provider.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, {required String title, required bool value, required ValueChanged<bool> onChanged}) {
    final provider = context.watch<SettingsProvider>();
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: provider.primaryColor,
      dense: true,
    );
  }

  Widget _buildSliderItem(BuildContext context, {required String title, required double value, required double min, required double max, required ValueChanged<double> onChanged}) {
    final provider = context.watch<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: provider.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _visToggle(BuildContext context, String key, String title) {
    final provider = context.watch<SettingsProvider>();
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: provider.homeVisibility[key] ?? true,
      onChanged: (v) => context.read<SettingsProvider>().setHomeSectionVisibility(key, v),
      dense: true,
    );
  }
}
