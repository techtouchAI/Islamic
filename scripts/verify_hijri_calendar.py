#!/usr/bin/env python3
"""Verify the bundled Hijri calendar table against the office of al-Sistani.

The app treats `hijri_calendar` in assets/data/content.json as its calendar of
record. The authority is the office of Grand Ayatollah al-Sistani in Najaf:

* months that were announced after the sighting of the crescent carry
  ``source: sistani_office_announcement`` — e.g. the statement that Sunday
  13 September 2026 is the first of Rabi' al-thani 1448;
* the remaining months carry ``source: sistani_office_booklet`` and are
  transcribed from the office's crescent booklet for 1448,
  https://www.sistani.org/downloads/ahelleh1448hj.pdf . Every one of them is
  the page line that states the evening the crescent is sought on, which is the
  last possible night of the running month:

      "يتوقع أن يكون هلال شهر جمادى الأولى مساء يوم الإثنين
       (30/ربيع الآخر/1448هـ) الموافق (12/تشرين الأول/2026م)"

  i.e. day 1 of Jumada al-ula 1448 = 13 October 2026.

The same expectations are asserted against the Dart implementation in
test/data/calendar_repository_test.dart, and scripts/verify_apk_calendar.py
checks the copy that actually ships inside a built APK.

Usage:
    python3 scripts/verify_hijri_calendar.py
    python3 scripts/verify_hijri_calendar.py --check-day 2026-09-30
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

# month -> (day 1, number of days, basis). The days of months 1-11 follow from
# the next start in this table; month 12 ends with the Hijri year.
OFFICE_1448: dict[int, tuple[str, int, str]] = {
    1: ("2026-06-17", 29, "announced: crescent 30/ذي الحجة/1447 = 16 Jun 2026"),
    2: ("2026-07-16", 30, "announced: crescent 29/محرم = 15 Jul 2026"),
    3: ("2026-08-15", 29, "announced: crescent 30/صفر = 14 Aug 2026"),
    4: ("2026-09-13", 30, "announced: crescent 29/ربيع الأول = 12 Sep 2026"),
    5: ("2026-10-13", 30, "booklet: crescent 30/ربيع الآخر = 12 Oct 2026"),
    6: ("2026-11-12", 29, "booklet: crescent 30/جمادى الأولى = 11 Nov 2026"),
    7: ("2026-12-11", 30, "booklet: crescent 29/جمادى الآخرة = 10 Dec 2026"),
    8: ("2027-01-10", 30, "booklet: crescent 30/رجب = 9 Jan 2027"),
    9: ("2027-02-09", 29, "booklet: crescent 30/شعبان = 8 Feb 2027"),
    10: ("2027-03-10", 30, "booklet: crescent 29/رمضان = 9 Mar 2027"),
    11: ("2027-04-09", 29, "booklet: crescent 30/شوال = 8 Apr 2027"),
    12: ("2027-05-08", 29, "booklet: crescent 29/ذي القعدة = 7 May 2027"),
}

ANNOUNCED_MONTHS = {1, 2, 3, 4}

# Days that were reported wrong in the app, as the office fixes them.
REGRESSION_DAYS = {
    "2026-09-28": (4, 16),
    "2026-09-29": (4, 17),
    "2026-09-30": (4, 18),
    "2026-10-01": (4, 19),
}

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)
    print(f"FAIL: {message}")


def load_months(path: Path) -> dict[int, dict]:
    document = json.loads(path.read_text(encoding="utf-8"))
    months: dict[int, dict] = {}
    for entry in document.get("hijri_calendar") or []:
        try:
            month = int(entry["month"])
            start = dt.date.fromisoformat(str(entry["expected_gregorian_start"]))
            total_days = int(entry["total_days"])
        except (KeyError, TypeError, ValueError) as error:
            fail(f"malformed month row: {entry!r} ({error})")
            continue
        if entry.get("source") not in (
            "sistani_office_announcement",
            "sistani_office_booklet",
        ):
            fail(f"month {month}: missing or unknown source {entry.get('source')!r}")
        if month in months:
            fail(f"duplicate month row {month}")
            continue
        months[month] = {"start": start, "total_days": total_days, "row": entry}
    months["_document"] = document  # type: ignore[assignment]
    return months


def check_document(months: dict[int, dict]) -> None:
    document = months.pop("_document")
    version = document.get("calendar_version")
    if not isinstance(version, int) or version <= 0:
        fail("the document must carry a positive calendar_version")
    if "السيستاني" not in str(document.get("calendar_source", "")):
        fail("calendar_source must name the office the table follows")


def check_office_table(months: dict[int, dict]) -> None:
    if sorted(months) != list(range(1, 13)):
        fail(f"expected months 1-12, found {sorted(months)}")
        return
    for month, (iso, days, _) in OFFICE_1448.items():
        entry = months[month]
        start = dt.date.fromisoformat(iso)
        if entry["start"] != start:
            fail(f"month {month}: starts {entry['start']}, the office says {start}")
        if entry["total_days"] != days:
            fail(
                f"month {month}: {entry['total_days']} days, "
                f"the office table gives {days}"
            )
        expected = (
            "sistani_office_announcement"
            if month in ANNOUNCED_MONTHS
            else "sistani_office_booklet"
        )
        if entry["row"].get("source") != expected:
            fail(f"month {month}: source must be {expected}")
        for row in entry["row"].get("days") or []:
            number = row.get("day")
            if not isinstance(number, int) or not 1 <= number <= days:
                fail(f"month {month}: day {number!r} is outside the month")


def hijri_of(civil: dt.date, months: dict[int, dict]) -> tuple[int, int] | None:
    for month in range(1, 13):
        entry = months[month]
        end = entry["start"] + dt.timedelta(days=entry["total_days"] - 1)
        if entry["start"] <= civil <= end:
            return (month, (civil - entry["start"]).days + 1)
    return None


def check_regression_days(months: dict[int, dict], extra_days: list[str]) -> None:
    days = dict(REGRESSION_DAYS)
    for iso in extra_days:
        parsed = dt.date.fromisoformat(iso)
        for month, (start_iso, _, _) in OFFICE_1448.items():
            start = dt.date.fromisoformat(start_iso)
            if start <= parsed and (parsed - start).days < OFFICE_1448[month][1]:
                days[iso] = (month, (parsed - start).days + 1)
    for iso, expected in days.items():
        found = hijri_of(dt.date.fromisoformat(iso), months)
        if found != expected:
            fail(f"{iso}: table answers {found}, the office gives {expected}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--content", default="assets/data/content.json")
    parser.add_argument(
        "--check-day",
        action="append",
        default=[],
        help="civil date (YYYY-MM-DD) to map with the office table",
    )
    args = parser.parse_args()

    path = Path(args.content)
    if not path.exists():
        print(f"FAIL: {path} not found")
        return 1

    months = load_months(path)
    check_document(months)
    check_office_table(months)
    check_regression_days(months, args.check_day)

    if failures:
        print(f"{len(failures)} problem(s) found")
        return 1
    print(f"calendar matches the office table for all {len(OFFICE_1448)} months")
    for iso in ("2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01"):
        month, day = REGRESSION_DAYS[iso]
        print(f"  {iso} -> {day} of month {month}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
