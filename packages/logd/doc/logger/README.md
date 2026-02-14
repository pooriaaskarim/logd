# Logger Module

The Logger module is the core of `logd`, implementing the hierarchical logger system, configuration management, and resolution logic.

## Quick Start

```dart
import 'package:logd/logd.dart';

// Get a logger instance
final logger = Logger.get('app');

// Log messages at different levels
logger.info('Application started');
logger.debug('Debug information');
logger.warning('Potential issue detected');
logger.error('Error occurred', error: exception, stackTrace: stack);

// Configure logger behavior
Logger.configure('app', 
  logLevel: LogLevel.info,
  handlers: [Handler(formatter: StructuredFormatter(), sink: ConsoleSink())],
);

// Use hierarchical loggers
final uiLogger = Logger.get('app.ui');  // Inherits from 'app'
final dbLogger = Logger.get('app.db');  // Inherits from 'app'
```

## Component Overview

The logger module consists of 6 source files:

### Core Components

#### [logger.dart](../../lib/src/logger/logger.dart)
Main implementation file containing:
- **`Logger`** - Primary public API for logging operations
- **`LoggerConfig`** - Sparse configuration storage (nullable fields for inheritance)
- **`LoggerCache`** - Version-based caching system with lazy resolution
- **`_ResolvedConfig`** - Immutable container for resolved configuration

#### [log_entry.dart](../../lib/src/logger/log_entry.dart)
- **`LogEntry`** - Structured representation of a log event
- Contains: logger name, level, message, timestamp, origin, stack frames, error, stack trace
- Computes `hierarchyDepth` dynamically from logger name

#### [log_buffer.dart](../../lib/src/logger/log_buffer.dart)
- **`LogBuffer`** - Efficient buffer for building multi-line log messages
- Extends `StringBuffer` with `sink()` method for atomic output
- Accessed via `logger.traceBuffer`, `logger.debugBuffer`, etc.

#### [internal_logger.dart](../../lib/src/logger/internal_logger.dart)
- **`InternalLogger`** - Fail-safe internal logging to prevent circularity
- Bypasses handler pipeline, outputs directly to console
- Used for logging library errors without triggering infinite loops

#### [flutter_stubs.dart](../../lib/src/logger/flutter_stubs.dart) / [flutter_stubs_flutter.dart](../../lib/src/logger/flutter_stubs_flutter.dart)
- Conditional Flutter integration using conditional imports
- `flutter_stubs.dart` - No-op for pure Dart environments
- `flutter_stubs_flutter.dart` - Hooks into `FlutterError.onError` when Flutter is available

## Responsibilities

- **Hierarchy Management**: Factory pattern via `Logger.get(name)` with dot-separated inheritance
- **Lazy Resolution**: Sparse configuration storage with version-based cache invalidation (O(1) access)
- **Log Dispatch**: Implicit `LogEntry` generation and routing to the `Handler` pipeline
- **Multi-Line Buffering**: Atomic multi-line log output via `LogBuffer`
- **Fail-Safe Logging**: Internal error handling via `InternalLogger`

## Core Concepts

### Sparse Hierarchy
Only explicit overrides are stored. `null` values signal inheritance from the nearest configured ancestor, terminating at the `"global"` root.

### Version-Based Caching
Configuration changes increment a version counter. Descendant loggers detect version mismatches and re-resolve lazily, avoiding expensive tree walks.

### Data Model Protection
The construction of `LogEntry` objects is an automated internal concern. The `LogEntry` constructor is marked **`@internal`** to preserve pipeline integrity and allow for future backend optimizations.

## API Overview

### Logger Retrieval
- `Logger.get(name)` - Retrieve or create logger with hierarchical inheritance
- Names are dot-separated, case-insensitive, normalized to lowercase
- Valid pattern: `^[a-z0-9_]+(\\.[a-z0-9_]+)*$`

### Configuration
- `Logger.configure(name, ...)` - Set configuration for a logger and its descendants
- Parameters: `enabled`, `logLevel`, `includeFileLineInHeader`, `stackMethodCount`, `timestamp`, `stackTraceParser`, `handlers`
- Changes propagate dynamically to descendants unless explicitly overridden

### Logging Methods
- `logger.trace(message, {error, stackTrace})` - Fine-grained diagnostics
- `logger.debug(message, {error, stackTrace})` - Development debugging
- `logger.info(message, {error, stackTrace})` - General operational info
- `logger.warning(message, {error, stackTrace})` - Potential issues
- `logger.error(message, {error, stackTrace})` - Errors requiring attention

### Multi-Line Buffering
```dart
final buffer = logger.infoBuffer;
buffer?.writeln('Line 1');
buffer?.writeln('Line 2');
buffer?.writeln('Line 3');
buffer?.sink();  // Atomically logs all lines
```

### Performance Optimization
- `logger.freezeInheritance()` - Bake current configuration into descendants for zero-cost lookups
- Use for hot paths where configuration is guaranteed static

### Flutter Integration
- `Logger.attachToFlutterErrors()` - Route Flutter errors through logd pipeline

## Configuration Properties

### Getters (Resolved from Hierarchy)
- `logger.enabled` - Whether logging is enabled
- `logger.logLevel` - Minimum level to log
- `logger.includeFileLineInHeader` - Include file:line in origin
- `logger.stackMethodCount` - Stack frames per level (unmodifiable map)
- `logger.timestamp` - Timestamp formatter configuration
- `logger.stackTraceParser` - Stack trace parser configuration
- `logger.handlers` - Handler list (unmodifiable)

## Documentation

- [Design Philosophy](philosophy.md) - Core principles and rationale
- [Architecture](architecture.md) - Internal implementation details
- [Roadmap](roadmap.md) - Planned improvements and known issues
