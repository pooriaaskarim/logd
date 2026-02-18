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
- **Layout Sovereignty** – A centralized engine guarantees structural integrity (e.g., perfect boxes) across all terminal widths.
- **Platform‑agnostic styling** – Decouple visual intent from representation using the semantic `LogTheme` system.

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

### Log levels

| Level | Description |
|-------|-------------|
| `trace` | Diagnostic noise |
| `debug` | Developer debugging |
| `info`  | Informational |
| `warning` | Potential issue |
| `error` | Failure |

## Advanced Features

### Custom Handlers

Create complex pipelines of formatters and sinks:

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
      align: ture,
    ),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
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
    ConsoleSinK(),
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

### File Rotation

| Strategy | Example |
|---------|--------|
| Size | `FileSink('logs/app.log', fileRotation: SizeRotation(maxSize: '10 MB', backupCount: 5, compress: true))` |
| Time | `FileSink('logs/app.log', fileRotation: TimeRotation(interval: Duration(hours: 1), timestamp: Timestamp(formatter: 'yyyy-MM-dd_HH'), backupCount: 24))` |

### Performance Tuning

```dart
Logger.get('app').freezeInheritance();   // snapshot config, eliminate runtime look‑ups
```

## Use Cases

### Development Console

```dart
Logger.configure('global', handlers: [
  const Handler(
    formatter: StructuredFormatter(),
    decorators: [
      HierarchyDepthPrefixDecorator(indent: '│ '),
      BoxDecorator(borderStyle: BorderStyle.rounded),
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
    ],
    sink: ConsoleSink(),
    lineLength: 80,
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

**Result**: A highly token-efficient, flat format that LLMs can parse with minimal overhead. The header is emitted only when the configuration changes.


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
  Logger.attachToFlutterErrors(); // listens to all uncaught Flutter errors

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
- **[Migration Guide](https://github.com/pooriaaskarim/logd/blob/master/doc/handler/migration.md)** - Upgrading from legacy components
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
