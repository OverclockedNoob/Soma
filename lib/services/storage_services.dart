import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// All the local storage for the app lives here, split into a few boxes.
// Nothing fancy — just thin wrappers around Hive so the rest of the app
// doesn't need to know Hive exists. Kept every failure path returning
// bool/empty-list instead of throwing, since a storage hiccup shouldn't
// ever crash a screen — worst case the user sees empty stats, not a
// red error screen.

// ==================== WORKOUT STORAGE ====================
class WorkoutStorage {
  static const String _workoutBox = 'workouts';
  static Future<void> init() async => await Hive.openBox(_workoutBox);
  static Box get _box => Hive.box(_workoutBox);

  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      await _box.add(workout);
      return true;
    } catch (e) {
      debugPrint('WorkoutStorage.saveWorkout error: $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getAllWorkouts() {
    try {
      final workouts = _box.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // newest first — every screen that reads this list assumes that order
      workouts.sort((a, b) {
        try {
          return DateTime.parse(b['date'] as String)
              .compareTo(DateTime.parse(a['date'] as String));
        } catch (_) {
          return 0; // malformed date, just leave it where it was
        }
      });
      return workouts;
    } catch (e) {
      debugPrint('WorkoutStorage.getAllWorkouts error: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> getWorkoutsThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1), // Monday as start of week
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getAllWorkouts().where((w) {
      try {
        final d = DateTime.parse(w['date'] as String);
        return d.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            d.isBefore(endOfWeek.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      return true;
    } catch (e) {
      debugPrint('WorkoutStorage.clearAll error: $e');
      return false;
    }
  }
}

// ==================== CUSTOM WORKOUT STORAGE ====================
class CustomWorkoutStorage {
  static const String _customWorkoutBox = 'custom_workouts';
  static Future<void> init() async => await Hive.openBox(_customWorkoutBox);
  static Box get _box => Hive.box(_customWorkoutBox);

  static Future<bool> saveCustomWorkout(Map<String, dynamic> workout) async {
    try {
      await _box.add(workout);
      return true;
    } catch (e) {
      debugPrint('CustomWorkoutStorage.saveCustomWorkout error: $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getAllCustomWorkouts() {
    try {
      return _box.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('CustomWorkoutStorage.getAllCustomWorkouts error: $e');
      return [];
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      return true;
    } catch (e) {
      debugPrint('CustomWorkoutStorage.clearAll error: $e');
      return false;
    }
  }
}

// ==================== SETTINGS & RECOVERY BANK STORAGE ====================
class SettingsStorage {
  static const String _settingsBox = 'settings';
  static Future<void> init() async => await Hive.openBox(_settingsBox);
  static Box get _box => Hive.box(_settingsBox);

  // ── Standard settings ──────────────────────────────────────────
  static bool getNotifications() =>
      _box.get('notifications', defaultValue: true) as bool;
  static bool getSoundEffects() =>
      _box.get('soundEffects', defaultValue: true) as bool;
  static String getUserName() =>
      _box.get('userName', defaultValue: 'Champion') as String;
  static String getUserTitle() =>
      _box.get('userTitle', defaultValue: 'Fitness Enthusiast') as String;

  static Future<void> setNotifications(bool value) async =>
      await _box.put('notifications', value);
  static Future<void> setSoundEffects(bool value) async =>
      await _box.put('soundEffects', value);
  static Future<void> setUserName(String value) async =>
      await _box.put('userName', value);
  static Future<void> setUserTitle(String value) async =>
      await _box.put('userTitle', value);

  // ── Body stats (used for the MET-based calorie estimate in
  // active_workout_screen.dart — heavier users burn more for the same
  // exercise, so this actually matters for accuracy) ───────────────
  static int getWeight() => _box.get('weight', defaultValue: 70) as int;
  static int getAge() => _box.get('age', defaultValue: 25) as int;

  static Future<void> setWeight(int value) async => await _box.put('weight', value);
  static Future<void> setAge(int value) async => await _box.put('age', value);

  // ── Recovery Bank ─────────────────────────────────────────────
  // Coins earned by finishing workouts, spendable to "freeze" a missed
  // day so it doesn't break a streak. New users start with 3 as a small
  // freebie so the feature isn't invisible until they've earned any.
  static int getRecoveryCoins() =>
      _box.get('recoveryCoins', defaultValue: 3) as int;

  static Future<void> setRecoveryCoins(int value) async {
    await _box.put('recoveryCoins', value);
  }

  static Future<void> addRecoveryCoins(int amount) async {
    final current = getRecoveryCoins();
    await _box.put('recoveryCoins', current + amount);
  }

  static Future<bool> spendRecoveryCoin() async {
    final current = getRecoveryCoins();
    if (current > 0) {
      await _box.put('recoveryCoins', current - 1);
      return true;
    }
    return false;
  }

  static List<String> getFrozenDates() {
    final dates = _box.get('frozenDates', defaultValue: <String>[]) as List;
    return dates.map((e) => e.toString()).toList();
  }

  static Future<void> freezeDate(String dateStr) async {
    final dates = getFrozenDates();
    if (!dates.contains(dateStr)) {
      dates.add(dateStr);
      await _box.put('frozenDates', dates);
    }
  }

  static bool isDateFrozen(String dateStr) {
    return getFrozenDates().contains(dateStr);
  }
}

// ==================== PROGRAM / SPLIT STORAGE ====================
class ProgramStorage {
  static const String _programBox = 'programs';
  static Future<void> init() async => await Hive.openBox(_programBox);
  static Box get _box => Hive.box(_programBox);

  static Future<bool> saveProgram(Map<String, dynamic> program) async {
    try {
      await _box.add(program);
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.saveProgram error: $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getAllPrograms() {
    try {
      return _box.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('ProgramStorage.getAllPrograms error: $e');
      return [];
    }
  }

  static Future<bool> deleteProgram(String id) async {
    try {
      // Hive gives us auto-generated keys, not the id we stored inside the
      // map, so we have to scan for the matching entry first
      final key = _box.keys.firstWhere((k) => _box.get(k)['id'] == id);
      await _box.delete(key);
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.deleteProgram error: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.clearAll error: $e');
      return false;
    }
  }
}