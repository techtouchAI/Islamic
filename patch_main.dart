import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  // Replace the duplicated code with just the optimized one
  content = content.replaceFirst('''                                  contentStr = ayahs.map((a) {
                                    final text = a['ar_text'].toString().trim();
                                    final index = a['anum']?.toString() ??
                                        a['ayah_surah_index'].toString();
                                    return index.isEmpty
                                        ? text
                                        : "\$text \\uFD3F\$index\\uFD3E";
                                  }).join(" ");
                                  contentStr = QuranService.getFormattedContent(
                                      surahId, ayahs);''', '''                                  contentStr = QuranService.getFormattedContent(surahId, ayahs);''');

  content = content.replaceFirst('''                    final content = ayahs.map((a) {
                      final text = a['ar_text'].toString().trim();
                      final index = a['anum']?.toString() ??
                          a['ayah_surah_index'].toString();
                      return index.isEmpty ? text : "\$text \\uFD3F\$index\\uFD3E";
                    }).join(" ");
                    final content =
                        QuranService.getFormattedContent(surah['id'], ayahs);''', '''                    final content = QuranService.getFormattedContent(surah['id'], ayahs);''');

  file.writeAsStringSync(content);
}
