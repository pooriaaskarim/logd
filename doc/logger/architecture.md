# Architecture Overview

This document provides a technical overview of the `logd` logger module implementation. It is intended for contributors and developers requiring a deeper understanding of the internal mechanics.

## File Structure

The logger module is organized into 5 files:

| File | Purpose |
|------|---------|
| [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart) | Core implementation: `Logger`, `LoggerConfig`, `LoggerCache`, `_ResolvedConfig`, `LoggerMetrics` |
| [`log_entry.dart`](../../packages/logd/lib/src/logger/log_entry.dart) | Structured log event representation |
| [`log_buffer.dart`](../../packages/logd/lib/src/logger/log_buffer.dart) | Multi-line log buffering with LIFO pool |
| [`internal_logger.dart`](../../packages/logd/lib/src/logger/internal_logger.dart) | Fail-safe internal logging (bypasses user pipeline) |
| [`serialization_registry.dart`](../../packages/logd/lib/src/logger/serialization_registry.dart) | JSON serialization registry for isolate transport |

## System Components

The logger module consists of eight primary subsystems:
1. **The Registry**: Manages sparse configuration state
2. **The Resolver**: Computes effective configurations based on hierarchy
3. **The Pipeline**: Handles the creation and dispatch of `LogEntry` objects
4. **The Buffer**: Provides atomic multi-line logging with a LIFO object pool
5. **The Fail-Safe**: Prevents logging system failures from crashing the application
6. **The Fallback Handler**: Captures log events when all handlers fail
7. **The Metrics**: Observability counters for cache, pipeline, and memory
8. **The Serialization Registry**: Enables configuration transport across isolates

### 1. Configuration Registry

**Location**: `Logger._registry` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

The `_registry` is a static map holding `LoggerConfig` objects. A `LoggerConfig` is immutable (all fields `final`, annotated `@immutable`) and represents the *explicit* configuration set by the user.

```dart
static final Map<String, LoggerConfig> _registry = {};
```

**`LoggerConfig` Structure**:
- **Nullable fields**: `enabled`, `logLevel`, `includeFileLineInHeader`, `stackMethodCount`, `timestamp`, `stackTraceParser`, `handlers`, `autoSinkBuffer`
- **Version tracking**: `version` counter for cache invalidation (immutable copy-on-write via `copyWith`)
- **Sparse storage**: Only explicitly set values are non-null; `null` signals inheritance
- **`implicit` flag**: Tracks whether a node was materialized by `Logger.get()` without an explicit `Logger.configure()` call

### 2. Name Validation & Normalization

**Location**: `Logger._normalizeName()` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

To ensure consistency and prevent fragile hierarchy lookups, all names pass through a normalization gate.

**Normalization Rules**:
- `null`, empty string `""`, and `"global"` (case-insensitive) all resolve to the root `"global"`
- All other names are converted to **lowercase** for case-insensitive matching

**Validation Rules**:
- Pattern: `^[a-z0-9_]+(\.[a-z0-9_]+)*$`
- Strictly alphanumeric with underscores, segments separated by dots
- Invalid segments or formatting throws an `ArgumentError`

### 3. Resolution & Caching

**Location**: `LoggerCache` class in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

The `LoggerCache` maintains the derived state of the system using a versioned-invalidation strategy.

**`_ResolvedConfig`**:
- An immutable snapshot of a logger's effective state
- Contains no nullable fields (defaults are applied if no parent provides a value)
- Stored in `LoggerCache._cache` map

**Version-Based Invalidation** (see `LoggerCache._resolve()`):
- Every `LoggerConfig` maintains a `version` counter
- When a parent logger is reconfigured, its version increments
- Descendant loggers track their parent's version; if a mismatch is detected during a log call, the cache is invalidated and re-resolved lazily
- Cache check: `cached.version == config.version`

**Deep Equality Optimization** (see `Logger.configure()`):
- `Logger.configure` uses `operator ==` on all configuration components
- Collections use `mapEquals` and `listEquals` for deep comparison
- If the provided configuration is value-identical to the existing one, the version is **not** incremented
- Descendant caches remain valid, avoiding expensive invalidation

