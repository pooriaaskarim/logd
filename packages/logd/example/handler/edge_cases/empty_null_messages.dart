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
  const handler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(),
    ],
    sink: ConsoleSink(lineLength: 80),
  );

  Logger.configure('example.edge', handlers: [handler]);
  Logger.get('example.edge')

    // Empty string
    ..info('')

    // Whitespace only
    ..info('   ')

    // Null-like (empty object)
    ..info('')

    // Very short
    ..info('x')

    // Only newlines
    ..info('\n\n\n');

  print('All edge cases handled without errors');
}
