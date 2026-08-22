/// Selects the next item that may appear on the home prayer card.
/// Imsak is a Ramadan-only display item; it is never treated as an adhan prayer.
const List<String> _dailyPrayerKeys = <String>[
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
];

const Map<String, String> prayerDisplayNamesAr = <String, String>{
  'imsak': 'الإمساك',
  'fajr': 'الفجر',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

String nextPrayerKeyForHome({
  required Map<String, DateTime> localCivilTimes,
  required DateTime now,
  required bool isRamadan,
}) {
  final displayKeys = <String>[
    if (isRamadan) 'imsak',
    ..._dailyPrayerKeys,
  ];
  final upcoming = displayKeys
      .where((key) => localCivilTimes[key] != null)
      .map((key) => MapEntry<String, DateTime>(key, localCivilTimes[key]!))
      .where((entry) => now.isBefore(entry.value))
      .toList()
    ..sort((left, right) => left.value.compareTo(right.value));

  if (upcoming.isNotEmpty) return upcoming.first.key;

  // Once Isha has passed, the card points to the next day's Fajr.
  return 'fajr';
}

String prayerDisplayNameAr(String key) => prayerDisplayNamesAr[key] ?? key;
