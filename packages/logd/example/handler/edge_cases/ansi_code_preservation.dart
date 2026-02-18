// Example: ANSI Code Preservation
//
// Demonstrates:
// - ANSI codes preserved during wrapping
// - Multiple ANSI codes
// - ANSI codes in box decorator
// - Edge cases with malformed codes
//
// Expected: ANSI codes correctly preserved and applied

import 'package:logd/logd.dart';

void main() async {
  // Handler that wraps colored content
  const handler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: ConsoleSink(),
    lineLength: 50,
  );

  Logger.configure('example.ansi', handlers: [handler]);
  Logger.get('example.ansi')

    // Long message that will wrap (colors should be preserved)
    ..info(
      'This is a long message that will wrap and the ANSI color codes '
      'should be preserved across the line breaks',
    )

    // Different log levels (different colors)
    ..trace('Trace: Long trace message that wraps')
    ..debug('Debug: Long debug message that wraps')
    ..info('Info: Long info message that wraps')
    ..warning('Warning: Long warning message that wraps')
    ..error('Error: Long error message that wraps');

  print('\nVerify that colors are preserved across wrapped lines');
}
