import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/event_bus.dart';
import '../models/workout_models.dart';

Map<String, dynamic> _deepStringKeyMap(Map<Object?, Object?> raw) {
  final result = <String, dynamic>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    result[key] = _deepNormalizeValue(entry.value);
  }
  return result;
}

dynamic _deepNormalizeValue(Object? value) {
  if (value is Map<Object?, Object?>) {
    return _deepStringKeyMap(value);
  }
  if (value is List<Object?>) {
    return value.map(_deepNormalizeValue).toList();
  }
  return value;
}

// ==================== WORKOUT STORAGE ====================
class WorkoutStorage {
  static const String _workoutBox = 'workouts';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_workoutBox)) {
      await Hive.openBox<dynamic>(_workoutBox);
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(_workoutBox);

  static Future<bool> saveWorkoutSession(WorkoutSession session) async {
    return saveWorkout(session.toMap());
  }

  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      final normalized = Map<String, dynamic>.from(workout);
      normalized['id'] ??=
          DateTime.now().microsecondsSinceEpoch.toString();
      await _box.add(normalized);
      WorkoutEventBus.instance.notifyWorkoutChanged();
      return true;
    } catch (e) {
      debugPrint('WorkoutStorage.saveWorkout error: $e');
      return false;
    }
  }

  static List<WorkoutSession> getAllWorkoutSessions() {
    try {
      final sessions = _box.values
          .whereType<Map<Object?, Object?>>()
          .map(WorkoutSession.fromMap)
          .toList();

      sessions.sort((WorkoutSession a, WorkoutSession b) {
        final dayA = a.dayUtc;
        final dayB = b.dayUtc;
        if (dayA == null && dayB == null) return 0;
        if (dayA == null) return 1;
        if (dayB == null) return -1;
        return dayB.compareTo(dayA);
      });
      return sessions;
    } catch (e) {
      debugPrint('WorkoutStorage.getAllWorkoutSessions error: $e');
      return <WorkoutSession>[];
    }
  }

  static List<Map<String, dynamic>> getAllWorkouts() {
    try {
      final workouts = _box.values
          .whereType<Map<Object?, Object?>>()
          .map(_deepStringKeyMap)
          .toList();

      workouts.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final dayA = tryParseCalendarDayUtc(a['date']?.toString());
        final dayB = tryParseCalendarDayUtc(b['date']?.toString());
        if (dayA == null && dayB == null) return 0;
        if (dayA == null) return 1;
        if (dayB == null) return -1;
        return dayB.compareTo(dayA);
      });
      return workouts;
    } catch (e) {
      debugPrint('WorkoutStorage.getAllWorkouts error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static List<WorkoutSession> getWorkoutSessionsThisWeek({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final mondayUtc = DateTime.utc(
      ref.year,
      ref.month,
      ref.day - (ref.weekday - 1),
    );
    final nextMondayUtc = DateTime.utc(
      mondayUtc.year,
      mondayUtc.month,
      mondayUtc.day + 7,
    );

    return getAllWorkoutSessions().where((WorkoutSession session) {
      final day = session.dayUtc;
      if (day == null) return false;
      return !day.isBefore(mondayUtc) && day.isBefore(nextMondayUtc);
    }).toList();
  }

  static List<Map<String, dynamic>> getWorkoutsThisWeek({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final mondayUtc = DateTime.utc(
      ref.year,
      ref.month,
      ref.day - (ref.weekday - 1),
    );
    final nextMondayUtc = DateTime.utc(
      mondayUtc.year,
      mondayUtc.month,
      mondayUtc.day + 7,
    );

    return getAllWorkouts().where((Map<String, dynamic> w) {
      final day = tryParseCalendarDayUtc(w['date']?.toString());
      if (day == null) return false;
      return !day.isBefore(mondayUtc) && day.isBefore(nextMondayUtc);
    }).toList();
  }

  static Future<bool> replaceAll(
    List<Map<String, dynamic>> workouts, {
    bool notify = true,
  }) async {
    try {
      await _box.clear();
      for (final workout in workouts) {
        await _box.add(_deepStringKeyMap(workout));
      }
      if (notify) WorkoutEventBus.instance.notifyWorkoutChanged();
      return true;
    } catch (e) {
      debugPrint('WorkoutStorage.replaceAll error: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      WorkoutEventBus.instance.notifyWorkoutChanged();
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

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_customWorkoutBox)) {
      await Hive.openBox<dynamic>(_customWorkoutBox);
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(_customWorkoutBox);

  static Future<bool> saveRoutine(WorkoutRoutine routine) async {
    return saveCustomWorkout(routine.toMap());
  }

  /// Upserts a custom workout by `'id'` instead of blindly appending duplicates.
  static Future<bool> saveCustomWorkout(Map<String, dynamic> workout) async {
    try {
      final normalized = _deepStringKeyMap(workout);
      final rawId = normalized['id']?.toString() ?? '';
      final id = rawId.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : rawId;
      normalized['id'] = id;

      final matchingKeys = <dynamic>[];
      for (final key in _box.keys) {
        final existing = _box.get(key);
        if (existing is Map<Object?, Object?> &&
            existing['id']?.toString() == id) {
          matchingKeys.add(key);
        }
      }

      if (matchingKeys.isNotEmpty) {
        await _box.put(matchingKeys.first, normalized);
        // Clean up any legacy duplicate records that shared the same ID.
        for (int i = 1; i < matchingKeys.length; i++) {
          await _box.delete(matchingKeys[i]);
        }
      } else {
        await _box.add(normalized);
      }

      WorkoutEventBus.instance.notifyCustomWorkoutsChanged();
      return true;
    } catch (e) {
      debugPrint('CustomWorkoutStorage.saveCustomWorkout error: $e');
      return false;
    }
  }

  static List<WorkoutRoutine> getAllRoutines() {
    try {
      final byId = <String, WorkoutRoutine>{};
      final withoutId = <WorkoutRoutine>[];
      for (final raw in _box.values.whereType<Map<Object?, Object?>>()) {
        final routine = WorkoutRoutine.fromMap(raw);
        if (routine.id.isEmpty) {
          withoutId.add(routine);
        } else {
          // Keep the newest entry if legacy duplicates exist.
          byId[routine.id] = routine;
        }
      }
      return <WorkoutRoutine>[...byId.values, ...withoutId];
    } catch (e) {
      debugPrint('CustomWorkoutStorage.getAllRoutines error: $e');
      return <WorkoutRoutine>[];
    }
  }

  static WorkoutRoutine? getRoutineById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final routine in getAllRoutines()) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  static List<Map<String, dynamic>> getAllCustomWorkouts() {
    return getAllRoutines()
        .map((WorkoutRoutine r) => r.toMap())
        .toList();
  }

  static Future<bool> deleteCustomWorkout(String id) async {
    try {
      final keysToDelete = <dynamic>[];
      for (final key in _box.keys) {
        final entry = _box.get(key);
        if (entry is Map<Object?, Object?> && entry['id']?.toString() == id) {
          keysToDelete.add(key);
        }
      }
      for (final key in keysToDelete) {
        await _box.delete(key);
      }

      // Scrub deleted workout ID from any split schedules so splits revert
      // cleanly to Rest Day instead of pointing at a deleted routine.
      await ProgramStorage.scrubDeletedWorkoutId(id);

      WorkoutEventBus.instance.notifyCustomWorkoutsChanged();
      return keysToDelete.isNotEmpty;
    } catch (e) {
      debugPrint('CustomWorkoutStorage.deleteCustomWorkout error: $e');
      return false;
    }
  }

  static Future<bool> replaceAll(
    List<Map<String, dynamic>> workouts, {
    bool notify = true,
  }) async {
    try {
      await _box.clear();
      for (final workout in workouts) {
        await _box.add(_deepStringKeyMap(workout));
      }
      if (notify) WorkoutEventBus.instance.notifyCustomWorkoutsChanged();
      return true;
    } catch (e) {
      debugPrint('CustomWorkoutStorage.replaceAll error: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      WorkoutEventBus.instance.notifyCustomWorkoutsChanged();
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

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_settingsBox)) {
      await Hive.openBox<dynamic>(_settingsBox);
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(_settingsBox);

  // ── Standard settings ──────────────────────────────────────────
  static bool getNotifications() =>
      (_box.get('notifications', defaultValue: true) as bool?) ?? true;
  static bool getSoundEffects() =>
      (_box.get('soundEffects', defaultValue: true) as bool?) ?? true;
  static String getUserName() =>
      (_box.get('userName', defaultValue: 'Champion') as String?) ?? 'Champion';
  static String getUserTitle() =>
      (_box.get('userTitle', defaultValue: 'Fitness Enthusiast') as String?) ??
      'Fitness Enthusiast';
  static String? getActiveProgramId() =>
      _box.get('activeProgramId') as String?;

  static Future<void> setNotifications(bool value) async {
    await _box.put('notifications', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> setSoundEffects(bool value) async {
    await _box.put('soundEffects', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> setUserName(String value) async {
    await _box.put('userName', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> setUserTitle(String value) async {
    await _box.put('userTitle', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> setActiveProgramId(
    String? id, {
    bool notify = true,
  }) async {
    if (id == null || id.isEmpty) {
      await _box.delete('activeProgramId');
    } else {
      await _box.put('activeProgramId', id);
    }
    if (notify) WorkoutEventBus.instance.notifyProgramsChanged();
  }

  // ── Body stats ─────────────────────────────────────────────────
  static int getWeight() {
    final raw = _box.get('weight', defaultValue: 70);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 70;
  }

  static int getAge() {
    final raw = _box.get('age', defaultValue: 25);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 25;
  }

  static Future<void> setWeight(int value) async {
    if (value <= 0) return;
    await _box.put('weight', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> setAge(int value) async {
    if (value <= 0) return;
    await _box.put('age', value);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  // ── Recovery Bank ─────────────────────────────────────────────
  static int getRecoveryCoins() {
    final raw = _box.get('recoveryCoins', defaultValue: 3);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 3;
  }

  static Future<void> setRecoveryCoins(
    int value, {
    bool notify = true,
  }) async {
    await _box.put('recoveryCoins', value < 0 ? 0 : value);
    if (notify) WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> addRecoveryCoins(int amount) async {
    final current = getRecoveryCoins();
    await _box.put('recoveryCoins', current + amount);
    WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<bool> spendRecoveryCoin() async {
    final current = getRecoveryCoins();
    if (current > 0) {
      await _box.put('recoveryCoins', current - 1);
      WorkoutEventBus.instance.notifySettingsChanged();
      return true;
    }
    return false;
  }

  static List<String> getFrozenDates() {
    final raw = _box.get('frozenDates', defaultValue: <String>[]);
    if (raw is List<Object?>) {
      return raw.map((Object? e) => e.toString()).toList();
    }
    return <String>[];
  }

  static Future<void> setFrozenDates(
    List<String> dates, {
    bool notify = true,
  }) async {
    final deduped = dates.toSet().toList()..sort();
    await _box.put('frozenDates', deduped);
    if (notify) WorkoutEventBus.instance.notifySettingsChanged();
  }

  static Future<void> freezeDate(String dateStr) async {
    final day = tryParseCalendarDayUtc(dateStr);
    final normalized = day != null ? formatDateKey(day) : dateStr;
    final dates = getFrozenDates();
    if (!dates.contains(normalized)) {
      dates.add(normalized);
      await _box.put('frozenDates', dates);
      WorkoutEventBus.instance.notifySettingsChanged();
    }
  }

  /// Atomically spends 1 coin and freezes [dateStr] if not already frozen.
  static Future<bool> spendCoinAndFreezeDate(String dateStr) async {
    final day = tryParseCalendarDayUtc(dateStr);
    final normalized = day != null ? formatDateKey(day) : dateStr;
    if (isDateFrozen(normalized)) return false;
    final current = getRecoveryCoins();
    if (current <= 0) return false;

    final dates = getFrozenDates()..add(normalized);
    await _box.put('recoveryCoins', current - 1);
    await _box.put('frozenDates', dates);
    WorkoutEventBus.instance.notifySettingsChanged();
    return true;
  }

  static bool isDateFrozen(String dateStr) {
    final day = tryParseCalendarDayUtc(dateStr);
    final normalized = day != null ? formatDateKey(day) : dateStr;
    return getFrozenDates().contains(normalized);
  }
}

// ==================== PROGRAM / SPLIT STORAGE ====================
class ProgramStorage {
  static const String _programBox = 'programs';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_programBox)) {
      await Hive.openBox<dynamic>(_programBox);
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(_programBox);

  static Future<bool> saveProgramModel(
    SplitProgram program, {
    bool makeActive = true,
  }) async {
    return saveProgram(program.toMap(), makeActive: makeActive);
  }

  static Future<bool> saveProgram(
    Map<String, dynamic> program, {
    bool makeActive = true,
  }) async {
    try {
      final model = SplitProgram.fromMap(program);
      final id = model.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : model.id;
      final mapToStore = SplitProgram(
        id: id,
        name: model.name,
        durationWeeks: model.durationWeeks,
        startDate: model.startDate,
        schedule: model.schedule,
        colorValue: model.colorValue,
      ).toMap();

      dynamic existingKey;
      for (final key in _box.keys) {
        final existing = _box.get(key);
        if (existing is Map<Object?, Object?> &&
            existing['id']?.toString() == id) {
          existingKey = key;
          break;
        }
      }

      if (existingKey != null) {
        await _box.put(existingKey, mapToStore);
      } else {
        await _box.add(mapToStore);
      }

      if (makeActive) {
        await SettingsStorage.setActiveProgramId(id, notify: false);
      }
      WorkoutEventBus.instance.notifyProgramsChanged();
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.saveProgram error: $e');
      return false;
    }
  }

  static List<SplitProgram> getAllProgramModels() {
    try {
      return _box.values
          .whereType<Map<Object?, Object?>>()
          .map(SplitProgram.fromMap)
          .toList();
    } catch (e) {
      debugPrint('ProgramStorage.getAllProgramModels error: $e');
      return <SplitProgram>[];
    }
  }

  static List<Map<String, dynamic>> getAllPrograms() {
    return getAllProgramModels()
        .map((SplitProgram p) => p.toMap())
        .toList();
  }

  static SplitProgram? getActiveProgramModel() {
    final programs = getAllProgramModels();
    if (programs.isEmpty) return null;
    final activeId = SettingsStorage.getActiveProgramId();
    if (activeId != null && activeId.isNotEmpty) {
      for (final p in programs) {
        if (p.id == activeId) return p;
      }
    }
    return programs.last;
  }

  static Future<void> setActiveProgram(String? id) async {
    await SettingsStorage.setActiveProgramId(id, notify: true);
  }

  static Future<bool> deleteProgram(String id) async {
    try {
      final keysToDelete = <dynamic>[];
      for (final key in _box.keys) {
        final entry = _box.get(key);
        if (entry is Map<Object?, Object?> && entry['id']?.toString() == id) {
          keysToDelete.add(key);
        }
      }
      for (final key in keysToDelete) {
        await _box.delete(key);
      }

      if (SettingsStorage.getActiveProgramId() == id) {
        final remaining = getAllProgramModels();
        await SettingsStorage.setActiveProgramId(
          remaining.isNotEmpty ? remaining.last.id : null,
          notify: false,
        );
      }
      WorkoutEventBus.instance.notifyProgramsChanged();
      return keysToDelete.isNotEmpty;
    } catch (e) {
      debugPrint('ProgramStorage.deleteProgram error: $e');
      return false;
    }
  }

  static Future<void> scrubDeletedWorkoutId(String deletedWorkoutId) async {
    try {
      for (final key in _box.keys) {
        final entry = _box.get(key);
        if (entry is! Map<Object?, Object?>) continue;
        final model = SplitProgram.fromMap(entry);
        bool changed = false;
        final updatedSchedule = Map<String, String?>.from(model.schedule);
        for (final day in SplitProgram.weekDayNames) {
          if (updatedSchedule[day] == deletedWorkoutId) {
            updatedSchedule[day] = null;
            changed = true;
          }
        }
        if (changed) {
          final updated = SplitProgram(
            id: model.id,
            name: model.name,
            durationWeeks: model.durationWeeks,
            startDate: model.startDate,
            schedule: updatedSchedule,
            colorValue: model.colorValue,
          );
          await _box.put(key, updated.toMap());
        }
      }
    } catch (e) {
      debugPrint('ProgramStorage.scrubDeletedWorkoutId error: $e');
    }
  }

  static Future<bool> replaceAll(
    List<Map<String, dynamic>> programs, {
    String? activeProgramId,
    bool notify = true,
  }) async {
    try {
      await _box.clear();
      for (final program in programs) {
        await _box.add(SplitProgram.fromMap(program).toMap());
      }
      await SettingsStorage.setActiveProgramId(activeProgramId, notify: false);
      if (notify) WorkoutEventBus.instance.notifyProgramsChanged();
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.replaceAll error: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      await SettingsStorage.setActiveProgramId(null, notify: false);
      WorkoutEventBus.instance.notifyProgramsChanged();
      return true;
    } catch (e) {
      debugPrint('ProgramStorage.clearAll error: $e');
      return false;
    }
  }
}
