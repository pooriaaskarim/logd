// Example: AnsiColorDecorator
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
      AnsiColorDecorator(useColors: true),
    ],
    sink: const ConsoleSink(),
  );

  // Custom color scheme
  final customScheme = AnsiColorScheme(
    trace: AnsiColor.cyan,
    debug: AnsiColor.white,
    info: AnsiColor.brightBlue,
    warning: AnsiColor.brightYellow,
    error: AnsiColor.brightRed,
  );

  final customHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: [
      AnsiColorDecorator(
        useColors: true,
        colorScheme: customScheme,
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Header background
  final headerBgHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: const [
      AnsiColorDecorator(
        useColors: true,
        config: AnsiColorConfig(headerBackground: true),
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Selective coloring
  final selectiveHandler = Handler(
    formatter: StructuredFormatter(lineLength: 80),
    decorators: const [
      AnsiColorDecorator(
        useColors: true,
        config: AnsiColorConfig(
          colorHeader: true,
          colorBody: true,
          colorBorder: false,
          colorStackFrame: true,
        ),
      ),
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
