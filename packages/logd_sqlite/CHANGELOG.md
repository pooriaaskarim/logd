## 0.1.1

- **Pub.dev Maintenance & Score Fixes**:
  - Added library-level documentation comment to `logd_sqlite` primary export.
  - Added `example/example.dart` standard example entrypoint for pub.dev automated score discovery.
  - Updated `pubspec.yaml` repository and homepage URLs to valid HTTP 200 endpoints.
  - Updated `sqlite3` dependency version constraint to `'>=2.4.0 <4.0.0'` supporting both 2.x and 3.x releases.
  - Updated `logd` dependency constraint to `^0.9.2`.

## 0.1.0

- Initial release of `logd_sqlite`, a dedicated satellite package providing production-grade SQLite persistence logging for `logd`.
- **`SqliteSink`**: High-performance `LogSink<LogDocument>` supporting:
  - Pre-compiled prepared statement reuse across all log writes.
  - Write-Ahead Logging (`WAL` mode) and synchronous pragma optimizations.
  - Atomic transaction batching (`batchSize`, `flushInterval`).
  - Full entry field fidelity (`timestamp`, `level`, `logger_name`, `origin`, `message`, `error`, `stack_trace`, `context_json`).
  - Auto-pruning retention policies (`maxEntries`, `maxAge`).
  - Rich query engine (`queryLogs`) supporting level filtering, logger namespace matching, full-text search, and pagination.
  - Inspection helpers `fetchLevelCounts()` and `fetchDistinctLoggerNames()`.
  - Database utilities `count()`, `clear()`, `vacuum()`, and `flush()`.
- **Examples & Showcase**:
  - `example.dart`: Standard usage entrypoint for log write, query engine, and level breakdown.
  - `sqlite_sink_showcase.dart`: Top-to-bottom telemetry simulation and query engine proof-of-concept.
  - `sqlite_interactive_dashboard.dart`: Interactive REPL CLI dashboard with level counts, discovered namespaces, and throughput benchmarking.
