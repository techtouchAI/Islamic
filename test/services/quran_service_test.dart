import 'package:flutter_test/flutter_test.dart';
import 'package:aldhakereen/services/quran_service.dart';
import 'package:aldhakereen/data/data_manager.dart';

void main() {
  setUp(() {
    // Reset DataManager state to null before each test
    DataManager.setDBForTesting(null);
  });

  group('QuranService - Fallback Logic', () {
    test('getSurahs returns hardcoded default data when DataManager has no quran content', () async {
      // By default, DataManager db is null, getItems('quran') will return []
      final surahs = await QuranService.getSurahs();

      // We expect the original fallback block from the code to be hit
      expect(surahs, isNotEmpty);
      expect(surahs.length, 2);
      expect(surahs[0]['id'], 2);
      expect(surahs[0]['name'], 'الفاتحة');
      expect(surahs[0]['total_ayahs'], 7);
    });

    test('getSurahs returns mapped data from DataManager when content exists', () async {
      // Setup mock CMS data in DataManager
      DataManager.setDBForTesting({
        'content': {
          'quran': [
            {
              'id': 1,
              'title': 'سورة الفاتحة'
            },
            {
              'id': 114,
              'title': 'سورة الناس'
            }
          ]
        }
      });

      final surahs = await QuranService.getSurahs();

      expect(surahs.length, 2);

      // Verification of CMS data formatting (stripping "سورة ")
      expect(surahs[0]['id'], 1);
      expect(surahs[0]['name'], 'الفاتحة');
      expect(surahs[0]['total_ayahs'], 'غير محدد');

      expect(surahs[1]['id'], 114);
      expect(surahs[1]['name'], 'الناس');
      expect(surahs[1]['total_ayahs'], 'غير محدد');
    });

    test('getAyahs returns ayah map when a match for the surah is found in DataManager', () async {
      // Setup mock CMS data
      DataManager.setDBForTesting({
        'content': {
          'quran': [
            {
              'id': 1,
              'title': 'سورة الفاتحة',
              'content': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'
            }
          ]
        }
      });

      final ayahs = await QuranService.getAyahs(1);

      expect(ayahs.length, 1);
      expect(ayahs[0]['ar_text'], 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(ayahs[0]['ayah_surah_index'], '');
    });

    test('getAyahs returns an empty list when surahId is not found in DataManager', () async {
      // Setup mock CMS data with different ID
      DataManager.setDBForTesting({
        'content': {
          'quran': [
            {
              'id': 5,
              'title': 'سورة المائدة',
              'content': '...'
            }
          ]
        }
      });

      final ayahs = await QuranService.getAyahs(2);

      expect(ayahs, isEmpty);
    });

    test('getAyahs returns an empty list when DataManager has no quran content', () async {
      // DataManager _db is null
      final ayahs = await QuranService.getAyahs(1);

      expect(ayahs, isEmpty);
    });
  });
}
