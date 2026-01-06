// Example: PlainFormatter
//
// Demonstrates:
// - Simple timestamp + level + message format
// - Minimal formatting
// - Suitable for file logs
//
// Expected: Simple, compact log format

import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.plain', handlers: [handler]);
  final logger = Logger.get('example.plain');

  logger.trace('Trace message');
  logger.debug('Debug message');
  logger.info('Info message');
  logger.warning('Warning message');
  logger.error('Error message');

  // With error
  try {
    throw Exception('Test error');
  } catch (e, stack) {
    logger.error(
      'Error occurred',
      error: e,
      stackTrace: stack,
    );
  }
}