**Default Configuration**:
```dart
enabled: true
logLevel: LogLevel.debug
includeFileLineInHeader: false
stackMethodCount: {
  trace: 0, debug: 0, info: 0,
  warning: 2, error: 8
}
timestamp: Timestamp(
  formatter: 'yyyy.MMM.dd Z HH:mm:ss.SSS',
  timezone: Timezone.local()
)
stackTraceParser: StackTraceParser(ignorePackages: ['logd', 'flutter'])
handlers: [
  Handler(
    formatter: StructuredFormatter(),
    sink: ConsoleSink(),
    decorators: [
      BoxDecorator(),
    ]
  ),
],
autoSinkBuffer: false,
```

**`stackMethodCount` Merge Semantics**:
- The map is merged key-by-key up the hierarchy using `putIfAbsent`, not overwritten wholesale.
- A child can override only `LogLevel.error` without losing the parent's `warning` value.

**Immutability Protection**:
- Resolved collections are wrapped in `Map.unmodifiable()` and `List.unmodifiable()`
- Prevents external mutation of cached configurations
- Ensures thread-safety and predictable behavior

### 4. Dispatch Pipeline

**Location**: `Logger._log()` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

When a log method (e.g., `info`) is called:

1. **The Fast Path**:
   - The logger checks its cached `enabled` state and `logLevel`
   - If disabled or below threshold, drops the log, increments `LoggerMetrics._drops`, and returns immediately (Zero-Cost).

2. **Single-Pass Stack Parsing**:
   - `parse()` extracts both caller and stack frames in one pass
   - Skips 1 frame to exclude `_log` itself
   - Collects up to `stackMethodCount[level]` frames
   - Returns `null` caller if no valid frame found (aborts logging)

3. **LogEntry Construction**:
   - Creates immutable `LogEntry` with all log data
   - Builds origin string from caller info using `StringBuffer` fast-path
   - Stack frames provided directly from `parse()` result
   - Formats timestamp

4. **Handler Dispatch**:
   - Iterates through resolved handlers
   - Each handler processes the `LogEntry` asynchronously
   - Handler failures are caught, increment `LoggerMetrics._handlerFailures`, and invoke `Logger.fallbackHandler` if all handlers fail.

**Origin Building** (see `Logger._buildOrigin()`):
```dart
origin = className.isNotEmpty ? 'ClassName.methodName' : 'methodName'
if (includeFileLineInHeader) origin += ' (file.dart:123)'
```

**Stack Frame Extraction** (via `StackTraceParser.parse()`):
- Single pass: extracts both caller and additional frames
- Limits to `stackMethodCount[level]` frames
- Returns empty list if count is 0 (optimization)

### 5. LogEntry Structure

**Location**: `LogEntry` class in [`log_entry.dart`](../../packages/logd/lib/src/logger/log_entry.dart)

**Fields**:
- `loggerName` - Name of the logger that created this entry
- `origin` - Caller origin string (e.g., `'Class.method'` or `'Class.method (file.dart:123)'`)
- `level` - Log severity level
- `message` - Log message content (always a string)
- `timestamp` - Formatted timestamp string
- `stackFrames` - Parsed stack frames (nullable, based on `stackMethodCount`)
- `error` - Associated error object (nullable)
- `stackTrace` - Full stack trace (nullable)

**Dynamic Hierarchy Depth**:
```dart
int get hierarchyDepth {
  if (loggerName == 'global') return 0;
  return loggerName.split('.').length;
}
```
- Computed from logger name, not stored
- `'global'` → 0, `'a'` → 1, `'a.b'` → 2, `'a.b.c'` → 3

**`@internal` Protection**:
- Constructor marked `@internal` to prevent external instantiation
- Preserves pipeline integrity and allows future optimizations
- Only `Logger._log` creates `LogEntry` instances

### 6. LogBuffer Architecture

**Location**: `LogBuffer` class in [`log_buffer.dart`](../../packages/logd/lib/src/logger/log_buffer.dart)

