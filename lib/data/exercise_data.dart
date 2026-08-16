import 'package:flutter/material.dart';

class ExerciseData {
  static const List<Map<String, String>> allExercises = [
    {"name": "Bicep Curls", "muscle": "Arms", "difficulty": "Beginner"},
    {
      "name": "Diamond Push-ups",
      "muscle": "Chest",
      "difficulty": "Intermediate",
    },
    {"name": "Hammer Curls", "muscle": "Arms", "difficulty": "Beginner"},
    {"name": "Tricep Dips", "muscle": "Arms", "difficulty": "Intermediate"},
    {"name": "Burpees", "muscle": "Cardio", "difficulty": "Intermediate"},
    {"name": "High Knees", "muscle": "Cardio", "difficulty": "Beginner"},
    {"name": "Jump Rope", "muscle": "Cardio", "difficulty": "Beginner"},
    {"name": "Running", "muscle": "Cardio", "difficulty": "Beginner"},
    {"name": "Chin-ups", "muscle": "Back", "difficulty": "Intermediate"},
    {"name": "Lat Pulldown", "muscle": "Back", "difficulty": "Beginner"},
    {"name": "Pull-ups", "muscle": "Back", "difficulty": "Intermediate"},
    {"name": "Crunches", "muscle": "Core", "difficulty": "Beginner"},
    {
      "name": "Mountain Climbers",
      "muscle": "Core",
      "difficulty": "Intermediate",
    },
    {"name": "Plank", "muscle": "Core", "difficulty": "Beginner"},
    {"name": "Russian Twists", "muscle": "Core", "difficulty": "Intermediate"},
    {"name": "Jump Squats", "muscle": "Legs", "difficulty": "Intermediate"},
    {"name": "Lunges", "muscle": "Legs", "difficulty": "Beginner"},
    {"name": "Squats", "muscle": "Legs", "difficulty": "Beginner"},
    {"name": "Push-ups", "muscle": "Chest", "difficulty": "Beginner"},
    {"name": "Wide Push-ups", "muscle": "Chest", "difficulty": "Beginner"},
  ];

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
    if (category == 'All') return allExercises.length;
    return allExercises.where((e) => e['muscle'] == category).length;
  }
}
