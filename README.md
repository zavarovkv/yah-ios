# Yet Another Habit

A native, local-first habit tracker for iOS 18+, built entirely with Apple frameworks.

## What it does

- Tracks regular habits and numeric counters with optional daily goals.
- Supports custom schedules, colors, and SF Symbols.
- Keeps incomplete habits visible first and organizes counters and completed items.
- Provides daily and monthly progress, streaks, and per-habit analytics.
- Makes past days easy to review while limiting edits to today and yesterday.
- Protects local data with Face ID or the device passcode.
- Includes profile customization, system-aware themes, and Dynamic Type-friendly UI.
- Supports Russian, English, Spanish, French, and Brazilian Portuguese.

## Built with

SwiftUI, SwiftData, Swift Testing, LocalAuthentication, PhotosUI, and Xcode string catalogs. The project has no third-party dependencies and keeps habit and profile data on the device.

## Run locally

1. Open `YetAnotherHabit.xcodeproj` in Xcode 16.4 or later.
2. Select the `YetAnotherHabit` scheme.
3. Choose an iOS 18+ simulator and press `Cmd+R`.

Run tests from Xcode or the command line:

```bash
xcodebuild test \
  -project YetAnotherHabit.xcodeproj \
  -scheme YetAnotherHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

For a physical device, select your own development team and use a unique bundle identifier.

## Privacy

Habit data, settings, and profile photos stay in the local SwiftData store. Authentication is handled by iOS; the app never receives or stores biometric credentials.

## License

Yet Another Habit is available under the [MIT License](LICENSE).
