// Example: JsonFormatter
//
// Demonstrates:
// - JSON serialization of log entries
// - Machine-readable format
// - Suitable for log aggregation systems
//
// Expected: Valid JSON output for each log entry

import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: const JsonFormatter(),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.json', handlers: [handler]);
  final logger = Logger.get('example.json');

  // Simple message
  logger.info('User logged in');

  // With error
  try {
    throw FormatException('Invalid input');
  } catch (e, stack) {
    logger.error(
      'Processing failed',
      error: e,
      stackTrace: stack,
    );
  }

  // All log levels
  logger.trace('Trace');
  logger.debug('Debug');
  logger.info('Info');
  logger.warning('Warning');
  logger.error('Error');
}
