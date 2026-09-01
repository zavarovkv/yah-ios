# AGENTS.md

This file defines the working conventions for coding agents in this repository. Apply these rules to the entire project unless a more specific `AGENTS.md` exists in a subdirectory.

## Project overview

Yet Another Habit is a native iOS 18+ habit tracker built with SwiftUI and SwiftData. It supports progress history, habit streaks, iCloud synchronization, Face ID protection, themes, and Russian/English localization. There are no third-party dependencies.

## Source layout

- `YetAnotherHabit/App`: application entry point and root tab navigation.
- `YetAnotherHabit/Features`: feature-owned screens and views.
- `YetAnotherHabit/Models`: SwiftData models and relationships.
- `YetAnotherHabit/Shared/Calendar`: date, schedule, streak, and progress calculations.
- `YetAnotherHabit/Shared/Persistence`: container setup, migration, maintenance, and persistence stores.
- `YetAnotherHabit/Shared/Security`: application locking and LocalAuthentication integration.
- `YetAnotherHabit/Shared/UI`: reusable UI and app preferences.
- `YetAnotherHabitTests`: unit and in-memory persistence tests.
- `.github/workflows`: continuous integration configuration.

## Architecture contract

Treat the following as architectural invariants. Extend these paths instead of
introducing parallel sources of truth or duplicating business rules.

### Composition and data flow

- `YetAnotherHabitApp` is the composition root. It owns the persistence,
  optimistic app state, lock state, locale, and theme, then injects them through
  the SwiftUI environment.
- `ContentView` owns the root SwiftData queries and builds one
  `HabitPresentationData` snapshot for feature screens. Keep transient tab state
  below this query boundary so tab selection and tab icon animations do not
  rebuild the completion index for the full history.
- The persisted `@Query` results are authoritative. `AppDataState` may only bridge
  the short delay after a successful save; it must reconcile and discard its
  overrides as soon as the queries contain the saved values.
- Feature views receive presentation snapshots and user actions. They must not
  create a second long-lived cache of habits or completions.

### Persistence and completion writes

- All habit-completion writes go through `HabitCompletionStore`. Completion keys
  are canonical `habit UUID | WeekCalendar.dayKey` identifiers and counts are
  non-negative integers, not independent Boolean state.
- Save SwiftData first and record the corresponding `AppDataState` override only
  after the save succeeds. A failed write must not leave optimistic UI behind.
- `HabitCompletionIndex` is the boundary that converts persisted completion
  models into read-optimized count and completed-identifier snapshots. Reuse one
  snapshot within a render/update pass rather than repeatedly scanning model
  arrays in rows.
- `DataMaintenance` repairs legacy and duplicate data. Repairs must be idempotent,
  versioned when they need to run once, and must preserve the largest meaningful
  counter value.
- The active model is `AppSchemaV6` with `AppMigrationPlan`. Never edit an old
  versioned schema in place. Add a new version and migration stage while keeping
  existing stores readable.
- Production persistence is currently configured with `cloudKitDatabase: .none`.
  Do not enable CloudKit or alter entitlements until the real App ID and CloudKit
  container identifier are supplied and migration/sync behavior is tested.

### Domain calculations

- `WeekCalendar` owns normalized days, stable day keys, Monday-based weeks, and
  navigation boundaries. `HabitCompletionPeriod` owns daily, weekly, biweekly,
  monthly, and legacy yearly counter buckets. New habits may choose the first
  four intervals; keep yearly readable for existing data, but do not offer it in
  the editor unless the product decision changes deliberately.
- `HabitDayPolicy` decides whether a habit is visible/actionable for a day.
  `HabitDaySorter` owns section membership and ordering.
- `HabitProgressCalculator`, `HabitStreakCalculator`, and
  `HabitAnalyticsCalculator` own progress, streak, and analytics semantics.
  Views may format their results but must not reproduce those algorithms.
- Counter values are preserved as counts. A target counter becomes complete only
  when its target is reached; a counter without a target is not silently treated
  as a Boolean habit or included in measurable progress.
- A pending regular habit may display its already-earned streak, but the selected
  pending day must never be counted. Use `HabitStreakCalculator.streakBefore`
  instead of changing the persisted or analytics definition of current streak.
