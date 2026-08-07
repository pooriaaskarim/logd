// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;

import 'package:logd/logd.dart';
import 'package:sqlite3/sqlite3.dart';

class _PendingSqliteLog {
  const _PendingSqliteLog({
    required this.timestamp,
    required this.level,
    required this.levelName,
    required this.loggerName,
    required this.origin,
    required this.message,
    required this.createdAt,
    this.error,
    this.stackTrace,
    this.contextJson,
  });

  final String timestamp;
  final int level;
  final String levelName;
  final String loggerName;
  final String origin;
  final String message;
  final String? error;
  final String? stackTrace;
  final String? contextJson;
  final int createdAt;
}

/// A high-performance [LogSink] that persists structured logs to SQLite.
///
/// Features pre-compiled prepared statements, Write-Ahead Logging (WAL),
/// batch transaction commits ([batchSize], [flushInterval]), full entry field
/// fidelity (origin, error, stackTrace, context), retention pruning, and a rich
/// query engine.
base class SqliteSink extends LogSink<LogDocument> {
  /// Creates a [SqliteSink].
  ///
  /// - [dbPath]: SQLite database filepath (or `:memory:` for testing).
  /// - [database]: Optional existing [Database] instance.
  /// - [tableName]: Custom table name (default: `'logs'`).
  /// - [maxEntries]: Maximum number of log records retained.
  /// - [maxAge]: Maximum age of log records retained.
  /// - [batchSize]: Number of log entries to buffer before committing to
  ///   disk.

  /// - [flushInterval]: Periodic timer interval to flush pending log
  ///   entries.

  /// - [walMode]: Whether to enable Write-Ahead Logging for high write
  ///   throughput.

  SqliteSink({
    this.dbPath = 'logs.db',
    final Database? database,
    this.tableName = 'logs',
    this.maxEntries = 10000,
    this.maxAge,
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 2),
    this.walMode = true,
    super.enabled = true,
  })  : _db = database ?? sqlite3.open(dbPath),
        _batch = [] {
    _initDatabase();
    _startFlushTimer();
  }

  /// Filepath of the SQLite database.
  final String dbPath;

  /// Table name used to store log entries.
  final String tableName;

  /// Maximum log records retained before auto-pruning.
  final int? maxEntries;

  /// Maximum age of log records retained before auto-pruning.
  final Duration? maxAge;

  /// Number of log entries buffered in memory before committing a transaction.
  final int batchSize;

  /// Periodic timer interval to flush pending log entries.
  final Duration? flushInterval;

  /// Whether Write-Ahead Logging (WAL) is enabled.
  final bool walMode;

  final Database _db;
  final List<_PendingSqliteLog> _batch;
  Timer? _flushTimer;

  late final PreparedStatement _insertStmt;
  late final PreparedStatement? _pruneAgeStmt;
  late final PreparedStatement? _pruneCountStmt;

  void _initDatabase() {
    if (walMode && dbPath != ':memory:') {
      _db
        ..execute('PRAGMA journal_mode = WAL;')
        ..execute('PRAGMA synchronous = NORMAL;');
    }

    _db
      ..execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          level INTEGER NOT NULL,
          level_name TEXT NOT NULL,
          logger_name TEXT NOT NULL,
          origin TEXT NOT NULL,
          message TEXT NOT NULL,
          error TEXT,
          stack_trace TEXT,
          context_json TEXT,
          created_at INTEGER NOT NULL
        );
      ''')
      ..execute(
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_created '
        'ON $tableName (created_at);',
      )
      ..execute(
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_level '
        'ON $tableName (level);',
      )
      ..execute(
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_logger '
        'ON $tableName (logger_name);',
      );

    _insertStmt = _db.prepare('''
      INSERT INTO $tableName (
        timestamp, level, level_name, logger_name, origin, message, error,
        stack_trace, context_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');

    _pruneAgeStmt = maxAge != null
        ? _db.prepare('DELETE FROM $tableName WHERE created_at < ?;')
        : null;

    _pruneCountStmt = maxEntries != null
        ? _db.prepare('''
            DELETE FROM $tableName WHERE id NOT IN (
              SELECT id FROM $tableName ORDER BY id DESC LIMIT ?
            );
          ''')
        : null;
  }

  void _startFlushTimer() {
    if (flushInterval != null && flushInterval! > Duration.zero) {
      _flushTimer = Timer.periodic(flushInterval!, (final _) {
        flush();
      });
    }
  }

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    if (!enabled) {
      return;
    }

    final now = DateTime.now();
    final contextJson = (entry.context != null && entry.context!.isNotEmpty)
        ? convert.jsonEncode(entry.context)
        : null;

    final pending = _PendingSqliteLog(
      timestamp: now.toIso8601String(),
      level: level.index,
      levelName: level.name,
      loggerName: entry.loggerName,
      origin: entry.origin,
      message: entry.message,
      error: entry.error?.toString(),
      stackTrace: entry.stackTrace?.toString(),
      contextJson: contextJson,
      createdAt: now.millisecondsSinceEpoch,
    );

    _batch.add(pending);

    if (_batch.length >= batchSize) {
      await flush();
    }
  }

  /// Flushes all pending in-memory log entries to disk in a single transaction.
  Future<void> flush() async {
    if (_batch.isEmpty) {
      return;
    }

    final itemsToFlush = List<_PendingSqliteLog>.from(_batch);
    _batch.clear();

    _db.execute('BEGIN TRANSACTION;');
    try {
      for (final item in itemsToFlush) {
        _insertStmt.execute([
          item.timestamp,
          item.level,
          item.levelName,
          item.loggerName,
          item.origin,
          item.message,
          item.error,
          item.stackTrace,
          item.contextJson,
          item.createdAt,
        ]);
      }
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }

    _pruneLogs();
  }

  void _pruneLogs() {
    final now = DateTime.now();
    final pruneAge = _pruneAgeStmt;
    if (pruneAge != null && maxAge != null) {
      final cutoff = now.subtract(maxAge!).millisecondsSinceEpoch;
      pruneAge.execute([cutoff]);
    }

    final pruneCount = _pruneCountStmt;
    if (pruneCount != null && maxEntries != null) {
      pruneCount.execute([maxEntries]);
    }
  }

  /// Queries log records matching the specified search and filter criteria.
  List<Map<String, dynamic>> queryLogs({
    final LogLevel? minLevel,
    final String? loggerName,
    final String? search,
    final DateTime? start,
    final DateTime? end,
    final int limit = 100,
    final int offset = 0,
  }) {
    // Ensure any buffered logs are written before querying
    if (_batch.isNotEmpty) {
      flush();
    }

    final whereClauses = <String>[];
    final params = <Object?>[];

    if (minLevel != null) {
      whereClauses.add('level >= ?');
      params.add(minLevel.index);
    }

    if (loggerName != null && loggerName.isNotEmpty) {
      whereClauses.add('(logger_name = ? OR logger_name LIKE ?)');
      params
        ..add(loggerName)
        ..add('$loggerName.%');
    }

    if (search != null && search.isNotEmpty) {
      whereClauses.add(
        '(message LIKE ? OR error LIKE ? OR context_json LIKE ?)',
      );
      final term = '%$search%';
      params
        ..add(term)
        ..add(term)
        ..add(term);
    }

    if (start != null) {
      whereClauses.add('created_at >= ?');
      params.add(start.millisecondsSinceEpoch);
    }

    if (end != null) {
      whereClauses.add('created_at <= ?');
      params.add(end.millisecondsSinceEpoch);
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final sql = '''
      SELECT * FROM $tableName
      $whereSql
      ORDER BY id DESC
      LIMIT ? OFFSET ?;
    ''';

    params
      ..add(limit)
      ..add(offset);

    final ResultSet results = _db.select(sql, params);
    return results.map((final row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Backward-compatible fetch helper.
  List<Map<String, dynamic>> fetchLogs({final int limit = 100}) =>
      queryLogs(limit: limit);

  /// Returns a summary breakdown of stored log record counts per [LogLevel].
  Map<LogLevel, int> fetchLevelCounts() {
    if (_batch.isNotEmpty) {
      flush();
    }
    final ResultSet results = _db.select('''
      SELECT level, COUNT(*) as cnt
      FROM $tableName
      GROUP BY level;
    ''');
    final counts = <LogLevel, int>{};
    for (final row in results) {
      final idx = row['level'] as int;
      if (idx >= 0 && idx < LogLevel.values.length) {
        counts[LogLevel.values[idx]] = row['cnt'] as int;
      }
    }
    return counts;
  }

  /// Returns distinct logger names stored in the database with record counts.
  List<Map<String, dynamic>> fetchDistinctLoggerNames() {
    if (_batch.isNotEmpty) {
      flush();
    }
    final ResultSet results = _db.select('''
      SELECT logger_name, COUNT(*) as record_count
      FROM $tableName
      GROUP BY logger_name
      ORDER BY record_count DESC;
    ''');
    return results.map((final row) => Map<String, dynamic>.from(row)).toList();
  }


  /// Returns total count of log records currently stored in the database.
  int count() {
    if (_batch.isNotEmpty) {
      flush();
    }
    final ResultSet results =
        _db.select('SELECT COUNT(*) as cnt FROM $tableName;');
    return results.first['cnt'] as int;
  }

  /// Deletes all log records stored in the database table.
  void clear() {
    _batch.clear();
    _db.execute('DELETE FROM $tableName;');
  }

  /// Compacts the database storage file.
  void vacuum() {
    if (_batch.isNotEmpty) {
      flush();
    }
    _db.execute('VACUUM;');
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();

    _insertStmt.dispose();
    _pruneAgeStmt?.dispose();
    _pruneCountStmt?.dispose();
    _db.dispose();

    await super.dispose();
  }
}