**Purpose**: Atomic multi-line logging to prevent interleaved output in concurrent scenarios.

**Design**:
- Extends `StringBuffer` for efficient string building
- Holds reference to parent `Logger` and target `LogLevel`
- Accessed via logger properties: `traceBuffer`, `debugBuffer`, `infoBuffer`, `warningBuffer`, `errorBuffer`

**LIFO Pool and Leak Detection**:
- `LogBuffer._pool` is a static `List<LogBuffer>` capped at `_maxPoolSize = 32`.
- The pool is sized to cover typical burst concurrency without excessive memory retention.
- `_checkout()` pops from the pool (or constructs fresh) and increments `LoggerMetrics._bufferAllocations`.
- `_recycle()` pushes back to the pool and increments `LoggerMetrics._bufferReleases`.
- Each checked-out buffer registers itself with a `Finalizer<_LogBuffer>`. If GC collects a buffer before `sink()` is called, the finalizer fires, increments `LoggerMetrics._bufferLeaks`, and optionally auto-sinks the lost data (logging a `[WARNING]` via `InternalLogger`).

**API**:
- `writeln(object)` - Append line to buffer
- `writeAll(objects)` - Append multiple lines
- `error` / `stackTrace` - Attach context objects to the buffered log
- `sink()` - Flush buffer to logger and clear

**Usage Pattern**:
```dart
final buffer = logger.infoBuffer;
buffer?.writeln('Line 1');
buffer?.writeln('Line 2');
buffer?.sink();  // Atomically logs all lines as single entry
```

### 7. Graceful Fallback Handler

**Location**: `Logger.fallbackHandler` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

When all configured handlers throw an exception during a log call, `Logger.fallbackHandler` is invoked to ensure the log entry is never silently lost.

```dart
/// Signature:
static void Function(LogEntry, Object? error, StackTrace?)? fallbackHandler;
```

- **Default**: `Logger._defaultFallbackHandler` prints a prefixed `FALLBACK:` line to standard output.
- **Customization**: Set to any callback to redirect (e.g., to `stderr`, a crash reporter API).
- **Disable**: Set to `null` to suppress fallback output entirely.

*Note: This is independent of `InternalLogger`. The fallback handler receives the original `LogEntry`, whereas the internal logger reports the pipeline failure itself.*

### 8. InternalLogger (Fail-Safe System)

**Location**: `InternalLogger` class in [`internal_logger.dart`](../../packages/logd/lib/src/logger/internal_logger.dart)

**Purpose**: Prevent logging system failures from crashing the application.

**The Problem**: If a handler fails (e.g., `FileSink` with disk full), and that error is logged via the standard hierarchy, it may trigger the same failing handler, causing an infinite loop.

**The Solution**:
- `InternalLogger` bypasses the user-defined handler pipeline
- Outputs directly to platform standard streams via `print()`
- Used for all internal library errors
- Marked `@internal` to prevent external use

**Usage**:
- Handler failures (in `Logger._log()`)
- LogBuffer sink errors (in `LogBuffer.sink()`)
- Public logging method failures (in logging methods)

**Output Format**:
```text
[logd-internal] [LEVEL]: message
[logd-internal] [Error]: error_object
[logd-internal] [Stack Trace]:
stack_trace_lines
```

### 9. Observability — LoggerMetrics

**Location**: `LoggerMetrics` class in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

The observability API exposes isolate-local static counters for monitoring performance and memory lifecycle. Counters are never reset automatically.

| Counter | Incremented in | Purpose |
|---------|----------------|---------|
| `cacheHits` | `LoggerCache._resolve()` | Tracks zero-allocation fast-path resolutions. |
| `cacheMisses` | `LoggerCache._resolve()` | Tracks full hierarchy walk resolutions. |
| `cacheInvalidations` | `LoggerCache.invalidate()` | Tracks eviction events due to configuration updates. |
| `handlerFailures` | `Logger._log()` | Tracks handler exceptions caught by the pipeline. |
| `bufferAllocations` | `LogBuffer._checkout()` | Tracks buffer checkouts from the pool or new constructions. |
| `bufferReleases` | `LogBuffer._recycle()` | Tracks buffer returns to the LIFO pool. |
| `bufferLeaks` | `LogBuffer._finalizer` | Tracks buffers collected by GC without a `sink()` call. |
| `drops` | `Logger._log()` | Tracks log entries discarded due to level or disabled state. |

