import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

void main() {
  runApp(const AlDhakereenApp());
}

class AlDhakereenApp extends StatefulWidget {
  const AlDhakereenApp({super.key});

  @override
  State<AlDhakereenApp> createState() => _AlDhakereenAppState();
}

class _AlDhakereenAppState extends State<AlDhakereenApp> {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSizeFactor = 1.0;
  Color _primaryColor = const Color(0xFFD4AF37);
  double _uiOpacity = 1.0;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الذاكرين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Kufi Arabic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Kufi Arabic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      themeMode: _themeMode,
      home: MainScaffold(
        fontSizeFactor: _fontSizeFactor,
        onFontSizeChanged: (val) => setState(() => _fontSizeFactor = val),
        onThemeToggled: _toggleTheme,
        primaryColor: _primaryColor,
        onColorChanged: (c) => setState(() => _primaryColor = c),
        uiOpacity: _uiOpacity,
        onOpacityChanged: (val) => setState(() => _uiOpacity = val),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final double fontSizeFactor;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final double uiOpacity;
  final ValueChanged<double> onOpacityChanged;

  const MainScaffold({
    super.key,
    required this.fontSizeFactor,
    required this.onFontSizeChanged,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  String _currentSection = 'home';
  final List<String> _history = ['home'];

  void _navigateTo(String section) {
    if (_currentSection == section) return;
    setState(() {
      _history.add(section);
      _currentSection = section;
    });
  }

  void _onBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _currentSection = _history.last;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubPage = _history.length > 1;

    return PopScope(
      canPop: !isSubPage,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        drawer: AppDrawer(
          currentSection: _currentSection,
          onNavigate: (section) {
            Navigator.pop(context);
            _navigateTo(section);
          },
        ),
        appBar: AppBar(
          title: const Text('الذاكرين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.notes), // 3 lines professional
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'القائمة',
            ),
          ),
          actions: [
            if (isSubPage)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios), // Logic 'back' in RTL
                onPressed: _onBack,
                tooltip: 'رجوع',
              ),
            if (!isSubPage) const SizedBox(width: 48), // Spacer to balance leading
          ],
        ),
        body: SafeArea(
          child: Opacity(
            opacity: widget.uiOpacity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentSection) {
      case 'home':
        return HomeSection(key: const ValueKey('home'), fontSizeFactor: widget.fontSizeFactor);
      case 'duas':
        return ContentListSection(key: const ValueKey('duas'), title: 'الأدعية', type: 'dua', fontSizeFactor: widget.fontSizeFactor);
      case 'visits':
        return ContentListSection(key: const ValueKey('visits'), title: 'الزيارات', type: 'visit', fontSizeFactor: widget.fontSizeFactor);
      case 'notes':
        return ContentListSection(key: const ValueKey('notes'), title: 'الملاحظات', type: 'note', fontSizeFactor: widget.fontSizeFactor);
      case 'settings':
        return SettingsSection(
          key: const ValueKey('settings'),
          onThemeToggled: widget.onThemeToggled,
          primaryColor: widget.primaryColor,
          onColorChanged: widget.onColorChanged,
          uiOpacity: widget.uiOpacity,
          onOpacityChanged: widget.onOpacityChanged,
        );
      default:
        return const Center(child: Text('صفحة غير معروفة'));
    }
  }
}

class AppDrawer extends StatelessWidget {
  final String currentSection;
  final ValueChanged<String> onNavigate;

