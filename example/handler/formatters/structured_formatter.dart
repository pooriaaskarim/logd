// Example: StructuredFormatter
//
// Demonstrates:
// - Structured layout with headers, origin, message
// - Multi-line message handling
// - Error and stack trace formatting
// - Line wrapping
//
// Expected: Well-formatted structured output

import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.structured', handlers: [handler]);
  final logger = Logger.get('example.structured');

  // Simple message
  logger.info('Simple log message');

  // Multi-line message
  logger.info('''
This is a multi-line message
that spans several lines
and should be formatted nicely
  ''');

  // Long message that needs wrapping
  logger.warning(
    'This is a very long message that will definitely exceed the line length '
    'limit and should be wrapped properly across multiple lines in the output',
  );

  // With error
  try {
    throw FormatException('Invalid format detected');
  } catch (e, stack) {
    logger.error(
      'Failed to process data',
      error: e,
      stackTrace: stack,
    );
  }

  // Different log levels
  logger.trace('Trace level message');
  logger.debug('Debug level message');
  logger.info('Info level message');
  logger.warning('Warning level message');
  logger.error('Error level message');
}
