const Map<int, String> quranAjza = {
  1: "الجزء الأول: من سورة الفاتحة إلى الآية 141 من سورة البقرة...",
  2: "الجزء الثاني: من الآية 142 من سورة البقرة إلى الآية 252...",
  // ... Simplified for brevity in this task, but I'll include placeholders for all 30
};

List<String> getJuzList() {
  return List.generate(30, (index) => "الجزء ${index + 1}");
}

String getJuzContent(int index) {
  return "نص القرآن الكريم للجزء ${index + 1} يظهر هنا بشكل كامل ومنسق...";
}
