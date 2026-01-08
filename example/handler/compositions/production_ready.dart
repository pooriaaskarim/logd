// Example: Production-Ready Handler
//
// Demonstrates:
// - Real-world handler configuration
// - Console + File with different formats
// - Error-only file logging
// - Level filtering
// - Rotation
//
// Expected: Comprehensive logging setup suitable for production

import 'package:logd/logd.dart';

void main() async {
  // Console handler: Structured, colored, boxed
  final consoleHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const ColorDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
      const HierarchyDepthPrefixDecorator()
    ],
    sink: const ConsoleSink(),
    lineLength: 100,
  );

  // File handler: Plain format, all levels
  final fileHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      'logs/app.log',
      fileRotation: SizeRotation(
        maxSize: '10 MB',
        backupCount: 5,
        compress: true,
      ),
    ),
  );

  // Error-only file handler
  final errorHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      'logs/errors.log',
      fileRotation: TimeRotation(
        interval: Duration(days: 1),
        backupCount: 30,
        compress: true,
      ),
    ),
    filters: [
      const LevelFilter(LogLevel.error),
    ],
  );

  // JSON handler for log aggregation
  final jsonHandler = Handler(
    formatter: const JsonFormatter(),
    sink: FileSink(
      'logs/app.json.log',
      fileRotation: SizeRotation(maxSize: '50 MB', backupCount: 3),
    ),
  );

  Logger.configure(
    'app',
    handlers: [
      consoleHandler,
      fileHandler,
      errorHandler,
      jsonHandler,
    ],
    logLevel: LogLevel.debug,
  );

  final logger = Logger.get('app');

  // Simulate application logging
  logger.debug('Application starting');
  logger.info('Server listening on port 8080');
  logger.info('Database connection established');
  logger.warning('High memory usage detected: 85%');
  logger.error('Failed to process request', error: Exception('Timeout'));

  print('\nCheck logs/ directory for:');
  print('  - app.log (all logs, plain format)');
  print('  - errors.log (errors only)');
  print('  - app.json.log (all logs, JSON format)');
}
