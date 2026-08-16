// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logd/logd.dart';

/// Web/WASM fallback stub for [SqliteSink].
///
/// On Web / WASM environments without native FFI (`dart:ffi`), [SqliteSink]
/// throws an [UnsupportedError].
base class SqliteSink extends LogSink<LogDocument> {
  SqliteSink({
    this.dbPath = 'logs.db',
    final Object? database,
    this.tableName = 'logs',
    this.maxEntries = 10000,
    this.maxAge,
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 2),
    this.walMode = true,
    super.enabled = true,
  }) {
    throw UnsupportedError(
      'SqliteSink is not supported on Web/WASM without native FFI (dart:ffi).',
    );
  }

  final String dbPath;
  final String tableName;
  final int? maxEntries;
  final Duration? maxAge;
  final int batchSize;
  final Duration? flushInterval;
  final bool walMode;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    throw UnsupportedError('SqliteSink requires native FFI.');
  }

  Future<void> flush() async {}

  List<Map<String, dynamic>> queryLogs({
    final LogLevel? minLevel,
    final String? loggerName,
    final String? search,
    final DateTime? start,
    final DateTime? end,
    final int limit = 100,
    final int offset = 0,
  }) {
    throw UnsupportedError('SqliteSink requires native FFI.');
  }

  List<Map<String, dynamic>> fetchLogs({final int limit = 100}) => [];

  Map<LogLevel, int> fetchLevelCounts() => {};

  List<Map<String, dynamic>> fetchDistinctLoggerNames() => [];

  int count() => 0;

  void clear() {}

  void vacuum() {}
}
