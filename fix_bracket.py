with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# The grid element needs to be closed properly since we wrapped it in InkWell.
# Before it was returning a Container, now it returns an InkWell which contains the Container.
# Let's check where the InkWell is closed.

search_str = """              Text(
                '${gDate.day}',
                style: TextStyle(
                  color: isToday ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }"""

replace_str = """              Text(
                '${gDate.day}',
                style: TextStyle(
                  color: isToday ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }"""

content = content.replace(search_str, replace_str)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