**`LoggerMetrics.toJson()`** returns a snapshot map of all counters, suitable for serialization or monitoring systems. 

**Lifecycle**: `Logger.reset()` does not reset metrics. Call `LoggerMetrics.reset()` to explicitly start a fresh measurement window.

### 10. Configuration Serialization & Isolate Transport

**Location**: `LoggerSerializationRegistry` in [`serialization_registry.dart`](../../packages/logd/lib/src/logger/serialization_registry.dart)

Because configurations are strictly isolate-local, moving configurations across isolates (e.g., to a worker isolate) requires serialization.

`LoggerConfig` implements `toJson()` and `fromJson()`. Components (formatters, sinks, filters, decorators, engines) are dynamically serialized via a type-keyed registry.

**Built-in Registrations** (via `ensureInitialized()`):
- Formatters: `PlainFormatter`, `JsonFormatter`, `StructuredFormatter`, `ToonFormatter`
- Sinks: `ConsoleSink`, `PrintSink`, `FileSink`, `NetworkSink`
- Filters: `LevelFilter`, `ContextFilter`
- Decorators: `BoxDecorator`, `StyleDecorator`, `PrefixDecorator`, `SuffixDecorator`
- Engines: `StandardEngine`, `ArenaEngine`, `NativeEngine`

**Custom Components**:
```dart
LoggerSerializationRegistry.registerFormatter<MyFormatter>(
  type: 'MyFormatter',
  fromJson: (json) => MyFormatter(param: json['param']),
  toJson: (val) => {'param': val.param},
);
```

**Isolate Transport Pattern**:
```dart
// Primary isolate:
final snapshot = Logger.exportConfig();

// Worker isolate:
Logger.importConfig(snapshot);
```

### 11. Flutter Integration

Since `logd` is a pure Dart package with zero runtime dependency on the Flutter SDK, it does not package built-in Flutter bindings. Instead, developers can easily forward Flutter framework errors to the `logd` pipeline manually:

```dart
void main() {
  FlutterError.onError = (final details) {
    Logger.get('app.crash').error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  
  runApp(MyApp());
}
```

This keeps `logd` compatible with pure Dart environments (VM, CLI, server, web) without SDK compilation blocks.

## Freezing Inheritance

**Location**: `Logger.freezeInheritance()` in [`logger.dart`](../../packages/logd/lib/src/logger/logger.dart)

For critical hot-paths where logger configuration is guaranteed to be static, developers can call `logger.freezeInheritance()`.

**Implementation**:
- Iterates through all descendants in registry
- Copies parent's effective values into child's explicit configuration (for `null` fields only)
- **No-op optimization**: Only increments version and invalidates cache when at least one field was actually populated (skips entirely if all fields were already explicit)

**Result**:
- Future lookups bypass the resolution path entirely
- Reduces logic to a single flag check and direct field access
- Descendants become disconnected from parent configuration changes

**Trade-off**: Performance vs. dynamic inheritance

## Performance Considerations

- **Cache Locality**: Once resolved, logger lookups involve a single map access
- **Resolution Walk**: Inheritance is O(D) where D is depth of hierarchy, but only occurs once per configuration change
- **Deep Equality**: O(K) where K is number of config parameters; prevents O(N) descendant cache clears
- **Unmodifiable Collections**: Prevents accidental mutation and ensures cache validity
- **Lazy Resolution**: Configuration is only resolved when first accessed after a change

## Isolation

State management in `logd` is static and isolate-local.
- Configurations are **not shared** between Dart isolates
- Multi-threaded applications using isolates must initialize logging configurations within each isolate entry point
- Each isolate maintains its own `_registry` and `LoggerCache`
