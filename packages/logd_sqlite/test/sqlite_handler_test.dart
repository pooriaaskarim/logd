// ignore_for_file: invalid_use_of_internal_member

import 'dart:io';

import 'package:logd/logd.dart';
import 'package:logd_sqlite/logd_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    registerLogdSqliteSerializers();
  });

  group('SqliteHandler (ADR-006)', () {
    late Directory tempDir;
    late String testDbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('logd_sqlite_test_');
      testDbPath = '${tempDir.path}/handler_test.db';
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('SqliteHandler.inMemory creates a valid Handler pipeline', () async {
      final handler = SqliteHandler.inMemory(
        batchSize: 1, // Flush immediately
      );

      expect(handler, isA<Handler>());
      expect(handler.formatter, isA<StructuredFormatter>());
      expect(handler.sink, isA<SqliteSink>());

      final entry = LogEntry(
        loggerName: 'test.sqlite_handler',
        origin: 'sqlite_handler_test.dart',
        level: LogLevel.info,
        message: 'Pre-wired SqliteHandler test',
        timestamp: '2026-08-16 12:00:00.000',
      );

      await handler.log(entry);

      final records = handler.sqliteSink.queryLogs();
      expect(records.length, equals(1));
      expect(records.first['message'], equals('Pre-wired SqliteHandler test'));

      await handler.dispose();
    });

    test('SqliteHandler.database wraps existing Database instance', () async {
      final db = sqlite3.openInMemory();
      final handler = SqliteHandler.database(
        database: db,
        batchSize: 1,
      );

      final entry = LogEntry(
        loggerName: 'test.db_wrapper',
        origin: 'sqlite_handler_test.dart',
        level: LogLevel.warning,
        message: 'Wrapped DB event',
        timestamp: '2026-08-16 12:00:00.000',
      );

      await handler.log(entry);

      expect(handler.sqliteSink.count(), equals(1));
      await handler.dispose();
    });

    test('SqliteHandler.async creates a background isolate handler', () async {
      final handler = SqliteHandler.async(
        path: testDbPath,
        batchSize: 1,
      );

      expect(handler, isA<AsyncHandler>());

      Logger.configure('test.sqlite_async', handlers: [handler]);
      final logger = Logger.get('test.sqlite_async');

      await handler.ready;

      logger.info('Async SQLite log entry');

      await handler.dispose();
      await Future.delayed(const Duration(milliseconds: 100));

      final file = File(testDbPath);
      expect(file.existsSync(), isTrue);

      final db = sqlite3.open(testDbPath);
      final results = db.select('SELECT * FROM logs;');
      expect(results.length, equals(1));
      expect(results.first['message'], equals('Async SQLite log entry'));
      db.close();
    });
  });
}
