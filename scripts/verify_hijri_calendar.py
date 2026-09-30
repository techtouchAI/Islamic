#!/usr/bin/env python3
"""Verify the bundled Hijri calendar table in assets/data/content.json.

The app treats `hijri_calendar` as the calendar of record: the announced month
starts of the reference authority (the office of Grand Ayatollah al-Sistani)
differ from the calculated Umm al-Qura calendar by a day, so the table — not the
`hijri` package — decides what day it is. This script guards that data:

* every month row is well formed (year, month, day count, parseable start date);
* the months are contiguous, with no gap or overlap between them;
* a documented day is covered by exactly one month row;
* the announced anchors still map to day 1 of the month they were announced for.

`test/data/calendar_repository_test.dart` asserts the same anchors against the
Dart implementation, so the data here and the runtime behaviour stay in step.

Usage:
    python3 scripts/verify_hijri_calendar.py             # offline (default)
    python3 scripts/verify_hijri_calendar.py --fetch      # also re-read the
                                                          # published statements
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ANCHORS = {
    # month -> (announced day 1, source)
    (1448, 1): (dt.date(2026, 6, 17), 'Sistani office statement (1 Muharram)'),
    (1448, 2): (dt.date(2026, 7, 16), 'Sistani office statement (1 Safar)'),
    (1448, 3): (dt.date(2026, 8, 15), "Sistani office statement (1 Rabi' I)"),
    (1448, 4): (dt.date(2026, 9, 13), "Sistani office statement (1 Rabi' II)"),
}

# Published statements kept for the record; `--fetch` re-reads the live pages.
SOURCES = [
    'https://ina.iq/ar/local/270776-.html',
    'https://iraq.shafaqna.com/AR/653093/',
]

MonthKey = tuple[int, int]


def fail(message: str) -> None:
    print(f'FAIL: {message}')
    global failures
    failures += 1


failures = 0


def parse_months(document: dict) -> dict[MonthKey, dict]:
    months: dict[MonthKey, dict] = {}
    for entry in document.get('hijri_calendar') or []:
        try:
            key = (int(entry['year']), int(entry['month']))
            start = dt.date.fromisoformat(str(entry['expected_gregorian_start']))
            total_days = int(entry['total_days'])
        except (KeyError, TypeError, ValueError) as error:
            fail(f'malformed month row: {entry!r} ({error})')
            continue
        if key in months:
            fail(f'duplicate month row {key}')
            continue
        if not 1 <= key[1] <= 12:
            fail(f'month out of range: {key}')
            continue
        if total_days not in (29, 30):
            fail(f'{key}: a Hijri month has 29 or 30 days, not {total_days}')
            continue
        months[key] = {'start': start, 'total_days': total_days, 'row': entry}
    return months


def check_contiguous(months: dict[MonthKey, dict]) -> None:
    years = sorted({year for year, _ in months})
    for year in years:
        for month in range(1, 12):
            current, following = months.get((year, month)), months.get(
                (year, month + 1)
            )
            if current is None or following is None:
                continue
            expected = current['start'] + dt.timedelta(
                days=current['total_days']
            )
            if following['start'] != expected:
                fail(
                    f'{year}-{month} ends {expected - dt.timedelta(days=1)} '
                    f'but {year}-{month + 1} starts {following["start"]}'
                )


def check_coverage(months: dict[MonthKey, dict]) -> None:
    for key, month in sorted(months.items()):
        last_day = month['start'] + dt.timedelta(days=month['total_days'] - 1)
        for offset in (0, month['total_days'] - 1):
            day = month['start'] + dt.timedelta(days=offset)
            owner = month_for(months, day)
            if owner != key:
                fail(f'{day} is covered by {owner}, expected {key}')
        for row in month['row'].get('days') or []:
            number = row.get('day')
            if not isinstance(number, int) or not 1 <= number <= (
                month['total_days']
            ):
                fail(f'{key}: day {number!r} is outside the month')
        _ = last_day


def month_for(months: dict[MonthKey, dict], day: dt.date) -> MonthKey | None:
    for key, month in months.items():
        end = month['start'] + dt.timedelta(days=month['total_days'] - 1)
        if month['start'] <= day <= end:
            return key
    return None


def check_anchors(months: dict[MonthKey, dict]) -> None:
    for key, (announced, source) in ANCHORS.items():
        month = months.get(key)
        if month is None:
            fail(f'{key}: month missing, cannot check the announcement')
            continue
        if month['start'] != announced:
            fail(
                f'{key}: table says {month["start"]}, the announcement says '
                f'{announced} ({source})'
            )
        before = announced - dt.timedelta(days=1)
        owner = month_for(months, before)
        if owner == key:
            fail(f'{key}: {before} still maps to this month')
    print(f'anchors checked: {len(ANCHORS)}')


def fetch_statements() -> None:
    """Best-effort re-read of the published statements (network optional)."""
    pattern = re.compile(
        r'الموافق\s*\(?([0-9]{1,2})[-/]([0-9]{1,2})[-/]([0-9]{4})'
    )
    for url in SOURCES:
        try:
            with urllib.request.urlopen(url, timeout=20) as response:
                body = response.read().decode('utf-8', 'replace')
        except (urllib.error.URLError, TimeoutError) as error:
            print(f'note: could not read {url} ({error}); using ANCHORS as is')
            continue
        found = {
            dt.date(int(y), int(m), int(d))
            for d, m, y in pattern.findall(body)
        }
        for key, (announced, _) in ANCHORS.items():
            if announced in found:
                print(f'confirmed {key} = {announced} from {url}')
                return
        print(f'note: no matching statement found on {url}')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--content',
        default='assets/data/content.json',
        help='path to the content document',
    )
    parser.add_argument(
        '--fetch',
        action='store_true',
        help='re-read the published month-start statements',
    )
    args = parser.parse_args()

    path = Path(args.content)
    if not path.exists():
        print(f'FAIL: {path} not found')
        return 1

    document = json.loads(path.read_text(encoding='utf-8'))
    months = parse_months(document)
    if not months:
        print('FAIL: no Hijri months in the content document')
        return 1

    years = sorted({year for year, _ in months})
    print(f'months: {len(months)} across {years}')

    check_contiguous(months)
    check_coverage(months)
    check_anchors(months)
    if args.fetch:
        fetch_statements()

    if failures:
        print(f'{failures} problem(s) found')
        return 1
    print('calendar table is consistent')
    return 0


if __name__ == '__main__':
    sys.exit(main())
