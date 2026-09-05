import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'lib/config/api_keys.dart';

Future<void> main() async {
  final all = <Map<String, dynamic>>[];
  final seen = <String>{};
  const pageSize = 10;
  const maxPages = 50;

  for (int page = 0; page < maxPages; page++) {
    final uri = Uri.https(
      ApiKeys.exercisedbHost,
      '/exercises',
      {'limit': '$pageSize', 'offset': '${page * pageSize}'},
    );

    final res = await http.get(uri, headers: {
      'x-rapidapi-key': ApiKeys.exercisedbKey,
      'x-rapidapi-host': ApiKeys.exercisedbHost,
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      print('⚠️ page $page: status ${res.statusCode} — stopping');
      break;
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List || decoded.isEmpty) break;

    int newCount = 0;
    for (final e in decoded) {
      final id = (e as Map)['id']?.toString() ?? '';
      if (seen.add(id)) {
        all.add(Map<String, dynamic>.from(e));
        newCount++;
      }
    }

    print('page $page: ${decoded.length} fetched ($newCount new)');
    if (newCount == 0 || decoded.length < pageSize) break;
  }

  if (all.isEmpty) {
    print('❌ Nothing fetched. Check key/quota.');
    exit(1);
  }

  final dir = Directory('assets');
  if (!dir.existsSync()) dir.createSync();
  File('assets/exercises.json').writeAsStringSync(jsonEncode(all));
  print('✅ Wrote ${all.length} exercises to assets/exercises.json');
}