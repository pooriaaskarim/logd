# Design Philosophy

This document outlines the architectural principles and design decisions behind the `logd` logger module.

## 1. Hierarchical Inheritance

The primary design goal of `logd` is to mirror the hierarchical nature of software systems. Just as classes belong to packages, loggers belong to namespaces.

### Principle
Loggers are organized in a tree structure using dot-separated names (e.g., `global` → `app` → `app.ui`). A logger inherits its configuration (Level, Handlers, Timestamp, etc.) from its nearest configured ancestor.

### Deterministic Validation
To ensure predictable hierarchy traversal, `logd` enforces strict naming rules:
- **Regex**: `^[a-z0-9_]+(\\.[a-z0-9_]+)*$`
- **Lowercase**: All names are normalized to lowercase to prevent "Ghost Hierarchy" issues where `App.UI` and `app.ui` would otherwise be treated as siblings
- **Single Source of Truth**: All loggers are registered in a central, static **Registry** (@internal). This ensures that requesting the same name from anywhere in the app always returns the same instance

## 2. Sparse Configuration & Lazy Resolution

To maintain high performance and low memory footprint, `logd` avoids duplicating configuration data.

### Sparse Configuration
The `LoggerConfig` object stores *only* values that satisfy an explicit override. If a value is `null`, it implies inheritance.

**Rationale**: In a typical application with hundreds of loggers, most inherit their configuration from a few root loggers. Storing full configuration for each logger would waste memory and complicate updates.

### Lazy Resolution
The effective configuration for a logger is not computed until it is accessed.
1. Upon access, the system traverses the hierarchy from the leaf (logger) to the root (`global`)
2. The resolving logic fills in gaps using parent configurations
3. The result is cached in a specialized `_ResolvedConfig` object for O(1) access in subsequent calls

**Rationale**: Configuration changes are rare compared to log calls. By caching resolved configurations and only invalidating when necessary, we achieve near-zero overhead for the common case.

## 3. Performance Optimization

### Version-Based Cache Invalidation
The system utilizes a versioning strategy. Modifying a parent node increments its version, signaling dependent children to invalidate their cached configurations lazily. This avoids expensive tree-walking operations during configuration updates.

**Rationale**: Eager invalidation (walking the entire tree on every config change) would be O(N) where N is the number of loggers. Version-based lazy invalidation is O(1) for the configuration change, with O(D) resolution cost deferred until the next log call (where D is hierarchy depth).

