// Example: Empty and Null Messages
//
// Demonstrates:
// - Handling of empty strings
// - Null message handling
// - Edge cases in formatters
//
// Expected: Graceful handling without crashes

import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: const [
      ColorDecorator(useColors: true),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('example.edge', handlers: [handler]);
  final logger = Logger.get('example.edge');

  // Empty string
  logger.info('');

  // Whitespace only
  logger.info('   ');

  // Null-like (empty object)
  logger.info('');

  // Very short
  logger.info('x');

  // Only newlines
  logger.info('\n\n\n');

  print('All edge cases handled without errors');
}
