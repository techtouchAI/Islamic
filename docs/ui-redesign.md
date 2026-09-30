# Home UI redesign

## Scope
- Flutter application UI (not the separate marketing website).
- Forest/ivory theme with gold accents, dark mode, Cairo UI typography.
- Five obligatory prayer cells inside the next-prayer card, RTL chronological
  order, 24-hour civil times, highlight, genuine HH:mm:ss countdown.
- Daily Quran/adhkar/tasbih/qibla shortcuts and a persisted personal daily dhikr
  goal. This goal is independent of tasbih al-Zahra and is not a religious prescription.
- Existing daily duas, inspirations, excerpts, reader routes, settings and content
  remain accessible. Empty excerpts open their category instead of a null reader.

## Boundaries
`HomePrayerController` owns only presentation loading/timers. `PrayerTimesService`
remains the source of location, timezone, calculation and saved manual offsets.
`loadScheduleForDate` reuses that pipeline for tomorrow; no guessed Fajr +24h.
Imsak is still Ramadan-only and is never inserted as a sixth obligatory prayer.
Unavailable times show a dash; failure offers retry; stale days are discarded on
resume. Tickers stop when disposed/backgrounded. Countdown updates only the card.

`AppNavigationController` separates root tabs from detail history. The adhkar tab
opens `adhkar`, not `duas`. Drawer and home shortcuts use the same routing method.
Back from a detail returns to its origin; back from a non-home tab returns home.
The existing Navigator continues to own reader/search routes.

User-selected colours/backgrounds remain; the default legacy background image is
not rendered behind the new dashboard. System font scaling and RTL are respected;
prayer cells wrap at large accessibility sizes, cards have no fixed content height.
No prayer algorithms, alarms, databases, Quran content or OTA rules were replaced.

## Verification
New automated coverage includes real shell navigation, drawer roots, RTL ordering,
320/390/768px layouts in both themes at 1×/2× scale, countdown/date boundaries,
manual offsets for tomorrow, loading/failure/retry/disposal, and dhikr persistence.
`UI verification` runs analyzer, all Flutter tests and a release web build on CI.
Native compass/GPS/permissions/adhan still require an Android/iOS device smoke test.

### Confirmed CI result
On 2026-09-30, [UI verification run 36645750300](https://github.com/techtouchAI/Islamic/actions/runs/36645750300)
passed Flutter analysis, the complete test suite, and the release web build.
The SDK used was Flutter 3.47.5, matching this repository's existing build jobs.
Testing caught and corrected progress-bar accessibility semantics and verified
that the drawer has finished opening before navigation is hit-tested.
No native-device runtime verification was performed in the sandbox.

## Prayer artwork refinement
- Removed the greeting, supporting sentence and sparkle icon. The prayer card
  is now the first element. Inspiration uses `lightbulb_outline`.
- `PrayerScenePainter` reconstructs the reference's paired mosque silhouettes,
  edge rosettes and upper-left sky as vector paths. The day scene has sun/clouds/
  birds; night has a crescent/stars. There are no enlarged icon watermarks.
- Scene selection is independent of dark mode. It uses the selected location's
  sunrise (inclusive) and sunset (exclusive), not Jafari Maghrib. Missing solar
  events use a visual-only 06:00–18:00 fallback; alarm calculations are unchanged.
- The hero has a right-aligned weekday/Hijri date, gold Cairo medium title, and
  curved OmarNaskh Eastern Arabic countdown numerals. Location moves below the
  times to preserve the reference hierarchy. Five obligatory prayers remain.
- The original concept is a generated raster, not an editable design or font
  specification: this is a vector/typographic reconstruction, not a claim of
  pixel-identical source recovery. Both selected fonts are already bundled.
- `CAPTURE_UI=1 flutter test test/ui/prayer_scene_test.dart` exports actual Flutter
  day/night card renders to ignored `build/ui-previews/` for visual review.
  The UI verification artifact includes both lossless PNG captures.
- Refinement tests additionally cover exact sunrise/sunset boundaries, stale or
  absent solar events, the removed greeting, the replacement inspiration icon,
  selected-location clock transitions and real-font day/night capture.
