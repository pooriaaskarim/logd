# Architecture Overview

This document provides a technical overview of the `logd` logger module implementation. It is intended for contributors and developers requiring a deeper understanding of the internal mechanics.

## File Structure

The logger module is organized into 6 files:

| File | Lines | Purpose |
|------|-------|---------|
| [`logger.dart`](../../lib/src/logger/logger.dart) | 711 | Core implementation: `Logger`, `LoggerConfig`, `LoggerCache`, `_ResolvedConfig` |
| [`log_entry.dart`](../../lib/src/logger/log_entry.dart) | 59 | Structured log event representation |
| [`log_buffer.dart`](../../lib/src/logger/log_buffer.dart) | 155 | Multi-line log buffering |
| [`internal_logger.dart`](../../lib/src/logger/internal_logger.dart) | 26 | Fail-safe internal logging |
| [`flutter_stubs.dart`](../../lib/src/logger/flutter_stubs.dart) | 6 | No-op Flutter stubs for pure Dart |
| [`flutter_stubs_flutter.dart`](../../lib/src/logger/flutter_stubs_flutter.dart) | 14 | Flutter error integration |

## System Components

The logger module consists of five primary subsystems:
1. **The Registry**: Manages sparse configuration state
2. **The Resolver**: Computes effective configurations based on hierarchy
3. **The Pipeline**: Handles the creation and dispatch of `LogEntry` objects
4. **The Buffer**: Provides atomic multi-line logging
5. **The Fail-Safe**: Prevents logging system failures from crashing the application

### 1. Configuration Registry

**Location**: `Logger._registry` in [`logger.dart`](../../lib/src/logger/logger.dart)

The `_registry` is a static map holding `LoggerConfig` objects. A `LoggerConfig` is mutable and represents the *explicit* configuration set by the user.

```dart
static final Map<String, LoggerConfig> _registry = {};
```

**`LoggerConfig` Structure**:
- **Nullable fields**: `enabled`, `logLevel`, `includeFileLineInHeader`, `stackMethodCount`, `timestamp`, `stackTraceParser`, `handlers`, `autoSinkBuffer`
- **Version tracking**: `_version` counter for cache invalidation
- **Sparse storage**: Only explicitly set values are non-null; `null` signals inheritance

### 2. Name Validation & Normalization

**Location**: `Logger._normalizeName()` in [`logger.dart`](../../lib/src/logger/logger.dart)

To ensure consistency and prevent fragile hierarchy lookups, all names pass through a normalization gate.

**Normalization Rules**:
- `null`, empty string `""`, and `"global"` (case-insensitive) all resolve to the root `"global"`
- All other names are converted to **lowercase** for case-insensitive matching

**Validation Rules**:
- Pattern: `^[a-z0-9_]+(\\.[a-z0-9_]+)*$`
- Strictly alphanumeric with underscores, segments separated by dots
- Invalid segments or formatting throws an `ArgumentError`

### 3. Resolution & Caching

**Location**: `LoggerCache` class in [`logger.dart`](../../lib/src/logger/logger.dart)

The `LoggerCache` maintains the derived state of the system using a versioned-invalidation strategy.

**`_ResolvedConfig`**:
- An immutable snapshot of a logger's effective state
- Contains no nullable fields (defaults are applied if no parent provides a value)
- Stored in `LoggerCache._cache` map

**Version-Based Invalidation** (see `LoggerCache._resolve()`):
- Every `LoggerConfig` maintains a `_version` counter
- When a parent logger is reconfigured, its version increments
- Descendant loggers track their parent's version; if a mismatch is detected during a log call, the cache is invalidated and re-resolved lazily
- Cache check: `cached.version == config._version`

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

**Immutability Protection**:
- Resolved collections are wrapped in `Map.unmodifiable()` and `List.unmodifiable()`
- Prevents external mutation of cached configurations
- Ensures thread-safety and predictable behavior

### 4. Dispatch Pipeline

**Location**: `Logger._log()` in [`logger.dart`](../../lib/src/logger/logger.dart)

When a log method (e.g., `info`) is called:

1. **The Fast Path**:
   - The logger checks its cached `enabled` state and `logLevel`
   - If disabled or below threshold, returns immediately (Zero-Cost)

2. **Single-Pass Stack Parsing**:
   - `parse()` extracts both caller and stack frames in one pass
   - Skips 1 frame to exclude `_log` itself
   - Collects up to `stackMethodCount[level]` frames
   - Returns `null` caller if no valid frame found (aborts logging)

3. **LogEntry Construction**:
   - Creates immutable `LogEntry` with all log data
   - Builds origin string from caller info
   - Stack frames provided directly from `parse()` result
   - Formats timestamp

4. **Handler Dispatch**:
   - Iterates through resolved handlers
   - Each handler processes the `LogEntry` asynchronously
   - Handler failures are caught and logged via `InternalLogger`

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

**Location**: `LogEntry` class in [`log_entry.dart`](../../lib/src/logger/log_entry.dart)

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

**Location**: `LogBuffer` class in [`log_buffer.dart`](../../lib/src/logger/log_buffer.dart)

**Purpose**: Atomic multi-line logging to prevent interleaved output in concurrent scenarios.

**Design**:
- Extends `StringBuffer` for efficient string building
- Holds reference to parent `Logger` and target `LogLevel`
- Accessed via logger properties: `traceBuffer`, `debugBuffer`, `infoBuffer`, `warningBuffer`, `errorBuffer`

**API**:
- `writeln(object)` - Append line to buffer
- `writeAll(objects)` - Append multiple lines
- `error` / `stackTrace` - Attach context objects to the buffered log
- `sink()` - Flush buffer to logger and clear

**Implementation Details**:
- Returns `null` if logger is disabled (null-safe chaining)
- `sink()` calls `Logger._log` with buffered content
- Errors during sink are caught and logged via `InternalLogger`
- Buffer is cleared after successful sink

**Usage Pattern**:
```dart
final buffer = logger.infoBuffer;
buffer?.writeln('Line 1');
buffer?.writeln('Line 2');
buffer?.sink();  // Atomically logs all lines as single entry
```

### 7. InternalLogger (Fail-Safe System)

**Location**: `InternalLogger` class in [`internal_logger.dart`](../../lib/src/logger/internal_logger.dart)

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
```
[logd-internal] [LEVEL]: message
[logd-internal] [Error]: error_object
[logd-internal] [Stack Trace]:
stack_trace_lines
```

### 8. Flutter Integration

**Conditional Import Mechanism** (see top of [`logger.dart`](../../lib/src/logger/logger.dart)):
```dart
import 'flutter_stubs.dart' if (dart.library.ui) 'flutter_stubs_flutter.dart'
    as flutter_stubs;
```

**Pure Dart Environment** ([`flutter_stubs.dart`](../../lib/src/logger/flutter_stubs.dart)):
- `attachToFlutterErrors()` throws `UnsupportedError`
- Prevents runtime errors in non-Flutter environments

**Flutter Environment** ([`flutter_stubs_flutter.dart`](../../lib/src/logger/flutter_stubs_flutter.dart)):
- Hooks into `FlutterError.onError`
- Routes Flutter framework errors through logd pipeline
- Logs to global logger with error level

**Usage**:
```dart
void main() {
  Logger.attachToFlutterErrors();
  runApp(MyApp());
}
```

## Freezing Inheritance

**Location**: `Logger.freezeInheritance()` in [`logger.dart`](../../lib/src/logger/logger.dart)

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
