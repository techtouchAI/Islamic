1. Edit `android/app/src/main/kotlin/com/islamic/aldhakereen/adhan/AdhanForegroundService.kt` to change the small icon to `R.mipmap.ic_launcher` and wrap the `startForeground` call in a try-catch block.
2. Edit `lib/ui/calendar/hijri_calendar_screen.dart` to change `Colors.grey.withValues(alpha: 0.2)` to `Colors.grey.withOpacity(0.2)` which is the likely cause of the white screen (rendering failure), and ensure safe initialization of `_todayHijri`. Also, verify the `GridView` index logic.
3. Edit `lib/ui/qibla/qibla_screen.dart` to make the degree text dynamically display the sensor data `_currentHeading.toStringAsFixed(1)`, replace the `Icon(Icons.mosque)` with `Image.asset('assets/images/kaaba.png', width: 40)`, and adjust the background colors to match exactly `Color(0xFF177AFB)` and `Color(0xFF4DE1FF)`.
4. Read the modified files (`AdhanForegroundService.kt`, `hijri_calendar_screen.dart`, `qibla_screen.dart`) to confirm the edits were applied correctly.
5. Run all relevant tests (e.g., `flutter test` and native Android tests) to ensure the changes are correct and introduce no regressions.
6. Complete pre commit steps to ensure proper testing, verification, review, and reflection are done.
7. Submit the changes.
