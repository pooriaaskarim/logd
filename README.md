# logd

[![Pub Version](https://img.shields.io/pub/v/logd.svg)](https://pub.dev/packages/logd)
[![Pub Points](https://img.shields.io/pub/points/logd.svg)](https://pub.dev/packages/logd/score)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A hierarchical, high-performance logging library for Dart and Flutter applications.

`logd` provides fine-grained control over logging output through a flexible pipeline of handlers, formatters, sinks, and filters. It is designed for complex applications requiring sophisticated logging strategies while maintaining zero-boilerplate simplicity for basic use cases.

---

## Why logd?

**Hierarchical Configuration**: Organize loggers in a tree structure (`app.network.http`) where children inherit settings from parents. Configure once at the top level, override where needed.

**Performance-Focused**: Lazy resolution and aggressive caching ensure minimal overhead. Disabled loggers cost virtually nothing.

**Production-Ready**: Built-in fail-safe mechanisms prevent logging failures from crashing your application. Suitable for production environments.

**Flexible Output**: Support for multiple output destinations (console, file, network), structured formats (JSON, boxed text), and intelligent filtering.

---

## Quick Start

### Installation

Add `logd` to your `pubspec.yaml`.

```yaml
dependencies:
  logd: ^latest_version
```

Then run:
```bash
dart pub get  # or flutter pub get
```

### Basic Usage

```dart
import 'package:logd/logd.dart';

void main() {
  final logger = Logger.get('app');
  
  logger.info('Application started');
  logger.debug('Debug information');
  logger.warning('Low disk space');
  logger.error('Connection failed', error: exception, stackTrace: stack);
}
```

**Output**:
```
[app][INFO]
2025-01-03 00:15:23.456
--app_main.dart:5
----|Application started
```

---

## Core Concepts

### Hierarchical Loggers

Loggers are named using dot-separated paths and inherit configuration from their ancestors:

```dart
// Configure the entire 'app' subtree
Logger.configure('app', logLevel: LogLevel.warning);

// Override for specific subsystem
Logger.configure('app.network', logLevel: LogLevel.debug);

// Create loggers anywhere
final uiLogger = Logger.get('app.ui.button');      // inherits WARNING from 'app'
final httpLogger = Logger.get('app.network.http'); // inherits DEBUG from 'app.network'

uiLogger.debug('Click');   // ignored (warning threshold)
httpLogger.debug('GET /'); // visible (debug threshold)
```

### Log Levels

Available levels in increasing severity:
- `LogLevel.trace`: Detailed diagnostic information
- `LogLevel.debug`: Developer-focused debugging
- `LogLevel.info`: General informational messages
- `LogLevel.warning`: Warning messages for potentially harmful situations
- `LogLevel.error`: Error messages for failures

---

## Advanced Features

### Custom Handlers

Combine formatters and sinks to create custom output pipelines:

```dart
// JSON logs to rotating file
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

### Atomic Multi-Line Logs

Prevent log interleaving in concurrent environments:

```dart
final buffer = logger.infoBuffer;
buffer?.writeln('=== User Session ===');
buffer?.writeln('User ID: ${user.id}');
buffer?.writeln('Login time: ${DateTime.now()}');
buffer?.writeln('IP: ${request.ip}');
buffer?.sink();  // Atomic write of all lines
```

### Multiple Output Destinations

Send logs to multiple destinations simultaneously:

```dart
final consoleHandler = Handler(
  formatter: StructuredFormatter(),
  decorators: [
    BoxDecorator(useColors: true),
    AnsiColorDecorator(),
  ],
  sink: ConsoleSink(),
);
// Note: Decorators are auto-sorted by type for optimal composition

final fileHandler = Handler(
  formatter: PlainFormatter(),
  sink: FileSink('logs/app.log'),
);

Logger.configure('global', handlers: [consoleHandler, fileHandler]);
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

### Flutter Integration

Capture framework errors and uncaught exceptions:

```dart
void main() {
  // Attach to Flutter framework errors
  Logger.attachToFlutterErrors();
  
  // Capture async errors
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

### Timezone and Timestamp Control

Customize timestamp format and timezone:

```dart
final timestamp = Timestamp(
  formatter: 'yyyy-MM-dd HH:mm:ss.SSS Z',
  timezone: Timezone.named('America/New_York'),
);

Logger.configure('app', timestamp: timestamp);
```

**Output**: `2025-01-02 14:30:45.123 -05:00`

### File Rotation Strategies

#### Size-Based Rotation

```dart
FileSink(
  'logs/app.log',
  fileRotation: SizeRotation(
    maxSize: '10 MB',
    backupCount: 5,
    compress: true,
  ),
)
// Creates: app.log, app.1.log.gz, app.2.log.gz, etc.
```

#### Time-Based Rotation

```dart
FileSink(
  'logs/app.log',
  fileRotation: TimeRotation(
    interval: Duration(hours: 1),
    timestamp: Timestamp(formatter: 'yyyy-MM-dd_HH'),
    backupCount: 24,
  ),
)
// Creates: app-2025-01-02_14.log, app-2025-01-02_15.log, etc.
```

### Performance Optimization

For production environments with static configuration:

```dart
// After configuration is complete, freeze the hierarchy
Logger.get('app').freezeInheritance();

// This snapshots all settings, eliminating dynamic resolution overhead
// Note: Changes to parent loggers won't affect frozen children
```

---

## Use Cases

### Development Console Logging

```dart
// Hierarchy-aware, colored, and boxed output for terminal
Logger.configure('global', handlers: [
  Handler(
    formatter: StructuredFormatter(),
    decorators: [
      // Auto-sorted by type: Visual -> Structural (Box -> Hierarchy)
      const AnsiColorDecorator(
        useColors: true,
        colorHeaderBackground: true,
      ),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        useColors: true,
      ),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
    ],
    sink: ConsoleSink(),
  ),
]);
```

### Production JSON Logging

```dart
// Structured JSON for log aggregation systems
Logger.configure('global', handlers: [
  Handler(
    formatter: JsonFormatter(),
    sink: FileSink('logs/production.log'),
  ),
]);
```

### Microservice Logging

```dart
// Different handlers for different modules
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

---

## Documentation

Comprehensive technical documentation is available in the `docs/` directory:

- **[Documentation Index](docs/README.md)** - Overview and navigation
- **[Logger Philosophy](docs/logger/philosophy.md)** - Design principles and rationale
- **[Logger Architecture](docs/logger/architecture.md)** - Implementation details
- **[Handler Guide](docs/handler/architecture.md)** - Pipeline customization
- **[Time Module](docs/time/architecture.md)** - Timestamp and timezone handling
- **[Roadmap](docs/logger/roadmap.md)** - Planned features and known limitations

---

## Contributing

We welcome contributions! Whether you're:
- Reporting bugs
- Suggesting features
- Improving documentation
- Submitting pull requests

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style and standards
- Testing requirements
- PR submission process
- Documentation updates

For documentation contributions specifically, see [docs/CONTRIBUTING_DOCS.md](docs/CONTRIBUTING_DOCS.md).

---

## License

This project is licensed under the **BSD 3-Clause License**. See the [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/pooriaaskarim/logd/issues)
- **Discussions**: [GitHub Discussions](https://github.com/pooriaaskarim/logd/discussions)
- **Pub.dev**: [logd package](https://pub.dev/packages/logd)