### Deep Equality Checks
`logd` employs **Deep Equality** on collection parameters (like `handlers` or `filters`) during configuration. If a configuration is logically identical (even if it's a new object), the library skips the cache invalidation cycle.

**Rationale**: Without deep equality, reconfiguring a logger with the same values would invalidate all descendant caches unnecessarily. This is especially important for programmatic configuration in tests or dynamic systems.

### Inheritance Freezing & Control

For hot-paths where even the overhead of checking a version number is too high, the library supports freezing the resolved configuration.

- **The Optimization**: `logger.freezeInheritance()` flattens resolved configuration properties down the logger hierarchy and bakes them into descendant `LoggerConfig` configurations. This eliminates the O(D) walk up the hierarchy tree on every log call, reducing it to a single O(1) cache lookup.
- **Dynamic Restructuring (`force: true`)**: By default, once a node's fields are frozen, subsequent changes to its ancestor will be ignored by those fields. However, calling `logger.freezeInheritance(force: true)` will re-snapshot and update currently frozen configurations with the latest resolved values from their ancestors, while keeping user-defined explicit configurations intact.
- **Selective Restoration (`unfreezeInheritance`)**: Dynamic resolution can be restored globally or selectively using `logger.unfreezeInheritance({Set<String>? fields, bool includeSelf = true})`. This allows restoring dynamic resolution on specific properties (like `logLevel` or `handlers`) without touching others, or restricting the unfreeze operation purely to descendants.
- **Safety Safeguards**:
  - **Implicit Node Warning**: If `freezeInheritance` is called on a "ghost node" (a logger created via `Logger.get()` that was never explicitly configured), a warning is logged via `InternalLogger` to alert the developer that they may be freezing unresolved default values.
  - **Promotion Warning**: If `Logger.configure()` is called on a logger for a property that is currently frozen, the property is promoted to explicit, and a warning is emitted to alert the developer that they are erasing the frozen status (suggesting `unfreezeInheritance()` first if they wanted dynamic propagation instead).
  - **Hierarchy Depth Warning**: If a logger is retrieved with a hierarchy depth exceeding a safety threshold (defaulting to 10), a warning is logged on first access to prevent potential performance issues or stack overflows. This safety limit is configurable via `Logger.maxHierarchyDepth`.

**Rationale**: In performance-critical paths (e.g., hot event loops, high-throughput message handlers), every microsecond matters. Freezing allows developers to opt into zero-overhead logging, while diagnostics warnings and unfreezing tools keep the configuration lifecycle clean and manageable.

- **Registry and Subtree Reset**: The central registry can be cleared globally or partially using `Logger.reset([String? loggerName])`. Passing a specific logger name/namespace clears only that subtree and its descendants from the registry, leaving the rest of the hierarchy untouched. If no argument is provided, the entire registry is reset to its default unresolved configurations (useful for teardowns in test suites).

## 4. Atomic Multi-Line Logging

### The Problem
In concurrent scenarios, interleaved log output from multiple sources can make logs unreadable:
```
[Thread A] Line 1
[Thread B] Line 1
[Thread A] Line 2
[Thread B] Line 2
```

### The Solution: LogBuffer
`LogBuffer` provides atomic multi-line logging by buffering lines and flushing them as a single `LogEntry`:
```dart
final buffer = logger.infoBuffer;
buffer?.writeln('Line 1');
buffer?.writeln('Line 2');
buffer?.sink();  // Atomically logs both lines
```

**Design Decisions**:
- **Extends `StringBuffer`**: Leverages efficient string building without reinventing the wheel
- **Null when disabled**: Returns `null` if logger is disabled, enabling null-safe chaining (`buffer?.writeln(...)`)
- **Explicit `sink()`**: Requires explicit flush to prevent accidental partial logs
- **Error isolation**: Sink errors are caught and logged via `InternalLogger` to prevent cascading failures

**Rationale**: Multi-line logs are common for stack traces, JSON dumps, and structured data. Providing a first-class API for atomic multi-line logging improves both usability and output quality.

## 5. Platform Abstraction

### The Challenge
`logd` must work in both pure Dart and Flutter environments without requiring Flutter as a dependency for non-Flutter users.

### The Solution: Complete Decoupling
Rather than maintaining fragile conditional imports or runtime stub bindings that complicate package resolution, `logd` chooses complete decoupling. It does not package Flutter-specific dependencies at runtime. 

Instead, Flutter users manually forward errors to `logd` by binding their error handlers (e.g. `FlutterError.onError`) to the logger in their main app.

**Rationale**: This approach:
- Eliminates compile-time/analysis-time Flutter SDK dependencies for pure Dart VM, CLI, and server users.
- Gives developers explicit control over how and where uncaught Flutter errors are routed.
- Eliminates stubs and complex conditional target compilations, resulting in a cleaner and more stable codebase.

## 6. Default Configuration Philosophy

The default configuration is designed for **development-first** usability:

```dart
enabled: true
logLevel: LogLevel.debug
includeFileLineInHeader: false
stackMethodCount: {trace: 0, debug: 0, info: 0, warning: 2, error: 8}
timestamp: Timestamp(formatter: 'yyyy.MMM.dd Z HH:mm:ss.SSS', timezone: Timezone.local())
stackTraceParser: StackTraceParser(ignorePackages: ['logd', 'flutter'])
handlers: [Handler(formatter: StructuredFormatter(), sink: ConsoleSink(), decorators: [BoxDecorator()])]
```

**Rationale for each default**:
- **`enabled: true`**: Logging should work out-of-the-box without configuration
- **`logLevel: LogLevel.debug`**: Development needs verbose logs; production can override
- **`includeFileLineInHeader: false`**: File paths add noise; stack frames provide better context
- **`stackMethodCount`**: Warnings get 2 frames (enough context), errors get 8 (full context)
- **`timestamp`**: Millisecond precision with timezone for debugging time-sensitive issues
- **`stackTraceParser`**: Filters out framework noise to focus on user code
- **`handlers`**: Structured format with box decoration for readable console output

**Production Override Pattern**:
```dart
void main() {
  Logger.configure('global',
    logLevel: LogLevel.info,  // Less verbose
    handlers: [Handler(formatter: JsonFormatter(), sink: FileSink('app.log'))],
  );
  runApp(MyApp());
}
```

## 7. Stability, Safety, and Graceful Degradation

Logging is a diagnostic tool and must not introduce instability into the application.

### The Problem: Circularity
If a `FileSink` fails (e.g., Disk Full), and that error is logged via the standard hierarchy, it may trigger the same failing `FileSink`, causing an infinite loop.

### The Solution: InternalLogger
`logd` utilizes an **InternalLogger** that:
- Bypasses the user-defined handler pipeline
- Outputs directly to platform standard streams via `print()`
- Is used for all internal library errors, ensuring that even if the logging system is broken, the failure is reported without crashing the host application

**Usage Scenarios**:
- Handler failures during log dispatch
- LogBuffer sink errors
- Public logging method failures

### Graceful Fallback
The fail-safe philosophy extends to data preservation. If *all* configured handlers fail during a log dispatch, the log entry is silently lost. To prevent this, `logd` uses a **Graceful Fallback Handler**. This system catches total pipeline failures and forcefully redirects the original `LogEntry` to a fail-safe destination (by default, the console). This guarantees that in catastrophic scenarios, critical logs still survive.

**Rationale**: A logging library that crashes the application on error is worse than no logging at all, and silently dropping logs when things go wrong defeats the purpose of logging. The fail-safe system and graceful degradation ensure that logging failures are visible, non-fatal, and data-preserving.

## 8. API Surface Protection

### The Problem
Allowing external code to create `LogEntry` instances or call `Handler.log()` directly could:
- Bypass logger configuration (enabled checks, level filtering)
- Break future optimizations (e.g., log entry pooling)
- Create inconsistent log data (missing timestamps, incorrect hierarchy depth)

### The Solution: `@internal` Annotations
Key APIs are marked `@internal` to restrict usage to the `logd` package:
- `LogEntry` constructor
- `Handler.log()` method
- `LoggerConfig` class
- `LoggerCache` class

**Rationale**: By controlling the creation of `LogEntry` and the invocation of handlers, `logd` can:
- Guarantee data consistency
- Implement future optimizations without breaking changes
- Maintain a clean, predictable API surface

**Public API**: Users interact only with:
- `Logger.get()` / `Logger.configure()` / `Logger.configureMultiple()`
- `logger.trace()` / `logger.debug()` / `logger.info()` / `logger.warning()` / `logger.error()`
- `logger.traceBuffer` / `logger.debugBuffer` / etc.

## 9. Immutability

To prevent race conditions and ensure predictable behavior, resolved configurations are immutable.

### Implementation
- `_ResolvedConfig` fields are `final`
- Collections are wrapped in `Map.unmodifiable()` and `List.unmodifiable()`
- Modification requires calling `Logger.configure()` or `Logger.configureMultiple()`, which creates a new resolved config

**Rationale**: Immutability eliminates entire classes of bugs:
- No accidental mutation of shared state
- Thread-safe reads without locks
- Predictable behavior in concurrent scenarios

### Trade-off
Immutability increases GC pressure (new objects on every config change), but configuration changes are rare compared to log calls, making this trade-off acceptable.

## 10. Observability (Zero-Cost Telemetry)

### Principle
A logging framework is the bedrock of application observability, but the framework itself must be observable to diagnose dropped logs, handler failures, and memory leaks. However, emitting standard telemetry events for these internal operations would destroy performance.

### Implementation
`logd` uses **Isolate-Local Static Counters** (`LoggerMetrics`). By using simple integer increments on the hot-path (e.g., `_drops++` when a log is filtered out), the framework provides complete visibility into its internal health with effectively zero CPU cost and zero allocations.

## 11. Cross-Isolate Determinism

### Principle
Dart's memory isolation prevents sharing configuration objects across threads. However, a multi-threaded application requires consistent logging rules across all workers.

### Implementation
Rather than relying on complex port-based messaging architectures or shared memory hacks, `logd` relies on **Deterministic Serialization**. The entire configuration registry can be exported to a simple JSON structure (`exportConfig`) and reconstructed perfectly on worker isolates (`importConfig`). This embraces Dart's shared-nothing philosophy while providing unified logging behavior.

## Summary of Design Principles

1. **Hierarchical Inheritance**: Mirror software system structure with dot-separated logger names
2. **Sparse Configuration**: Store only explicit overrides, inherit the rest
3. **Lazy Resolution**: Compute effective configuration on-demand, cache aggressively
4. **Version-Based Invalidation**: O(1) configuration updates with lazy cache invalidation
5. **Deep Equality**: Avoid unnecessary cache clears for logically identical configurations
6. **Atomic Multi-Line Logging**: `LogBuffer` for readable concurrent output
7. **Platform Abstraction**: Decoupled design allows easy integration with Flutter error handlers without runtime SDK dependencies
8. **Development-First Defaults**: Sensible defaults for immediate usability
9. **Graceful Degradation**: `InternalLogger` and Fallback Handler prevent crashes and data loss
10. **API Surface Protection**: `@internal` annotations preserve integrity and enable future optimizations
11. **Immutability**: Prevent race conditions and ensure predictable behavior
12. **Zero-Cost Telemetry**: Observable metrics without performance penalties
13. **Cross-Isolate Determinism**: Seamless configuration transport across Dart isolates
