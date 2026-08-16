// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_sink.dart';

/// A pre-wired [Handler] that persists logs to a SQLite database (ADR-006).
@immutable
class SqliteHandler extends Handler {
  /// Creates a [SqliteHandler] writing to the SQLite database at [path].
  SqliteHandler({
    required final String path,
    final String tableName = 'logs',
    final int batchSize = 50,
    final Duration flushInterval = const Duration(seconds: 2),
    final int? maxEntries,
    final Duration? maxAge,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    super.filters = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) : super(
          formatter: formatter ?? const StructuredFormatter(),
          sink: SqliteSink(
            dbPath: path,
            tableName: tableName,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxEntries: maxEntries ?? 10000,
            maxAge: maxAge,
          ),
          decorators: decorators ?? const [],
        );

  /// Creates a [SqliteHandler] using an in-memory SQLite database.
  SqliteHandler.inMemory({
    final String tableName = 'logs',
    final int batchSize = 50,
    final Duration flushInterval = const Duration(seconds: 2),
    final int? maxEntries,
    final Duration? maxAge,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    super.filters = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) : super(
          formatter: formatter ?? const StructuredFormatter(),
          sink: SqliteSink(
            dbPath: ':memory:',
            tableName: tableName,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxEntries: maxEntries ?? 10000,
            maxAge: maxAge,
          ),
          decorators: decorators ?? const [],
        );

  /// Creates a [SqliteHandler] using an existing [Database] instance.
  SqliteHandler.database({
    required final Database database,
    final String tableName = 'logs',
    final int batchSize = 50,
    final Duration flushInterval = const Duration(seconds: 2),
    final int? maxEntries,
    final Duration? maxAge,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    super.filters = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) : super(
          formatter: formatter ?? const StructuredFormatter(),
          sink: SqliteSink(
            database: database,
            tableName: tableName,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxEntries: maxEntries ?? 10000,
            maxAge: maxAge,
          ),
          decorators: decorators ?? const [],
        );

  /// Access to the underlying [SqliteSink] for query engine operations.
  SqliteSink get sqliteSink => sink as SqliteSink;
}
