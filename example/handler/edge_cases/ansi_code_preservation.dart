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
  final handler = Handler(
    formatter: StructuredFormatter(lineLength: 50),
    decorators: [
      const ColorDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 50,
      ),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('example.ansi', handlers: [handler]);
  final logger = Logger.get('example.ansi');

  // Long message that will wrap (colors should be preserved)
  logger.info(
    'This is a long message that will wrap and the ANSI color codes '
    'should be preserved across the line breaks',
  );

  // Different log levels (different colors)
  logger.trace('Trace: Long trace message that wraps');
  logger.debug('Debug: Long debug message that wraps');
  logger.info('Info: Long info message that wraps');
  logger.warning('Warning: Long warning message that wraps');
  logger.error('Error: Long error message that wraps');

  print('\nVerify that colors are preserved across wrapped lines');
}
