import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/string_extensions.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _EventModel {
  final int hDay;
  final int hMonth;
  final int hYear;
  final String title;
  final String? description;
  final bool isImportant;

  const _EventModel({
    required this.hDay,
    required this.hMonth,
    required this.hYear,
    required this.title,
    this.description,
    this.isImportant = false,
  });
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  static const int _initialPage = 1000;
  static const List<String> _weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  int _manualOffset = 0;
  HijriCalendar? _todayHijri;
  HijriCalendar _displayedHijri = HijriCalendar.fromDate(DateTime.now());
  PageController? _pageController;
  List<_EventModel> _events = [];
  bool _isLoading = true;

  int? _selectedDay;
  List<_EventModel> _selectedDayEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchHijriData();
  }

  Future<void> _fetchHijriData() async {
    final prefs = await SharedPreferences.getInstance();
    // MUST match main.dart: _hijriAdjustment = prefs.getInt('hijriAdj') ?? 0;
    _manualOffset = prefs.getInt('hijriAdj') ?? 0;

    final DateTime trueNow = DateTime.now().add(Duration(days: _manualOffset));
    _todayHijri = HijriCalendar.fromDate(trueNow);
    _displayedHijri = _todayHijri!;

    _pageController = PageController(initialPage: _initialPage);

    _events = [
    _EventModel(hDay: 1, hMonth: 1, hYear: 1, title: 'بداية السنة الهجرية'),
    _EventModel(hDay: 1, hMonth: 1, hYear: 1, title: 'بداية حصار النبي الأكرم محمد( صلى الله عليه واله وسلم ) في شعب أبي طالب سنة 3 قبل الهجرة'),
    _EventModel(hDay: 2, hMonth: 1, hYear: 1, title: 'ورود الإمام الحسين (عليه السلام) أرض كربلاء سنة 61هـ'),
    _EventModel(hDay: 3, hMonth: 1, hYear: 1, title: 'ورود عمر بن سعد مع جيشه أرض كربلاء سنة 61هـ'),
    _EventModel(hDay: 10, hMonth: 1, hYear: 1, title: 'واقعة الطف الخالدة واستشهاد الإمام الحسين واهل بيته (عليهم السلام)'),
    _EventModel(hDay: 12, hMonth: 1, hYear: 1, title: 'دخول سبايا أهل البيت (عليهم السلام) الى مدينة الكوفة'),
    _EventModel(hDay: 13, hMonth: 1, hYear: 1, title: 'دفن الأجساد الطاهرة لشهداء واقعة الطف الخالدة'),
    _EventModel(hDay: 19, hMonth: 1, hYear: 1, title: 'خروج سبايا أهل البيت (عليهم السلام) من الكوفة الى الشام'),
    _EventModel(hDay: 20, hMonth: 1, hYear: 1, title: 'وصول أمير المؤمنين الامام علي (عليه السلام) الى صفين'),
    _EventModel(hDay: 25, hMonth: 1, hYear: 1, title: 'شهادة الإمام علي بن الحسين السجاد (عليهما السلام) في المدينة المنورة سنة ٩٥هـ'),
    _EventModel(hDay: 26, hMonth: 1, hYear: 1, title: 'شهادة علي بن الحسين المثلث (رضوان الله عليه) حفيد الامام الحسن المجتبى (عليه السلام)'),
    _EventModel(hDay: 28, hMonth: 1, hYear: 1, title: 'وفاة الصحابي الجليل حذيفة بن اليمان (رضوان الله عليه)'),
    _EventModel(hDay: 28, hMonth: 1, hYear: 1, title: 'إحضار الإمام محمد الجواد (عليه السلام) من المدينة المنورة الى بغداد سنة ٢٢٠هـ'),
    _EventModel(hDay: 1, hMonth: 2, hYear: 1, title: 'واقعة صفين سنة ٣٧هـ'),
    _EventModel(hDay: 1, hMonth: 2, hYear: 1, title: 'دخول سبايا آل البيت (عليهم السلام) الى بلاد الشام سنة ٦١هـ'),
    _EventModel(hDay: 2, hMonth: 2, hYear: 1, title: 'شهادة زيد بن علي بن الحسين (عليهم السلام) سنة ١٢١هـ'),
    _EventModel(hDay: 3, hMonth: 2, hYear: 1, title: 'ولادة الإمام محمد الباقر(عليه السلام) سنة ٥٧ هـ على رواية'),
    _EventModel(hDay: 5, hMonth: 2, hYear: 1, title: 'شهادة السيدة رقية بنت الإمام الحسين (عليهما السلام) سنة ٦١هـ'),
    _EventModel(hDay: 7, hMonth: 2, hYear: 1, title: 'شهادة الإمام الحسن المجتبى (عليه السلام) سنة ٥٠هـ'),
    _EventModel(hDay: 8, hMonth: 2, hYear: 1, title: 'وفاة الصحابي الجليل سلمان الفارسي (رضوان الله عليه) سنة ٣٥هـ'),
    _EventModel(hDay: 9, hMonth: 2, hYear: 1, title: 'شهادة الصحابي الجليل عمار بن ياسر (رضوان الله عليه) في معركة صفين سنة ٣٧هـ'),
    _EventModel(hDay: 9, hMonth: 2, hYear: 1, title: 'واقعة النهروان سنة ٣٨هـ'),
    _EventModel(hDay: 14, hMonth: 2, hYear: 1, title: 'شهادة محمد بن أبي بكر(رضوان الله عليه) في مصر سنة ٣٨هـ'),
    _EventModel(hDay: 17, hMonth: 2, hYear: 1, title: 'شهادة الإمام علي بن موسى الرضا (عليهما السلام) على رواية سنة ٢٠٣هـ'),
    _EventModel(hDay: 20, hMonth: 2, hYear: 1, title: 'ورود السبايا من آل بيت النبي (عليهم السلام) أرض كربلاء سنة ٦١هـ'),
    _EventModel(hDay: 28, hMonth: 2, hYear: 1, title: 'إستشهاد النبي الاعظم رسول الله محمد (صلى الله عليه واله وسلم) سنة ١١هـ'),
    _EventModel(hDay: 1, hMonth: 3, hYear: 1, title: 'مبيت أمير المؤمنين الامام علي (عليه السلام) في فراش النبي الأكرم محمد (صلى الله عليه واله وسلم) وهجرة النبي الى المدينة المنورة'),
    _EventModel(hDay: 3, hMonth: 3, hYear: 1, title: 'إحراق الكعبة المشرفة بالمنجنيق بأمر من حصين بن نمير قائد جيش يزيد سنة 64هـ'),
    _EventModel(hDay: 4, hMonth: 3, hYear: 1, title: 'خروج رسول الله محمد (صلى الله عليه واله وسلم) من غار ثور متوجها الى المدينة المنورة في السنة الأولى من الهجرة'),
    _EventModel(hDay: 5, hMonth: 3, hYear: 1, title: 'وفاة السيدة سكينة بنت الإمام الحسين(عليهما السلام) سنة ١١٧هـ'),
    _EventModel(hDay: 8, hMonth: 3, hYear: 1, title: 'شهادة الإمام الحسن العسكري (عليه السلام) على رواية سنة ٢٦٠هـ'),
    _EventModel(hDay: 10, hMonth: 3, hYear: 1, title: 'زواج النبي الأكرم محمد(صلى الله عليه واله وسلم) من السيدة خديجة الكبرى(عليها السلام) سنة ٢٨ قبل الهجرة'),
    _EventModel(hDay: 10, hMonth: 3, hYear: 1, title: 'وفاة عبد المطلب جد النبي الأكرم محمد (صلى الله عليه واله وسلم) في السنة الثامنة من ولادته سنة ٤٥ قبل الهجرة'),
    _EventModel(hDay: 12, hMonth: 3, hYear: 1, title: 'ولادة النبي الاكرم محمد (صلى الله عليه واله وسلم) على رواية'),
    _EventModel(hDay: 12, hMonth: 3, hYear: 1, title: 'دخول رسول الله محمد (صلى الله عليه واله وسلم) المدينة المنورة في السنة الأولى من الهجرة'),
    _EventModel(hDay: 17, hMonth: 3, hYear: 1, title: 'ولادة سيد الرسل والمخلوقات النبي الاعظم محمد (صلى الله عليه واله وسلم) سنة 53 قبل الهجرة على الرواية المشهورة'),
    _EventModel(hDay: 17, hMonth: 3, hYear: 1, title: 'ولادة الإمام جعفر الصادق ( عليه السلام) سنة ٨٣هـ'),
    _EventModel(hDay: 22, hMonth: 3, hYear: 1, title: 'غزوة بني النضير سنة ٤هـ'),
    _EventModel(hDay: 25, hMonth: 3, hYear: 1, title: 'استشهاد سعيد بن جبير(رضوان الله عليه) على يد الحجاج سنة ٩٥هـ'),
    _EventModel(hDay: 26, hMonth: 3, hYear: 1, title: 'إبرام معاهدة الصلح بين الإمام الحسن (عليه السلام) ومعاوية بن أبي سفيان سنة ٤١هـ'),
    _EventModel(hDay: 8, hMonth: 4, hYear: 1, title: 'شهادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ١١هـ على رواية'),
    _EventModel(hDay: 10, hMonth: 4, hYear: 1, title: 'ولادة الإمام الحسن العسكري (عليه السلام) سنة ٢٣٢هـ على رواية'),
    _EventModel(hDay: 10, hMonth: 4, hYear: 1, title: 'وفاة السيدة فاطمة المعصومة بنت الإمام موسى الكاظم (عليهما السلام) سنة ٢٠١هـ على رواية'),
    _EventModel(hDay: 14, hMonth: 4, hYear: 1, title: 'خروج المختار الثقفي (رحمه الله ) في الكوفة للأخذ بثأر الإمام الحسين (عليه السلام) سنة ٦٦هـ'),
    _EventModel(hDay: 5, hMonth: 5, hYear: 1, title: 'ولادة السيدة زينب الكبرى بنت امير المؤمنين الإمام علي (عليهما السلام) سنة ٥هـ'),
    _EventModel(hDay: 6, hMonth: 5, hYear: 1, title: 'حرب مؤته واستشهاد جعفر بن أبي طالب (عليه السلام) سنة ٨هـ'),
    _EventModel(hDay: 10, hMonth: 5, hYear: 1, title: 'واقعة الجمل سنة ٣٦هـ'),
    _EventModel(hDay: 13, hMonth: 5, hYear: 1, title: 'شهادة سيدة نساء العالمين فاطمة الزهراء(عليها السلام) سنة ١١هـ على رواية'),
    _EventModel(hDay: 15, hMonth: 5, hYear: 1, title: 'فتح البصرة على يد أمير المؤمنين الامام علي (عليه السلام) سنة ٣٦هـ'),
    _EventModel(hDay: 19, hMonth: 5, hYear: 1, title: 'شهادة زيد بن صوحان (رضوان الله عليه) في حرب الجمل سنة ٣٦هـ'),
    _EventModel(hDay: 22, hMonth: 5, hYear: 1, title: 'وفاة القاسم بن الإمام موسى الكاظم (عليهما السلام) سنة ١٩٢هـ على رواية'),
    _EventModel(hDay: 30, hMonth: 5, hYear: 1, title: 'وفاة محمد بن عثمان بن سعيد الخلاني (رضوان الله عليه) السفير الثاني للإمام المهدي المنتظر (عجل الله فرجه الشريف) سنة ٣٠٤هـ'),
    _EventModel(hDay: 3, hMonth: 6, hYear: 1, title: 'شهادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ١١هـ على رواية'),
    _EventModel(hDay: 13, hMonth: 6, hYear: 1, title: 'وفاة السيدة فاطمة أم البنين (عليها السلام) سنة ٦٤هـ'),
    _EventModel(hDay: 19, hMonth: 6, hYear: 1, title: 'زواج عبد الله وآمنة (رضوان الله عليهما) والدي النبي الأكرم محمد (صلى الله عليه واله وسلم)'),
    _EventModel(hDay: 20, hMonth: 6, hYear: 1, title: 'ولادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ٨ قبل الهجرة'),
    _EventModel(hDay: 21, hMonth: 6, hYear: 1, title: 'رجوع أمير المؤمنين الامام علي(عليه السلام) من حرب الجمل سنة ٣٦هـ'),
    _EventModel(hDay: 21, hMonth: 6, hYear: 1, title: 'وفاة السيدة أم كلثوم بنت الإمام علي(عليه السلام) سنة ٦١هـ'),
    _EventModel(hDay: 1, hMonth: 7, hYear: 1, title: 'ولادة الإمام محمد الباقر(عليه السلام) سنة ٥٧هـ على رواية'),
    _EventModel(hDay: 2, hMonth: 7, hYear: 1, title: 'ولادة الإمام علي الهادي (عليه السلام) سنة ٢١٢هـ'),
    _EventModel(hDay: 3, hMonth: 7, hYear: 1, title: 'غزوة تبوك سنة ٩هـ'),
    _EventModel(hDay: 3, hMonth: 7, hYear: 1, title: 'شهادة الإمام علي الهادي(عليه السلام) سنة ٢٥٤هـ'),
    _EventModel(hDay: 10, hMonth: 7, hYear: 1, title: 'ولادة الإمام محمد الجواد(عليه السلام) سنة ١٩٥هـ'),
    _EventModel(hDay: 11, hMonth: 7, hYear: 1, title: 'وصول أمير المؤمنين الامام علي(عليه السلام) الى الكوفة بعد حرب الجمل سنة ٣٦هـ'),
    _EventModel(hDay: 12, hMonth: 7, hYear: 1, title: 'دخول أمير المؤمنين الامام علي(عليه السلام) الكوفة واتخاذها مقرا للخلافة سنة ٣٦هـ'),
    _EventModel(hDay: 13, hMonth: 7, hYear: 1, title: 'ولادة أمير المؤمنين الامام علي بن ابي طالب (عليه السلام) سنة ٢٣ قبل الهجرة'),
    _EventModel(hDay: 15, hMonth: 7, hYear: 1, title: 'وفاة السيدة زينب الكبرى بنت أمير المؤمنين الامام علي (عليهما السلام) سنة ٦٢هـ على رواية'),
    _EventModel(hDay: 15, hMonth: 7, hYear: 1, title: 'تحويل القبلة من بيت المقدس الى الكعبة المشرّفة سنة ٢هـ على رواية'),
    _EventModel(hDay: 18, hMonth: 7, hYear: 1, title: 'وفاة إبراهيم بن الرسول الأكرم محمد(صلى الله عليه واله وسلم)'),
    _EventModel(hDay: 24, hMonth: 7, hYear: 1, title: 'فتح خيبر على يد الإمام علي بن أبي طالب (عليه السلام) سنة ٧هـ وعودة جعفر بن أبي طالب (عليه السلام) من الحبشة'),
    _EventModel(hDay: 25, hMonth: 7, hYear: 1, title: 'شهادة الإمام موسى بن جعفر الكاظم (عليهما السلام) سنة ١٨٣هـ'),
    _EventModel(hDay: 26, hMonth: 7, hYear: 1, title: 'وفاة أبي طالب (عليه السلام) عم النبي الأكرم محمد (صلى الله عليه واله وسلم) سنة ٣ قبل الهجرة على رواية'),
    _EventModel(hDay: 27, hMonth: 7, hYear: 1, title: 'بعثة النبي الاعظم محمد (صلى الله عليه واله وسلم) سنة ١٣ قبل الهجرة'),
    _EventModel(hDay: 28, hMonth: 7, hYear: 1, title: 'خروج الإمام الحسين(عليه السلام) من المدينة الى مكة سنة ٦٠هـ'),
    _EventModel(hDay: 3, hMonth: 8, hYear: 1, title: 'ولادة سبط النبي الأكرم (صلى الله عليه واله وسلم) الإمام الحسين (عليه السلام) سنة ٤هـ'),
    _EventModel(hDay: 3, hMonth: 8, hYear: 1, title: 'دخول الإمام الحسين (عليه السلام) مكة سنة ٦٠هـ'),
    _EventModel(hDay: 4, hMonth: 8, hYear: 1, title: 'ولادة المولى ابي الفضل العباس بن امير المؤمنين الامام علي (عليهما السلام) سنة ٢٦هـ'),
    _EventModel(hDay: 5, hMonth: 8, hYear: 1, title: 'ولادة زين العابدين الإمام علي بن الحسين (عليهما السلام) سنة ٣٨هـ'),
    _EventModel(hDay: 11, hMonth: 8, hYear: 1, title: 'ولادة سيدنا علي الأكبر بن الإمام الحسين (عليهما السلام) سنة ٣٣هـ'),
    _EventModel(hDay: 13, hMonth: 8, hYear: 1, title: 'وفاة الحسين بن روح (رضوان الله عليه) السفير الثالث للإمام المهدي (عجل الله فرجه الشريف) سنة ٣٢٦هـ'),
    _EventModel(hDay: 15, hMonth: 8, hYear: 1, title: 'ولادة بقية الله الأعظم الحجة بن الحسن الامام صاحب العصر والزمان (عجل الله فرجه الشريف) سنة ٢٥٥هـ'),
    _EventModel(hDay: 15, hMonth: 8, hYear: 1, title: 'وفاة علي بن محمد السمري(رضوان الله عليه) السفير الرابع للإمام المهدي (عجل الله فرجه الشريف) سنة ٣٢٩هـ وهذا اليوم بدأت الغيبة الكبرى'),
    _EventModel(hDay: 19, hMonth: 8, hYear: 1, title: 'غزوة بني المصطلق سنة ٥هـ'),
    _EventModel(hDay: 1, hMonth: 9, hYear: 1, title: 'وفاة عثمان بن سعيد (رضوان الله عليه) النائب الأول للإمام المهدي (عجل الله فرجه الشريف) سنة ٢٦٧هـ'),
    _EventModel(hDay: 2, hMonth: 9, hYear: 1, title: 'تولي الإمام الرضا (عليه السلام) ولاية عهد المأمون العباسي سنة ٢٠١هـ على رواية'),
    _EventModel(hDay: 3, hMonth: 9, hYear: 1, title: 'غزوة تبوك سنة 9هـ'),
    _EventModel(hDay: 6, hMonth: 9, hYear: 1, title: 'بيعة الناس للإمام الرضا(عليه السلام) سنة ٢٠١هـ على رواية'),
    _EventModel(hDay: 8, hMonth: 9, hYear: 1, title: 'خروج النبي الأكرم محمد (صلى الله عليه واله وسلم) لغزوة بدر الكبرى سنة ٢هـ'),
    _EventModel(hDay: 10, hMonth: 9, hYear: 1, title: 'وفاة الصديقة خديجة الكبرى (عليها السلام) سنة ٣هـ قبل الهجرة'),
    _EventModel(hDay: 12, hMonth: 9, hYear: 1, title: 'المؤاخاة بين المهاجرين والأنصار في المدينة المنورة في السنة الأولى للهجرة'),
    _EventModel(hDay: 14, hMonth: 9, hYear: 1, title: 'شهادة المختار الثقفي (رحمه الله) سنة ٦٧هـ'),
    _EventModel(hDay: 15, hMonth: 9, hYear: 1, title: 'ولادة سبط النبي الأكرم (صلى الله عليه واله وسلام) الإمام الحسن المجتبى (عليه السلام) سنة ٣هـ'),
    _EventModel(hDay: 15, hMonth: 9, hYear: 1, title: 'خروج سيدنا مسلم بن عقيل رسول الإمام الحسين (عليهما السلام) لأهل الكوفة سنة ٦٠هـ'),
    _EventModel(hDay: 17, hMonth: 9, hYear: 1, title: 'عروج الرسول الأكرم محمد (صلى الله عليه واله وسلم ) الى السماء قبل ستة أشهر من الهجرة'),
    _EventModel(hDay: 17, hMonth: 9, hYear: 1, title: 'واقعة معركة بدر الكبرى سنة ٢هـ'),
    _EventModel(hDay: 18, hMonth: 9, hYear: 1, title: 'ليلة القدر المباركة على رواية (الاولى)'),
    _EventModel(hDay: 19, hMonth: 9, hYear: 1, title: 'جرح أمير المؤمنين الامام علي (عليه السلام) على يد أشقى الأولين والآخرين ابن ملجم (لعنهُ الله) سنة ٤٠هـ'),
    _EventModel(hDay: 20, hMonth: 9, hYear: 1, title: 'فتح مكة المكرمة سنة ٨هـ'),
    _EventModel(hDay: 20, hMonth: 9, hYear: 1, title: 'ليلة القدر المباركة على رواية (الثانية)'),
    _EventModel(hDay: 21, hMonth: 9, hYear: 1, title: 'شهادة مولى المتقين أمير المؤمنين الامام علي بن ابي طالب (عليه السلام) سنة ٤٠هـ'),
    _EventModel(hDay: 22, hMonth: 9, hYear: 1, title: 'ليلة القدر المباركة على اقرب الاحتمالات فيها على رواية (الثالثة)'),
    _EventModel(hDay: 1, hMonth: 10, hYear: 1, title: 'عيد الفطر المبارك'),
    _EventModel(hDay: 3, hMonth: 10, hYear: 1, title: 'معركة الخندق سنة ٥هـ على رواية'),
    _EventModel(hDay: 4, hMonth: 10, hYear: 1, title: 'غزوة حنين سنة ٨هـ على رواية'),
    _EventModel(hDay: 5, hMonth: 10, hYear: 1, title: 'توجه أمير المؤمنين الإمام علي (عليه السلام) الى صفين سنة ٣٦هـ'),
    _EventModel(hDay: 8, hMonth: 10, hYear: 1, title: 'هدم قبور أئمة البقيع (عليهم السلام) سنة ١٣٤٤هـ'),
    _EventModel(hDay: 14, hMonth: 10, hYear: 1, title: 'وفاة السيد عبد العظيم الحسني (رضوان الله عليه) سنة ٢٥٢هـ'),
    _EventModel(hDay: 15, hMonth: 10, hYear: 1, title: 'معركة احد وشهادة حمزة سيد الشهداء (عليه السلام) سنة ٣هـ'),
    _EventModel(hDay: 15, hMonth: 10, hYear: 1, title: 'رد الشمس لأمير المؤمنين الإمام علي (عليه السلام) في المدينة المنورة / مسجد الفضيخ والمعروف بمسجد رد الشمس سنة ٣هـ'),
    _EventModel(hDay: 15, hMonth: 10, hYear: 1, title: 'غزوة بني القينقاع سنة ٢هـ'),
    _EventModel(hDay: 17, hMonth: 10, hYear: 1, title: 'غزوة بني سليم سنة ٢هـ'),
    _EventModel(hDay: 25, hMonth: 10, hYear: 1, title: 'شهادة الإمام جعفر الصادق (عليه السلام) سنة ١٤٨هـ'),
    _EventModel(hDay: 27, hMonth: 10, hYear: 1, title: 'خروج النبي الأكرم محمد (صلى الله عليه واله وسلام) الى الطائف لدعوتهم الى الإسلام'),
    _EventModel(hDay: 1, hMonth: 11, hYear: 1, title: 'ولادة السيدة فاطمة المعصومة بنت الامام الكاظم (عليهما السلام) سنة ١٧٣هـ على رواية'),
    _EventModel(hDay: 5, hMonth: 11, hYear: 1, title: 'تجديد بناء الكعبة المشرفة على يد نبي الله ابراهيم وولده إسماعيل (عليهما السلام)'),
    _EventModel(hDay: 9, hMonth: 11, hYear: 1, title: 'إرسال مسلم بن عقيل رسالة إلى الامام الحسين (عليهما السلام) عن أحوال الكوفة وأهلها سنة ٦٠هـ'),
    _EventModel(hDay: 11, hMonth: 11, hYear: 1, title: 'ولادة الامام الرضا (عليه السلام) سنة ١٤٨هـ'),
    _EventModel(hDay: 23, hMonth: 11, hYear: 1, title: 'غزوة بني قريضة سنة ٥هـ'),
    _EventModel(hDay: 25, hMonth: 11, hYear: 1, title: 'دحو الارض من تحت الكعبة المشرفة'),
    _EventModel(hDay: 25, hMonth: 11, hYear: 1, title: 'خروج النبي الأكرم محمد (صلى الله عليه واله وسلم) من المدينة المنورة لأداء فريضة الحج سنة ١٠هـ'),
    _EventModel(hDay: 25, hMonth: 11, hYear: 1, title: 'خروج الامام الرضا (عليه السلام) من المدينة المنورة إلى خراسان سنة ٢٠٠هـ'),
    _EventModel(hDay: 25, hMonth: 11, hYear: 1, title: 'ولادة محمد بن أبي بكر (رضوان الله عليه) سنة ١٠هـ'),
    _EventModel(hDay: 29, hMonth: 11, hYear: 1, title: 'شهادة الامام محمد الجواد (عليه السلام) سنة ٢٢٠هـ'),
    _EventModel(hDay: 1, hMonth: 12, hYear: 1, title: 'زواج امير المؤمنين الامام علي من سيدتنا فاطمة الزهراء (عليهما السلام) سنة ٢هـ'),
    _EventModel(hDay: 3, hMonth: 12, hYear: 1, title: 'دخول النبي الأكرم محمد (صلى الله عليه واله وسلم) مكة المكرمة في حجة الوداع سنة ١٠هـ'),
    _EventModel(hDay: 4, hMonth: 12, hYear: 1, title: 'سجن الامام موسى الكاظم (عليه السلام) سنة ١٧٩هـ'),
    _EventModel(hDay: 7, hMonth: 12, hYear: 1, title: 'شهادة الامام محمد الباقر (عليه السلام) سنة ١١٤هـ'),
    _EventModel(hDay: 8, hMonth: 12, hYear: 1, title: 'يوم التروية'),
    _EventModel(hDay: 8, hMonth: 12, hYear: 1, title: 'خروج الامام الحسين (عليه السلام) من مكة المكرمة إلى الكوفة سنة ٦٠هـ'),
    _EventModel(hDay: 9, hMonth: 12, hYear: 1, title: 'يوم عرفة'),
    _EventModel(hDay: 9, hMonth: 12, hYear: 1, title: 'شهادة سيدنا مسلم بن عقيل (عليه السلام) سنة ٦٠هـ'),
    _EventModel(hDay: 9, hMonth: 12, hYear: 1, title: 'شهادة هاني بن عروة (رضوان الله عليه) سنة ٦٠هـ'),
    _EventModel(hDay: 10, hMonth: 12, hYear: 1, title: 'عيد الأضحى المبارك'),
    _EventModel(hDay: 11, hMonth: 12, hYear: 1, title: 'رمي الحجاج بن يوسف الثقفي الكعبة المشرفة بالمنجنيق سنة ٧٣هـ'),
    _EventModel(hDay: 14, hMonth: 12, hYear: 1, title: 'نحلة النبي الأكرم محمد(صلى الله عليه واله وسلم) فدك لفاطمة الزهراء (عليها السلام) سنة ٧هـ على رواية'),
    _EventModel(hDay: 18, hMonth: 12, hYear: 1, title: 'عيد الغدير الاغر سنة ١٠هـ'),
    _EventModel(hDay: 19, hMonth: 12, hYear: 1, title: 'بيعة المسلمين لأمير المؤمنين الامام علي (عليه السلام) بالخلافة سنة ٣٥هـ'),
    _EventModel(hDay: 22, hMonth: 12, hYear: 1, title: 'شهادة ميثم التمار (رضوان الله عليه) سنة ٦٠هـ'),
    _EventModel(hDay: 23, hMonth: 12, hYear: 1, title: 'شهادة محمد وابراهيم اولاد مسلم بن عقيل(عليهم السلام)'),
    _EventModel(hDay: 24, hMonth: 12, hYear: 1, title: 'خروج النبي الأكرم محمد(صلى الله عليه واله وسلم) مع أهل بيته (عليهم السلام) للمباهلة مع نصارى نجران سنة ١٠هـ'),
    _EventModel(hDay: 25, hMonth: 12, hYear: 1, title: 'نزول سورة (هل أتى) في المدينة المنورة بشأن اهل البيت (عليهم السلام)'),
    _EventModel(hDay: 27, hMonth: 12, hYear: 1, title: 'وفاة علي بن الامام جعفر الصادق (عليهما السلام) سنة ٢١٠هـ الملقب (العريضي)'),
    _EventModel(hDay: 28, hMonth: 12, hYear: 1, title: 'وقعة الحرة التي استباح فيها جيش يزيد بن معاوية المدينة المنورة سنة ٦٣هـ'),    ];

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Returns a FULLY INITIALIZED HijriCalendar for the target month.
  /// Uses round-trip through Gregorian to ensure valid internal state.
  HijriCalendar _getHijriMonthForPage(int pageIndex) {
    int offset = pageIndex - _initialPage;
    int targetYear = _todayHijri!.hYear;
    int targetMonth = _todayHijri!.hMonth + offset;

    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }
    while (targetMonth < 1) {
      targetMonth += 12;
      targetYear--;
    }

    final DateTime gregDate = _todayHijri!.hijriToGregorian(targetYear, targetMonth, 1);
    final hijri = HijriCalendar.fromDate(gregDate);
    hijri.hDay = 1;
    return hijri;
  }

  List<_EventModel> _getEventsForDay(int day, int month) {
    return _events.where((e) => e.hDay == day && e.hMonth == month).toList();
  }

  bool _hasEvent(int day, int month) {
    return _events.any((e) => e.hDay == day && e.hMonth == month);
  }

  /// Returns the next upcoming event from TODAY (with year wrap-around).
  /// Events are treated as annual (hYear is ignored, only hMonth+hDay matter).
  _EventModel? _getNextEvent() {
    if (_todayHijri == null) return null;

    final int currentMonth = _todayHijri!.hMonth;
    final int currentDay = _todayHijri!.hDay;

    // Sort by month then day (annual cycle)
    final sorted = List<_EventModel>.from(_events)
      ..sort((a, b) {
        if (a.hMonth != b.hMonth) return a.hMonth.compareTo(b.hMonth);
        return a.hDay.compareTo(b.hDay);
      });

    // First pass: look for events in remaining months of current year
    for (final event in sorted) {
      if (event.hMonth > currentMonth ||
          (event.hMonth == currentMonth && event.hDay > currentDay)) {
        return event;
      }
    }

    // Second pass: wrap around to next year (events before current month)
    for (final event in sorted) {
      if (event.hMonth < currentMonth ||
          (event.hMonth == currentMonth && event.hDay < currentDay)) {
        return event;
      }
    }

    return sorted.isNotEmpty ? sorted.first : null;
  }

  void _goToToday() {
    _pageController?.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _displayedHijri = _todayHijri!;
      _selectedDay = null;
      _selectedDayEvents = [];
    });
  }

  /// ═══════════════════════════════════════════════════════════════
  /// دالة جديدة: تحويل أيام الأسبوع للعربي
  /// ═══════════════════════════════════════════════════════════════
  String _getArabicWeekday(int weekday) {
    const days = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد'
    };
    return days[weekday] ?? '';
  }

  Widget _buildCalendarGridForPage(BuildContext context, int pageIndex) {
    final HijriCalendar monthHijri = _getHijriMonthForPage(pageIndex);

    final DateTime gregFirstDay = _todayHijri!.hijriToGregorian(
      monthHijri.hYear,
      monthHijri.hMonth,
      1,
    );

    // ═══════════════════════════════════════════════════════════════
    // منطق حساب اليوم المحدد (Selected Day) وتاريخه الميلادي
    // ═══════════════════════════════════════════════════════════════
    // 1. تحديد اليوم الذي سيُعرض في الهيدر
    int displayHDay = 1;
    bool isCurrentMonth = monthHijri.hMonth == _todayHijri!.hMonth && monthHijri.hYear == _todayHijri!.hYear;

    if (_selectedDay != null && _displayedHijri.hMonth == monthHijri.hMonth && _displayedHijri.hYear == monthHijri.hYear) {
      displayHDay = _selectedDay!; // اليوم الذي ضغط عليه المستخدم
    } else if (isCurrentMonth) {
      displayHDay = _todayHijri!.hDay; // إذا لم يضغط شيء، أظهر اليوم الحالي
    }

    // 2. حساب التاريخ الميلادي المضبوط لهذا اليوم المحدد
    final DateTime exactGregDate = _todayHijri!.hijriToGregorian(
      monthHijri.hYear,
      monthHijri.hMonth,
      displayHDay,
    );

    String weekdayName = _getArabicWeekday(exactGregDate.weekday);

    final int leadingEmptyCells = (gregFirstDay.weekday + 1) % 7;
    final int daysInMonth = monthHijri.lengthOfMonth;
    final double gridHeight = ((leadingEmptyCells + daysInMonth) / 7).ceil() * 48.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ═══════════════════════════════════════════════════════════════
                  // الهيدر المتفاعل: يعرض اليوم الهجري والميلادي المحدد
                  // ═══════════════════════════════════════════════════════════════
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayHDay ${monthHijri.longMonthName} ${monthHijri.hYear} هـ'.toEasternArabic(), // يقرأ اليوم الهجري المتفاعل
                          style: const TextStyle(
                            fontFamily: 'me_quran',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$weekdayName ${exactGregDate.day} ${_getGregorianMonthName(exactGregDate.month)} ${exactGregDate.year} م'.toEasternArabic(), // يقرأ اليوم الميلادي واسم الأسبوع المتفاعل
                          style: const TextStyle(
                            fontFamily: 'me_quran',
                            color: Colors.tealAccent,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Lottie.asset(
                      'assets/lottie/calendar.json',
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'me_quran',
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: gridHeight,
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(leadingEmptyCells + daysInMonth, (index) {
                if (index < leadingEmptyCells) {
                  return const SizedBox.shrink();
                }

                final int hDay = index - leadingEmptyCells + 1;
                final bool isToday = _todayHijri != null &&
                    hDay == _todayHijri!.hDay &&
                    monthHijri.hMonth == _todayHijri!.hMonth &&
                    monthHijri.hYear == _todayHijri!.hYear;

                final bool hasEvent = _hasEvent(hDay, monthHijri.hMonth);
                final bool isSelected = _selectedDay == hDay &&
                    _displayedHijri.hMonth == monthHijri.hMonth &&
                    _displayedHijri.hYear == monthHijri.hYear;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDay = hDay;
                      _selectedDayEvents = _getEventsForDay(hDay, monthHijri.hMonth);
                      _displayedHijri = monthHijri;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? (hasEvent ? Colors.teal.shade700 : Colors.teal)
                          : null,
                      shape: isToday ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isToday ? null : BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday && hasEvent
                            ? Colors.amber
                            : (isSelected
                                ? Colors.green
                                : (hasEvent ? Colors.amber : Colors.transparent)),
                        width: isToday && hasEvent
                            ? 2.0
                            : (isSelected ? 2.0 : (hasEvent ? 1.5 : 0.0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$hDay'.toEasternArabic(),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? (hasEvent ? Colors.amber.shade200 : Colors.white)
                                : (hasEvent ? Colors.amber.shade300 : Colors.white70),
                          ),
                        ),
                        if (isToday && hasEvent)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEventsCard(String title, List<_EventModel> events) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'me_quran',
                color: Colors.tealAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24, height: 16),
            ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, color: Colors.tealAccent, size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return '';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return months[month - 1];
  }

  @override
  Widget _buildTodayEventCard(List<_EventModel> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.amber,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مناسبة اليوم',
            style: TextStyle(
              fontFamily: 'me_quran',
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 16),
          ...events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🕌', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_todayHijri!.hDay} ${_todayHijri!.longMonthName} ${_todayHijri!.hYear} هـ'.toEasternArabic(),
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    if (_isLoading || _todayHijri == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    final _EventModel? nextEvent = _getNextEvent();
    final List<_EventModel> todayEvents = _getEventsForDay(_todayHijri!.hDay, _todayHijri!.hMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التقويم الهجري',
          style: TextStyle(
            fontFamily: 'me_quran',
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: 'اليوم',
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          if (todayEvents.isNotEmpty)
            _buildTodayEventCard(todayEvents),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _displayedHijri = _getHijriMonthForPage(page);
                  _selectedDay = null;
                  _selectedDayEvents = [];
                });
              },
              itemBuilder: (context, index) => _buildCalendarGridForPage(context, index),
            ),
          ),
          if (nextEvent != null && !(todayEvents.isNotEmpty && nextEvent.title == todayEvents.first.title))
            _buildEventsCard('الأحداث القادمة', [nextEvent])
          else if (nextEvent == null)
             _buildEventsCard('الأحداث القادمة', [_EventModel(hDay: 0, hMonth: 0, hYear: 0, title: 'لا توجد مناسبات قادمة')]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
