import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logd/logd.dart';

import '../../../scripts/servers/network_test_utils.dart';

/// This example serves as a comprehensive tutorial for [logd].
/// It covers everything from basic usage to advanced hierarchical configuration,
/// custom pipelines, and network logging.
void main() async {
  print('================================================');
  print('          LOGD: COMPREHENSIVE SHOWCASE          ');
  print('================================================');
  print('Welcome to the logd tutorial. Follow the console');
  print('output to see how to master the logging engine.');
  print('');

  await runZonedGuarded(
    () async {
      _showcaseBasics();
      _showcaseHierarchy();
      _showcasePipelines();
      _showcaseTimeAndLocalization();
      _showcaseAdvancedLayouts();
      await _showcaseNetwork();

      print('\n\x1B[1mTutorial Complete!\x1B[0m');
      print('Check the source code in `example/main.dart` to learn more.');
    },
    (final error, final stack) {
      Logger.get().error(
        'Caught unexpected error in demo zone',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

/// 1. The Basics: Getting Started
/// logd uses a hierarchical naming system. The root logger is accessed via
/// Logger.get(), or you can specify a name.
void _showcaseBasics() {
  _section('1. The Basics');

  // By default, logd is configured with a ConsoleSink and StructuredFormatter.
  final logger = Logger.get('app')
    ..info('Welcome to Logd!')
    ..debug('Debug messages are hidden by default if level is higher.')
    ..warning('This is a warning message.')
    ..trace('Trace messages are not visible, right now.');

  // You can check and change the log level globally or per logger.
  Logger.configure('app', logLevel: LogLevel.trace);
  logger.trace('Now trace messages are visible.');
}

/// 2. Hierarchical Logging
/// Loggers inherit configuration from their parents. Overriding a parent's
/// config allows for fine-grained control over specific modules.
void _showcaseHierarchy() {
  _section('2. Hierarchical Logging');

  // We'll configure a decorator to visually show the depth.
  final hierarchicalHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(),
      const HierarchyDepthPrefixDecorator(indent: '  │ '),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('app.services', handlers: [hierarchicalHandler]);

  final authService = Logger.get('app.services.auth');
  final database = Logger.get('app.services.database');

  authService.info('User "admin" logged in.');
  database.debug('Starting transaction...');

  // Overriding a sub-logger's level doesn't affect the parent.
  Logger.configure('app.services.database', logLevel: LogLevel.error);
  database.info('This will NOT be printed.');
  database.error('Critical database failure!');
}

/// 3. Pipeline Architecture: Handlers, Formatters, & Decorators
/// logd pipelines are modular. A Handler composes a Formatter (what it says),
/// a sequence of Decorators (how it looks), and a Sink (where it goes).
void _showcasePipelines() {
  _section('3. Pipeline Architecture');

  const prettyHandler = Handler(
    formatter: JsonPrettyFormatter(),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.double),
      StyleDecorator(),
    ],
    sink: ConsoleSink(
      lineLength: 60,
    ),
  );

  Logger.configure('app.api', handlers: [prettyHandler]);
  Logger.get('app.api').info('Received GET /users/123');

  // Multi-Sink: Send logs to multiple places (e.g., Console + File)
  final multiHandler = Handler(
    formatter: const PlainFormatter(),
    sink: MultiSink([
      const ConsoleSink(),
      FileSink('logs/demo.log'),
    ]),
  );

  Logger.configure('app.audit', handlers: [multiHandler]);
  Logger.get('app.audit').info('Audit log saved to file (logs/) and console.');
}

/// 4. Time & Localization
/// You can configure how timestamps appear globally or per handler.
/// Timezones are fully supported (UTC, Local, or Fixed offsets).
void _showcaseTimeAndLocalization() {
  _section('4. Time & Localization');

  // Global Timestamp configuration via Logger.configure
  Logger.configure(
    'global',
    timestamp: Timestamp(
      formatter: 'yyyy-MM-dd HH:mm:ss.SSS',
      timezone: Timezone.utc(),
    ),
  );
  Logger.get('app').info('This log is in UTC.');

  // Reset to Local time
  Logger.configure(
    'global',
    timestamp: Timestamp(
      formatter: 'HH:mm:ss',
      timezone: Timezone.local(),
    ),
  );
  Logger.get('app').info('Now we are back to Local time.');

  // Named Timezone (e.g., Asia/Tehran)
  Logger.configure(
    'global',
    timestamp: Timestamp(
      formatter: 'HH:mm:ss ZZZ',
      timezone: Timezone.named('Asia/Tehran'),
    ),
  );
  Logger.get('app').info('Log from a specific named timezone.');

  // Reset to default for the rest of the demo
  Logger.configure(
    'global',
    timestamp: Timestamp(
      formatter: 'HH:mm:ss',
      timezone: Timezone.local(),
    ),
  );
}

/// 5. Advanced Layouts: Toon & JSON
/// Specialized formatters provide unique visual styles for different use cases.
void _showcaseAdvancedLayouts() {
  _section('5. Advanced Layouts');

  // Comic-style structured logs
  Logger.configure('app.toon', handlers: [
    const Handler(
      formatter: ToonFormatter(),
      sink: ConsoleSink(),
    )
  ]);
  Logger.get('app.toon').warning('Something unusual happened in the story!');

  // Vibrant JSON for deep inspection
  Logger.configure('app.vibrant', handlers: [
    const Handler(
      formatter: JsonPrettyFormatter(),
      sink: ConsoleSink(),
    )
  ]);
  Logger.get('app.vibrant').info('Inspection of complex data.');
}

/// 6. High-Performance Network Logging
/// logd can ship logs to remote servers via WebSocket or HTTP with batching.
Future<void> _showcaseNetwork() async {
  _section('6. Network Logging');

  Process? socketServer;
  Process? httpServer;

  try {
    // Dynamically find script paths
    final scriptFile = File(Platform.script.toFilePath());
    final projectRoot = scriptFile.parent.parent.parent.parent.path;
    final socketDir = '$projectRoot/scripts/servers/socket';
    final httpDir = '$projectRoot/scripts/servers/http';

    final socketPort = await NetworkTestUtils.findAvailablePort(12347);
    final httpPort = await NetworkTestUtils.findAvailablePort(8081);

    print('Starting local test servers...');
    socketServer = await Process.start(
      './.venv/bin/python',
      ['main.py', '--port', socketPort.toString()],
      workingDirectory: socketDir,
      environment: {'PYTHONUNBUFFERED': '1'},
    );

    httpServer = await Process.start(
      './.venv/bin/python',
      ['main.py', '--port', httpPort.toString()],
      workingDirectory: httpDir,
      environment: {'PYTHONUNBUFFERED': '1'},
    );

    // Give servers a moment to bind
    await Future.delayed(const Duration(seconds: 1));

    // Show server output in console
    socketServer.stdout.transform(utf8.decoder).listen((final data) {
      if (data.contains('ENTRY') || data.contains('Connection')) {
        stdout.write('\x1B[34m[WS] $data\x1B[0m');
      }
    });
    httpServer.stdout.transform(utf8.decoder).listen((final data) {
      if (data.contains('BATCH') || data.contains('Received')) {
        stdout.write('\x1B[35m[HTTP] $data\x1B[0m');
      }
    });

    final networkHandler = Handler(
      formatter: const JsonFormatter(),
      sink: HttpSink(
        url: 'http://127.0.0.1:$httpPort/logs',
        batchSize: 2, // Flush every 2 logs
        flushInterval: const Duration(seconds: 1),
      ),
    );

    Logger.configure('app.network', handlers: [networkHandler]);
    final logger = Logger.get('app.network');

    logger.info('Shipping log #1...');
    logger.info('Shipping log #2 (Triggers HTTP Batch)...');

    // Socket Sink Example (Manual disposal for flush)
    final wsHandler = Handler(
      formatter: const JsonFormatter(),
      sink: SocketSink(url: 'ws://127.0.0.1:$socketPort'),
    );
    Logger.configure('app.ws', handlers: [wsHandler]);
    Logger.get('app.ws').info('Log via WebSocket');

    // Wait for network activity to settle
    await Future.delayed(const Duration(seconds: 2));
    await wsHandler.sink.dispose();
    await networkHandler.sink.dispose();
  } catch (e) {
    print('\x1B[31mNetwork showcase failed (is Python venv setup?): $e\x1B[0m');
  } finally {
    socketServer?.kill();
    httpServer?.kill();
    print('\n[Cleanup] Network servers terminated.');
  }
}

/// Helper to print section headers
void _section(final String title) {
  print('\n\x1B[1m--- $title ---\x1B[0m');
}
