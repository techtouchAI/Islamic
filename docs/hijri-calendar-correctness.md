# Hijri calendar: source of record, delivery to devices, and verification

The home card and the calendar screen answer the Hijri date for a civil date.
Both read the same table through `CalendarRepository`, and that table is the
calendar of the office of Grand Ayatollah al-Sistani in Najaf — not Umm al-Qura,
not a general arithmetic calendar.

## Why the app showed 17 instead of 18 for 30 September 2026

Three separate faults, all of them data delivery rather than arithmetic:

1. **The table on `main` was a day late.** The released document started
   Rabi' al-thani 1448 on 14 September 2026. The office announced Sunday
   13 September 2026 as day 1, so 30 September is 18, not 17. The APK released
   as `v1.0.55+805` packages that stale table (`git show
   v1.0.55-805:assets/data/content.json`), which is exactly what the installed
   app displayed.
2. **The device copy outranks the bundle.** `DataManager.loadContent()` reads
   `${documents}/content.json` first and only falls back to the bundled asset
   when that file is missing or corrupt. The file survives app updates, so a
   corrected table inside a *newly installed* APK was never read: the app kept
   answering from the cached document. That is why installing another build did
   not change the date.
3. **Nothing ever superseded it.** `syncCloudData()` only adopts a cloud
   document whose bytes differ from the cached one, and the cloud copy on
   `main` carried the same stale table, so the two agreed and the date stayed
   wrong. A fix that is only merged locally cannot travel either: the cloud
   document *is* the OTA source.

Time zone, the `hijri` package and a second date source were ruled out: the
date is computed from local civil fields (never UTC-truncated), the package is
only a fallback outside the table, and every Hijri display in the Dart code
goes through `CalendarRepository`.

## The table of record

`assets/data/content.json → hijri_calendar` holds year 1448 with a
`calendar_version`, a `calendar_source`, and a `source` on every month row:

* `sistani_office_announcement` — months 1-4, announced after the sighting of
  the crescent (e.g. "يوم غدٍ الأحد الموافق (9/13/2026م) هو الأول من شهر ربيع
  الآخر لعام 1448هـ").
* `sistani_office_booklet` — months 5-12, transcribed from the office's
  crescent booklet for 1448, `https://www.sistani.org/downloads/ahelleh1448hj.pdf`.
  Every start is the line that states the evening the crescent is sought on,
  which is the last possible night of the running month.

| Month (1448) | Day 1 | Days | Basis |
| --- | --- | --- | --- |
| 1 محرم | 2026-06-17 | 29 | announced (crescent 16 Jun) |
| 2 صفر | 2026-07-16 | 30 | announced (crescent 15 Jul) |
| 3 ربيع الأول | 2026-08-15 | 29 | announced (crescent 14 Aug) |
| 4 ربيع الآخر | 2026-09-13 | 30 | announced (crescent 12 Sep) |
| 5 جمادى الأولى | 2026-10-13 | 30 | booklet (crescent 12 Oct) |
| 6 جمادى الآخرة | 2026-11-12 | 29 | booklet (crescent 11 Nov) |
| 7 رجب | 2026-12-11 | 30 | booklet (crescent 10 Dec) |
| 8 شعبان | 2027-01-10 | 30 | booklet (crescent 9 Jan) |
| 9 رمضان | 2027-02-09 | 29 | booklet (crescent 8 Feb) |
| 10 شوال | 2027-03-10 | 30 | booklet (crescent 9 Mar) |
| 11 ذو القعدة | 2027-04-09 | 29 | booklet (crescent 8 Apr) |
| 12 ذو الحجة | 2027-05-08 | 29 | booklet (crescent 7 May) |

Months 1-11 are contiguous by construction; month 12 ends with the Hijri year
and its length is the length the source data carried (the office publishes the
Muharram 1449 crescent in the next booklet). Days of the month that carry
events are re-checked against these lengths, which is how the martyrdom of Imam
Muhammad al-Jawad — the office lists it as the *last day* of ذو القعدة — moved
to day 29 of a 29-day month.

### Updating a month

1. Take the start from the office (announcement, or the booklet line).
2. Edit the row in `assets/data/content.json`, set `"source"`, and increment
   `calendar_version`. A device only accepts a table with a **higher**
   generation, so this number is what lets a correction reach phones.
3. `python3 scripts/verify_hijri_calendar.py` and `flutter test` must pass.
4. Merge to `main`: the document is the OTA payload, so merging is what heals
   installed apps (`syncCloudData` runs on every launch). The next APK build
   packages the same table for offline installs.

## Delivery guarantees

* **Installed build (bundle).** On the first launch after an app update,
  `DataManager` compares the bundled table with the device copy and adopts the
  bundle when its generation is higher, then persists the merged document.
  Without this step a corrected APK could never take effect (fault 2).
* **Cloud (OTA).** `syncCloudData()` adopts the cloud document and keeps the
  newer of the two tables: an older document can no longer roll a corrected
  table back, and a document without a table leaves the device table alone.
  The request timeout is sized for the ~25 MB CMS document (`cloudTimeout`),
  because a sync that times out leaves a device on stale data.
* **Web.** The browser loads the bundled document on every start, so it always
  carries the table of the deployed build.
* **Single source.** Home card, calendar screen and the Ramadan imsak check all
  call `CalendarRepository.getTodayHijri` / `getMonthData`, which read
  `hijri_calendar` from the loaded document.

## Verification

* `scripts/verify_hijri_calendar.py` — asserts the whole 1448 table, the
  provenance fields, the version marker, event days inside their month, and the
  regression days (28-30 Sep and 1 Oct 2026). Runs on every Android build.
* `scripts/verify_apk_calendar.py` — unpacks the built APK and verifies the
  document that actually ships in it; a release cannot be signed while the
  packaged calendar is stale.
* `test/data/calendar_repository_test.dart` — the same expectations against the
  Dart implementation, plus day-by-day coverage of 1448.
* `test/data/calendar_delivery_test.dart` — drives `DataManager.loadContent()`
  and `syncCloudData()` with a cached document holding the stale table and
  requires `getTodayHijri(2026-09-30).day == 18` afterwards, in both the
  app-update and the OTA direction.
* `test/ui/home_prayer_card_layout_test.dart` — the card prints the date the
  repository reports instead of computing its own.

## Related code paths

* `lib/ui/home/widgets/home_prayer_card.dart` — the date line, its calendar tap
  target and the `prayer-date` key.
* `lib/ui/calendar/hijri_calendar_screen.dart` — grid and day sheet, built from
  the same synchronous table (`adjustedMonthStart`).
* `lib/ui/home/home_prayer_controller.dart` — uses the repository date for the
  Ramadan imsak decision.
* `android/.../hijri/HijriNativeManager.kt` — an arithmetic converter kept for
  the platform channel; no Dart code calls it, so it is not a date source of
  the app.
