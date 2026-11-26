import 'package:flutter/material.dart';

import '../models/workout_models.dart';
import '../services/exercise_service.dart';

class ExerciseData {
  ExerciseData._();

  /// Pre-sorted, immutable list of all 500 local exercises (O(1) access).
  static List<ExerciseItem> get items => ExerciseService.allItems;

  /// Legacy map view backed by the memoized cache in [ExerciseService].
  static List<Map<String, dynamic>> get allExercises =>
      ExerciseService.allLegacyMaps;

  static Color getMuscleColor(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return const Color(0xFFFF6B9D);
      case 'Back':
        return const Color(0xFF00D9FF);
      case 'Legs':
        return const Color(0xFFFFB800);
      case 'Arms':
        return const Color(0xFF8B7CFF);
      case 'Shoulders':
        return const Color(0xFF3DDCB8);
      case 'Core':
        return const Color(0xFF9B59B6);
      case 'Cardio':
        return const Color(0xFFFF6B4A);
      default:
        return const Color(0xFF8B7CFF);
    }
  }

  static IconData getMuscleIcon(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return Icons.favorite;
      case 'Back':
        return Icons.accessibility_new;
      case 'Legs':
        return Icons.directions_run;
      case 'Arms':
        return Icons.fitness_center;
      case 'Shoulders':
        return Icons.sports_gymnastics;
      case 'Core':
        return Icons.self_improvement;
      case 'Cardio':
        return Icons.directions_bike;
      default:
        return Icons.fitness_center;
    }
  }

  static Color getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return const Color(0xFF4CAF50);
      case 'Intermediate':
        return const Color(0xFFFF9800);
      case 'Advanced':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  static IconData getDifficultyIcon(String? difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Icons.trending_down;
      case 'Intermediate':
        return Icons.trending_flat;
      case 'Advanced':
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
  }

  static int getCountForCategory(String category) =>
      ExerciseService.countForCategory(category);
}
