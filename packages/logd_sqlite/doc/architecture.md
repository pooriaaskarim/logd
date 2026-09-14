# logd_sqlite Architecture

`logd_sqlite` provides high-performance relational log persistence for the `logd` ecosystem, featuring Write-Ahead Logging (WAL), atomic batching, auto-pruning retention policies, and full-fidelity log query capabilities.

## Core Concepts

### 1. `SqliteSink`
The `SqliteSink` extends `LogSink<LogDocument>` and interfaces directly with `package:sqlite3`. It holds a pre-compiled set of prepared statements for low-overhead insertion and auto-pruning:
- `_insertStmt`: Atomic row insertions.
- `_pruneAgeStmt`: Age-based row deletion (`maxAge`).
- `_pruneCountStmt`: Count-based row deletion (`maxEntries`).

### 2. `SqliteHandler`
A pre-wired `Handler` combining `StructuredFormatter` and `SqliteSink`. It offers convenient constructors:
- `SqliteHandler(path: ...)`: Standard disk-backed database file.
- `SqliteHandler.inMemory()`: In-memory database, ideal for test suites.
- `SqliteHandler.database(database: ...)`: Wraps an existing `Database` connection.
- `SqliteHandler.async(path: ...)`: Spawns an `AsyncHandler` executing all SQLite reads/writes on a background Dart isolate.

### 3. Background Isolate Serialization
When using `SqliteHandler.async()`, `registerLogdSqliteSerializers()` must be called during application bootstrapping. This registers `SqliteSink` with `LoggerSerializationRegistry` so that database path configuration and retention limits are safely serialized across isolate boundaries without attempting to transfer native pointers.
