import 'package:aldhakereen/services/search_engine.dart';
import 'package:aldhakereen/utils/arabic_normalizer.dart';
import 'package:aldhakereen/utils/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all JSON entry points use one canonical Arabic normalizer', () {
    const text = '  ٱلرَّحْـمَٰنُ   عَلَى  فاطمة ';
    const expected = 'الرحمن علي فاطمه';
    expect(ArabicNormalizer.normalize(text), expected);
    expect(text.normalizeArabic(), expected);
    expect(SearchEngine.normalizeArabic(text), expected);
  });

  test('LIKE special characters are escaped independently of Arabic text', () {
    expect(ArabicNormalizer.escapeLike('a_b%'), r'a\_b\%');
  });
}
