// Example: Simple Console Logging
//
// Demonstrates the most basic handler configuration:
// - StructuredFormatter for layout
// - ConsoleSink for output
// - No decorators or filters
//
// Expected: Clean, structured log output to console

import 'package:logd/logd.dart';

void main() async {
  // Configure a simple handler

  final handler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    sink: const ConsoleSink(),
  );

  Logger.configure(
    'example',
    handlers: [
      handler,
    ],
    logLevel: LogLevel.trace,
  );

  final logger = Logger.get('example');

  // Test all log levels
  logger.trace('This is a trace message');
  logger.debug('This is a debug message');
  logger.info('This is an info message');
  logger.warning('This is a warning message');
  logger.error('This is an error message');

  // Test with error and stack trace
  try {
    throw Exception('Test exception');
  } catch (e, stack) {
    logger.error(
      'Caught an exception',
      error: e,
      stackTrace: stack,
    );
  }
}
