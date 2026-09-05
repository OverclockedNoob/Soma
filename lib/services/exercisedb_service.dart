import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

// ── MODEL ────────────────────────────────────────────────────
class ExerciseDbExercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String gifUrl;
  final List<String> instructions;

  ExerciseDbExercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.gifUrl,
    required this.instructions,
  });

  static String _extractMedia(Map<String, dynamic> json) {
    const keys = [
      'gifUrl', 'gifURL', 'gif_url', 'gif',
      'imageUrl', 'imageURL', 'image', 'imgUrl', 'img',
      'animation', 'videoUrl', 'video', 'demonstration',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  factory ExerciseDbExercise.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? 'Unknown';
    final prettyName = rawName
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');

    return ExerciseDbExercise(
      id: json['id']?.toString() ?? '',
      name: prettyName,
      bodyPart: json['bodyPart'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      target: json['target'] as String? ?? '',
      gifUrl: _extractMedia(json),
      instructions:
          (json['instructions'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'target': target,
        'gifUrl': gifUrl,
        'instructions': instructions,
      };

  String get muscleCategory {
    switch (bodyPart) {
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

  String get difficulty {
    if (equipment.contains('body weight') || equipment.contains('assisted')) {
      return 'Beginner';
    }
    if (equipment.contains('barbell') || equipment.contains('band')) {
      return 'Intermediate';
    }
    return 'Intermediate';
  }
}

// ── SERVICE: 100% LOCAL — ZERO NETWORK, ZERO KEY, ZERO QUOTA ──
class ExerciseDbService {
  static const String _assetPath = 'assets/exercises.json';
  static List<ExerciseDbExercise>? _memoryCache;

  static Future<void> init() async {
    if (_memoryCache != null) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final list = jsonDecode(raw) as List;
      _memoryCache = list
          .map((e) =>
              ExerciseDbExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      debugPrint(
          '✅ ExerciseDB: ${_memoryCache!.length} exercises loaded from bundled asset (offline!)');
    } catch (e) {
      debugPrint('❌ ExerciseDB asset error: $e');
      _memoryCache = [];
    }
  }

  static List<ExerciseDbExercise> getCached() => _memoryCache ?? const [];
}