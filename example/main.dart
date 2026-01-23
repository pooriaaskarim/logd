import 'dart:async';

import 'package:logd/logd.dart';

void main() {
  print('================================================');
  print('                 LOGD EXAMPLE                  ');
  print('================================================');
  print('This example showcases the high-performance,');
  print('hierarchical, and composable logging system.');
  print('');

  // Attach to uncaught errors (wraps the demo logic).
  runZonedGuarded(
    () {
      _runDemo();
    },
    (error, stack) {
      Logger.get().error(
        'Caught uncaught error in zone',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

void _runDemo() {
  // 1. Core Architecture: Formatters & Decorators
  // The Handler module decouples layout from visual decoration.
  print('--- 1. Composable Architecture ---');

  final composableHandler = Handler(
    // StructuredFormatter handles the layout (origin, metadata, wrapping)
    formatter: const StructuredFormatter(),
    decorators: [
      // StyleDecorator adds level-based coloring to the content (before boxing)
      const StyleDecorator(),
      // BoxDecorator adds the visual frame (border color is handled internally)
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  Logger.configure(
    'example',
    handlers: [composableHandler],
    logLevel: LogLevel.trace,
  );

  final logger = Logger.get('example');

  logger.info('Welcome to Logd!');
  logger.debug('Debug messages are perfect for deep tracing.');
  logger.warning('This is a warning, something might be wrong.');

  // 2. Robust Wrapping & Decoupling
  // BoxDecorator can now wrap ANY input, even from other formatters.
  print('\n--- 2. Robust JSON Boxing ---');

  final jsonBoxedHandler = Handler(
    formatter: const JsonPrettyFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.double,
      ),
      const StyleDecorator(),
    ],
    sink: const ConsoleSink(),
    lineLength: 50, // Narrow box for JSON
  );

  Logger.configure('example.json', handlers: [jsonBoxedHandler]);
  final jsonLogger = Logger.get('example.json');

  jsonLogger.info(
    'User profile updated successfully.',
  );

  // 3. Hierarchical Logging & Indentation
  // Loggers inherit configuration from their parents.
  // We use HierarchyDepthPrefixDecorator to visually show the depth.
  print('\n--- 3. Hierarchical Indentation ---');

  final hierarchicalHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(
        theme: _HierarchicalTheme(),
      ),
      BoxDecorator(
        borderStyle: BorderStyle.sharp,
      ),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  Logger.configure(
    'example.service',
    handlers: [hierarchicalHandler],
    logLevel: LogLevel.trace,
  );

  final rootService = Logger.get('example.service');
  final dbService = Logger.get('example.service.database');
  final cacheService = Logger.get('example.service.database.cache');

  rootService.info('General service message');
  dbService.debug('Database query initiated...');
  cacheService.trace('Cache hit for key: user_123');

  // 4. Styled JSON Logging (Vibrant JSON)
  // JsonPrettyFormatter enables vibrant, styled JSON in the terminal.
  print('\n--- 4. Styled JSON Logging ---');

  final prettyHandler = Handler(
    formatter: const JsonPrettyFormatter(),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.pretty', handlers: [prettyHandler]);
  final prettyLogger = Logger.get('example.pretty');

  prettyLogger.info('Task completed successfully.');

  // 5. Atomic Multi-line Buffers
  // Send atomic multi-line logs without interleaving.
  print('\n--- 5. Atomic Multi-line Buffers ---');

  final buffer = logger.infoBuffer;
  buffer?.writeln('Deployment Report:');
  buffer?.writeln(' - Artifact: logd_v0.5.0.aot');
  buffer?.writeln(' - Target: production-us-east');
  buffer?.writeln(' - Status: SUCCESS');
  buffer?.sink();

  // 6. Multi-Sink & File Rotation
  // Output to multiple destinations simultaneously.
  print('\n--- 6. Multi-Sink & File Rotation ---');

  final fileHandler = Handler(
    formatter: const PlainFormatter(),
    sink: MultiSink([
      const ConsoleSink(),
      FileSink(
        'logs/audit.log',
        // Rotate when file reaches 1MB
        fileRotation: SizeRotation(maxSize: '1 MB'),
      ),
    ]),
    filters: [
      // Only log errors to this high-priority audit sink
      const LevelFilter(LogLevel.error),
    ],
  );

  Logger.configure('example.audit', handlers: [fileHandler]);
  final auditLogger = Logger.get('example.audit');

  auditLogger.error('Security alert: Unauthorized access attempt detected');

  // 7. Stack Trace Parsing
  // Clean, readable stack traces with package filtering.
  print('\n--- 7. Clean Stack Traces ---');

  try {
    _simulateError();
  } catch (e, stack) {
    logger.error(
      'Operation Failed',
      error: e,
      stackTrace: stack,
    );
  }

  print('\nDemo Complete! Check the console output for colors and boxes.');
  print('Audit logs written to: logs/audit.log');
}

void _simulateError() {
  throw Exception('A simulated error for demonstration purposes.');
}

class _HierarchicalTheme extends LogTheme {
  const _HierarchicalTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    if (tags.contains(LogTag.message)) {
      return const LogStyle(); // Don't color message body
    }
    return super.getStyle(level, tags);
  }
}
