const Map<int, String> quranAjza = {
  1: "الجزء الأول: بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ...",
  2: "الجزء الثاني: سَيَقُولُ السُّفَهَاءُ مِنَ النَّاسِ مَا وَلَّاهُمْ عَنْ قِبْلَتِهِمُ...",
  // ... Simplified
};

List<String> getJuzList() {
  return List.generate(30, (index) => "الجزء ${index + 1}");
}

String getJuzContent(int index) {
  return "نص القرآن الكريم للجزء ${index + 1} يظهر هنا بشكل كامل ومنسق ومريح للعين...";
}
