<h1 style="margin-bottom: 20px; font-size: 50px; text-align: left;font-weight: bold; width:" > <a href="https://pub.dev/packages/logd" style="color: white; " >logd</a> <a href="https://img.shields.io/pub/v/logd.svg"><img src="https://img.shields.io/pub/v/logd.svg"></a> <a href="https://img.shields.io/pub/points/logd.svg"><img src="https://img.shields.io/pub/points/logd.svg"></a> <a href="https://img.shields.io/pub/dm/logd.svg"> <a href="https://opensource.org/licenses/BSD-3-Clause"><img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg"></a> </h1>

![logd Hero](https://raw.githubusercontent.com/pooriaaskarim/logd/refs/heads/master/assets/img/logd_hero.webp)

<p style="margin-top: 0px; text-align: left;font-weight: normal; font-size: 18px;" >
A <b> modular</b> <b>hierarchical</b> logger for Dart and Flutter. Build structured logs, control output destinations, and keep overhead minimal.
</p>

## Why logd?

- **Hierarchical configuration** – Loggers are named with dot‑separated paths (`app.network.http`). Settings propagate from parents to children unless overridden.
- **Zero‑boilerplate** – Simple `Logger.get('app')` gives a fully‑configured logger.
- **Performance‑first** – Lazy resolution, aggressive caching, and optional inheritance freezing keep the cost of a disabled logger essentially zero.
- **Flexible output** – Choose between console, file, network, HTML, or any custom sink; format logs as text, structured JSON, HTML, Markdown or **LLM‑optimized TOON**.
- **Protocol Auto-Detection** – Standard sinks (`ConsoleSink`, `FileSink`, `HttpSink`, `SocketSink`) automatically detect the handler's formatter (`ToonFormatter`, `JsonFormatter`, or custom formatters via `'logd.encoder'`) and delegate to matching physical encoders out-of-the-box.
- **Layout Sovereignty** – A centralized engine guarantees structural integrity (e.g., perfect boxes) across all terminal widths.
- **Platform‑agnostic styling** – Decouple visual intent from representation using the semantic `LogTheme` system.
- **Web & Desktop Parity** – Built-in platform-aware stack trace parsers for Chrome (V8), Firefox, Safari, and the Dart VM, preserving column numbers for high-fidelity source map resolution.

## Getting Started

Add `logd` to your project:

```yaml
dependencies:
  logd: ^latest_version
```

Then run:
```bash
dart pub get  # or flutter pub get
```

### Quick Example

```dart
import 'package:logd/logd.dart';

void main() {
  final logger = Logger.get('app');

  logger.info('Application started');
  logger.debug('Debug message');
  logger.warning('Low disk space');
  logger.error('Connection failed',
    error: exception,
    stackTrace: stack,
  );
}
```

**Typical console output**

```
[app][INFO] 2025-01-23 05:30:12.456
  --example/main.dart:12 (main)
  ----Application started
```

> *Tip*: Use `Logger.configure` to set global log‑levels, handlers, or timestamps. `logd` uses **Deep Equality** to ensure that re-configuring with identical values results in zero performance overhead.

## Core Concepts

### Hierarchical Loggers

Loggers inherit configuration from their ancestors.

```dart
// Configure the entire app
Logger.configure('app', logLevel: LogLevel.warning);

// Override a subsystem
Logger.configure('app.network', logLevel: LogLevel.debug);

// Create a logger deep in the tree
final uiLogger = Logger.get('app.ui.button');  // inherits WARNING
final httpLogger = Logger.get('app.network.http'); // inherits DEBUG
```

### Bulk Configuration

For complex or large applications, configuring multiple loggers individually can lead to boilerplate and redundant cache invalidation traversals. You can use the bulk configuration API to apply multiple updates at once:

```dart
Logger.configureMultiple({
  'global': const LoggerConfig(logLevel: LogLevel.warning),
  'app.network': const LoggerConfig(logLevel: LogLevel.debug),
  'app.ui': const LoggerConfig(enabled: false),
});
```

* **Atomic Validation**: Input validation occurs across the entire configuration map *before* any updates are written. If a single configuration fails (e.g., negative stack trace count), the entire update is cleanly rejected.
* **Single-Pass Cache Invalidation**: The cache is invalidated in a single optimized pass for all changed loggers and their descendants, eliminating redundant tree-walks and reducing GC pressure.

### Pattern-Based Configuration

When you want to apply configurations to loggers that don't share a strict parent-child relationship or to match loggers dynamically across your application using wildcards, you can use `configurePattern`. It supports standard glob wildcards (`*` matches zero or more characters, `?` matches a single character).

```dart
// Configure all database loggers to DEBUG
Logger.configurePattern('*.database', logLevel: LogLevel.debug);

// Disable all third-party package loggers under a prefix
Logger.configurePattern('vendor.*', enabled: false);

// Wildcard matches are evaluated dynamically on cache resolution,
// with newer pattern rules overriding older ones if they both match.
Logger.configurePattern('app.services.*', logLevel: LogLevel.info);
```

### Ambient Structured Context (MDC / `LogContext`) (v0.9.4+)

In complex systems, microservices, and asynchronous pipelines, you often need to attach contextual metadata (such as `requestId`, `userId`, `traceId`, or `tenantId`) to every log entry across many deeply nested functions without manually threading a map through every method argument.

`logd` provides **`LogContext.run()`** — an ambient, async-safe Mapped Diagnostic Context (MDC) powered by Dart [Zone]s:

```dart
import 'package:logd/logd.dart';

Future<void> handleCheckout(String requestId, int userId) async {
  // Bind ambient context across all sync and async calls in this scope
  await LogContext.run({'requestId': requestId, 'userId': userId}, () async {
    final logger = Logger.get('app.checkout');

    logger.info('Validating cart items'); // Context attached automatically!
    await chargePaymentGateway();        // Downstream async calls inherit context
    logger.info('Order completed');
  });
}

Future<void> chargePaymentGateway() async {
  // Deep in the call stack — zero logger or context parameters passed!
  final logger = Logger.get('app.payment');
  logger.info('Connecting to Stripe gateway'); 
  // Output: [INFO] [app.payment] Connecting to Stripe gateway {requestId: req-9812, userId: 42}
}
```

#### Nested Scopes & Call-Site Overrides
- **Inheritance & Shadowing**: Inner `LogContext.run` scopes inherit keys from outer scopes. Conflicting keys in the child scope override the parent's value for the duration of the child scope without mutating the parent.
- **Call-Site Overrides**: Pass `logger.info('msg', context: {'key': 'val'})` to append or override specific metadata keys for a single log entry.
- **Strict Concurrency Isolation**: Concurrent tasks (e.g. `Future.wait` or parallel HTTP requests) maintain separate contexts with zero race conditions.
- **Zero-Cost Fast Path**: When no ambient or explicit context is present, log dispatch performs 0 heap allocations.

### Log levels

| Level | Description |
|-------|-------------|
| `trace` | Diagnostic noise |
| `debug` | Developer debugging |
| `info`  | Informational |
| `warning` | Potential issue |
| `error` | Failure |

## Output Handlers

### Pre-Wired Target Handlers (v0.9.3+)

`logd` ships with pre-wired, strongly-typed `Handler` subclasses for all common output destinations. You can configure complete, styled logging pipelines with zero boilerplate:

```dart
// 1. Terminal / Console (with Dark or Light themes)
Logger.configure('app', handlers: [
  ConsoleHandler(theme: const LogTheme.dark()),
]);

// 2. Structured JSON File (Pretty-printed or compact single-line)
Logger.configure('app.api', handlers: [
  JsonFileHandler('logs/api.json', pretty: true),
]);

// 3. HTML Log Report (self-contained with embedded CSS and document shell)
Logger.configure('app.web', handlers: [
  HtmlFileHandler('logs/session.html', title: 'App Web Logs'),
]);

// 4. Token-Optimized TOON File (designed for LLM / AI parsing)
Logger.configure('app.ai', handlers: [
  ToonFileHandler('logs/telemetry.toon'),
]);

// 5. In-Memory Ring Buffer (for in-app debug screens or tests)
final memoryHandler = MemoryHandler(capacity: 200);
Logger.configure('app.debug', handlers: [memoryHandler]);
// Programmatically inspect recent entries:
print(memoryHandler.entries.length);

// 6. Live Interactive Web Dashboard (HTTP + WebSockets)
Logger.configure('app.dashboard', handlers: [
  HttpDashboardHandler(port: 8080),
]);
```

### Dual-Mode Execution: Non-Blocking Background Isolates (`.async()`)

For Flutter UI applications and high-throughput servers, all output-bound file and console handlers provide an `.async()` constructor. This automatically offloads document formatting, decoration, and disk I/O to a background worker isolate (~15µs return):

```dart
// Zero-config isolate offloading — keeps the UI thread 100% jank-free
Logger.configure('app', handlers: [
  ConsoleHandler.async(),
  JsonFileHandler.async('logs/production.json'),
  HtmlFileHandler.async('logs/report.html'),
]);
```

> [!TIP]
> State-bound handlers like `MemoryHandler` (in-process heap) and `HttpDashboardHandler` (local socket server) intentionally run synchronously in-process to ensure direct memory visibility and deterministic port binding.

## Advanced Features

### Custom Pipeline Handlers

When you need granular control, compose custom formatters, decorators, and sinks manually:

```dart
final jsonHandler = Handler(
  formatter: const JsonFormatter(
    metadata: {LogMetadata.timestamp, LogMetadata.logger},
  ),
  sink: FileSink(
    'logs/app.log',
    fileRotation: TimeRotation(
      interval: Duration(days: 1),
      timestamp: Timestamp(formatter: 'yyyy-MM-dd'),
      backupCount: 7,
      compress: true,
    ),
  ),
  filters: [LevelFilter(LogLevel.info)],
);

Logger.configure('app', handlers: [jsonHandler]);
```

**Result**: JSON logs written to `logs/app.log`, rotated daily, keeping 7 compressed backups.  
> [!NOTE]  
> Modern formatters (v0.6.1+) automatically include mandatory data like `level`, `message`, `error`, and `stackTrace`. The `metadata` parameter is used only for additional context like timestamps or logger names.

### High-Throughput Caller Origin Bypass (`includeOrigin: false`) (v0.9.4+)

By default, `logd` captures the caller's file and line origin (e.g., `main.dart:42 (handleCheckout)`) for development convenience. In ultra-high-throughput environments (e.g., processing millions of logs/sec or tight loops), capturing and parsing VM stack traces incurs non-trivial latency.

You can configure `includeOrigin: false` to completely bypass `StackTrace.current` VM unwinding and regex parsing, boosting log dispatch throughput by up to **~5x**:

```dart
// Completely bypass caller stack unwinding for high-frequency logs
Logger.configure(
  'app.analytics',
  includeOrigin: false,
  handlers: [ConsoleHandler()],
);
```

- **Selective Error Preservation**: Passing explicit stack traces (`logger.error('Failed', stackTrace: st)`) or configuring `stackMethodCount[LogLevel.error] = 5` continues to capture and preserve error traces even when caller origin is bypassed.

### Atomic multi‑line logs

Prevent interleaving in concurrent environments:

```dart
final buffer = logger.infoBuffer;
buffer?.writeln('=== User Session ===');
buffer?.writeln('User ID: ${user.id}');
buffer?.writeln('Login time: ${DateTime.now()}');
buffer?.writeln('IP: ${request.ip}');
buffer?.sink(); // writes atomically
```

### Multiple Outputs

You can either use multiple handlers:
```dart
final consoleHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(),
    SuffixDecorator(
      label: '[v1.0.2]',
      align: true,
    ),
  ],
  sink: const ConsoleSink(lineLength: 80),
);

final fileHandler = Handler(
  formatter: const PlainFormatter(),
  sink: FileSink('logs/app.log'),
);

Logger.configure('global', handlers: [consoleHandler, fileHandler]);
```

Or use a multi-sink in a handler:
```dart
final multiSinkHandler = Handler(
  formatter: PlainFormatter(),
  sink: MultiSink(sinks: [
    ConsoleSink(),
    FileSink('logs/app.log'),
    ],
  ),
);
```

### Filtering

Control which logs reach which handlers:

```dart
// Level-based filtering
final errorHandler = Handler(
  formatter: JsonFormatter(),
  sink: FileSink('logs/errors.log'),
  filters: [LevelFilter(LogLevel.error)],  // Errors only
);

// Regex-based filtering (exclude sensitive data)
final publicHandler = Handler(
  formatter: PlainFormatter(),
  sink: FileSink('logs/public.log'),
  filters: [
    RegexFilter(r'password|secret|token', exclude: true),
  ],
);
```

### Timezone & Timestamp

```dart
final timestamp = Timestamp(
  formatter: 'yyyy-MM-dd HH:mm:ss.SSS Z',
  timezone: Timezone.named('America/New_York'),
);

Logger.configure('app', timestamp: timestamp);
```

For high-frequency or daily aggregate logs where sub-second precision is not needed, you can use date-only formatting to bypass sub-second calculations entirely:
```dart
final dateOnly = Timestamp.dateOnly('yyyy-MM-dd');
Logger.configure('app.audit', timestamp: dateOnly);
```

### File Rotation

| Strategy | Example |
|---------|--------|
| Size | `FileSink('logs/app.log', fileRotation: SizeRotation(maxSize: '10 MB', backupCount: 5, compress: true))` |
| Time | `FileSink('logs/app.log', fileRotation: TimeRotation(interval: Duration(hours: 1), timestamp: Timestamp(formatter: 'yyyy-MM-dd_HH'), backupCount: 24))` |

### High-Performance Execution (v0.8.0+)
 
 `logd` features a modular engine architecture to match your performance requirements:
 
- **StandardEngine (Default)**: A reliable, platform-agnostic engine running on the Dart GC heap. Fully compatible with Web, Desktop, Mobile, and VM.
- **ArenaEngine**: Uses isolate-local LIFO object pooling to eliminate GC pressure. Ideal for complex logs with many decorators.
- **NativeEngine (Opt-in)**: Leverages `dart:ffi` and a **Binary IR (B-IR)** instruction stream for native VM platforms. Fully stabilized in v0.8.1 with 100% verified layout parity.

```dart
// StandardEngine is used by default.
// You can explicitly swap to ArenaEngine or NativeEngine in your Handler setup.
// To optimize performance further, you can freeze inheritance:
Logger.get('app').freezeInheritance(); 
```

### Inheritance Control & Diagnostics (v0.8.2+)

`logd` features a mature, production-ready logger inheritance management system for hot paths and troubleshooting:

- **Bake & Force Update**: `logger.freezeInheritance()` bakes configuration down the hierarchy to bypass tree-walks. It returns the number of fields written. To re-snapshot currently frozen configurations after ancestry changes, call `logger.freezeInheritance(force: true)`.
- **Selective Unfreeze**: Restore dynamic propagation to the parent hierarchy on specific fields, or restrict the restoration strictly to descendants:
  ```dart
  logger.unfreezeInheritance(
    fields: {'logLevel'},
    includeSelf: false, // only unfreeze descendants
  );
  ```
- **Tree Visualization**: Visualize the active registry tree, with annotations for explicit/frozen settings and actual effective values:
  ```dart
  final textTree = Logger.formatHierarchy();
  Logger.printHierarchy(sink: print); // or custom sink
  ```
- **JSON-serializable Export**: `Logger.exportHierarchy()` returns a map of all registered loggers, including effective resolved values and ghost-node detection (`'implicit': true` for implicit loggers).
- **Subtree & Global Reset**: Reset the entire registry or a specific namespace subtree to default unresolved settings:
  ```dart
  Logger.reset('app.ui'); // Resets only 'app.ui' and its descendants
  Logger.reset();        // Global reset, clears the entire registry
  ```
- **Hierarchy Depth Warning (v0.8.5+)**: Accessing loggers with abnormally deep hierarchies (e.g. >10 levels) prints an `InternalLogger` warning on first access to protect against stack overflows and resolution performance issues. This threshold is customizable:
  ```dart
  Logger.maxHierarchyDepth = 12; // Customize safety limit
  ```
  This can be disabled by setting `Logger.maxHierarchyDepth <= 0`.

### Isolate Configuration Transport (v0.8.4+)

To share configurations across isolates, serialize the configuration registry to a plain JSON-compatible map and import it in a worker isolate:

```dart
// In primary isolate:
final configMap = Logger.exportConfig();

// In background isolate:
Logger.importConfig(configMap);
```

Non-serializable fields (like custom sinks or formatters) are mapped via the `LoggerSerializationRegistry.register` API to allow seamless reconstructive routing.

### Observability & Metrics (v0.8.4+)

Monitor cache efficiency, pipeline handler failures, and memory buffer allocations or GC/leak warnings:

```dart
final metricsJson = LoggerMetrics.toJson();
print('Cache hits: ${LoggerMetrics.cacheHits}');
print('Buffer leaks: ${LoggerMetrics.bufferLeaks}');
```

### Graceful Fallback & Degradation (v0.8.4+)

If all configured handlers throw exceptions, `logd` gracefully falls back to console output so that critical diagnostics are never lost. You can customize this behavior (or disable it) using `Logger.fallbackHandler`:

```dart
Logger.fallbackHandler = (final entry, final error, final stackTrace) {
  stderr.writeln('ALERT: All log handlers failed for: ${entry.message}');
};
```

### Testing Utilities (v0.8.4+)

Import `package:logd/testing.dart` to assert against logs inside your test suites:

```dart
import 'package:logd/testing.dart';

void main() {
  test('verify logic logs warning', () async {
    final logger = TestLogger.get('app');
    final capture = CaptureSink();
    logger.configure(handlers: [
      Handler(formatter: const PlainFormatter(), sink: capture),
    ]);

    performAction(logger);

    expect(capture, hasLog(
      message: contains('action failed'),
      level: LogLevel.warning,
    ));
  });
}
```

For a detailed walkthrough of each execution engine, see the [Execution Engines Guide](../../doc/handler/engines.md).

## Use Cases

### Development Console

```dart
Logger.configure('global', handlers: [
  const Handler(
    formatter: StructuredFormatter(),
    decorators: [
      HierarchyDepthPrefixDecorator(indent: '│ '),
      BoxDecorator(borderStyle: BorderStyle.rounded),
      StyleDecorator(DarkTheme()),
    ],
    sink: const ConsoleSink(lineLength: 80),
  ),
]);
```

### Production JSON

```dart
Logger.configure('global', handlers: [
  Handler(
    formatter: JsonFormatter(),
    sink: FileSink('logs/production.log'),
    ),
]);
```

### LLM-Native Logging (TOON)

Optimize logs for consumption by AI agents by using the Token-Oriented Object Notation:

```dart
Logger.configure('ai.agent', handlers: [
  Handler(
    formatter: const ToonFormatter(
      arrayName: 'context',
      metadata: {LogMetadata.timestamp},
    ),
    sink: FileSink('logs/ai_feed.toon'),
  ),
]);
```

**Result**: A highly token-efficient, flat format that LLMs can parse with minimal overhead. All standard sinks (`ConsoleSink`, `FileSink`, `HttpSink`) auto-detect `ToonFormatter` via the standard `AutoEncoder.encoderKey` contract (`'logd.encoder'`), automatically emitting TOON table structures without requiring manual `encoder: ToonEncoder()` overrides.

#### Dialects & Pipeline Ingestion (v0.9.1+)
TOON supports two output dialects via `ToonFormatter(dialect: ...)`:
- **`ToonDialect.compact`** (default): Minimal byte footprint for LLM context windows.
- **`ToonDialect.strict`**: Adds version headers (`-- TOON/1.0 logs`) and parser hints (`-- DELIMITER:\t QUOTE:" NULL:\N`) while emitting explicit `\N` tokens for null/absent fields. Ideal for automated log processing with **DuckDB**, **Loki**, or **awk**.

```dart
// Strict dialect for DuckDB / log pipelines
Handler(
  formatter: const ToonFormatter(
    dialect: ToonDialect.strict,
    sortKeys: true, // Deterministic key ordering
    maxDepth: 3,    // Bounded map recursion
  ),
  sink: FileSink('logs/pipeline.toon'),
)
```

#### LLM Context Slicing (`extractPreamble`)
When slicing a TOON log stream for a sliding window or RAG context prompt, extract the preamble header line to retain full schema context:

```dart
final bytes = await File('logs/app.toon').readAsBytes();
final schema = ToonEncoder.extractPreamble(bytes) ?? '';
final recentLines = sliceLines(bytes, last: 50);

final llmPrompt = '$schema\n${recentLines.join('\n')}';
```



### Network Logging

Ship logs to remote servers with built-in resilience:

```dart
const httpSink = HttpSink(
  url: 'https://logs.api.com',
  batchSize: 50,
  flushInterval: Duration(seconds: 10),
  dropPolicy: DropPolicy.discardOldest,
);

Logger.configure('app', handlers: [
  Handler(formatter: JsonFormatter(), sink: httpSink),
]);
```

Supported sinks: `HttpSink` (batching & retries), `SocketSink` (real-time streaming).

```dart
// For real-time streaming to a WebSocket server:
const socketSink = SocketSink(
  url: 'wss://monitor.example.com/logs',
);
```

### In-Memory Ring Buffering (MemorySink)

For testing, in-app debug panels, or transient error buffer dumps:
```dart
final memorySink = MemorySink<LogDocument>(capacity: 100);

Logger.configure('global', handlers: [
  Handler(formatter: const PlainFormatter(), sink: memorySink),
]);

// Inspect stored entries or clear buffer:
print(memorySink.logs.length);
memorySink.clear();
```

### SQLite Persistence Logging (`logd_sqlite`)

For structured SQLite database persistence, WAL-mode batch transaction commits, retention policies, and built-in search query filtering, use the satellite package [`logd_sqlite`](https://pub.dev/packages/logd_sqlite):

```yaml
dependencies:
  logd: ^0.9.2
  logd_sqlite: ^0.1.0
```

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

  final logger = Logger.get('app.payment');
  logger.info(
    'Payment transaction processed',
    context: {'transactionId': 'TX-9042', 'amount': 150.00},
  );

  // Search & Filter stored logs
  final errorLogs = sqliteSink.queryLogs(
    minLevel: LogLevel.warning,
    search: 'Payment',
    limit: 50,
  );

  // Inspect level breakdown summary
  final counts = sqliteSink.fetchLevelCounts();
  print('Warning/Error count: ${counts[LogLevel.warning]}');

  await sqliteSink.dispose();
}
```

Key features:
- **Write-Ahead Logging (WAL Mode)** & atomic transaction batching (`batchSize`, `flushInterval`).
- **Auto-Pruning Retention Policies** (`maxEntries`, `maxAge`).
- **Rich Query & Inspection Engine** (`queryLogs`, `fetchLevelCounts`, `fetchDistinctLoggerNames`).
- See full documentation, configuration parameters, and schema details in the [`logd_sqlite` Package Manual](https://pub.dev/packages/logd_sqlite).




### Microservice Logging

```dart
Logger.configure('api', handlers: [
  Handler(formatter: JsonFormatter(), sink: FileSink('logs/api.log')),
]);

Logger.configure('database', handlers: [
  Handler(formatter: JsonFormatter(), sink: FileSink('logs/db.log')),
]);

Logger.configure('auth', handlers: [
  Handler(
    formatter: JsonFormatter(),
    sink: FileSink('logs/security.log'),
    filters: [LevelFilter(LogLevel.warning)],
  ),
]);
```

## Flutter integration

Capture framework errors and async errors:

```dart
void main() {
  // Listen to all uncaught Flutter errors
  FlutterError.onError = (final details) {
    Logger.get('app.crash').error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () => runApp(MyApp()),
    (error, stack) {
      Logger.get('app.crash').error(
        'Uncaught error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}
```

## Documentation

- **[Documentation Index](https://github.com/pooriaaskarim/logd/blob/master/doc/README.md)** - Overview and navigation
- **[Logger Philosophy](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/philosophy.md)** - Design principles and rationale
- **[Logger Architecture](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/architecture.md)** - Implementation details
- **[Handler Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/architecture.md)** - Pipeline and sink customization
- **[Target Handlers Showcase](https://github.com/pooriaaskarim/logd/blob/master/packages/logd/example/handler/showcase/target_handlers_showcase.dart)** - Interactive showcase and verification of all 8 pre-wired TargetHandlers
- **[Execution Engines Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/engines.md)** - Standard, Arena, and Native engines guide
- **[Engine Stability Report](https://github.com/pooriaaskarim/logd/blob/master/doc/engine_stability_report.md)** - Engine profiling & memory lifecycle report
- **[Migration Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/migration.md)** - Upgrading from legacy components
- **[Decorator Composition](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/decorator_compositions.md)** - Execution priority and flow
- **[Time Module](https://github.com/pooriaaskarim/logd/blob/master/doc/time/architecture.md)** - Timestamp and timezone handling
- **[Roadmap](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/roadmap.md)** - Planned features and vision

---

## Contributing

- Report bugs or suggest features via [GitHub Issues](https://github.com/pooriaaskarim/logd/issues).  
- Share ideas in [Discussions](https://github.com/pooriaaskarim/logd/discussions).  

All contributions should follow the guidelines in [CONTRIBUTING.md](../../CONTRIBUTING.md) and, for docs, [doc/CONTRIBUTING_DOCS.md](https://github.com/pooriaaskarim/logd/blob/master/doc/CONTRIBUTING_DOCS.md).

## License

This project is licensed under the **BSD 3-Clause License**. See the [LICENSE](LICENSE) file for details.

## Support

- Issues: [GitHub Issues](/issues)  
- Discussions: [GitHub Discussions](/discussions)  
- Package page: [logd on pub.dev](https://pub.dev/packages/logd)
