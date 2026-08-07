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
  - `sqlite_sink_showcase.dart`: Top-to-bottom telemetry simulation and query engine proof-of-concept.
  - `sqlite_interactive_dashboard.dart`: Interactive REPL CLI dashboard with level counts, discovered namespaces, and throughput benchmarking.
