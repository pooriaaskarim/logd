// Example: StyleDecorator
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
    formatter: const StructuredFormatter(),
    decorators: const [
      StyleDecorator(),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  // 1. Custom Color Scheme
  final customColors = StyleDecorator(
    theme: LogTheme(
      colorScheme: LogColorScheme(
        trace: LogColor.cyan,
        debug: LogColor.white,
        info: LogColor.brightBlue,
        warning: LogColor.yellow,
        error: LogColor.brightRed,
      ),
    ),
  );
  final customHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      customColors,
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  // 3. Header Background (Reverse Video)
  final headerHighlight = StyleDecorator(
    theme: _HeaderBackgroundTheme(),
  );
  final headerBgHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      headerHighlight,
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  // 2. High Contrast (Header Only)
  final highContrast = StyleDecorator(
    theme: _HeaderOnlyTheme(),
  );
  final selectiveHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      highContrast,
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
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

class _HeaderBackgroundTheme extends LogTheme {
  const _HeaderBackgroundTheme()
      : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    var style = super.getStyle(level, tags);
    if (tags.contains(LogTag.header)) {
      style = LogStyle(
        color: style.color,
        bold: style.bold,
        dim: style.dim,
        inverse: true, // Force inverse
      );
    }
    return style;
  }
}

class _HeaderOnlyTheme extends LogTheme {
  const _HeaderOnlyTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    if (tags.contains(LogTag.message) ||
        tags.contains(LogTag.stackFrame) ||
        tags.contains(LogTag.border)) {
      return const LogStyle(); // No style
    }
    return super.getStyle(level, tags);
  }
}
