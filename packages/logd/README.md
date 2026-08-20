<h1>
  <a href="https://pub.dev/packages/logd">logd</a>
  &nbsp;
  <a href="https://pub.dev/packages/logd"><img src="https://img.shields.io/pub/v/logd.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/logd/score"><img src="https://img.shields.io/pub/points/logd.svg" alt="pub points"></a>
  <a href="https://opensource.org/licenses/BSD-3-Clause"><img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="BSD-3-Clause"></a>
</h1>

![logd Hero](https://raw.githubusercontent.com/pooriaaskarim/logd/refs/heads/master/assets/img/logd_hero.webp)

**A structured, hierarchical logging engine for Dart and Flutter.**

Most Dart logging libraries handle the simple case well. logd handles the rest: multiple isolates, structured context propagation, background I/O offloading, and a full output pipeline — from styled ANSI terminals to a live browser dashboard — without ever breaking the simple case.

---

## Quick Start

```yaml
dependencies:
  logd: ^latest_version
```

```dart
import 'package:logd/logd.dart';

void main() {
  final logger = Logger.get('app');
  logger.info('Server started');
  logger.warning('Disk space low', context: {'freeGb': 1.2});
  logger.error('Connection failed', error: e, stackTrace: st);
}
```

That's it for most use cases. Everything below is opt-in.

---

## Why logd?

### The problems it solves

**Logging across isolates is broken in most libraries.**
When you offload work to a background isolate, your logger either silently drops entries or forces you to wire up ports manually. logd's `.async()` constructors offload the entire pipeline — formatting, decoration, I/O — to a worker isolate, returning to your code in ~15µs.

**Structured context disappears in async code.**
Attaching a `requestId` to every log entry in a request handler means threading a `Map` through every function signature. logd's zone-based MDC (`LogContext.run`) binds context once and propagates it automatically through every `await`, microtask, and nested call — with zero allocations when no context is present.

**Output pipelines are all-or-nothing.**
Most libraries give you console or file. logd gives you a clean pipeline: Formatter → Decorator → Encoder → Sink. Swap any stage independently. Run the same formatter to a styled ANSI terminal, a JSON file, an HTML report, and a live browser dashboard — simultaneously.

---

## Pre-Wired Handlers

Seven core ready-to-use handlers cover common destinations out of the box (with network telemetry provided by [`logd_network`](https://pub.dev/packages/logd_network)). No pipeline wiring required:

```dart
// Styled terminal output (dark or light theme)
ConsoleHandler(theme: const LogTheme.dark())

// Structured JSON to file (pretty or compact)
JsonFileHandler('logs/api.json', pretty: true)

// Self-contained HTML report with search and level filters
HtmlFileHandler('logs/session.html')

// Token-efficient format for LLM / AI agent consumption
ToonFileHandler('logs/telemetry.toon')

// Plain text to file
PlainFileHandler('logs/app.log')

// GitHub-Flavored Markdown for CI summaries
MarkdownFileHandler('logs/ci.md')

// In-memory ring buffer for tests and debug panels
MemoryHandler(capacity: 200)

// Live browser dashboard via HTTP + WebSocket server (from package:logd_network)
HttpDashboardHandler(port: 8080)
```

Add `.async()` to any output-bound handler to offload its pipeline to a background isolate:

```dart
Logger.configure('app', handlers: [
  ConsoleHandler.async(),
  JsonFileHandler.async('logs/production.json'),
  HtmlFileHandler.async('logs/report.html'),
]);
```

> [!TIP]
> `MemoryHandler` and `HttpDashboardHandler` intentionally stay synchronous — they need direct heap access and deterministic port binding respectively.

---

## Core Concepts

### Log Levels

| Level | Description |
|---|---|
| `trace` | Verbose diagnostic noise |
| `debug` | Developer debugging |
| `info` | Informational milestones |
| `warning` | Potential issues |
| `error` | Failures |

### Hierarchical Logger Tree

Loggers are named with dot-separated paths. Configuration propagates from parents to children unless overridden — the same model as Python's `logging` or Java's `log4j`:

```dart
// Set the baseline for the whole app
Logger.configure('app', logLevel: LogLevel.warning);

// Override a noisy subsystem
Logger.configure('app.network', logLevel: LogLevel.debug);

// Deep loggers inherit from the nearest configured ancestor
final httpLogger = Logger.get('app.network.http'); // → DEBUG
final uiLogger   = Logger.get('app.ui.button');    // → WARNING
```

### Bulk Configuration

Configure multiple loggers atomically — validated and cache-invalidated in a single pass:

```dart
Logger.configureMultiple({
  'global':      const LoggerConfig(logLevel: LogLevel.warning),
  'app.network': const LoggerConfig(logLevel: LogLevel.debug),
  'app.ui':      const LoggerConfig(enabled: false),
});
```

- **Atomic Validation**: the entire map is validated before any updates are written.
- **Single-Pass Invalidation**: cache is invalidated in one optimized pass for all changed loggers and descendants.

### Pattern-Based Configuration

Match loggers dynamically with glob patterns:

```dart
Logger.configurePattern('*.database', logLevel: LogLevel.debug);
Logger.configurePattern('vendor.*',   enabled: false);
Logger.configurePattern('app.services.*', logLevel: LogLevel.info);
```

---

## Ambient Structured Context (MDC)

Bind context once. It flows automatically through every `await`, sync call, and microtask — no threading required:

```dart
Future<void> handleCheckout(String requestId, int userId) async {
  await LogContext.run({'requestId': requestId, 'userId': userId}, () async {
    logger.info('Validating cart');       // → {requestId: req-9812, userId: 42}
    await chargePaymentGateway();         // downstream async calls inherit context
    logger.info('Order completed');       // → {requestId: req-9812, userId: 42}
  });
}

Future<void> chargePaymentGateway() async {
  // No context parameter. No logger parameter. Zero boilerplate.
  Logger.get('app.payment').info('Connecting to Stripe');
  // Output includes: {requestId: req-9812, userId: 42}
}
```

- **Scope nesting**: inner `LogContext.run` scopes inherit outer keys; conflicting keys override without mutation.
- **Call-site overrides**: `logger.info('msg', context: {'key': 'val'})` overrides specific keys for one entry.
- **Concurrent isolation**: parallel tasks (`Future.wait`) maintain separate contexts with zero race conditions.
- **Zero-cost fast path**: when no context is present, dispatch performs 0 heap allocations.

---

## Output Formats

| Format | Handler / Formatter | Best for |
|---|---|---|
| Styled ANSI | `ConsoleHandler` | Development terminal |
| Structured JSON | `JsonFileHandler` / `JsonFormatter` | Log aggregators (Loki, ELK) |
| HTML report | `HtmlFileHandler` / `HtmlEncoder` | Shareable session logs |
| Markdown | `MarkdownFileHandler` | CI/CD job summaries |
| TOON | `ToonFileHandler` / `ToonFormatter` | LLM / AI agent consumption |
| Plain text | `PlainFileHandler` / `PlainFormatter` | Simple file logs |
| SQLite | [`logd_sqlite`](https://pub.dev/packages/logd_sqlite) | Queryable persistent storage |

### TOON: Logs Optimized for LLMs

Token-Oriented Object Notation emits the column schema once, then tab-delimited rows — **30–50% fewer tokens than JSON** for the same data:

```dart
Logger.configure('ai.agent', handlers: [
  ToonFileHandler('logs/agent.toon'),
]);
```

The `strict` dialect adds parser headers for direct ingestion into DuckDB, Loki, or awk:

```dart
Handler(
  formatter: const ToonFormatter(
    dialect: ToonDialect.strict,
    sortKeys: true,  // deterministic key ordering
    maxDepth: 3,     // bounded map recursion
  ),
  sink: FileSink('logs/pipeline.toon'),
)
```

When slicing a TOON file for an LLM sliding-window prompt:

```dart
final schema = ToonEncoder.extractPreamble(bytes) ?? '';
final window = sliceLines(bytes, last: 50);
final prompt = '$schema\n${window.join('\n')}';
```

---

## Advanced Features

### Custom Pipeline Handlers

When pre-wired handlers aren't enough, compose your own:

```dart
final handler = Handler(
  formatter: const JsonFormatter(
    metadata: {LogMetadata.timestamp, LogMetadata.logger},
  ),
  decorators: const [StyleDecorator(DarkTheme())],
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

Logger.configure('app', handlers: [handler]);
```

> [!NOTE]
> Modern formatters automatically include `level`, `message`, `error`, and `stackTrace`. The `metadata` parameter controls optional context like timestamps or logger names.

### Multiple Outputs

Attach multiple handlers to route the same logs to different destinations:

```dart
Logger.configure('global', handlers: [
  Handler(
    formatter: const StructuredFormatter(),
    decorators: const [
      BoxDecorator(borderStyle: BorderStyle.rounded),
      StyleDecorator(DarkTheme()),
    ],
    sink: const ConsoleSink(lineLength: 80),
  ),
  Handler(
    formatter: const PlainFormatter(),
    sink: FileSink('logs/app.log'),
  ),
]);
```

Or fan out a single formatter to multiple sinks:

```dart
Handler(
  formatter: const PlainFormatter(),
  sink: MultiSink(sinks: [
    ConsoleSink(),
    FileSink('logs/app.log'),
  ]),
)
```

### Atomic Multi-Line Logs

Prevent line interleaving in concurrent environments:

```dart
final buffer = logger.infoBuffer;
buffer?.writeln('=== User Session ===');
buffer?.writeln('User ID: ${user.id}');
buffer?.writeln('Login time: ${DateTime.now()}');
buffer?.writeln('IP: ${request.ip}');
buffer?.sink(); // flushed as a single atomic LogEntry
```

### Filtering

```dart
// Level filter — errors only
Handler(filters: [LevelFilter(LogLevel.error)], ...)

// Regex filter — exclude sensitive fields
Handler(filters: [RegexFilter(r'password|secret|token', exclude: true)], ...)

// Context filter — match on MDC key presence or value
Handler(filters: [ContextFilter(key: 'tenantId', value: 'acme')], ...)
```

### Timestamp & Timezone

```dart
final timestamp = Timestamp(
  formatter: 'yyyy-MM-dd HH:mm:ss.SSS Z',
  timezone: Timezone.named('America/New_York'),
);

Logger.configure('app', timestamp: timestamp);
```

For high-frequency or daily aggregate logs, bypass sub-second calculations entirely with date-only formatting:

```dart
Logger.configure('app.audit', timestamp: Timestamp.dateOnly('yyyy-MM-dd'));
```

### File Rotation

```dart
// Size-based
FileSink('logs/app.log', fileRotation: SizeRotation(
  maxSize: '10 MB', backupCount: 5, compress: true,
))

// Time-based
FileSink('logs/app.log', fileRotation: TimeRotation(
  interval: Duration(hours: 1),
  timestamp: Timestamp(formatter: 'yyyy-MM-dd_HH'),
  backupCount: 24,
))
```

### Network Logging (`logd_network`)

Ship logs to remote servers with built-in resilience using [`package:logd_network`](https://pub.dev/packages/logd_network):

```dart
import 'package:logd/logd.dart';
import 'package:logd_network/logd_network.dart';

// HTTP batching with retry and drop policy
final httpSink = HttpSink(
  url: 'https://logs.api.com',
  batchSize: 50,
  flushInterval: const Duration(seconds: 10),
  dropPolicy: DropPolicy.discardOldest,
);

// Real-time WebSocket streaming
final socketSink = SocketSink(
  url: 'wss://monitor.example.com/logs',
);

Logger.configure('app', handlers: [
  Handler(formatter: const JsonFormatter(), sink: httpSink),
]);
```

---

## Performance

### Hot-Path Dispatch Bypass

Capturing caller origin (file, line, method) requires a `StackTrace.current` VM call on every log entry. When you don't need it, turn it off:

```dart
Logger.configure('app.analytics', includeOrigin: false);
```

Result: **~5x dispatch throughput gain** (~2.38µs vs ~11.76µs per entry). Explicit `stackTrace:` parameters and `stackMethodCount` overrides are still respected.

### Execution Engines

| Engine | Allocation | Platform | When to use |
|---|---|---|---|
| `StandardEngine` | GC heap | All | Default — always correct |
| `ArenaEngine` | LIFO pool | VM / Native | Complex logs, many decorators |
| `NativeEngine` | C heap via FFI | VM / Native | Narrow-width wrapping, 1.5x speedup |

### Inheritance Freezing

Eliminate hierarchy tree-walks on hot paths by baking resolved configuration into descendant loggers:

```dart
// Bake current resolved config into all descendants (O(1) lookup after)
Logger.get('app').freezeInheritance();

// Re-snapshot after ancestry changes, preserving explicit overrides
Logger.get('app').freezeInheritance(force: true);

// Restore dynamic resolution for specific fields only
Logger.get('app').unfreezeInheritance(
  fields: {'logLevel'},
  includeSelf: false, // descendants only
);
```

---

## Inheritance Control & Diagnostics

```dart
// Visualize the live logger hierarchy with effective values
Logger.printHierarchy();
final tree = Logger.formatHierarchy();

// Full JSON export — effective values, frozen state, ghost-node detection
final snapshot = Logger.exportHierarchy();

// Reset a namespace subtree (useful in tests)
Logger.reset('app.ui'); // resets 'app.ui' and its descendants
Logger.reset();         // full registry reset

// Hierarchy safety limit (warns at >10 levels by default)
Logger.maxHierarchyDepth = 12;
```

---

## Isolate Configuration Transport

Export and import the full logger registry across isolate boundaries:

```dart
// Primary isolate
final config = Logger.exportConfig();

// Worker isolate
Logger.importConfig(config);
```

Custom formatters and sinks are mapped via `LoggerSerializationRegistry.register`.

---

## Observability & Metrics

```dart
// Cache efficiency, handler failures, buffer allocations and leak warnings
print('Cache hits:    ${LoggerMetrics.cacheHits}');
print('Buffer leaks:  ${LoggerMetrics.bufferLeaks}');
print('Handler fails: ${LoggerMetrics.handlerFailures}');

final metricsJson = LoggerMetrics.toJson();
```

---

## Graceful Fallback & Degradation

If all configured handlers throw, logd automatically falls back to console output — critical logs are never silently lost. Customize or disable this behavior:

```dart
Logger.fallbackHandler = (entry, error, stackTrace) {
  stderr.writeln('ALERT: all handlers failed for: ${entry.message}');
};
```

---

## Use Cases

### Development Console

```dart
Logger.configure('global', handlers: [
  Handler(
    formatter: const StructuredFormatter(),
    decorators: const [
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
    formatter: const JsonFormatter(),
    sink: FileSink('logs/production.log'),
  ),
]);
```

### Microservice — Per-Subsystem Routing

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

### SQLite Persistence (`logd_sqlite`)

```yaml
dependencies:
  logd: ^0.9.4
  logd_sqlite: ^0.1.0
```

```dart
import 'package:logd/logd.dart';
import 'package:logd_sqlite/logd_sqlite.dart';

void main() async {
  final sqliteHandler = SqliteHandler(
    dbPath: 'app_logs.db',
    maxEntries: 10000,
    maxAge: const Duration(days: 7),
    batchSize: 50,
    flushInterval: const Duration(seconds: 2),
    walMode: true,
  );

  Logger.configure('app', handlers: [sqliteHandler]);

  final logger = Logger.get('app.payment');
  logger.info(
    'Payment processed',
    context: {'transactionId': 'TX-9042', 'amount': 150.00},
  );

  // Query stored logs
  final errors = sqliteHandler.queryLogs(
    minLevel: LogLevel.warning,
    search: 'Payment',
    limit: 50,
  );

  // Level breakdown
  final counts = sqliteHandler.fetchLevelCounts();
  print('Warnings: ${counts[LogLevel.warning]}');

  await sqliteHandler.dispose();
}
```

Key features: WAL-mode batch commits, auto-pruning retention (`maxEntries`, `maxAge`), rich query engine (`queryLogs`, `fetchLevelCounts`, `fetchDistinctLoggerNames`).

### In-Memory Ring Buffer

For testing, debug panels, or transient error dumps:

```dart
final memoryHandler = MemoryHandler(capacity: 100);
Logger.configure('global', handlers: [memoryHandler]);

// Inspect recent entries programmatically
print(memoryHandler.entries.length);
```

---

## Flutter Integration

```dart
void main() {
  FlutterError.onError = (details) {
    Logger.get('app.crash').error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () => runApp(MyApp()),
    (error, stack) => Logger.get('app.crash').error(
      'Uncaught error', error: error, stackTrace: stack,
    ),
  );
}
```

---

## Testing

```dart
import 'package:logd/testing.dart';

test('logs warning on failure', () async {
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
```

---

## Satellite Packages

| Package | Purpose |
|---|---|
| [`logd_sqlite`](https://pub.dev/packages/logd_sqlite) | WAL-mode SQLite persistence, auto-pruning, rich query engine |
| [`logd_network`](https://pub.dev/packages/logd_network) | HTTP batching, WebSocket streaming, embedded viewer dashboard |
| [`logd_linters`](https://pub.dev/packages/logd_linters) | Custom lint rules for arena lifecycle and formatter purity |

---

## Documentation

| Document | Description |
|---|---|
| [Logger Philosophy](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/philosophy.md) | 13 design principles with rationale |
| [Handler Architecture](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/architecture.md) | Pipeline internals |
| [Execution Engines Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/engines.md) | Standard, Arena, Native |
| [TOON Specification](https://github.com/pooriaaskarim/logd/blob/master/doc/toon_spec.md) | Format spec + DuckDB ingestion |
| [Isolates Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/isolates.md) | Cross-isolate configuration |
| [Migration Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/migration.md) | Upgrading from legacy components |
| [Architecture Decisions](https://github.com/pooriaaskarim/logd/blob/master/doc/decisions/README.md) | ADR-001 through ADR-006 |
| [Roadmap](https://github.com/pooriaaskarim/logd/blob/master/doc/logger/roadmap.md) | Planned features |

---

## Contributing

- Report bugs or suggest features via [GitHub Issues](https://github.com/pooriaaskarim/logd/issues)
- Share ideas in [GitHub Discussions](https://github.com/pooriaaskarim/logd/discussions)
- Read [CONTRIBUTING.md](https://github.com/pooriaaskarim/logd/blob/master/CONTRIBUTING.md) before sending a PR

## License

BSD 3-Clause. See [LICENSE](https://github.com/pooriaaskarim/logd/blob/master/LICENSE).
