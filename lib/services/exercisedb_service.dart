import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// ── MODEL ─────────────────────────────────────────────────────
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

  /// Checks 13 possible key names for media — catches any naming variant
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

// ── SERVICE ───────────────────────────────────────────────────
class ExerciseDbService {
  static const String _boxName = 'exercisedb_cache';
  static const String _dataKey = 'exercises';
  static const String _timeKey = 'fetched_at';

  static List<ExerciseDbExercise>? _memoryCache;
  static bool _printedKeys = false;

  static Future<void> init() async => await Hive.openBox(_boxName);
  static Box get _box => Hive.box(_boxName);

  static Map<String, String> get _headers => {
        'x-rapidapi-key': ApiKeys.exercisedbKey,
        'x-rapidapi-host': ApiKeys.exercisedbHost,
      };

  static List<ExerciseDbExercise> getCached() {
    if (_memoryCache != null) return _memoryCache!;
    final raw = _box.get(_dataKey);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw as String);
      _memoryCache = list
          .map((e) =>
              ExerciseDbExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return _memoryCache!;
    } catch (e) {
      debugPrint('ExerciseDbService.getCached error: $e');
      return [];
    }
  }

  static bool get isStale {
    final t = _box.get(_timeKey);
    if (t == null) return true;
    final fetched = DateTime.fromMillisecondsSinceEpoch(t as int);
    return DateTime.now().difference(fetched).inDays >= 7;
  }

  /// Strategy 1: paginate the BASE endpoint (biggest source)
  static Future<List<ExerciseDbExercise>> _fetchBasePaginated() async {
    final seen = <String, ExerciseDbExercise>{};
    const pageSize = 10;
    const maxPages = 50;

    for (int page = 0; page < maxPages; page++) {
      final uri = Uri.https(
        ApiKeys.exercisedbHost,
        '/exercises',
        {'limit': '$pageSize', 'offset': '${page * pageSize}'},
      );

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) break;

      final List<dynamic> data = jsonDecode(res.body);
      if (data.isEmpty) break;

      // 🕵️ ONE-TIME truth print: the API's actual field names
      if (!_printedKeys) {
        _printedKeys = true;
        debugPrint('🔑 API FIELDS: ${(data.first as Map).keys.toList()}');
      }

      int newCount = 0;
      for (final e in data) {
        final ex =
            ExerciseDbExercise.fromJson(Map<String, dynamic>.from(e as Map));
        if (!seen.containsKey(ex.id)) {
          seen[ex.id] = ex;
          newCount++;
        }
      }

      if (newCount == 0) break;
      if (data.length < pageSize) break;
    }

    return seen.values.toList();
  }

  /// Strategy 2: bodyPart endpoints (fallback)
  static Future<List<ExerciseDbExercise>> _fetchByBodyPart() async {
    final bodyParts = [
      'back', 'cardio', 'chest', 'lower arms', 'lower legs',
      'shoulders', 'upper arms', 'upper legs', 'waist',
    ];

    final all = <ExerciseDbExercise>[];
    for (final part in bodyParts) {
      final seen = <String, ExerciseDbExercise>{};
      const pageSize = 10;
      const maxPages = 5;

      for (int page = 0; page < maxPages; page++) {
        final uri = Uri.https(
          ApiKeys.exercisedbHost,
          '/exercises/bodyPart/$part',
          {'limit': '$pageSize', 'offset': '${page * pageSize}'},
        );

        final res = await http.get(uri, headers: _headers);
        if (res.statusCode != 200) break;

        final List<dynamic> data = jsonDecode(res.body);
        if (data.isEmpty) break;

        int newCount = 0;
        for (final e in data) {
          final ex =
              ExerciseDbExercise.fromJson(Map<String, dynamic>.from(e as Map));
          if (!seen.containsKey(ex.id)) {
            seen[ex.id] = ex;
            newCount++;
          }
        }

        if (newCount == 0) break;
        if (data.length < pageSize) break;
      }

      all.addAll(seen.values);
      debugPrint('✅ $part: ${seen.length} exercises');
    }
    return all;
  }

  static Future<List<ExerciseDbExercise>> fetchAndCache() async {
    List<ExerciseDbExercise> result = [];

    try {
      final base = await _fetchBasePaginated();
      final withGif = base.where((e) => e.gifUrl.isNotEmpty).length;
      debugPrint('🎬 BASE ENDPOINT: ${base.length} exercises, $withGif with GIFs');
      if (base.isNotEmpty) result = base; // base = biggest source
    } catch (e) {
      debugPrint('❌ Base fetch error: $e');
    }

    if (result.isEmpty) {
      result = await _fetchByBodyPart();
    }

    if (result.isEmpty) {
      throw Exception('Failed to fetch any exercises from API');
    }

    final uniqueMap = {for (var ex in result) ex.id: ex};
final uniqueList = uniqueMap.values.toList();
    await _box.put(_dataKey, jsonEncode(uniqueList.map((e) => e.toJson()).toList()));
    await _box.put(_timeKey, DateTime.now().millisecondsSinceEpoch);
    _memoryCache = uniqueList;
    debugPrint('✅ ExerciseDB: cached ${uniqueList.length} unique exercises');

    return uniqueList;
  }

  static Future<List<ExerciseDbExercise>> load() async {
    final cached = getCached();
    if (cached.isNotEmpty && !isStale) return cached;
    try {
      return await fetchAndCache();
    } catch (e) {
      debugPrint('ExerciseDbService.load error: $e');
      return cached;
    }
  }
}