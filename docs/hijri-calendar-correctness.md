# Hijri calendar correctness (home date, calendar grid, month data)

## Problem

The home card showed the wrong Hijri day (17 instead of 18 on 30 Sep 2026) and a
Hijri month start could be off by one day. Two independent causes:

1. **The data.** `assets/data/content.json → hijri_calendar` started 1448–4
   (`ربيع الآخر`) on 14 Sep 2026 while the office of Grand Ayatollah al-Sistani
   announced 13 Sep 2026 as day 1, and several other months carried a start that
   was a day late relative to that announcement.
2. **The code.** `CalendarRepository.getTodayHijri` asked the `hijri` package
   (Umm al-Qura) which month came first and then measured the day from the table
   row for *that* month. On a boundary where the two calendars disagree, the
   calculated month won and the reported day was wrong by one, and the calendar
   grid moved the month start a day in the opposite direction from the reported
   date.

## Rule now used

The bundled table is the **calendar of record**: the announced month starts come
from the reference authority, not from a calculation.

* `CalendarRepository.monthSummaries()` reads only the header fields of each
  row (`year`, `month`, `total_days`, `expected_gregorian_start`), so locating a
  month stays cheap in a large document.
* `getTodayHijri(date, offset)` shifts the civil date by the user correction and
  asks the table which month contains it; the day is the difference from that
  month's start. Dates outside the table fall back to the `hijri` package as
  before, so navigation outside 1448 still works.
* `adjustedMonthStart(month, offset)` moves the month start by `-offset` on the
  grid, so the highlighted "today" cell and the printed date always describe the
  same Hijri day.
* Day arithmetic uses UTC fields ([`civilDate`]) so a daylight-saving change on
  the device can never truncate a difference by a day.

## Data

`scripts/verify_hijri_calendar.py` guards the document offline:

```
python3 scripts/verify_hijri_calendar.py          # data + anchors
python3 scripts/verify_hijri_calendar.py --fetch  # also re-read statements
```

It checks that every month row is well formed, 29 or 30 days long, contiguous
with its neighbours, that no event sits outside its month (this caught a day-30
event inside a 29-day `ذو القعدة`, which made that month 30 days and moved
`ذو الحجة` one day later), and that the announced anchors still map to day 1:

| Month (1448) | Day 1 | Source |
| --- | --- | --- |
| 1 محرم | 2026-06-17 | Sistani office statement |
| 2 صفر | 2026-07-16 | Sistani office statement |
| 3 ربيع الأول | 2026-08-15 | Sistani office statement |
| 4 ربيع الآخر | 2026-09-13 | Sistani office statement |

Months 5–12 keep the same one-day difference from Umm al-Qura until the office
publishes them; replacing a row with the published values needs no code change.

`test/data/calendar_repository_test.dart` asserts the same anchors, the same
month lengths, full coverage of every day of 1448, and the corrected 18
`ربيع الآخر` for 30 Sep 2026 against the Dart implementation, so the data and the
runtime rule cannot drift apart silently.

## Related code paths

* `lib/ui/home/widgets/home_prayer_card.dart` — the date line renders the
  corrected date and owns a `فتح التقويم الهجري` tap target.
* `lib/ui/calendar/hijri_calendar_screen.dart` — the grid reads the same table
  synchronously (no spinner per swipe, no second day-calculation rule) and
  `_goToToday` uses the date the repository already resolved.
* `lib/ui/home/widgets/home_prayer_controller.dart` — the Ramadan test that
  gates ئimsak uses the same corrected date.
