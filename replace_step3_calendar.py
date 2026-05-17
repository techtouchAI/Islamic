with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

search_str1 = """    } on PlatformException catch (e) {
      debugPrint("Failed to get Hijri Date: '${e.message}'.");
      setState(() {
        _todayHijri = HijriCalendar.now();
      });
    } catch (e) {
      // التقاط أي استثناءات أخرى (مثل أخطاء التحويل) لضمان عدم ظهور الشاشة الرمادية
      debugPrint("Unknown error fetching Hijri Date: $e");
      setState(() {
        _todayHijri = HijriCalendar.now();
      });
    }"""

replace_str1 = """    } on PlatformException catch (e) {
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
    }"""

content = content.replace(search_str1, replace_str1)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
