import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/workout_models.dart';

/// 100% offline local exercise catalog backed by `assets/exercises.json`.
///
/// Parses, normalizes, sorts, and indexes all 500 exercises once at startup so
/// library browsing, filtering, category counts, detail lookups, and mid-workout
/// equipment substitutions ("Gym Tetris") execute in memory with zero network IO.
class ExerciseService {
  ExerciseService._();

  static const String assetPath = 'assets/exercises.json';

  static List<ExerciseItem>? _sortedItems;
  static List<Map<String, dynamic>>? _legacyMaps;
  static Map<String, ExerciseItem> _byId = const <String, ExerciseItem>{};
  static Map<String, ExerciseItem> _byLowerName = const <String, ExerciseItem>{};
  static Map<String, int> _categoryCounts = const <String, int>{};

  static Future<void> init() async {
    if (_sortedItems != null) return;
    try {
      final raw = await rootBundle.loadString(assetPath);
      loadFromJsonString(raw);
      debugPrint(
        'ExerciseService: ${_sortedItems!.length} exercises loaded locally.',
      );
    } catch (e) {
      debugPrint('ExerciseService asset load error: $e');
      _setCatalog(const <ExerciseItem>[]);
    }
  }

  /// Parses and indexes a JSON array of exercises (used by [init] and tests).
  static void loadFromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List<Object?>) {
      _setCatalog(const <ExerciseItem>[]);
      return;
    }

    final seenNames = <String, int>{};
    final parsed = <ExerciseItem>[];

    for (final entry in decoded) {
      if (entry is! Map<Object?, Object?>) continue;
      final jsonMap = <String, Object?>{
        for (final MapEntry<Object?, Object?> kv in entry.entries)
          kv.key.toString(): kv.value,
      };
      final baseName = titleCaseWords(
        jsonMap['name']?.toString() ?? 'Unknown Exercise',
      );
      final lowerBase = baseName.toLowerCase();
      final count = (seenNames[lowerBase] ?? 0) + 1;
      seenNames[lowerBase] = count;

      final uniqueName = count == 1 ? baseName : '$baseName (v. $count)';
      parsed.add(
        ExerciseItem.fromJson(jsonMap, disambiguatedName: uniqueName),
      );
    }

    _setCatalog(parsed);
  }

  @visibleForTesting
  static void resetForTesting([List<ExerciseItem>? items]) {
    if (items == null) {
      _sortedItems = null;
      _legacyMaps = null;
      _byId = const <String, ExerciseItem>{};
      _byLowerName = const <String, ExerciseItem>{};
      _categoryCounts = const <String, int>{};
    } else {
      _setCatalog(List<ExerciseItem>.from(items));
    }
  }

  static void _setCatalog(List<ExerciseItem> items) {
    final sorted = List<ExerciseItem>.from(items)
      ..sort((ExerciseItem a, ExerciseItem b) => a.name.compareTo(b.name));

    final byId = <String, ExerciseItem>{};
    final byLowerName = <String, ExerciseItem>{};
    final counts = <String, int>{'All': sorted.length};

    for (final item in sorted) {
      if (item.id.isNotEmpty) {
        byId[item.id] = item;
      }
      byLowerName[item.name.toLowerCase()] = item;
      counts[item.muscle] = (counts[item.muscle] ?? 0) + 1;
    }

    _sortedItems = List<ExerciseItem>.unmodifiable(sorted);
    _legacyMaps = List<Map<String, dynamic>>.unmodifiable(
      sorted.map((ExerciseItem e) => e.toLegacyMap()),
    );
    _byId = Map<String, ExerciseItem>.unmodifiable(byId);
    _byLowerName = Map<String, ExerciseItem>.unmodifiable(byLowerName);
    _categoryCounts = Map<String, int>.unmodifiable(counts);
  }

  static List<ExerciseItem> get allItems =>
      _sortedItems ?? const <ExerciseItem>[];

  static List<Map<String, dynamic>> get allLegacyMaps =>
      _legacyMaps ?? const <Map<String, dynamic>>[];

  static int countForCategory(String category) {
    if (category == 'All') return allItems.length;
    return _categoryCounts[category] ?? 0;
  }

  static ExerciseItem? findByIdOrName({String? id, String? name}) {
    if (id != null && id.isNotEmpty) {
      final match = _byId[id];
      if (match != null) return match;
    }
    if (name != null && name.isNotEmpty) {
      return _byLowerName[name.toLowerCase()];
    }
    return null;
  }

  /// Picks a real local substitute exercise for the same muscle group and
  /// requested equipment category during an active workout ("Gym Tetris").
  static RoutineExercise findSubstitute({
    required RoutineExercise current,
    required String equipmentChoice,
    Set<String> excludedNames = const <String>{},
  }) {
    bool matchesEquipment(String rawEquipment) {
      final eq = rawEquipment.toLowerCase();
      switch (equipmentChoice) {
        case 'Dumbbells':
          return eq.contains('dumbbell') || eq.contains('kettlebell');
        case 'Machine / Cable':
          return eq.contains('cable') || eq.contains('leverage machine');
        case 'Bodyweight Only':
          return eq.contains('body weight') || eq.contains('assisted');
        default:
          return true;
      }
    }

    final currentLower = current.name.toLowerCase();
    final excludedLower = excludedNames
        .map((String s) => s.toLowerCase())
        .toSet();

    final candidates = allItems.where((ExerciseItem item) {
      if (item.muscle != current.muscle) return false;
      if (!matchesEquipment(item.equipment)) return false;
      if (item.name.toLowerCase() == currentLower) return false;
      return true;
    }).toList();

    // Prefer exercises not already present in the current workout session.
    final freshCandidates = candidates
        .where(
          (ExerciseItem item) => !excludedLower.contains(item.name.toLowerCase()),
        )
        .toList();

    final pool = freshCandidates.isNotEmpty ? freshCandidates : candidates;
    if (pool.isNotEmpty) {
      final chosen = pool.first;
      return current.copyWith(
        exerciseId: chosen.id,
        name: chosen.name,
        muscle: chosen.muscle,
        difficulty: chosen.difficulty,
        equipment: chosen.equipment,
      );
    }

    // Fallback when catalog is empty (e.g., isolated test without loaded asset)
    return _builtInFallbackSubstitute(current, equipmentChoice);
  }

  static RoutineExercise _builtInFallbackSubstitute(
    RoutineExercise current,
    String equipmentChoice,
  ) {
    final lower = current.name.toLowerCase();
    String replacement;
    if (lower.contains('push-up') || current.muscle == 'Chest') {
      if (equipmentChoice == 'Bodyweight Only') {
        replacement =
            lower == 'incline push-up' ? 'Decline Push-up' : 'Incline Push-up';
      } else if (equipmentChoice == 'Dumbbells') {
        replacement = 'Dumbbell Bench Press';
      } else {
        replacement = 'Cable Chest Press';
      }
    } else if (lower.contains('squat') || current.muscle == 'Legs') {
      if (equipmentChoice == 'Bodyweight Only') {
        replacement = lower == 'jump squat' ? 'Bodyweight Lunge' : 'Jump Squat';
      } else if (equipmentChoice == 'Dumbbells') {
        replacement = 'Dumbbell Goblet Squat';
      } else {
        replacement = 'Lever Leg Extension';
      }
    } else if (lower.contains('plank') || current.muscle == 'Core') {
      if (equipmentChoice == 'Bodyweight Only') {
        replacement = lower == 'air bike' ? '3/4 Sit-Up' : 'Air Bike';
      } else if (equipmentChoice == 'Dumbbells') {
        replacement = 'Kettlebell Windmill';
      } else {
        replacement = 'Lever Kneeling Twist';
      }
    } else {
      replacement = '${current.muscle} ($equipmentChoice)';
    }

    return current.copyWith(name: replacement, equipment: equipmentChoice);
  }
}
