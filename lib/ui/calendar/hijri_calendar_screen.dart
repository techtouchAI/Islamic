import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HijriCalendarScreen extends StatefulWidget {
  @override
  _HijriCalendarScreenState createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late PageController _pageController;
  HijriCalendar? _todayHijri;
  int _manualOffset = 0;
  int? _selectedDay;
  List<dynamic> _selectedDayEvents = [];

  List<dynamic> _events = [
    {"title": 'بداية السنة الهجرية', "day": 1, "month": 1},
    {
      "title":
          'بداية حصار النبي الأكرم  محمد( صلى الله عليه واله وسلم ) في شعب أبي طالب سنة 3 قبل الهجرة',
      "day": 1,
      "month": 1,
    },
    {
      "title": 'ورود الإمام الحسين (عليه السلام) أرض كربلاء سنة 61هـ',
      "day": 2,
      "month": 1,
    },
    {
      "title": ' ورود عمر بن سعد مع جيشه أرض كربلاء سنة 61هـ',
      "day": 3,
      "month": 1,
    },
    {
      "title":
          'واقعة الطف الخالدة واستشهاد الإمام الحسين واهل بيته (عليهم السلام)',
      "day": 10,
      "month": 1,
    },
    {
      "title": 'دخول سبايا أهل البيت (عليهم السلام) الى مدينة الكوفة',
      "day": 12,
      "month": 1,
    },
    {
      "title": 'دفن الأجساد الطاهرة لشهداء واقعة الطف الخالدة',
      "day": 13,
      "month": 1,
    },
    {
      "title": 'خروج سبايا أهل البيت (عليهم السلام) من الكوفة الى الشام',
      "day": 19,
      "month": 1,
    },
    {
      "title": ' وصول أمير المؤمنين الامام علي (عليه السلام) الى صفين',
      "day": 20,
      "month": 1,
    },
    {
      "title":
          ' شهادة الإمام علي بن الحسين السجاد (عليهما السلام) في المدينة المنورة سنة ٩٥هـ',
      "day": 25,
      "month": 1,
    },
    {
      "title":
          'شهادة علي بن الحسين المثلث (رضوان الله عليه) حفيد الامام الحسن المجتبى (عليه السلام)',
      "day": 26,
      "month": 1,
    },
    {
      "title": ' وفاة الصحابي الجليل حذيفة بن اليمان (رضوان الله عليه)',
      "day": 28,
      "month": 1,
    },
    {
      "title":
          ' إحضار الإمام محمد الجواد (عليه السلام) من المدينة المنورة الى بغداد سنة ٢٢٠هـ',
      "day": 28,
      "month": 1,
    },
    {"title": 'واقعة صفين سنة ٣٧هـ', "day": 1, "month": 2},
    {
      "title": 'دخول سبايا آل البيت (عليهم السلام) الى بلاد الشام سنة ٦١هـ',
      "day": 1,
      "month": 2,
    },
    {
      "title": 'شهادة زيد بن علي بن الحسين (عليهم السلام) سنة ١٢١هـ',
      "day": 2,
      "month": 2,
    },
    {
      "title": 'ولادة الإمام محمد الباقر(عليه السلام) سنة ٥٧ هـ على رواية',
      "day": 3,
      "month": 2,
    },
    {
      "title": 'شهادة السيدة رقية بنت الإمام الحسين (عليهما السلام) سنة ٦١هـ',
      "day": 5,
      "month": 2,
    },
    {
      "title": 'شهادة الإمام الحسن المجتبى (عليه السلام) سنة ٥٠هـ',
      "day": 7,
      "month": 2,
    },
    {
      "title": 'وفاة الصحابي الجليل سلمان الفارسي (رضوان الله عليه) سنة ٣٥هـ',
      "day": 8,
      "month": 2,
    },
    {
      "title":
          'شهادة الصحابي الجليل عمار بن ياسر (رضوان الله عليه) في معركة صفين سنة ٣٧هـ  ',
      "day": 9,
      "month": 2,
    },
    {"title": 'واقعة النهروان سنة ٣٨هـ', "day": 9, "month": 2},
    {
      "title": 'شهادة محمد بن أبي بكر(رضوان الله عليه) في مصر سنة ٣٨هـ',
      "day": 14,
      "month": 2,
    },
    {
      "title":
          'شهادة الإمام علي بن موسى الرضا (عليهما السلام) على رواية سنة ٢٠٣هـ',
      "day": 17,
      "month": 2,
    },
    {
      "title":
          'ورود السبايا من آل بيت النبي (عليهم السلام) أرض كربلاء سنة ٦١هـ',
      "day": 20,
      "month": 2,
    },
    {
      "title":
          'إستشهاد النبي الاعظم رسول الله محمد (صلى الله عليه واله وسلم) سنة ١١هـ',
      "day": 28,
      "month": 2,
    },
    {
      "title":
          'مبيت أمير المؤمنين الامام علي (عليه السلام) في فراش النبي الأكرم محمد (صلى الله عليه واله وسلم) وهجرة النبي الى المدينة المنورة ',
      "day": 1,
      "month": 3,
    },
    {
      "title":
          'إحراق الكعبة المشرفة بالمنجنيق بأمر من حصين بن نمير قائد جيش يزيد سنة 64هـ',
      "day": 3,
      "month": 3,
    },
    {
      "title":
          'خروج رسول الله محمد (صلى الله عليه واله وسلم) من غار ثور متوجها الى المدينة المنورة في السنة الأولى من الهجرة',
      "day": 4,
      "month": 3,
    },
    {
      "title": 'وفاة السيدة سكينة بنت الإمام الحسين(عليهما السلام) سنة ١١٧هـ',
      "day": 5,
      "month": 3,
    },
    {
      "title": 'شهادة الإمام الحسن العسكري (عليه السلام) على رواية سنة ٢٦٠هـ',
      "day": 8,
      "month": 3,
    },
    {
      "title":
          'زواج النبي الأكرم محمد(صلى الله عليه واله وسلم) من السيدة خديجة الكبرى(عليها السلام) سنة ٢٨ قبل الهجرة',
      "day": 10,
      "month": 3,
    },
    {
      "title":
          'وفاة عبد المطلب جد النبي الأكرم محمد (صلى الله عليه واله وسلم) في السنة الثامنة من ولادته سنة ٤٥ قبل الهجرة',
      "day": 10,
      "month": 3,
    },
    {
      "title": 'ولادة النبي الاكرم محمد (صلى الله عليه واله وسلم) على رواية',
      "day": 12,
      "month": 3,
    },
    {
      "title":
          'دخول رسول الله محمد (صلى الله عليه واله وسلم) المدينة المنورة في السنة الأولى من الهجرة',
      "day": 12,
      "month": 3,
    },
    {
      "title":
          'ولادة سيد الرسل والمخلوقات النبي الاعظم محمد (صلى الله عليه واله وسلم) سنة 53 قبل الهجرة على الرواية المشهورة',
      "day": 17,
      "month": 3,
    },
    {
      "title": 'ولادة الإمام جعفر الصادق ( عليه السلام) سنة ٨٣هـ',
      "day": 17,
      "month": 3,
    },
    {"title": 'غزوة بني النضير سنة ٤هـ', "day": 22, "month": 3},
    {
      "title": 'استشهاد سعيد بن جبير(رضوان الله عليه) على يد الحجاج سنة ٩٥هـ',
      "day": 25,
      "month": 3,
    },
    {
      "title":
          'إبرام معاهدة الصلح بين الإمام الحسن (عليه السلام) ومعاوية بن أبي سفيان سنة ٤١هـ',
      "day": 26,
      "month": 3,
    },
    {
      "title":
          'شهادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ١١هـ على رواية',
      "day": 8,
      "month": 4,
    },
    {
      "title": 'ولادة الإمام الحسن العسكري (عليه السلام) سنة ٢٣٢هـ  على رواية',
      "day": 10,
      "month": 4,
    },
    {
      "title":
          'وفاة السيدة فاطمة المعصومة بنت الإمام موسى الكاظم (عليهما السلام) سنة ٢٠١هـ  على رواية',
      "day": 10,
      "month": 4,
    },
    {
      "title":
          'خروج المختار الثقفي (رحمه الله ) في الكوفة للأخذ بثأر الإمام الحسين (عليه السلام) سنة ٦٦هـ',
      "day": 14,
      "month": 4,
    },
    {
      "title":
          'ولادة السيدة زينب الكبرى  بنت امير المؤمنين الإمام علي (عليهما السلام) سنة ٥هـ',
      "day": 5,
      "month": 5,
    },
    {
      "title": 'حرب مؤته واستشهاد جعفر بن أبي طالب (عليه السلام)  سنة ٨هـ',
      "day": 6,
      "month": 5,
    },
    {"title": 'واقعة الجمل سنة ٣٦هـ', "day": 10, "month": 5},
    {
      "title":
          'شهادة سيدة نساء العالمين فاطمة الزهراء(عليها السلام) سنة ١١هـ على رواية',
      "day": 13,
      "month": 5,
    },
    {
      "title":
          'فتح البصرة على يد أمير المؤمنين الامام علي (عليه السلام) سنة ٣٦هـ',
      "day": 15,
      "month": 5,
    },
    {
      "title": 'شهادة زيد بن صوحان (رضوان الله عليه) في حرب الجمل سنة ٣٦هـ',
      "day": 19,
      "month": 5,
    },
    {
      "title":
          'وفاة القاسم بن الإمام موسى الكاظم (عليهما السلام) سنة ١٩٢هـ على رواية ',
      "day": 22,
      "month": 5,
    },
    {
      "title":
          'وفاة محمد بن عثمان بن سعيد الخلاني (رضوان الله عليه) السفير الثاني للإمام المهدي المنتظر (عجل الله فرجه الشريف) سنة ٣٠٤هـ',
      "day": 30,
      "month": 5,
    },
    {
      "title":
          'شهادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ١١هـ على رواية',
      "day": 3,
      "month": 6,
    },
    {
      "title": 'وفاة السيدة فاطمة أم البنين (عليها السلام) سنة ٦٤هـ',
      "day": 13,
      "month": 6,
    },
    {
      "title":
          ' زواج عبد الله وآمنة (رضوان الله عليهما) والدي النبي الأكرم محمد (صلى الله عليه واله وسلم)',
      "day": 19,
      "month": 6,
    },
    {
      "title":
          'ولادة سيدة نساء العالمين فاطمة الزهراء (عليها السلام) سنة ٨ قبل الهجرة',
      "day": 20,
      "month": 6,
    },
    {
      "title":
          'رجوع أمير المؤمنين الامام علي(عليه السلام) من حرب الجمل سنة ٣٦هـ',
      "day": 21,
      "month": 6,
    },
    {
      "title": 'وفاة السيدة أم كلثوم بنت الإمام علي(عليه السلام) سنة ٦١هـ',
      "day": 21,
      "month": 6,
    },
    {
      "title": 'ولادة الإمام محمد الباقر(عليه السلام) سنة ٥٧هـ على رواية',
      "day": 1,
      "month": 7,
    },
    {
      "title": 'ولادة الإمام علي الهادي (عليه السلام) سنة ٢١٢هـ',
      "day": 2,
      "month": 7,
    },
    {"title": 'غزوة تبوك سنة ٩هـ', "day": 3, "month": 7},
    {
      "title": 'شهادة الإمام علي الهادي(عليه السلام) سنة ٢٥٤هـ',
      "day": 3,
      "month": 7,
    },
    {
      "title": 'ولادة الإمام محمد الجواد(عليه السلام) سنة ١٩٥هـ',
      "day": 10,
      "month": 7,
    },
    {
      "title":
          'وصول أمير المؤمنين الامام علي(عليه السلام) الى الكوفة بعد حرب الجمل سنة ٣٦هـ ',
      "day": 11,
      "month": 7,
    },
    {
      "title":
          'دخول أمير المؤمنين الامام علي(عليه السلام) الكوفة واتخاذها مقرا للخلافة سنة ٣٦هـ',
      "day": 12,
      "month": 7,
    },
    {
      "title":
          'ولادة أمير المؤمنين الامام علي بن ابي طالب (عليه السلام) سنة ٢٣ قبل الهجرة',
      "day": 13,
      "month": 7,
    },
    {
      "title":
          'وفاة السيدة زينب الكبرى بنت أمير المؤمنين الامام علي (عليهما السلام) سنة ٦٢هـ على رواية ',
      "day": 15,
      "month": 7,
    },
    {
      "title":
          'تحويل القبلة من بيت المقدس الى الكعبة المشرّفة  سنة ٢هـ على رواية',
      "day": 15,
      "month": 7,
    },
    {
      "title": 'وفاة إبراهيم بن الرسول الأكرم محمد(صلى الله عليه واله وسلم)',
      "day": 18,
      "month": 7,
    },
    {
      "title":
          'فتح خيبر على يد الإمام علي بن أبي طالب (عليه السلام) سنة ٧هـ وعودة جعفر بن أبي طالب (عليه السلام) من الحبشة',
      "day": 24,
      "month": 7,
    },
    {
      "title": 'شهادة الإمام موسى بن جعفر الكاظم (عليهما السلام) سنة ١٨٣هـ',
      "day": 25,
      "month": 7,
    },
    {
      "title":
          'وفاة أبي طالب (عليه السلام) عم النبي الأكرم  محمد (صلى الله عليه واله وسلم) سنة ٣ قبل الهجرة على رواية',
      "day": 26,
      "month": 7,
    },
    {
      "title":
          'بعثة النبي الاعظم محمد (صلى الله عليه واله وسلم) سنة ١٣ قبل الهجرة',
      "day": 27,
      "month": 7,
    },
    {
      "title": 'خروج الإمام الحسين(عليه السلام) من المدينة الى مكة سنة ٦٠هـ',
      "day": 28,
      "month": 7,
    },
    {
      "title":
          'ولادة سبط النبي الأكرم (صلى الله عليه واله وسلم) الإمام الحسين (عليه السلام) سنة ٤هـ',
      "day": 3,
      "month": 8,
    },
    {
      "title": 'دخول الإمام الحسين (عليه السلام) مكة سنة ٦٠هـ',
      "day": 3,
      "month": 8,
    },
    {
      "title":
          ' ولادة المولى ابي الفضل العباس بن امير المؤمنين الامام علي (عليهما السلام) سنة ٢٦هـ',
      "day": 4,
      "month": 8,
    },
    {
      "title":
          ' ولادة زين العابدين الإمام علي بن الحسين (عليهما السلام) سنة ٣٨هـ',
      "day": 5,
      "month": 8,
    },
    {
      "title":
          ' ولادة سيدنا علي الأكبر بن الإمام الحسين (عليهما السلام) سنة ٣٣هـ',
      "day": 11,
      "month": 8,
    },
    {
      "title":
          ' وفاة الحسين بن روح (رضوان الله عليه) السفير الثالث للإمام المهدي (عجل الله فرجه الشريف) سنة ٣٢٦هـ',
      "day": 13,
      "month": 8,
    },
    {
      "title":
          'ولادة بقية الله الأعظم الحجة بن الحسن الامام صاحب العصر والزمان (عجل الله فرجه الشريف) سنة ٢٥٥هـ ',
      "day": 15,
      "month": 8,
    },
    {
      "title":
          'وفاة علي بن محمد السمري(رضوان الله عليه) السفير الرابع للإمام المهدي (عجل الله فرجه الشريف) سنة ٣٢٩هـ وهذا اليوم بدأت الغيبة الكبرى',
      "day": 15,
      "month": 8,
    },
    {"title": 'غزوة بني المصطلق سنة ٥هـ', "day": 19, "month": 8},
    {
      "title":
          'وفاة عثمان بن سعيد (رضوان الله عليه) النائب الأول للإمام المهدي (عجل الله فرجه الشريف) سنة  ٢٦٧هـ',
      "day": 1,
      "month": 9,
    },
    {
      "title":
          'تولي الإمام الرضا (عليه السلام) ولاية عهد المأمون العباسي سنة ٢٠١هـ على رواية',
      "day": 2,
      "month": 9,
    },
    {"title": 'غزوة تبوك سنة 9هـ', "day": 3, "month": 9},
    {
      "title": ' بيعة الناس للإمام الرضا(عليه السلام) سنة ٢٠١هـ على رواية',
      "day": 6,
      "month": 9,
    },
    {
      "title":
          ' خروج النبي الأكرم محمد (صلى الله عليه واله وسلم) لغزوة بدر الكبرى سنة ٢هـ',
      "day": 8,
      "month": 9,
    },
    {
      "title": 'وفاة الصديقة خديجة الكبرى (عليها السلام) سنة ٣هـ قبل الهجرة',
      "day": 10,
      "month": 9,
    },
    {
      "title":
          'المؤاخاة بين المهاجرين والأنصار في المدينة المنورة في السنة الأولى للهجرة',
      "day": 12,
      "month": 9,
    },
    {
      "title": 'شهادة المختار الثقفي (رحمه الله) سنة ٦٧هـ',
      "day": 14,
      "month": 9,
    },
    {
      "title":
          'ولادة سبط النبي الأكرم (صلى الله عليه واله وسلام) الإمام الحسن المجتبى (عليه السلام) سنة ٣هـ',
      "day": 15,
      "month": 9,
    },
    {
      "title":
          'خروج سيدنا مسلم بن عقيل رسول الإمام الحسين (عليهما السلام) لأهل الكوفة سنة ٦٠هـ ',
      "day": 15,
      "month": 9,
    },
    {
      "title":
          'عروج الرسول الأكرم محمد (صلى الله عليه واله وسلم ) الى السماء قبل ستة أشهر من الهجرة',
      "day": 17,
      "month": 9,
    },
    {"title": 'واقعة معركة بدر الكبرى سنة ٢هـ', "day": 17, "month": 9},
    {"title": 'ليلة القدر المباركة على رواية (الاولى)', "day": 18, "month": 9},
    {
      "title":
          'جرح أمير المؤمنين الامام علي (عليه السلام) على يد أشقى الأولين والآخرين ابن ملجم (لعنهُ الله) سنة ٤٠هـ',
      "day": 19,
      "month": 9,
    },
    {"title": 'فتح مكة المكرمة سنة ٨هـ', "day": 20, "month": 9},
    {"title": 'ليلة القدر المباركة على رواية (الثانية)', "day": 20, "month": 9},
    {
      "title":
          'شهادة مولى المتقين أمير المؤمنين الامام علي بن ابي طالب (عليه السلام) سنة ٤٠هـ',
      "day": 21,
      "month": 9,
    },
    {
      "title":
          'ليلة القدر المباركة على اقرب الاحتمالات فيها على رواية (الثالثة)',
      "day": 22,
      "month": 9,
    },
    {"title": 'عيد الفطر المبارك', "day": 1, "month": 10},
    {"title": 'معركة الخندق سنة ٥هـ على رواية ', "day": 3, "month": 10},
    {"title": ' غزوة حنين سنة ٨هـ على رواية', "day": 4, "month": 10},
    {
      "title": 'توجه أمير المؤمنين الإمام علي (عليه السلام) الى صفين سنة ٣٦هـ',
      "day": 5,
      "month": 10,
    },
    {
      "title": ' هدم قبور أئمة البقيع (عليهم السلام) سنة ١٣٤٤هـ',
      "day": 8,
      "month": 10,
    },
    {
      "title": ' وفاة السيد عبد العظيم الحسني (رضوان الله عليه) سنة ٢٥٢هـ',
      "day": 14,
      "month": 10,
    },
    {
      "title": 'معركة احد وشهادة حمزة سيد الشهداء (عليه السلام) سنة ٣هـ',
      "day": 15,
      "month": 10,
    },
    {
      "title":
          'رد الشمس لأمير المؤمنين الإمام علي (عليه السلام) في المدينة المنورة / مسجد الفضيخ والمعروف بمسجد رد الشمس سنة ٣هـ',
      "day": 15,
      "month": 10,
    },
    {"title": 'غزوة بني القينقاع سنة ٢هـ', "day": 15, "month": 10},
    {"title": ' غزوة بني سليم سنة ٢هـ', "day": 17, "month": 10},
    {
      "title": 'شهادة الإمام جعفر الصادق (عليه السلام) سنة ١٤٨هـ',
      "day": 25,
      "month": 10,
    },
    {
      "title":
          ' خروج النبي الأكرم محمد (صلى الله عليه واله وسلام) الى الطائف لدعوتهم الى الإسلام',
      "day": 27,
      "month": 10,
    },
    {
      "title":
          'ولادة السيدة فاطمة المعصومة بنت الامام الكاظم (عليهما السلام) سنة ١٧٣هـ على رواية',
      "day": 1,
      "month": 11,
    },
    {
      "title":
          'تجديد بناء الكعبة المشرفة على يد نبي الله ابراهيم وولده إسماعيل (عليهما السلام)',
      "day": 5,
      "month": 11,
    },
    {
      "title":
          'إرسال مسلم بن عقيل رسالة إلى الامام الحسين (عليهما السلام) عن أحوال الكوفة وأهلها سنة ٦٠هـ',
      "day": 9,
      "month": 11,
    },
    {
      "title": 'ولادة الامام الرضا (عليه السلام) سنة ١٤٨هـ',
      "day": 11,
      "month": 11,
    },
    {"title": 'غزوة بني قريضة سنة ٥هـ', "day": 23, "month": 11},
    {"title": 'دحو الارض من تحت الكعبة المشرفة', "day": 25, "month": 11},
    {
      "title":
          'خروج النبي الأكرم محمد (صلى الله عليه واله وسلم) من المدينة المنورة لأداء فريضة الحج سنة ١٠هـ',
      "day": 25,
      "month": 11,
    },
    {
      "title":
          'خروج الامام الرضا (عليه السلام) من المدينة المنورة  إلى خراسان سنة ٢٠٠هـ',
      "day": 25,
      "month": 11,
    },
    {
      "title": 'ولادة محمد بن أبي بكر (رضوان الله عليه) سنة ١٠هـ',
      "day": 25,
      "month": 11,
    },
    {
      "title": 'شهادة الامام محمد الجواد (عليه السلام) سنة ٢٢٠هـ',
      "day": 29,
      "month": 11,
    },
    {
      "title":
          'زواج امير المؤمنين الامام علي من سيدتنا فاطمة الزهراء (عليهما السلام) سنة ٢هـ',
      "day": 1,
      "month": 12,
    },
    {
      "title":
          'دخول النبي الأكرم محمد (صلى الله عليه واله وسلم) مكة المكرمة في حجة الوداع سنة ١٠هـ ',
      "day": 3,
      "month": 12,
    },
    {
      "title": 'سجن الامام موسى الكاظم (عليه السلام) سنة ١٧٩هـ ',
      "day": 4,
      "month": 12,
    },
    {
      "title": 'شهادة الامام محمد الباقر (عليه السلام) سنة ١١٤هـ ',
      "day": 7,
      "month": 12,
    },
    {"title": 'يوم التروية', "day": 8, "month": 12},
    {
      "title":
          'خروج الامام الحسين (عليه السلام) من مكة المكرمة إلى الكوفة سنة ٦٠هـ',
      "day": 8,
      "month": 12,
    },
    {"title": 'يوم عرفة', "day": 9, "month": 12},
    {
      "title": 'شهادة سيدنا مسلم بن عقيل (عليه السلام) سنة ٦٠هـ ',
      "day": 9,
      "month": 12,
    },
    {
      "title": 'شهادة هاني بن عروة (رضوان الله عليه) سنة ٦٠هـ ',
      "day": 9,
      "month": 12,
    },
    {"title": 'عيد الأضحى المبارك ', "day": 10, "month": 12},
    {
      "title": 'رمي الحجاج بن يوسف الثقفي الكعبة المشرفة بالمنجنيق سنة ٧٣هـ ',
      "day": 11,
      "month": 12,
    },
    {
      "title":
          'نحلة النبي الأكرم محمد(صلى الله عليه واله وسلم) فدك لفاطمة الزهراء (عليها السلام) سنة ٧هـ على رواية',
      "day": 14,
      "month": 12,
    },
    {"title": 'عيد الغدير الاغر سنة ١٠هـ ', "day": 18, "month": 12},
    {
      "title":
          'بيعة المسلمين لأمير المؤمنين الامام علي (عليه السلام) بالخلافة سنة ٣٥هـ ',
      "day": 19,
      "month": 12,
    },
    {
      "title": 'شهادة ميثم التمار (رضوان الله عليه) سنة ٦٠هـ',
      "day": 22,
      "month": 12,
    },
    {
      "title": 'شهادة محمد وابراهيم اولاد مسلم بن عقيل(عليهم السلام)',
      "day": 23,
      "month": 12,
    },
    {
      "title":
          'خروج النبي الأكرم محمد(صلى الله عليه واله وسلم) مع أهل بيته (عليهم السلام) للمباهلة مع نصارى نجران سنة ١٠هـ ',
      "day": 24,
      "month": 12,
    },
    {
      "title":
          'نزول سورة (هل أتى) في المدينة المنورة بشأن اهل البيت (عليهم السلام)',
      "day": 25,
      "month": 12,
    },
    {
      "title":
          'وفاة علي بن الامام جعفر الصادق (عليهما السلام) سنة ٢١٠هـ الملقب (العريضي)',
      "day": 27,
      "month": 12,
    },
    {
      "title":
          'وقعة الحرة التي استباح فيها جيش يزيد بن معاوية المدينة المنورة سنة ٦٣هـ',
      "day": 28,
      "month": 12,
    },
  ];

  static const MethodChannel _hijriChannel = MethodChannel(
    'com.techtouchai.islamic/hijri',
  );

  @override
  void initState() {
    super.initState();
    // استخدام رقم كبير لتفعيل التمرير اللانهائي (Infinite Scroll)
    _pageController = PageController(initialPage: 1200);
    _fetchHijriData();
  }

  Future<void> _fetchHijriData() async {
    HijriCalendar.setLocal('ar');
    final prefs = await SharedPreferences.getInstance();
    _manualOffset = prefs.getInt('hijri.date.correction.value') ?? 0;

    try {
      final date = await _hijriChannel.invokeMethod('getHijriDate', {
        'manualOffset': _manualOffset,
      });
      final events = await _hijriChannel.invokeMethod('getEvents');

      setState(() {
        if (date != null && date is Map) {
          // We ignore the map from Native because manually setting properties breaks HijriCalendar internals.
          // Instead we initialize properly by letting the library process the date via `fromDate` using the manual offset.
          _todayHijri = HijriCalendar.fromDate(
            DateTime.now().add(Duration(days: _manualOffset)),
          );
        } else {
          _todayHijri = HijriCalendar.fromDate(
            DateTime.now().add(Duration(days: _manualOffset)),
          );
        }

        if (events != null && events is List) {
          _events = events;
        }
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get Hijri Date: '${e.message}'.");
      setState(() {
        _todayHijri = HijriCalendar.fromDate(
          DateTime.now().add(Duration(days: _manualOffset)),
        );
      });
    } catch (e) {
      // التقاط أي استثناءات أخرى (مثل أخطاء التحويل) لضمان عدم ظهور الشاشة الرمادية
      debugPrint("Unknown error fetching Hijri Date: $e");
      setState(() {
        _todayHijri = HijriCalendar.fromDate(
          DateTime.now().add(Duration(days: _manualOffset)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة التحميل الآمنة
    if (_todayHijri == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text(
          'التقويم الهجري',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        reverse: true, // الاتجاه من اليمين لليسار RTL
        itemBuilder: (context, index) {
          try {
            int monthOffset = index - 1200;
            int targetMonth = _todayHijri!.hMonth + monthOffset;
            int targetYear = _todayHijri!.hYear;
            while (targetMonth > 12) {
              targetMonth -= 12;
              targetYear++;
            }
            while (targetMonth < 1) {
              targetMonth += 12;
              targetYear--;
            }

            // Let HijriCalendar handle the math safely.
            // The method `hijriToGregorian` works as long as we use an initialized object.
            DateTime gFirstDay = _todayHijri!.hijriToGregorian(
              targetYear,
              targetMonth,
              1,
            );
            var pageHijri = HijriCalendar.fromDate(gFirstDay);
            // Force hDay=1 to align grid since fromDate uses the exact day it resolved to.
            pageHijri.hDay = 1;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pageHijri.longMonthName} ${pageHijri.hYear}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${gFirstDay.year} ${_getGregorianMonthName(gFirstDay.month)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: Lottie.asset(
                              'assets/lottie/calendar.json',
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
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
                  const SizedBox(height: 20),

                  Expanded(
                    child: _buildCalendarGridForPage(pageHijri, gFirstDay),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        Icon(Icons.event, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          _selectedDay != null
                              ? "أحداث هذا اليوم"
                              : "الحدث القادم",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _selectedDay != null
                          ? _selectedDayEvents.length
                          : _events
                                .where(
                                  (e) =>
                                      int.tryParse(
                                        e['month']?.toString() ?? '-1',
                                      ) ==
                                      pageHijri.hMonth,
                                )
                                .length,
                      itemBuilder: (context, index) {
                        final monthEvents = _events
                            .where(
                              (e) =>
                                  int.tryParse(
                                    e['month']?.toString() ?? '-1',
                                  ) ==
                                  pageHijri.hMonth,
                            )
                            .toList();
                        final event = _selectedDay != null
                            ? _selectedDayEvents[index]
                            : monthEvents[index];
                        // التعامل الآمن مع القيم الفارغة (Null handling)
                        final title =
                            event['title']?.toString() ?? 'حدث غير محدد';
                        final day = event['day']?.toString() ?? '';
                        final month = event['month']?.toString() ?? '';

                        return Card(
                          color: const Color(0xFF2A2A2A),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Text(
                              "$day $month",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } catch (e) {
            return Center(
              child: Text(
                "Error: ${e.toString()}",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCalendarGridForPage(
    HijriCalendar pageHijri,
    DateTime gFirstDay,
  ) {
    int daysInMonth = 30; // قيمة افتراضية للسلامة
    try {
      daysInMonth = pageHijri.lengthOfMonth;
    } catch (e) {
      debugPrint("Error getting length of month: $e");
    }

    int startingWeekday = gFirstDay.weekday;
    if (startingWeekday == 7) startingWeekday = 0; // الأحد = 0 في بعض التقويمات

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Safe constraint inside Expanded Column
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return const SizedBox.shrink(); // استخدام SizedBox.shrink للأداء الأفضل بدلاً من Container فارغ
        }

        int hDay = index - startingWeekday + 1;
        bool isToday =
            (hDay == _todayHijri!.hDay) &&
            (pageHijri.hMonth == _todayHijri!.hMonth) &&
            (pageHijri.hYear == _todayHijri!.hYear);

        DateTime gDate = gFirstDay.add(Duration(days: hDay - 1));

        // معالجة التوافق بين أنواع البيانات بأمان
        bool hasEvent = _events.any((e) {
          final eDay = int.tryParse(e['day']?.toString() ?? '-1');
          final eMonth = int.tryParse(e['month']?.toString() ?? '-1');
          return eDay == hDay && eMonth == pageHijri.hMonth;
        });

        bool isSelected = _selectedDay == hDay;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = hDay;
              _selectedDayEvents = _events.where((e) {
                final eDay = int.tryParse(e['day']?.toString() ?? '-1');
                final eMonth = int.tryParse(e['month']?.toString() ?? '-1');
                return eDay == hDay && eMonth == pageHijri.hMonth;
              }).toList();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.red
                  : (isSelected
                        ? Colors.green.withAlpha(51)
                        : (hasEvent
                              ? Colors.blue.withAlpha(51)
                              : Colors.transparent)),
              shape: isToday ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isToday ? null : BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.withAlpha(51),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$hDay',
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : (hasEvent ? Colors.blueAccent : Colors.white70),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${gDate.day}',
                  style: TextStyle(
                    color: isToday ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return ''; // حماية من خطأ RangeError
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
