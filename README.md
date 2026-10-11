# Soma

A workout tracker I built in Flutter because I got tired of apps that just count reps and don't care whether you actually feel like training that day.

No backend, no login, no account. Everything's stored locally on your device with Hive. Open it up and it just works.

## Why this exists

Most workout apps treat every day the same — log your sets, see a number go up, repeat. But some days you're running on 4 hours of sleep and still sore from yesterday, and some days you're feeling great and could push harder. Soma tries to account for that instead of ignoring it.

## What it actually does

**Home screen**
Shows you what you're supposed to be doing today based on your weekly split — or tells you it's a rest day and to go enjoy it. Quick glance at your stats, streak, and this week's activity without digging through menus.

**The Vibe Check**
Before a workout starts, it asks you 3 quick questions — how much sleep you got, how sore you are, how motivated you're feeling. Based on that, it quietly adjusts your target reps up or down. Feeling great? It bumps things up 10%. Running on empty? It backs off 20% so you're not fighting your own program on a bad day.

**Streaks that don't punish you for resting**
If your split has a scheduled rest day, that day doesn't break your streak — it's supposed to be a rest day. On top of that, you earn "Recovery Coins" from working out, which you can spend to freeze a day you actually missed. Life happens. One skipped Tuesday shouldn't erase three weeks of consistency.

**Exercise Library**
Around 500 exercises from a bundled ExerciseDB dataset — fully offline, no API key. Each one has real difficulty ratings, target and secondary muscles, equipment, a description, and step-by-step form instructions. Filter by muscle group or difficulty, tap an exercise, and either quick-start it solo or drop it straight into a custom workout.

**Build your own splits**
Make custom workouts from the library, then assign them to specific days of the week — Push/Pull/Legs, Upper/Lower, whatever works for you. The home screen automatically knows what day it is and shows the right workout.

**Stats**
Lifetime totals, weekly chart, average session length. Nothing fancy, just enough to see the trend.

## Built with

- Flutter / Dart
- Hive for local storage — no backend, no server costs, no waiting on network requests
- ExerciseDB data bundled locally as JSON (`assets/exercises.json`) — zero network at runtime
- Google Fonts

## Running it locally

```bash
git clone https://github.com/OverclockedNoob/Soma.git
cd Soma
flutter pub get
