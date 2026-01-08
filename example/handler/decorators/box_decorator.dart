// Example: BoxDecorator
//
// Demonstrates:
// - Different border styles (rounded, sharp, double)
// - Line length configuration
// - Color support
// - Wrapping long content
//
// Expected: Logs wrapped in ASCII boxes

import 'package:logd/logd.dart';

void main() async {
  // Rounded borders
  final roundedHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Sharp borders
  final sharpHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.sharp,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Double borders
  final doubleHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.double,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Narrow box (tests wrapping)
  final narrowHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 40,
  );

  Logger.configure('example.rounded', handlers: [roundedHandler]);
  Logger.configure('example.sharp', handlers: [sharpHandler]);
  Logger.configure('example.double', handlers: [doubleHandler]);
  Logger.configure('example.narrow', handlers: [narrowHandler]);

  final roundedLogger = Logger.get('example.rounded');
  final sharpLogger = Logger.get('example.sharp');
  final doubleLogger = Logger.get('example.double');
  final narrowLogger = Logger.get('example.narrow');

  print('=== Rounded Borders ===');
  roundedLogger.info('This is a message in a rounded box');

  print('\n=== Sharp Borders ===');
  sharpLogger.warning('This is a warning in a sharp box');

  print('\n=== Double Borders ===');
  doubleLogger.error('This is an error in a double box');

  print('\n=== Narrow Box (Wrapping Test) ===');
  narrowLogger.info(
    'This is a very long message that will definitely wrap '
    'across multiple lines inside the box',
  );
}
