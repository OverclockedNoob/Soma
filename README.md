# Soma

**Soma** is an offline-first, privacy-focused adaptive fitness & workout tracker built with Flutter. All **500 exercises**, instructions, target & secondary muscles, equipment tags, difficulty tiers, typography (`Outfit`), and user logs live **100% locally on your device**—zero API keys, zero cloud accounts, and zero internet connection required.

---

## Key Features

- **500 Bundled Local Exercises** — Instant offline search and filtering across Chest, Back, Legs, Arms, Shoulders, Core, and Cardio with step-by-step instructions, primary/secondary muscle breakdown, equipment requirements, and real Beginner / Intermediate / Advanced difficulty ratings.
- **Vibe Check (Adaptive Volume)** — Before every session, choose **Peak Energy**, **Normal**, or **Low Energy** (`-30%` sets survival mode) so you keep showing up even on tough days.
- **Gym Tetris (Equipment-Aware Swaps)** — Equipment occupied at the gym? Swap any exercise mid-workout with up to 5 local alternatives targeting the same muscle group on different equipment—preserving your completed sets.
- **Custom Routines & Multi-Week Splits** — Create, edit, and delete custom workout routines, schedule multi-week training splits with rest days, and switch active programs anytime.
- **Unified Streak & Recovery Bank** — Earn Recovery Coins every 5 workouts and spend a coin to freeze a missed day so illness or travel never wipes out hard-earned consistency.
- **Analytics & Personal Records** — Track lifetime sets, reps, lifted volume (`kg`), 7-day volume bar charts, muscle distribution, and per-exercise max weight & estimated 1RM (`Epley`).
- **Full JSON Backup & Restore** — Export workouts, custom routines, splits, and profile settings to a portable JSON file or clipboard and restore anytime across devices.

---

## Tech Stack & Architecture

- **Framework:** Flutter (`>=3.44.0`, Dart `^3.12.0`)
- **Local Persistence:** `hive` + `hive_flutter` (typed domain models in `lib/models/workout_models.dart`)
- **State Synchronization:** `WorkoutEventBus` (`ValueNotifier<int>`) automatically notifies subscribed screens whenever storage mutates
- **Offline Assets:**
  - `assets/exercises.json` — 500 curated exercises loaded once at startup via `ExerciseService`
  - `assets/fonts/Outfit.ttf` — Variable `Outfit` font (`OFL-1.1`) bundled locally for zero-network rendering

```text
lib/
├── core/
│   ├── event_bus.dart          # Reactive storage revision notifier
│   └── premium_ui.dart         # Offline Outfit typography & glassmorphic UI primitives
├── data/
│   └── exercise_data.dart      # Memoized UI facade & muscle palette/icons
├── models/
│   └── workout_models.dart     # Typed models & UTC calendar-day helpers
├── screens/                    # Home, Library, Picker, Builder, Active Workout, Summary,
│                               # My Workouts, Schedule, Split Builder, Stats, Settings
├── services/
│   ├── exercise_service.dart   # 500-exercise local loader, O(1) lookup & Gym Tetris engine
│   ├── streak_service.dart     # Shared DST-safe streak & Recovery Bank calculator
│   ├── storage_services.dart   # Hive persistence for workouts, routines, splits & settings
│   └── backup_service.dart     # Cross-platform JSON backup export & restore
├── widgets/
│   └── vibe_check_sheet.dart   # Pre-workout energy & volume-scaling sheet
└── main.dart                   # App bootstrap & bottom navigation shell
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.44.0` (Dart `>=3.12.0`)

### Run Locally

```bash
git clone https://github.com/OverclockedNoob/Soma.git
cd Soma
flutter pub get
flutter run
```

No `.env` file or API key setup is required.

### Analyze & Run Tests

```bash
flutter analyze
flutter test
```

### Production Android Signing (Optional)

Release builds automatically use `android/key.properties` when present (and fall back to debug signing for local/CI verification builds):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore.jks>
```
