// Example: JsonFormatter
//
// Demonstrates:
// - JSON serialization of log entries
// - Machine-readable format
// - Customizable fields for compact output
// - Suitable for log aggregation systems
//
// Expected: Valid JSON output for each log entry

import 'package:logd/logd.dart';

void main() async {
  print('--- JSON Formatter Example ---\n');

  // Example 1: Default (all fields)
  print('Scenario 1: Default JSON (All Fields)');
  final defaultHandler = Handler(
    formatter: const JsonFormatter(),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.json.default', handlers: [defaultHandler]);
  final defaultLogger = Logger.get('example.json.default');

  defaultLogger.info('User logged in');

  print('\n------------------------------------------------\n');

  // Example 2: Minimal fields for compact output
  print('Scenario 2: Minimal JSON (Compact for Storage)');
  final minimalHandler = Handler(
    formatter: const JsonFormatter(
      fields: [LogField.timestamp, LogField.level, LogField.message],
    ),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.json.minimal', handlers: [minimalHandler]);
  final minimalLogger = Logger.get('example.json.minimal');

  minimalLogger.info('User logged in');
  minimalLogger.warning('High memory usage');

  print('\n------------------------------------------------\n');

  // Example 3: Error tracking (message + error + stackTrace)
  print('Scenario 3: Error Tracking (Errors Only)');
  final errorHandler = Handler(
    formatter: const JsonFormatter(
      fields: [
        LogField.timestamp,
        LogField.logger,
        LogField.message,
        LogField.error,
        LogField.stackTrace,
      ],
    ),
    sink: const ConsoleSink(),
  );

  Logger.configure('example.json.errors', handlers: [errorHandler]);
  final errorLogger = Logger.get('example.json.errors');

  try {
    throw FormatException('Invalid input');
  } catch (e, stack) {
    errorLogger.error(
      'Processing failed',
      error: e,
      stackTrace: stack,
    );
  }

  print('\n------------------------------------------------\n');

  // Example 4: Pretty-printed JSON with custom fields
  print('Scenario 4: Colorized Pretty JSON (Human-Readable Debug)');
  final prettyHandler = Handler(
    formatter: const JsonPrettyFormatter(
      fields: [LogField.level, LogField.logger, LogField.message],
      color: true, // Enable coloring support in the formatter
    ),
    decorators: [
      StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.defaultScheme)),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('example.json.pretty', handlers: [prettyHandler]);
  final prettyLogger = Logger.get('example.json.pretty');

  prettyLogger.debug('Debugging information');
  prettyLogger.info('Normal information');
  prettyLogger.warning('Warning message');
  prettyLogger.error('Error occurred');
}
