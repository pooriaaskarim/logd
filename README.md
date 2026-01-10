# logd

A **high‑performance** hierarchical logger for Dart and Flutter. Build structured logs, control output destinations, and keep overhead minimal.

[![Pub Version](https://img.shields.io/pub/v/logd.svg)](https://pub.dev/packages/logd)  
[![Pub Points](https://img.shields.io/pub/points/logd.svg)](https://pub.dev/packages/logd/score)  
[![License: BSD 3‑Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

## Why logd?

- **Hierarchical configuration** – Loggers are named with dot‑separated paths (`app.network.http`). Settings propagate from parents to children unless overridden.
- **Zero‑boilerplate** – Simple `Logger.get('app')` gives a fully‑configured logger.
- **Performance‑first** – Lazy resolution, aggressive caching, and optional inheritance freezing keep the cost of a disabled logger essentially zero.
- **Flexible output** – Choose between console, file, network, or any custom sink; format logs as plain text, boxed, or structured JSON.

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
[app][INFO] 2025-01-03 00:15:23.456
  --app_main.dart:5
  ----Application started
```

> *Tip*: Use `Logger.configure` to set global log‑level, handlers, or timestamps once in `main()`.

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
  formatter: JsonFormatter(),
  sink: FileSink(
    'logs/app.log',
    fileRotation: TimeRotation(
      interval: Duration(days: 1),
      timestamp: Timestamp(formatter: 'yyyy-MM-dd'),
      backupCount: 7,
      compress: true,
    ),
  ),
  filters: [LevelFilter(LogLevel.info)],  // Only info and above
);

Logger.configure('app', handlers: [jsonHandler]);
```

**Result**: JSON logs written to `logs/app.log`, rotated daily, keeping 7 compressed backups.

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
  formatter: StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    ColorDecorator(),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
);

final fileHandler = Handler(
  formatter: PlainFormatter(),
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
  sink: NetworkSink('https://logs.example.com'),
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
      ColorDecorator(config: ColorConfig(headerBackground: true)),
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
    sink: NetworkSink('https://security-logs.example.com'),
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

- **[Documentation Index](doc/README.md)** - Overview and navigation
- **[Logger Philosophy](doc/logger/philosophy.md)** - Design principles and rationale
- **[Logger Architecture](doc/logger/architecture.md)** - Implementation details
- **[Handler Guide](doc/handler/architecture.md)** - Pipeline customization
- **[Time Module](doc/time/architecture.md)** - Timestamp and timezone handling
- **[Roadmap](doc/logger/roadmap.md)** - Planned features and known limitations

---

## Contributing

- Report bugs or suggest features via [GitHub Issues](https://github.com/pooriaaskarim/logd/issues).  
- Share ideas in [Discussions](https://github.com/pooriaaskarim/logd/discussions).  

All contributions should follow the guidelines in [CONTRIBUTING.md](CONTRIBUTING.md) and, for docs, [docs/CONTRIBUTING_DOCS.md](doc/CONTRIBUTING_DOCS.md).

## License

This project is licensed under the **BSD 3-Clause License**. See the [LICENSE](LICENSE) file for details.

## Support

- Issues: [GitHub Issues](/issues)  
- Discussions: [GitHub Discussions](/discussions)  
- Package page: [logd on pub.dev](https://pub.dev/packages/logd)
