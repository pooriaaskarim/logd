# logd_sqlite

[![pub package](https://img.shields.io/pub/v/logd_sqlite.svg)](https://pub.dev/packages/logd_sqlite)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A high-performance SQLite persistence log sink for [`logd`](https://pub.dev/packages/logd).

Features pre-compiled prepared statements, Write-Ahead Logging (WAL mode), atomic transaction batching, full log field fidelity (`origin`, `error`, `stackTrace`, `context`), auto-pruning retention policies (`maxEntries`, `maxAge`), and a rich query engine.

---

## Installation

Add `logd` and `logd_sqlite` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.2
  logd_sqlite: ^0.1.0
```

### Platform & Native Setup

`logd_sqlite` relies on standard `package:sqlite3` dynamic library bindings:

* **Flutter (Android / iOS / macOS / Windows / Linux)**: Add `sqlite3_flutter_libs` to your `pubspec.yaml` to bundle native SQLite binaries.
* **Pure Dart CLI / Server**: Uses system SQLite libraries (e.g. `libsqlite3.so` on Linux, `libsqlite3.dylib` on macOS).

---

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
    'Payment processed successfully',
    context: {'transactionId': 'TX-1002', 'amount': 99.99},
  );

  // Querying stored logs
  final errorLogs = sqliteSink.queryLogs(
    minLevel: LogLevel.warning,
    search: 'Payment',
    limit: 50,
  );

  // Flush and dispose handle on app exit
  await sqliteSink.dispose();
}
```

---

## Configuration Reference

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `dbPath` | `String` | `'logs.db'` | Path to SQLite database file (or `:memory:` for testing). |
| `tableName` | `String` | `'logs'` | SQL table name for log records. |
| `maxEntries` | `int?` | `10000` | Capped record count retained before auto-pruning. |
| `maxAge` | `Duration?` | `null` | Maximum age of log records before auto-pruning. |
| `batchSize` | `int` | `50` | Number of log entries buffered before committing transaction. |
| `flushInterval` | `Duration?` | `2 seconds` | Interval timer to flush pending memory buffer. |
| `walMode` | `bool` | `true` | Enables Write-Ahead Logging for high write throughput. |

---

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

---

## Database Schema Reference

`SqliteSink` automatically initializes the following SQL table structure (`tableName: 'logs'`):

| Column Name | SQL Type | Description |
| :--- | :--- | :--- |
| `id` | `INTEGER PRIMARY KEY` | Auto-incrementing log record ID. |
| `timestamp` | `TEXT NOT NULL` | ISO-8601 formatted timestamp string. |
| `level` | `INTEGER NOT NULL` | Numeric level index (`0=trace` to `4=error`). |
| `level_name` | `TEXT NOT NULL` | Uppercase level string (`'INFO'`, `'ERROR'`). |
| `logger_name` | `TEXT NOT NULL` | Hierarchical namespace (`'app.payment'`). |
| `origin` | `TEXT NOT NULL` | Caller method/function origin string. |
| `message` | `TEXT NOT NULL` | Log message body. |
| `error` | `TEXT` | Formatted exception message (optional). |
| `stack_trace` | `TEXT` | Decomposed stack trace string (optional). |
| `context_json` | `TEXT` | JSON encoded context parameters (optional). |
| `created_at` | `INTEGER NOT NULL` | Milliseconds since Unix epoch (indexed). |

---

## Lifecycle & Graceful Shutdown

Because `SqliteSink` buffers entries in memory (`batchSize: 50`), ensure you dispose or flush the sink during application shutdown to avoid losing buffered entries:

```dart
// Explicitly flush pending entries to disk
await sqliteSink.flush();

// Flush remaining buffer and close SQLite database handle
await sqliteSink.dispose();
```

---

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

---

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

---

## License

BSD-3-Clause
