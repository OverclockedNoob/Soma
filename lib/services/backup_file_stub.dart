// Web / non-IO fallback for local backup file persistence.

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
  return null;
}

Future<List<LocalBackupFileEntry>> listBackupFiles() async {
  return const <LocalBackupFileEntry>[];
}

Future<String> readBackupFile(String path) {
  throw UnsupportedError('Direct file-system access is unavailable on Web.');
}
