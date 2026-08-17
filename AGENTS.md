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
