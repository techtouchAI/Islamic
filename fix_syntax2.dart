import 'dart:io';

void main() {
  var file = File('lib/ui/calendar/hijri_calendar_screen.dart');
  var lines = file.readAsLinesSync();

  for (int i = 330; i < 360; i++) {
    print('\${i + 1}: \${lines[i]}');
  }
}
