import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalBackupFileEntry {
  final String name;
  final String path;
  final DateTime modifiedAt;

  const LocalBackupFileEntry({
    required this.name,
    required this.path,
    required this.modifiedAt,
  });
}

Future<String?> writeBackupFile(String fileName, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}

Future<List<LocalBackupFileEntry>> listBackupFiles() async {
  final dir = await getApplicationDocumentsDirectory();
  if (!dir.existsSync()) return const <LocalBackupFileEntry>[];

  final entries = <LocalBackupFileEntry>[];
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.isEmpty
        ? ''
        : entity.uri.pathSegments.last;
    if (name.startsWith('Soma_Backup_') && name.endsWith('.json')) {
      entries.add(
        LocalBackupFileEntry(
          name: name,
          path: entity.path,
          modifiedAt: entity.lastModifiedSync(),
        ),
      );
    }
  }

  entries.sort(
    (LocalBackupFileEntry a, LocalBackupFileEntry b) =>
        b.modifiedAt.compareTo(a.modifiedAt),
  );
  return entries;
}

Future<String> readBackupFile(String path) async {
  return File(path).readAsString();
}