- Pass an explicit `Calendar` through calculations and initializers. A view must
  not initialize calendar state with a different calendar than the environment
  used to update it.

### UI, security, and performance boundaries

- `AppTabView` is the only owner of app-wide tab-bar behavior. On iOS 26 it uses
  the native `tabBarMinimizeBehavior(.onScrollDown)`. Feature scroll views must
  not move, resize, or change the minimization policy themselves.
  Keep the iOS 26 tab item structure stable during scrolling and render both the
  expanded count and compact dot into one fixed-size habit icon; do not mutate a
  native `.badge` mid-transition. Derive compactness from the presentation-layer
  visibility of the native tab-item titles; do not infer badge presentation from
  animation delays. Scroll direction may wake this visual observer and an upward
  gesture may temporarily force expansion from any list position, but it must
  not directly choose between count and dot. Release the temporary expansion
  policy while the bar enters its visually expanded range and when the scroll
  interaction ends, so `.onScrollDown` is active before the next gesture. Detect
  direction from small cumulative travel rather than isolated frame deltas.
  Switch the fixed icon artwork with hysteresis during the real native morph,
  without an intermediate hidden indicator. Do not add a bottom accessory solely
  to observe placement.
  Keep the habits root navigation stack unbound: iOS 26 does not reliably expand
  the native tab bar when its scrolling content is inside `NavigationStack(path:)`.
- Keep accordion, drag, pull, and completion-transition state local to the owning
  feature. Gesture code may decide intent; it must delegate mutations and domain
  decisions to the stores/calculators above.
- Preserve the current pull behavior contract: a downward pull may return
  navigation to today, but must not introduce a second hidden/revealed screen
  state unless that interaction is deliberately redesigned and tested.
- Views kept alive only for transitions must skip expensive work while hidden.
  In particular, do not calculate streaks or scan completion history for
  zero-opacity/collapsed rows.
- Respect Reduce Motion for decorative movement while preserving immediate state
  feedback and native navigation behavior.
- `HabitReminderScheduler` is the only owner of local habit-notification
  identifiers and scheduling. Store only the optional hour/minute on `Habit`;
  derive repeating weekday requests from the habit schedule. Ask for permission
  only after the user explicitly enables a reminder. Coordinate scheduling with
  persistence so a failed save restores/removes requests, and remove requests
  after deletion.
- Habit card backgrounds communicate status through `HabitCardVisualState`:
  neutral for pending habits, orange for counters in progress, and green for
  completed goals. A habit's user-selected color belongs only to its icon and
  compact icon background; do not use it to tint the full card.
- `AppLockController` is the single owner of authentication state. Keep
  `LocalAuthentication` behind `AppAuthenticationContext` so behavior stays
  deterministic in tests. When locked, render `AppLockView` instead of placing it
  over live sensitive content.
- Avoid unbounded repeated work in `body`: build indexes once at an owning
  boundary, pass value snapshots downward, use stable identities, and do not add
  per-row SwiftData fetches. If completion history outgrows an in-memory snapshot,
  evolve it with scoped fetches or persisted aggregates plus migrations rather
  than adding another full-history cache.

### Architecture change checklist

Before changing these boundaries, document why the existing owner cannot support
the requirement, update this section, and add tests at the affected boundary.
At minimum verify strict concurrency, calendar/time-zone determinism, optimistic
state reconciliation, migration safety, locked-content privacy, and that tab or
row animations do not trigger history-wide recomputation.

## Development principles

- Prefer native Apple frameworks and controls. Do not add a dependency when the platform API is sufficient.
- Keep views declarative. Put calendar calculations, persistence mutations, and business rules outside view bodies.
- Keep feature-specific code inside its feature directory; move code to `Shared` only when multiple features use it.
- Use `@MainActor` for UI-observed state and SwiftData operations that use the main context.
- Treat `@Query` as the persisted source of truth. Use `AppDataState` only as a short-lived bridge until query results reflect a successful save.
- Route completion mutations through `HabitCompletionStore` so writes stay idempotent and duplicate records are repaired.
- Use `HabitProgressCalculator`, `HabitStreakCalculator`, and `WeekCalendar` instead of reimplementing their rules in views.
- Preserve existing user data. Any SwiftData model change must update the versioned schema and include an appropriate migration plan.
- Keep CloudKit compatibility in mind: avoid unsupported uniqueness constraints and required relationships without defaults.
- Never force-unwrap production values or use `try!`. Surface recoverable failures through localized UI.