  const AppDrawer({super.key, required this.currentSection, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mosque, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text('تطبيق الذاكرين', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, 'home', 'الرئيسية', Icons.home),
                _buildItem(context, 'duas', 'الأدعية', Icons.auto_stories),
                _buildItem(context, 'visits', 'الزيارات', Icons.place),
                _buildItem(context, 'notes', 'الملاحظات', Icons.edit_note),
                const Divider(),
                _buildItem(context, 'settings', 'الإعدادات', Icons.settings),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('الإصدار 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String id, String title, IconData icon) {
    final bool active = currentSection == id;
    return ListTile(
      leading: Icon(icon, color: active ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
      selected: active,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () => onNavigate(id),
    );
  }
}

class HomeSection extends StatelessWidget {
  final double fontSizeFactor;
  const HomeSection({super.key, required this.fontSizeFactor});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Card(
            elevation: 10,
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const _ClockWidget(),
                  const SizedBox(height: 20),
                  const Text('1 ذوالقعدة 1447 هـ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(intl.DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(now), style: const TextStyle(color: Colors.white60, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('محتوى اليوم المختار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          const _DailyCard(tag: 'دعاء اليوم', title: 'دعاء الصباح', content: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.'),
          const _DailyCard(tag: 'زيارة اليوم', title: 'زيارة عاشوراء', content: 'السَّلامُ عَلَيْكَ يا أَبا عَبْدِ اللهِ، السَّلامُ عَلَيْكَ يَا بْنَ رَسُولِ اللهِ، السَّلامُ عَلَيْكَ يا خِيَرَةَ اللهِ وَابْنَ خِيَرَتِهِ، السَّلامُ عَلَيْكَ يَا بْنَ أَمِيرِ الْمُؤْمِنِينَ وَابْنَ سَيِّدِ الْوَصِيِّينَ.'),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();
  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  String _timeString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = intl.DateFormat('hh:mm:ss a', 'en_US').format(now);
    if (mounted) {
      setState(() {
        _timeString = formattedTime.replaceFirst('AM', 'ص').replaceFirst('PM', 'م');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeString,
      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 50, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final String tag, title, content;
  const _DailyCard({required this.tag, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ReaderPage(title: title, content: content, fontSizeFactor: 1.0))),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(tag, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 1.5), textAlign: TextAlign.right),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentListSection extends StatelessWidget {
  final String title, type;
  final double fontSizeFactor;
  const ContentListSection({super.key, required this.title, required this.type, required this.fontSizeFactor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث في المختار...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: 10,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text('$title نموذج ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('نص تجريبي للمحتوى يظهر هنا للتحقق من التنسيق والوضوح في العرض...', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
                ),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ReaderPage(title: 'عرض النص الكامل', content: 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف التى يولدها التطبيق. ' * 5, fontSizeFactor: fontSizeFactor))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String title, content;
  final double fontSizeFactor;
  const ReaderPage({super.key, required this.title, required this.content, required this.fontSizeFactor});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late double _factor;

  @override
  void initState() {
    super.initState();
    _factor = widget.fontSizeFactor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.content_copy), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
                ),
                child: Column(
                  children: [
                    Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      widget.content,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Amiri', fontSize: 22 * _factor, height: 1.8),
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 30), color: Theme.of(context).colorScheme.primary, onPressed: () => setState(() => _factor = (_factor > 0.5 ? _factor - 0.1 : 0.5))),
                const SizedBox(width: 15),
                const Text('Aa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 15),
                IconButton(icon: const Icon(Icons.add_circle_outline, size: 30), color: Theme.of(context).colorScheme.primary, onPressed: () => setState(() => _factor = (_factor < 3.0 ? _factor + 0.1 : 3.0))),
                const SizedBox(width: 25),
                Text('${(_factor * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final double uiOpacity;
  final ValueChanged<double> onOpacityChanged;

  const SettingsSection({
    super.key,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _Group(
          title: 'المظهر والتخصيص',
          children: [
            SwitchListTile(
              title: const Text('الوضع الليلي'),
              subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (val) => onThemeToggled(),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              title: const Text('لون التطبيق الأساسي'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [const Color(0xFFD4AF37), Colors.blueGrey, Colors.teal, Colors.brown, Colors.deepPurple, Colors.indigo].map((c) => GestureDetector(
                    onTap: () {
                      onColorChanged(c);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير اللون بنجاح'), duration: Duration(seconds: 1)));
                    },
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 22,
                      child: primaryColor.value == c.value ? const Icon(Icons.check, size: 22, color: Colors.white) : null,
                    ),
                  )).toList(),
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('شفافية القوائم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${(uiOpacity * 100).toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(value: uiOpacity, min: 0.3, max: 1.0, onChanged: onOpacityChanged),
                ],
              ),
            ),
          ],
        ),
        _Group(
          title: 'إدارة البيانات',
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('تصدير البيانات'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.upload),
                          label: const Text('استيراد البيانات'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('مسح جميع البيانات', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
          ...children,
        ],
      ),
    );
  }
}
