import 'package:aldhakereen/utils/content_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('displayMarkup', () {
    test('drops the payload marker and keeps the inline tags', () {
      const raw = 'html <p><c=#ff0000><b>عنوان</b></c></p><p>نص</p>';
      expect(
        ContentSanitizer.displayMarkup(raw),
        '<c=#ff0000><b>عنوان</b></c>\n\nنص',
      );
    });

    test('turns block tags into paragraph breaks and br into a line break', () {
      const raw = '<div>أول</div><br><br /><p>ثاني</p>';
      expect(ContentSanitizer.displayMarkup(raw), 'أول\n\nثاني');
    });

    test('removes comments, heading markers and document wrappers', () {
      const raw =
          '<!-- exported --> <html><body>\n### عنوان\n<p>نص</p></body></html>';
      final result = ContentSanitizer.displayMarkup(raw);
      expect(result, contains('عنوان'));
      expect(result, contains('نص'));
      expect(result, isNot(contains('<!--')));
      expect(result, isNot(contains('###')));
      expect(result, isNot(contains('<html>')));
    });

    test('spells out the Quranic ligatures', () {
      expect(
        ContentSanitizer.displayMarkup('محمد ﷺ وربنا ﷻ'),
        'محمد (صلى الله عليه وآله) وربنا (جل جلاله)',
      );
    });
  });

  group('plainText', () {
    test('leaves no tag behind', () {
      const raw = 'html <p><c=#ff0000><b>عنوان</b></c></p><p>نص</p>';
      expect(ContentSanitizer.plainText(raw), 'عنوان\n\nنص');
    });

    test('keeps paragraphs separated by a blank line', () {
      const raw = '<p>first</p><p>second</p>';
      expect(ContentSanitizer.plainText(raw), 'first\n\nsecond');
    });

    test('an exclamation mark stays an exclamation mark', () {
      // The reader used to rewrite `!` as `(عليه السلام)`, which turned real
      // questions and exclamations into a phrase that was never there.
      const raw = 'html <p><b>كيف تنجب بغير زواج!!</b></p>';
      expect(ContentSanitizer.plainText(raw), 'كيف تنجب بغير زواج!!');
      expect(
        ContentSanitizer.displayMarkup(raw),
        '<b>كيف تنجب بغير زواج!!</b>',
      );
    });

    test('a URL survives, because nothing strips `//` any more', () {
      const raw = 'html <p>القناة: https://t.me/techtouchAI_bot</p>';
      expect(
        ContentSanitizer.plainText(raw),
        'القناة: https://t.me/techtouchAI_bot',
      );
    });

    test('decodes entities, and an escaped entity only once', () {
      expect(
        ContentSanitizer.plainText('<p>a&nbsp;&amp;&lt;b&gt;&quot;c&quot;</p>'),
        'a &<b>"c"',
      );
      expect(ContentSanitizer.plainText('<p>&amp;lt;</p>'), '&lt;');
    });

    test('a stray angle bracket in prose is not treated as a tag', () {
      expect(
        ContentSanitizer.plainText('<p>5 < 6 و 7 > 3</p>'),
        '5 < 6 و 7 > 3',
      );
    });

    test('an empty payload stays empty', () {
      expect(ContentSanitizer.plainText(''), '');
      expect(ContentSanitizer.displayMarkup('   '), '');
    });
  });

  group('snippet', () {
    test('is a single line', () {
      const raw = 'html <p>أول</p><p>ثاني</p>';
      expect(ContentSanitizer.snippet(raw), 'أول ثاني');
    });

    test('clips to the requested length with an ellipsis', () {
      expect(ContentSanitizer.snippet('abcdefghij', maxLength: 4), 'abcd…');
      expect(ContentSanitizer.snippet('abc', maxLength: 4), 'abc');
    });
  });

  group('a real payload', () {
    test('the prophets stories share as prose and read as prose', () {
      const raw = 'html <p><c=#ff0000><b> اليسع عليه السلام</b></c></p>'
          '<p><c=#0000ff><b>ملخص قصة اليسع عليه السلام</b></c></p>'
          '<p><b>من العبدة الأخيار!</b></p>';
      final shared = ContentSanitizer.plainText(raw);
      expect(shared, contains('اليسع عليه السلام'));
      expect(shared, contains('ملخص قصة اليسع عليه السلام'));
      expect(shared, contains('من العبدة الأخيار!'));
      expect(shared, isNot(contains('<')));
      expect(shared, isNot(contains('>')));
    });
  });
}
