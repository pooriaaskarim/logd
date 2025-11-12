# logd

[![Pub Version](https://img.shields.io/pub/v/logd.svg)](https://pub.dev/packages/logd)
[![Pub Points](https://img.shields.io/pub/points/logd.svg)](https://pub.dev/packages/logd/score)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A flexible, hierarchical logging library for Dart and Flutter applications. `logd` provides
customizable logging with support for multiple handlers, formatters, sinks, and filters,
making it ideal for debugging, monitoring, and production logging in complex projects.

## Features

- **Hierarchical Logger Tree**: Dot-separated case-insensitive naming for inheritance (e.g., 'app.ui' inherits from 'app').
- **Pure Dart Support**: Fully compatible with standalone Dart environments.
- **Dynamic Inheritance with Caching**: Dynamic configurations; configurations dynamically propagate down the hierarchy tree; cached configurations for performance.
- **Customizable Layouts**: Boxed, JSON, or custom formatters.
- **Customizable Outputs**: Console, File, and Network Sinks; Size/Time based File Rotation; Level and Regex Filters.
- **Stack Trace Integration**: Automatic caller extraction, configurable frame counts per level, ignoring packages like 'flutter'.
- **Timestamp/Timezone Support**: Custom patterns with timezone support (e.g., 'yyyy-MM-dd HH:mm:ss ZZZ').
- **Multi-line Buffers**: Atomic logging for complex messages.
- **Flutter Integration**: Attach to FlutterError and uncaught exceptions.
- **Immutable and Efficient**: Loggers act as lightweight proxies to configurations; lazy inheritance and caching for optimal performance.

## Installation

Add `logd` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^latest_version
```
Then run:
```bash
dart pub get
```
For Flutter:
```bash
flutter pub get
```
## Usage
### Basic Logging
Import and get a logger:
```dart
import 'package:logd/logd.dart';

final logger = Logger.get('my.app');
logger.info('Application started');
```
### Configuring Loggers
Set global or specific configs:
```dart
Logger.configure('global', logLovel: LogLevel.info);
Logger.configure('my.app', enabled: true, includeFileLineInHeader: true);
```
### Logging with Details
Include errors and stack traces:
```dart
try {
// Code that may fail
} catch (e, stack) {
logger.error('Operation failed', error: e, stackTrace: stack);
}
```
### Multi-line Buffers
For atomic multi-line logs:
```dart
final buffer = logger.debugBuffer;
buf?.writeln('Step 1: Initialize');
buf?.writeln('Step 2: Process data');
buf?.sync();
```
### Hierarchical Inheritance
Child loggers inherit from parents dynamically:
```dart
final parent = Logger.get('app');
final child = Logger.get('app.ui');

Logger.configure('app', logLevel: LogLevel.warning);
// 'app.ui' now uses warning level unless overridden
```
## Advanced:
### Freezing Inheritance
Snapshot configs down the Logger hierarchy tree to children for isolation or optimization:
```dart
parent.freezeInheritance();
```
### Attaching to Flutter
Capture framework errors:
```dart
Logger.attachToFlutterErrors();
```

### Attach to Uncaught Errors
```dart
  runZonedGuarded(
    // Run your app here
    ,
    (error, stack) {
      Logger.get().error(
        'Caught uncaught error in zone',
        error: error,
        stackTrace: stack,
      );
    },
);
```
## Examples
### Custom Handler
```dart
final handler = Handler(
  formatter: JsonFormatter(),
  sink: FileSink('logs/app.log'),
  filters: [LevelFilter(LogLevel.warning)],
);
Logger.configure('global', handlers: [handler]);
```
### FileRotation for FileSink
#### Time Based
 ```dart
 FileSink(
   'logs/app.log',
   fileRotation: TimeRotation(
     interval: Duration(days: 1),
     nameFormatter: Timestamp(formatter: 'yyyy-MM-dd'),
     backupCount: 7,
     compress: true,
   ),
 );
// Rotated files: app-2025-11-11.log.gz, etc.
// (current logs always to 'app.log').
```
#### Size Based
```dart
FileSink(
  'logs/app.log',
  fileRotation: SizeRotation(
    maxSize: '10 MB',
    backupCount: 5,
    compress: true,
  ),
);
// Rotated files: app.1.log.gz, app.2.log.gz, etc. (index 1 is newest).
```
### Custom Timestamp
```dart
final ts = Timestamp(formatter: 'yyyy-MM-dd HH:mm:ss Z', timeZone: TimeZone.utc());
Logger.configure('global', timestamp: ts);
```

For more examples, see the example/ directory.


## Contributing
Contributions are welcome! Please read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License
This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for
details.
