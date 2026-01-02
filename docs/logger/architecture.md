# Architecture Overview

This document provides a technical overview of the `logd` logger module implementation. It is intended for contributors and developers requiring a deeper understanding of the internal mechanics.

## System Components

The logger module consists of three primary subsystems:
1. **The Registry**: Manages sparse configuration state.
2. **The Resolver**: Computes effective configurations based on hierarchy.
3. **The Pipeline**: Handles the creation and dispatch of `LogEntry` objects.

### 1. Configuration Registry
The `_registry` is a static map holding `LoggerConfig` objects. A `LoggerConfig` is mutable and represents the *explicit* configuration set by the user.

- **Key**: Normalized logger name (lowercase).
- **Value**: `LoggerConfig` (contains nullable fields).

### 2. Resolution & Caching
The `LoggerCache` maintains the derived state of the system.

- **_ResolvedConfig**: An immutable snapshot of a logger's effective state. It contains no nullable fields (defaults are applied if no parent provides a value).
- **Resolution Strategy**:
  When a logger is requested, the cache is checked. On a miss, the system walks the ancestry tree (Leaf -> ... -> Root). The first non-null value encountered for each property (Level, Handler, etc.) is adopted.

### 3. Dispatch Pipeline
When a log method (e.g., `info`) is called:
1. **Level Check**: The logger compares the message level against its configured `logLevel`.
2. **Caller Extraction**: If enabled, the `StackTraceParser` identifies the call site.
3. **Entry Creation**: A `LogEntry` is constructed containing the message, timestamp, error object, and context.
4. **Handler Invocation**: The entry is passed to all configured `Handlers`.

## Data Dictionary

| Component | Responsibility |
|-----------|----------------|
| `Logger` | Public API facade. Proxies calls to the underlying cached configuration. |
| `LoggerConfig` | Internal storage for explicit user settings. Supports inheritance via nullability. |
| `_ResolvedConfig` | Internal storage for effective settings. Optimized for read performance. |
| `Handler` | Combines a `Formatter` and a `Sink` to process log entries. |

## Performance Considerations

- **Cache Locality**: Once resolved, logger lookups involve a single map access.
- **Descendant Invalidation**: `Logger.configure()` triggers an invalidation pass. Currently, this scans the cache keys to identify descendants (O(N) operation, where N is cached logger count).
- **Freezing**: The `freezeInheritance()` method flattens the configuration for a subtree, copying values to children. This effectively disables dynamic resolution for that branch, optimizing for read-heavy workloads where config does not change.

## Isolation

State management in `logd` is static and isolate-local.
- Configurations are **not shared** between Dart isolates.
- Multi-threaded applications using isolates must initialize logging configurations within each isolate entry point.
