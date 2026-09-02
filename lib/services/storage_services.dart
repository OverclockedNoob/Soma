import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      final workouts =
          _box.values
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      workouts.sort((a, b) {
        try {
          return DateTime.parse(
            b['date'] as String,
          ).compareTo(DateTime.parse(a['date'] as String));
        } catch (_) {
          return 0;
        }
      });
      return workouts;
    } catch (e) {
      return [];
    }
  }

  static List<Map<String, dynamic>> getWorkoutsThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
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
      return [];
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ==================== SETTINGS & RECOVERY BANK STORAGE ====================
class SettingsStorage {
  static const String _settingsBox = 'settings';
  static Future<void> init() async => await Hive.openBox(_settingsBox);
  static Box get _box => Hive.box(_settingsBox);

  // ── Standard Settings ──────────────────────────────────────────
  static bool getNotifications() =>
      _box.get('notifications', defaultValue: true) as bool;
  static bool getSoundEffects() =>
      _box.get('soundEffects', defaultValue: true) as bool;
  static String getUserName() =>
      _box.get('userName', defaultValue: 'Mitesh') as String;
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

  // ── 🛡️ RECOVERY BANK ──────────────────────────────────────────
  static int getRecoveryCoins() =>
      _box.get('recoveryCoins', defaultValue: 3) as int;

  static Future<void> setRecoveryCoins(int value) async =>
      await _box.put('recoveryCoins', value);

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
      return [];
    }
  }

  static Future<bool> deleteProgram(String id) async {
    try {
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
      return false;
    }
  }
}