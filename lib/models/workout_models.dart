// Typed domain models for Soma's offline local storage and workout flows.

String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? tryParseCalendarDayUtc(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  // Prefer parsing the leading YYYY-MM-DD calendar date directly so timestamps
  // or timezone offsets never shift the user's intended calendar day.
  final datePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (datePrefix != null) {
    final year = int.tryParse(datePrefix.group(1)!);
    final month = int.tryParse(datePrefix.group(2)!);
    final day = int.tryParse(datePrefix.group(3)!);
    if (year != null &&
        month != null &&
        month >= 1 &&
        month <= 12 &&
        day != null &&
        day >= 1 &&
        day <= 31) {
      return DateTime.utc(year, month, day);
    }
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

int _coerceInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String titleCaseWords(String raw) {
  return raw
      .trim()
      .split(RegExp(r'\s+'))
      .map((String w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Immutable exercise definition loaded from the bundled 500-exercise catalog.
class ExerciseItem {
  final String id;
  final String name;
  final String bodyPart;
  final String muscle;
  final String equipment;
  final String target;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String description;
  final String difficulty;
  final String category;

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.muscle,
    required this.equipment,
    required this.target,
    required this.secondaryMuscles,
    required this.instructions,
    required this.description,
    required this.difficulty,
    required this.category,
  });

  static String mapBodyPartToMuscle(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'upper legs':
      case 'lower legs':
        return 'Legs';
      case 'upper arms':
      case 'lower arms':
      case 'forearms':
        return 'Arms';
      case 'shoulders':
      case 'neck':
        return 'Shoulders';
      case 'waist':
        return 'Core';
      case 'cardio':
        return 'Cardio';
      default:
        return 'Core';
    }
  }

  static String normalizeDifficulty(String? rawDifficulty, String equipment) {
    switch (rawDifficulty?.trim().toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
    }
    final lowerEq = equipment.toLowerCase();
    if (lowerEq.contains('body weight') || lowerEq.contains('assisted')) {
      return 'Beginner';
    }
    return 'Intermediate';
  }

  factory ExerciseItem.fromJson(
    Map<String, Object?> json, {
    String? disambiguatedName,
  }) {
    final rawName = json['name']?.toString() ?? 'Unknown Exercise';
    final prettyName = disambiguatedName ?? titleCaseWords(rawName);
    final bodyPart = json['bodyPart']?.toString() ?? '';
    final equipment = json['equipment']?.toString() ?? '';
    final target = json['target']?.toString() ?? '';
    final rawSecondary = json['secondaryMuscles'];
    final secondaryMuscles = rawSecondary is List<Object?>
        ? rawSecondary
            .map((Object? e) => titleCaseWords(e?.toString() ?? ''))
            .where((String s) => s.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final rawInstructions = json['instructions'];
    final instructions = rawInstructions is List<Object?>
        ? rawInstructions
            .map((Object? e) => e?.toString().trim() ?? '')
            .where((String s) => s.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return ExerciseItem(
      id: json['id']?.toString() ?? '',
      name: prettyName,
      bodyPart: bodyPart,
      muscle: mapBodyPartToMuscle(bodyPart),
      equipment: equipment,
      target: target,
      secondaryMuscles: secondaryMuscles,
      instructions: instructions,
      description: json['description']?.toString().trim() ?? '',
      difficulty: normalizeDifficulty(
        json['difficulty']?.toString(),
        equipment,
      ),
      category: json['category']?.toString() ?? 'strength',
    );
  }

  RoutineExercise toRoutineExercise({int sets = 3, int targetReps = 10}) {
    return RoutineExercise(
      exerciseId: id,
      name: name,
      muscle: muscle,
      difficulty: difficulty,
      equipment: equipment,
      sets: sets,
      targetReps: targetReps,
    );
  }

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'muscle': muscle,
        'difficulty': difficulty,
        'instructions': instructions,
        'description': description,
        'equipment': equipment,
        'target': target,
        'secondaryMuscles': secondaryMuscles,
        'category': category,
      };
}

/// An exercise configured inside a custom workout routine or active session.
class RoutineExercise {
  final String? exerciseId;
  final String name;
  final String muscle;
  final String difficulty;
  final String? equipment;
  final int sets;
  final int targetReps;

  const RoutineExercise({
    this.exerciseId,
    required this.name,
    required this.muscle,
    this.difficulty = 'Intermediate',
    this.equipment,
    this.sets = 3,
    this.targetReps = 10,
  });

  RoutineExercise copyWith({
    String? exerciseId,
    String? name,
    String? muscle,
    String? difficulty,
    String? equipment,
    int? sets,
    int? targetReps,
  }) {
    return RoutineExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
    );
  }

  factory RoutineExercise.fromMap(Map<Object?, Object?> map) {
    final setsVal = _coerceInt(map['sets'], 3);
    final repsVal = _coerceInt(map['targetReps'], 10);
    return RoutineExercise(
      exerciseId: map['exerciseId']?.toString() ?? map['id']?.toString(),
      name: map['name']?.toString() ?? 'Exercise',
      muscle: map['muscle']?.toString() ?? 'Core',
      difficulty: map['difficulty']?.toString() ?? 'Intermediate',
      equipment: map['equipment']?.toString(),
      sets: setsVal < 1 ? 1 : setsVal,
      targetReps: repsVal < 1 ? 1 : repsVal,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (exerciseId != null && exerciseId!.isNotEmpty)
          'exerciseId': exerciseId,
        'name': name,
        'muscle': muscle,
        'difficulty': difficulty,
        if (equipment != null && equipment!.isNotEmpty) 'equipment': equipment,
        'sets': sets,
        'targetReps': targetReps,
      };
}

/// A single completed set recorded during an active workout session.
class CompletedSet {
  final int? exerciseIndex;
  final String exercise;
  final int setNumber;
  final int reps;

  const CompletedSet({
    this.exerciseIndex,
    required this.exercise,
    required this.setNumber,
    required this.reps,
  });

  factory CompletedSet.fromMap(Map<Object?, Object?> map) {
    final rawIdx = map['exerciseIndex'];
    return CompletedSet(
      exerciseIndex: rawIdx == null ? null : _coerceInt(rawIdx, 0),
      exercise: map['exercise']?.toString() ?? 'Exercise',
      setNumber: _coerceInt(map['set'], 1),
      reps: _coerceInt(map['reps'], 0),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
        'exercise': exercise,
        'set': setNumber,
        'reps': reps,
      };
}

/// A completed workout session saved to local history.
class WorkoutSession {
  final String id;
  final String name;
  final String date;
  final int durationSeconds;
  final int durationMinutes;
  final int calories;
  final int totalSets;
  final int totalReps;
  final List<String> exercises;
  final List<CompletedSet> sets;

  const WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.calories,
    required this.totalSets,
    required this.totalReps,
    required this.exercises,
    required this.sets,
  });

  DateTime? get dayUtc => tryParseCalendarDayUtc(date);

  factory WorkoutSession.fromMap(Map<Object?, Object?> map) {
    final rawExercises = map['exercises'];
    final exercises = rawExercises is List<Object?>
        ? rawExercises.map((Object? e) => e?.toString() ?? '').toList()
        : const <String>[];

    final rawSets = map['sets'];
    final sets = rawSets is List<Object?>
        ? rawSets
            .whereType<Map<Object?, Object?>>()
            .map(CompletedSet.fromMap)
            .toList()
        : const <CompletedSet>[];

    final durationMins = _coerceInt(map['durationMinutes'], 0);
    final durationSecs = map['durationSeconds'] != null
        ? _coerceInt(map['durationSeconds'], durationMins * 60)
        : durationMins * 60;

    return WorkoutSession(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Workout',
      date: map['date']?.toString() ?? '',
      durationSeconds: durationSecs,
      durationMinutes: durationMins,
      calories: _coerceInt(map['calories'], 0),
      totalSets: _coerceInt(map['totalSets'], sets.length),
      totalReps: _coerceInt(
        map['totalReps'],
        sets.fold<int>(0, (int sum, CompletedSet s) => sum + s.reps),
      ),
      exercises: exercises,
      sets: sets,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'date': date,
        'durationSeconds': durationSeconds,
        'durationMinutes': durationMinutes,
        'calories': calories,
        'totalSets': totalSets,
        'totalReps': totalReps,
        'exercises': exercises,
        'sets': sets.map((CompletedSet s) => s.toMap()).toList(),
      };
}

/// A user-built custom workout template stored in CustomWorkoutStorage.
class WorkoutRoutine {
  final String id;
  final String name;
  final String description;
  final List<RoutineExercise> exercises;
  final String createdAt;

  const WorkoutRoutine({
    required this.id,
    required this.name,
    this.description = '',
    required this.exercises,
    required this.createdAt,
  });

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? description,
    List<RoutineExercise>? exercises,
    String? createdAt,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WorkoutRoutine.fromMap(Map<Object?, Object?> map) {
    final rawExercises = map['exercises'];
    final exercises = rawExercises is List<Object?>
        ? rawExercises
            .whereType<Map<Object?, Object?>>()
            .map(RoutineExercise.fromMap)
            .toList()
        : <RoutineExercise>[];

    return WorkoutRoutine(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Untitled Workout',
      description: map['description']?.toString() ?? '',
      exercises: exercises,
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'exercises': exercises.map((RoutineExercise e) => e.toMap()).toList(),
        'createdAt': createdAt,
      };
}

/// A weekly training split program assigning routines or rest days to Mon–Sun.
class SplitProgram {
  static const List<String> weekDayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final String id;
  final String name;
  final int durationWeeks;
  final String startDate;
  final Map<String, String?> schedule;
  final int colorValue;

  const SplitProgram({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.startDate,
    required this.schedule,
    required this.colorValue,
  });

  DateTime? get startDayUtc => tryParseCalendarDayUtc(startDate);

  DateTime? get endDayExclusiveUtc {
    final start = startDayUtc;
    if (start == null) return null;
    return DateTime.utc(
      start.year,
      start.month,
      start.day + (durationWeeks < 1 ? 1 : durationWeeks) * 7,
    );
  }

  bool get hasScheduledWorkouts =>
      schedule.values.any((String? id) => id != null && id.isNotEmpty);

  bool isDateInRange(DateTime date) {
    final start = startDayUtc;
    final endExclusive = endDayExclusiveUtc;
    if (start == null || endExclusive == null) return true;
    final dayUtc = DateTime.utc(date.year, date.month, date.day);
    return !dayUtc.isBefore(start) && dayUtc.isBefore(endExclusive);
  }

  String? workoutIdForDate(DateTime date, {bool enforceRange = true}) {
    if (enforceRange && !isDateInRange(date)) return null;
    final dayName = weekDayNames[date.weekday - 1];
    final workoutId = schedule[dayName];
    if (workoutId == null || workoutId.isEmpty) return null;
    return workoutId;
  }

  bool isScheduledRestDay(DateTime date, {bool enforceRange = true}) {
    if (!hasScheduledWorkouts) return false;
    if (enforceRange && !isDateInRange(date)) return false;
    final dayName = weekDayNames[date.weekday - 1];
    final workoutId = schedule[dayName];
    return workoutId == null || workoutId.isEmpty;
  }

  factory SplitProgram.fromMap(Map<Object?, Object?> map) {
    final normalizedSchedule = <String, String?>{
      for (final String day in weekDayNames) day: null,
    };
    final rawSchedule = map['schedule'];
    if (rawSchedule is Map<Object?, Object?>) {
      for (final String day in weekDayNames) {
        final rawId = rawSchedule[day]?.toString();
        normalizedSchedule[day] =
            (rawId == null || rawId.isEmpty) ? null : rawId;
      }
    }

    final parsedStart = tryParseCalendarDayUtc(map['startDate']?.toString());
    final normalizedStart = parsedStart != null
        ? formatDateKey(parsedStart)
        : (map['startDate']?.toString() ?? formatDateKey(DateTime.now()));

    return SplitProgram(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'My Split',
      durationWeeks: _coerceInt(map['durationWeeks'], 4).clamp(1, 52),
      startDate: normalizedStart,
      schedule: normalizedSchedule,
      colorValue: _coerceInt(map['colorValue'], 0xFF8B7CFF),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'durationWeeks': durationWeeks,
        'startDate': startDate,
        'schedule': schedule,
        'colorValue': colorValue,
      };
}
