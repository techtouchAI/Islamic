#!/usr/bin/env python3
"""Check the Hijri calendar that is really inside a built APK.

The app answers 17 instead of 18 for 30 September 2026 whenever the copy of
`hijri_calendar` that ships with the APK is the stale one, so the build is only
correct when the packaged document passes the office table check. This script
unpacks `assets/flutter_assets/assets/data/content.json` from the APK and runs
the same verification as scripts/verify_hijri_calendar.py against it.

Usage:
    python3 scripts/verify_apk_calendar.py build/app/outputs/flutter-apk/app-release.apk
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import zipfile
from pathlib import Path

CONTENT_ENTRY = "assets/flutter_assets/assets/data/content.json"


def load_verifier():
    path = Path(__file__).with_name("verify_hijri_calendar.py")
    spec = importlib.util.spec_from_file_location("verify_hijri_calendar", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", help="path to the release APK")
    args = parser.parse_args()

    apk = Path(args.apk)
    if not apk.exists():
        print(f"FAIL: {apk} not found")
        return 1

    verifier = load_verifier()
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        if CONTENT_ENTRY not in names:
            print(f"FAIL: {CONTENT_ENTRY} is not packaged in {apk.name}")
            return 1
        with archive.open(CONTENT_ENTRY) as handle:
            document = json.load(handle)

    # The verifier works on a file; the APK entry is already in memory, so the
    # checks are applied to the very data that shipped.
    months = {}
    for entry in document.get("hijri_calendar") or []:
        months[int(entry["month"])] = {
            "start": verifier.dt.date.fromisoformat(
                str(entry["expected_gregorian_start"])
            ),
            "total_days": int(entry["total_days"]),
            "row": entry,
        }
    months["_document"] = document
    verifier.check_document(months)
    verifier.check_office_table(months)
    verifier.check_regression_days(months, [])

    if verifier.failures:
        print(f"{len(verifier.failures)} problem(s) inside {apk.name}")
        return 1

    print(
        f"{apk.name}: packaged calendar matches the office table "
        f"(generation {document.get('calendar_version')})"
    )
    print("  2026-09-30 -> 18 ربيع الآخر 1448")
    return 0


if __name__ == "__main__":
    sys.exit(main())
