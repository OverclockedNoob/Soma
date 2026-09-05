import 'package:flutter/material.dart';
import '../services/exercisedb_service.dart';

class ExerciseData {
  /// Returns the full list of exercises from the API cache
  static List<Map<String, dynamic>> get allExercises {
    final apiExercises = ExerciseDbService.getCached();

    final merged = apiExercises.map((ex) {
      return {
        'name': ex.name,
        'muscle': ex.muscleCategory,
        'difficulty': ex.difficulty,
        'gifUrl': ex.gifUrl,
        'instructions': ex.instructions,
        'equipment': ex.equipment,
        'target': ex.target,
      };
    }).toList();

    // Sort alphabetically
    merged.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return merged;
  }

  static Color getMuscleColor(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return const Color(0xFFFF6B9D);
      case 'Back':
        return const Color(0xFF00D9FF);
      case 'Legs':
        return const Color(0xFFFFB800);
      case 'Arms':
        return const Color(0xFF6C5CE7);
      case 'Shoulders':
        return const Color(0xFF00E5FF); // New cyan for shoulders
      case 'Core':
        return const Color(0xFF9B59B6);
      case 'Cardio':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF6C5CE7);
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
        return Icons.fitness_center;
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

  static int getCountForCategory(String category) {
    final exercises = allExercises;
    if (category == 'All') return exercises.length;
    return exercises.where((e) => e['muscle'] == category).length;
  }
}