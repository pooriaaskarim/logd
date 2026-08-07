// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';
import 'package:logd_sqlite/logd_sqlite.dart';

void main() async {
  // 1. Initialize SQLite persistence sink
  final sqliteSink = SqliteSink(
    dbPath: 'example_logs.db',
    maxEntries: 1000,
    maxAge: const Duration(days: 7),
    batchSize: 20,
    flushInterval: const Duration(seconds: 1),
    walMode: true,
  );

  // 2. Configure logd pipeline with SqliteSink
  Logger.configure(
    'global',
    handlers: [
      Handler(
        formatter: const PlainFormatter(),
        sink: sqliteSink,
      ),
    ],
  );

  // 3. Emit structured logs
  Logger.get('app.payment')
    ..info(
      'Processing payment',
      context: const {'transactionId': 'TX-9042', 'amount': 250.00},
    )
    ..warning(
      'Payment latency spike',
      context: const {'durationMs': 1250},
    );

  // Flush buffer to SQLite database
  await sqliteSink.flush();

  // 4. Query & Filter logs
  final warningLogs = sqliteSink.queryLogs(
    minLevel: LogLevel.warning,
    search: 'Payment',
    limit: 10,
  );
  print('Found ${warningLogs.length} warning logs.');

  // 5. Inspect database stats & cleanup
  final counts = sqliteSink.fetchLevelCounts();
  print('Level breakdown: $counts');

  await sqliteSink.dispose();
}
