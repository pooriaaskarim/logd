// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

import 'sqlite_sink.dart';

/// Web/WASM fallback stub for [SqliteHandler].
@immutable
class SqliteHandler extends Handler {
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

  SqliteHandler.database({
    required final Object database,
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

  SqliteSink get sqliteSink => sink as SqliteSink;
}
