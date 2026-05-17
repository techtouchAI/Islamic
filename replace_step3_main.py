with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

search_str = """    final hijri = HijriCalendar.now();
    if (widget.hijriAdjustment != 0) {
      hijri.hDay += widget.hijriAdjustment;
      if (hijri.hDay > 30) {
        hijri.hDay -= 30;
        hijri.hMonth += 1;
      }
      if (hijri.hDay < 1) {
        hijri.hDay += 30;
        hijri.hMonth -= 1;
      }
    }"""

replace_str = """    final hijri = HijriCalendar.fromDate(DateTime.now().add(Duration(days: widget.hijriAdjustment)));"""

content = content.replace(search_str, replace_str)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
