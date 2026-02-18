// Example: Very Long Lines
//
// Demonstrates:
// - Wrapping of extremely long lines
// - ANSI code preservation during wrapping
// - Box decorator with long content
// - Performance with large content
//
// Expected: Proper wrapping without breaking ANSI codes or box structure

import 'package:logd/logd.dart';

void main() async {
  // Handler with wrapping
  const wrappedHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(),
    ],
    sink: ConsoleSink(),
    lineLength: 40,
  );

  // Handler with box and wrapping
  const boxedHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: ConsoleSink(),
    lineLength: 40,
  );

  Logger.configure('example.wrapped', handlers: [wrappedHandler]);
  Logger.configure('example.boxed', handlers: [boxedHandler]);

  final wrappedLogger = Logger.get('example.wrapped');
  final boxedLogger = Logger.get('example.boxed');

  // Very long single line
  const longLine = 'This is an extremely long line that contains many words '
      'and should definitely wrap across multiple lines when formatted. '
      'It should preserve ANSI codes if any are present and maintain '
      'readability throughout the wrapping process.';

  print('=== Wrapped Long Line ===');
  wrappedLogger.info(longLine);

  print('\n=== Boxed Long Line ===');
  boxedLogger.info(longLine);

  // Very long word (should still wrap)
  final longWord = 'supercalifragilisticexpialidocious' * 10;
  print('\n=== Very Long Word ===');
  wrappedLogger.warning('Word: $longWord');
}
