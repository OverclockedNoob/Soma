# Soma

An offline workout tracker built with Flutter.

I wanted to log sets without making an account first, and without the app misbehaving when the gym has no signal. Soma keeps everything on your phone. It has no backend, so there's nothing to sign into, and it doesn't need an internet connection or any API keys.

## Download

Grab an APK from the [Releases](https://github.com/OverclockedNoob/Soma/releases) page.

- `Soma-v1.0.0-arm64-v8a.apk` works on most phones from the last several years.
- `Soma-v1.0.0.apk` is the universal build, for older devices or emulators.

It isn't on the Play Store, so you'll need to allow installs from unknown sources.

## Features

**Exercise library.** 500 exercises are bundled in the app. You can search and filter by muscle group, and each one has instructions, primary and secondary muscles, the equipment it needs, and a difficulty level.

**Vibe Check.** Before a workout, tell Soma how you're feeling: Peak Energy, Normal, or Low Energy. On a low day it cuts your sets by 30% so you still show up instead of skipping. The numbers are just what felt right in testing.

**Gym Tetris.** If someone is on the machine you need, swap the exercise mid-workout. Soma suggests up to five alternatives for the same muscle group using different equipment, and the sets you've already done stay logged.

**Routines and splits.** Build your own routines, edit or delete them later, and set up a multi-week split with rest days. You can switch programs whenever you like.

**Streaks and Recovery Coins.** You earn a coin every 5 workouts. Spend one to cover a missed day if you're sick or traveling, so the streak doesn't reset.

**Stats.** Lifetime sets, reps and volume, a 7-day volume chart, muscle distribution, and personal records with estimated one-rep max (Epley formula).

**Backup and restore.** Export your workouts, routines, splits and settings to a JSON file or the clipboard, and import them on another phone. There's no cloud sync, so this is the only way to move your data. Back up now and then.

## Limitations

- Android only. I haven't built or tested it on iOS.
- Dark theme only.
- Everything is stored on the device. If you uninstall without exporting, your data is gone.

## Running from source

You need Flutter `>=3.44.0` (Dart `>=3.12.0`). There's no `.env` file or API key setup.

```bash
git clone https://github.com/OverclockedNoob/Soma.git
cd Soma
flutter pub get
flutter run
```

Checks:

```bash
flutter analyze
flutter test
```

### Release signing (optional)

Release builds use `android/key.properties` if it exists, and fall back to debug signing if it doesn't. That fallback keeps CI and local builds working, but it isn't suitable for publishing.

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore.jks>
```

## How it's put together

Storage is [Hive](https://pub.dev/packages/hive). The exercise data is a single bundled `assets/exercises.json`, loaded once at startup. The `Outfit` font is bundled too, so nothing is fetched at runtime. Screens refresh through a small `ValueNotifier` event bus that fires whenever storage changes.

```text
lib/
├── core/        # event bus, shared UI styles
├── data/        # exercise data helpers, muscle colors and icons
├── models/      # workout models, date helpers
├── screens/     # home, library, workout builder, active workout, stats, settings, etc.
├── services/    # exercise loading, streaks, Hive storage, backup
├── widgets/     # vibe check sheet
└── main.dart    # startup and bottom navigation
```

## License

Licensed under the [GNU General Public License v3.0](LICENSE). Copyright (c) 2026 OverclockedNoob.
