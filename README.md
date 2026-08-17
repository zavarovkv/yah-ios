# Yet Another Habit

Yet Another Habit is a native iOS app for building habits, maintaining streaks, and tracking progress over time.

## Features

- Create and customize habits with schedules, colors, and SF Symbols.
- Mark habits complete with swipe gestures.
- Browse past and upcoming weeks.
- Track daily and monthly completion progress.
- Review streaks and read-only history for previous days.
- Store habits and profile data locally on the device.
- Protect the app with Face ID or the device passcode.
- Choose a light, dark, or system appearance.
- Use the app in Russian or English.

## Tech stack

- SwiftUI
- SwiftData
- LocalAuthentication
- Swift Testing
- Xcode string catalogs

The app targets iOS 18 and has no third-party dependencies.

## Project structure

```text
YetAnotherHabit/
├── App/                 App entry point and root navigation
├── Features/            Screens grouped by product feature
│   ├── Habits/
│   ├── Progress/
│   ├── Friends/
│   └── Settings/
├── Models/              SwiftData models
├── Shared/              Reusable calendar, persistence, security, and UI code
├── Assets.xcassets/
├── Localizable.xcstrings
└── InfoPlist.xcstrings

YetAnotherHabitTests/      Unit and persistence tests
```

## Requirements

- macOS with Xcode 16.4 or later
- iOS 18 or later
- An Apple Developer account for installation on a physical device
- A development team selected in Xcode for installation on a physical device

## Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/zavarovkv/yah-ios.git
   cd yah-ios
   ```

2. Open `YetAnotherHabit.xcodeproj` in Xcode.
3. Select the `YetAnotherHabit` scheme.
4. Choose an iOS Simulator and run the app with `Cmd+R`.

To run on a physical iPhone, select your development team in **Signing & Capabilities**, choose a unique bundle identifier, connect the device, trust the developer certificate if prompted, and choose the iPhone as the run destination.

## Build and test

List available simulator destinations:

```bash
xcodebuild -project YetAnotherHabit.xcodeproj \
  -scheme YetAnotherHabit \
  -showdestinations
```

Run the tests by replacing the simulator name when necessary:

```bash
xcodebuild test \
  -project YetAnotherHabit.xcodeproj \
  -scheme YetAnotherHabit \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

GitHub Actions runs the same build and test workflow for pushes and pull requests.

## Data and privacy

Habit data and profile settings are stored locally with SwiftData. Photos selected for the avatar remain part of the user's local app data. Face ID authentication is handled by iOS; the app never receives or stores biometric data.

## Localization

User-facing strings belong in the Xcode string catalogs:

- `YetAnotherHabit/Localizable.xcstrings`
- `YetAnotherHabit/InfoPlist.xcstrings`

Russian is the default language, with English, Spanish, Brazilian Portuguese, and French also available.

## Status

The project is under active development. The Friends section is currently a placeholder for future functionality.
