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

  const handler = Handler(
    formatter: StructuredFormatter(),
    sink: ConsoleSink(),
    lineLength: 80,
  );

  Logger.configure(
    'example',
    handlers: [
      handler,
    ],
    logLevel: LogLevel.trace,
  );

  final logger = Logger.get('example')

    // Test all log levels
    ..trace('This is a trace message')
    ..debug('This is a debug message')
    ..info('This is an info message')
    ..warning('This is a warning message')
    ..error('This is an error message');

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