## Swift and SwiftUI style

- Follow the existing Swift formatting and naming conventions.
- Prefer small focused types and computed properties over long view bodies.
- Use `private` by default for implementation details.
- Use value types unless identity, observation, or framework requirements call for a reference type.
- Use stable identifiers for `ForEach`; do not use array offsets for mutable model collections.
- Use semantic system colors, Dynamic Type-compatible fonts, and SF Symbols.
- Preserve native navigation, sheets, alerts, swipe actions, accessibility labels, and disabled states.
- Do not encode layout around one simulator model. Respect safe areas and test with different text sizes and appearances.

## Dates and habit rules

- Normalize persisted daily activity to `Calendar.startOfDay(for:)`.
- Generate completion identifiers through `HabitCompletion.identifier(habitID:dayKey:)`.
- Use `WeekCalendar.dayKey` for date keys; do not introduce ad hoc date formatters.
- A habit must not appear before its creation date.
- A habit is actionable only on its scheduled weekdays and never on a future date.
- Streaks advance across scheduled occurrences, not merely consecutive calendar dates.
- Progress denominators include only habits scheduled for the relevant dates.
- Make the calendar explicit in logic and tests to avoid locale and time-zone-dependent behavior.

## Persistence and app state

- Save the `ModelContext` before recording optimistic UI state.
- On a failed save, roll back or leave the persisted state unchanged and show a localized error.
- Capture model identifiers before deleting a SwiftData object; do not access a deleted model afterward.
- Reconcile optimistic additions, deletions, and completion overrides when `@Query` updates.
- Keep preview and test stores in memory and disable CloudKit for them.
- Do not erase, reset, or replace a user's store to resolve a migration problem.

## Localization

- Put every user-visible string in `YetAnotherHabit/Localizable.xcstrings`.
- Put permission usage descriptions in `YetAnotherHabit/InfoPlist.xcstrings`.
- Add both Russian and English translations in the same change.
- Use the active SwiftUI locale for weekday and date formatting; do not hardcode `ru_RU` or `en_US` in UI code.
- Keep SF Symbol names, persistence keys, identifiers, and debug output unlocalized.

## Security and privacy

- Use `LocalAuthentication`; never implement or store biometric credentials.
- Do not render sensitive application content underneath the locked state.
- Avoid logging names, avatar data, habit contents, or CloudKit identifiers.
- Request photo-library and camera access only in direct response to a user action.
- Do not weaken entitlements, signing, privacy descriptions, or data protection to make a local build pass.

## Testing requirements

Add or update tests when changing:

- scheduling, week navigation, date titles, streaks, or progress;
- habit creation, completion, editing, or deletion;
- SwiftData models, relationships, migrations, or maintenance;
- optimistic state reconciliation;
- localization-sensitive date behavior.

Use an in-memory `ModelContainer` for persistence tests. Use a fixed Gregorian calendar and time zone for deterministic date tests.

Before handing off a code change, run:

```bash
git diff --check
xcodebuild build-for-testing \
  -project YetAnotherHabit.xcodeproj \
  -scheme YetAnotherHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
xcodebuild test-without-building \
  -project YetAnotherHabit.xcodeproj \
  -scheme YetAnotherHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

If that simulator is unavailable, inspect `xcodebuild -showdestinations` and use an installed iOS simulator. Report commands that could not run and why.

## Change discipline

- Inspect the working tree before editing and preserve unrelated user changes.
- Keep changes scoped to the request; avoid opportunistic rewrites.
- Do not modify generated Xcode user data or commit DerivedData.
- Validate string catalogs as JSON after editing them.
- Do not commit, push, alter signing, or change CloudKit containers unless the user explicitly requests it.
- In the final handoff, summarize behavior changes and list the checks actually run.
