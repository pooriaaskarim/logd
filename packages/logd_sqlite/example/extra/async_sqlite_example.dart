import 'dart:io';

import 'package:logd/logd.dart';
import 'package:logd_sqlite/logd_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';

void main() async {
  registerLogdSqliteSerializers();

  const dbPath = 'async_telemetry.db';

  final handler = SqliteHandler.async(
    path: dbPath,
    batchSize: 5,
    maxEntries: 1000,
    maxAge: const Duration(days: 7),
  );

  Logger.configure('telemetry', handlers: [handler]);
  final logger = Logger.get('telemetry');

  print('Emitting logs asynchronously to $dbPath...');
  for (var i = 1; i <= 20; i++) {
    logger.info('Background telemetry record #$i', context: {'index': i});
  }

  await handler.dispose();

  // Read back written logs using sqlite3
  final db = sqlite3.open(dbPath);
  final count = db.select('SELECT COUNT(*) as cnt FROM logs;').first['cnt'];
  print('Persisted $count logs successfully.');
  db.close();

  // Cleanup
  File(dbPath).deleteSync();
}
