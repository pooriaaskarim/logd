// Example: ColorDecorator
//
// Demonstrates:
// - Level-based coloring
// - Custom color schemes
// - Fine-grained color control
// - Header background option
//
// Expected: Colorized output based on log level

import 'package:logd/logd.dart';

void main() async {
  // Default color scheme
  final defaultHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: const [
      ColorDecorator(useColors: true),
    ],
    sink: const ConsoleSink(),
  );

  // 1. Custom Color Scheme
  final customColors = ColorDecorator(
    colorScheme: ColorScheme(
      trace: LogColor.cyan,
      debug: LogColor.white,
      info: LogColor.brightBlue,
      warning: LogColor.yellow,
      error: LogColor.brightRed,
    ),
  );
  final customHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: [
      customColors,
    ],
    sink: const ConsoleSink(),
  );

  // 3. Header Background (Reverse Video)
  final headerHighlight = ColorDecorator(
    config: ColorConfig(
      headerBackground: true,
    ),
  );
  final headerBgHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: [
      headerHighlight,
    ],
    sink: const ConsoleSink(),
  );

  // 2. High Contrast (Header Only)
  final highContrast = ColorDecorator(
    config: ColorConfig(
      colorTimestamp: true,
      colorLevel: true,
      colorLoggerName: true,
      colorMessage: false,
      colorBorder: false,
      colorStackFrame: false,
    ),
  );
  final selectiveHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: [
      highContrast,
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('example.default', handlers: [defaultHandler]);
  Logger.configure('example.custom', handlers: [customHandler]);
  Logger.configure('example.headerbg', handlers: [headerBgHandler]);
  Logger.configure('example.selective', handlers: [selectiveHandler]);

  final defaultLogger = Logger.get('example.default');
  final customLogger = Logger.get('example.custom');
  final headerBgLogger = Logger.get('example.headerbg');
  final selectiveLogger = Logger.get('example.selective');

  print('=== Default Color Scheme ===');
  defaultLogger.trace('Trace message');
  defaultLogger.debug('Debug message');
  defaultLogger.info('Info message');
  defaultLogger.warning('Warning message');
  defaultLogger.error('Error message');

  print('\n=== Custom Color Scheme ===');
  customLogger.trace('Trace message');
  customLogger.debug('Debug message');
  customLogger.info('Info message');
  customLogger.warning('Warning message');
  customLogger.error('Error message');

  print('\n=== Header Background ===');
  headerBgLogger.info('Info with background header');
  headerBgLogger.warning('Warning with background header');

  print('\n=== Selective Coloring ===');
  selectiveLogger.info('Selective coloring example');
  try {
    throw Exception('Test');
  } catch (e, stack) {
    selectiveLogger.error(
      'Error with selective coloring',
      error: e,
      stackTrace: stack,
    );
  }
}
