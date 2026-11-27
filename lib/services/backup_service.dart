import 'dart:convert';

import '../core/event_bus.dart';
import 'backup_file_stub.dart'
    if (dart.library.io) 'backup_file_io.dart'
    as file_ops;
import 'storage_services.dart';

export 'backup_file_stub.dart'
    if (dart.library.io) 'backup_file_io.dart'
    show LocalBackupFileEntry;

class BackupExportResult {
  final String json;
  final String? savedFilePath;

  const BackupExportResult({
    required this.json,
    required this.savedFilePath,
  });
}

class BackupRestoreSummary {
  final int workoutsRestored;
  final int routinesRestored;
  final int splitsRestored;

  const BackupRestoreSummary({
    required this.workoutsRestored,
    required this.routinesRestored,
    required this.splitsRestored,
  });
}

/// Cross-platform JSON backup export & restore service (safe on Mobile,
/// Desktop, and Web via conditional `dart:io` imports + Clipboard JSON).
class BackupService {
  BackupService._();

  static Map<String, dynamic> buildBackupPayload() {
    return <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'workouts': WorkoutStorage.getAllWorkouts(),
      'programs': ProgramStorage.getAllPrograms(),
      'activeProgramId': SettingsStorage.getActiveProgramId(),
      'customWorkouts': CustomWorkoutStorage.getAllCustomWorkouts(),
      'settings': <String, dynamic>{
        'userName': SettingsStorage.getUserName(),
        'userTitle': SettingsStorage.getUserTitle(),
        'notifications': SettingsStorage.getNotifications(),
        'soundEffects': SettingsStorage.getSoundEffects(),
        'recoveryCoins': SettingsStorage.getRecoveryCoins(),
        'frozenDates': SettingsStorage.getFrozenDates(),
        'weight': SettingsStorage.getWeight(),
        'age': SettingsStorage.getAge(),
      },
    };
  }

  static String createBackupJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(buildBackupPayload());
  }

  static Future<BackupExportResult> exportBackup() async {
    final json = createBackupJson();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'Soma_Backup_$stamp.json';
    final path = await file_ops.writeBackupFile(fileName, json);
    return BackupExportResult(json: json, savedFilePath: path);
  }

  static Future<List<file_ops.LocalBackupFileEntry>> listLocalBackups() {
    return file_ops.listBackupFiles();
  }

  static Future<BackupRestoreSummary> restoreFromFile(String path) async {
    final raw = await file_ops.readBackupFile(path);
    return restoreFromJson(raw);
  }

  static Future<BackupRestoreSummary> restoreFromJson(String rawJson) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Backup JSON cannot be empty.');
    }

    final Object? decoded = jsonDecode(trimmed);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Backup root must be a JSON object.');
    }

    const expectedKeys = <String>{
      'workouts',
      'programs',
      'customWorkouts',
      'settings',
    };
    if (!decoded.keys
        .map((Object? k) => k.toString())
        .any(expectedKeys.contains)) {
      throw const FormatException(
        'JSON does not appear to be a valid Soma backup.',
      );
    }

    List<Map<String, dynamic>> parseMapList(Object? rawList, String fieldName) {
      if (rawList == null) return <Map<String, dynamic>>[];
      if (rawList is! List<Object?>) {
        throw FormatException('Field "$fieldName" must be a JSON list.');
      }
      return rawList
          .whereType<Map<Object?, Object?>>()
          .map(
            (Map<Object?, Object?> m) => <String, dynamic>{
              for (final MapEntry<Object?, Object?> kv in m.entries)
                kv.key.toString(): kv.value,
            },
          )
          .toList();
    }

    final workouts = parseMapList(decoded['workouts'], 'workouts');
    final routines = parseMapList(decoded['customWorkouts'], 'customWorkouts');
    final programs = parseMapList(decoded['programs'], 'programs');
    final activeProgramId = decoded['activeProgramId']?.toString();

    final rawSettings = decoded['settings'];
    if (rawSettings != null && rawSettings is! Map<Object?, Object?>) {
      throw const FormatException('Field "settings" must be a JSON object.');
    }

    // All validation passed — apply mutations to Hive boxes.
    await WorkoutStorage.replaceAll(workouts, notify: false);
    await CustomWorkoutStorage.replaceAll(routines, notify: false);
    await ProgramStorage.replaceAll(
      programs,
      activeProgramId: activeProgramId,
      notify: false,
    );

    if (rawSettings is Map<Object?, Object?>) {
      final userName = rawSettings['userName']?.toString().trim();
      if (userName != null && userName.isNotEmpty) {
        await SettingsStorage.setUserName(userName);
      }
      final userTitle = rawSettings['userTitle']?.toString().trim();
      if (userTitle != null && userTitle.isNotEmpty) {
        await SettingsStorage.setUserTitle(userTitle);
      }
      final notifications = rawSettings['notifications'];
      if (notifications is bool) {
        await SettingsStorage.setNotifications(notifications);
      }
      final soundEffects = rawSettings['soundEffects'];
      if (soundEffects is bool) {
        await SettingsStorage.setSoundEffects(soundEffects);
      }
      final coins = rawSettings['recoveryCoins'];
      if (coins is num) {
        await SettingsStorage.setRecoveryCoins(coins.toInt(), notify: false);
      }
      final frozen = rawSettings['frozenDates'];
      if (frozen is List<Object?>) {
        await SettingsStorage.setFrozenDates(
          frozen.map((Object? e) => e.toString()).toList(),
          notify: false,
        );
      }
      final weight = rawSettings['weight'];
      if (weight is num && weight.toInt() > 0) {
        await SettingsStorage.setWeight(weight.toInt());
      }
      final age = rawSettings['age'];
      if (age is num && age.toInt() > 0) {
        await SettingsStorage.setAge(age.toInt());
      }
    }

    WorkoutEventBus.instance.notifyWorkoutChanged();

    return BackupRestoreSummary(
      workoutsRestored: workouts.length,
      routinesRestored: routines.length,
      splitsRestored: programs.length,
    );
  }
}
