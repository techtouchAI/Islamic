with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

list_search = """                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "الحدث القادم",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];"""

list_replace = """                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        _selectedDay != null ? "أحداث هذا اليوم" : "الحدث القادم",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _selectedDay != null ? _selectedDayEvents.length : _events.length,
                    itemBuilder: (context, index) {
                      final event = _selectedDay != null ? _selectedDayEvents[index] : _events[index];"""

content = content.replace(list_search, list_replace)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
