# logd_sqlite

[![pub package](https://img.shields.io/pub/v/logd_sqlite.svg)](https://pub.dev/packages/logd_sqlite)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A high-performance SQLite persistence log sink for [`logd`](https://pub.dev/packages/logd).

Features pre-compiled prepared statements, Write-Ahead Logging (WAL mode), atomic transaction batching, full log field fidelity (`origin`, `error`, `stackTrace`, `context`), auto-pruning retention policies (`maxEntries`, `maxAge`), and a rich query engine.

## Installation

Add `logd_sqlite` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.2
  logd_sqlite: ^0.1.0
```

## Basic Usage

```dart
import 'package:logd/logd.dart';
import 'package:logd_sqlite/logd_sqlite.dart';

void main() async {
  final sqliteSink = SqliteSink(
    dbPath: 'app_logs.db',
    maxEntries: 10000,
    maxAge: const Duration(days: 7),
    batchSize: 50,
    flushInterval: const Duration(seconds: 2),
    walMode: true,
  );

  Logger.configure(
    handlers: [
      Handler(
        formatter: const PlainFormatter(),
        sink: sqliteSink,
      ),
    ],
  );

  final logger = Logger.get('app.service');
  logger.info(
    'Payment processed',
    context: {'transactionId': 'TX-1002', 'amount': 99.99},
  );

  // Querying logs
  final errorLogs = sqliteSink.queryLogs(
    minLevel: LogLevel.warning,
    search: 'Payment',
    limit: 50,
  );
}
```

## Advanced Query Engine & Inspection

`SqliteSink` provides a built-in search and filter engine along with metadata discovery helpers for developer dashboards:

```dart
// Rich Query Engine
final logs = sqliteSink.queryLogs(
  minLevel: LogLevel.warning,         // Filter by minimum LogLevel
  loggerName: 'app.auth',              // Filter by logger namespace hierarchy
  search: 'token expired',             // Full-text search across message & error
  start: DateTime.now().subtract(const Duration(hours: 1)), // Start window
  end: DateTime.now(),                 // End window
  limit: 100,
  offset: 0,
);

// Level Count Summary
final levelCounts = sqliteSink.fetchLevelCounts();
// Map<LogLevel, int> -> {LogLevel.info: 20, LogLevel.warning: 5, ...}

// Discover Logger Namespaces
final loggerNamespaces = sqliteSink.fetchDistinctLoggerNames();
// List<Map<String, dynamic>> -> [{'logger_name': 'app.auth', 'record_count': 14}, ...]
```

## Maintenance Utilities

```dart
// Total log count
final count = sqliteSink.count();

// Manual transaction flush
await sqliteSink.flush();

// Clear all logs
sqliteSink.clear();

// Vacuum database file
sqliteSink.vacuum();
```

## Executable Examples

The package includes interactive and automated CLI examples:

* **[sqlite_interactive_dashboard.dart](example/sqlite_interactive_dashboard.dart)**:
  An interactive REPL dashboard allowing real-time log ingestion, level filtering, namespace discovery, single-record inspection, and write throughput benchmarking.
  ```bash
  dart run example/sqlite_interactive_dashboard.dart
  ```

* **[sqlite_sink_showcase.dart](example/sqlite_sink_showcase.dart)**:
  A non-interactive telemetry simulation and proof-of-concept tour.
  ```bash
  dart run example/sqlite_sink_showcase.dart
  ```

## License

BSD-3-Clause
