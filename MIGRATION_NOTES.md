# Migration Notes

## Deduplication & Unification

`PrayerTimesService` is the single Flutter source of truth for location resolution, prayer calculation, final adjusted times, and alarm scheduling. `PrayerAlarmService` is a thin MethodChannel bridge, while Android `AdhanNativeManager` owns deterministic alarm creation, cancellation, persistence, and restoration. The previous competing notification-service path remains removed.

## Background Scheduling

The app schedules a rolling seven-day set of deterministic native alarms. Android `AdhanReceiver` rebuilds those records after boot, package replacement, date changes, and timezone changes, so a separate WorkManager task is not required for alarm reliability. The unused WorkManager dependency and stale background-registration documentation were removed.

## Dynamic Location & Timezone

A canonical `PrayerLocation` record identifies whether coordinates came from live GPS, the selected Iraqi city, a cached GPS fix, or the explicit default city. A GPS failure is never mislabeled as live GPS. Selected Iraqi cities use the fixed Iraq civil offset of UTC+3, while GPS follows the device timezone policy; the same policy feeds calculation, display, manual adjustments, and native alarm timestamps.

## Battery Optimization & Resilience

The app retains the existing user-facing battery-optimization setting and declares the Android permission needed by that flow. The unused `disable_battery_optimization` helper and dependency were removed rather than leaving an import to a missing package. Exact alarms and full-screen intent are checked explicitly, with documented system fallbacks.

## Audio Assets

Native foreground playback uses the single canonical `android/app/src/main/res/raw/adhan.mp3` asset. The duplicate `azan5.mp3` files were removed because they were byte-identical and were not referenced by the content or update scripts.
