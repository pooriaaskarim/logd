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
    formatter: StructuredFormatter(lineLength: 60),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 60,
        useColors: true,
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Sharp borders
  final sharpHandler = Handler(
    formatter: StructuredFormatter(lineLength: 60),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.sharp,
        lineLength: 60,
        useColors: true,
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Double borders
  final doubleHandler = Handler(
    formatter: StructuredFormatter(lineLength: 60),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.double,
        lineLength: 60,
        useColors: true,
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Narrow box (tests wrapping)
  final narrowHandler = Handler(
    formatter: StructuredFormatter(lineLength: 40),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 40,
        useColors: false,
      ),
    ],
    sink: const ConsoleSink(),
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
