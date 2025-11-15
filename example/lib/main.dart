import 'dart:async';
import 'dart:io';

import 'package:logd/logd.dart';

void main() {
  // Welcome message for the demo.
  print('Welcome to the logd package demo!');
  print(
    'This example showcases key features: configuration, hierarchical logging, custom timestamps, stack traces, buffers, handlers, and freezing inheritance.',
  );
  print(
    'Logs will appear in the console, and some will be written to files (app.log, app_multi.log).',
  );
  print('Run with `dart run` to see it in action.\n');

  // Attach to uncaught errors (wraps the demo logic).
  runZonedGuarded(
    () {
      _runDemo();
    },
    (error, stack) {
      Logger.get().error(
        'Caught uncaught error in zone',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

void _runDemo() {
  // 1. Basic Setup: Retrieve global and hierarchical loggers.
  // Loggers are created on-demand and inherit configurations dynamically from parents or global.
  final Logger globalLogger =
      Logger.get(); // Global logger (equivalent to Logger.get('global'))
  final Logger appLogger = Logger.get(
    'app',
  ); // Parent logger for 'app' hierarchy
  final uiLogger = Logger.get('app.ui'); // Child inherits from 'app'
  final apiLogger = Logger.get('app.api'); // Another child

  // 2. Basic Logging: Demonstrate levels without config (uses defaults).
  print('--- Basic Logging (Using Defaults) ---');
  globalLogger.trace('Trace: Fine-grained diagnostic info');
  globalLogger.debug('Debug: Development details');
  globalLogger.info('Info: General operational message');
  globalLogger.warning('Warning: Potential issue detected');
  globalLogger.error('Error: Critical failure occurred');

  // 3. Global Configuration: Set defaults for all loggers.
  print('\n--- Global Configuration ---');
  Logger.configure(
    'global',
    enabled: true, // Explicitly enable (defaults to debug mode check)
    logLevel: LogLevel.info, // Drop trace/debug by default
    includeFileLineInHeader: true, // Add file:line to origin
    stackMethodCount: {
      LogLevel.info: 1, // 1 frame for info
      LogLevel.warning: 3, // 3 frames for warnings
      LogLevel.error: 5, // 5 frames for errors
    },
    timestamp: Timestamp.millisecondsSinceEpoch(
      timezone: Timezone.utc(), // Use UTC
    ),
    stackTraceParser: const StackTraceParser(
      ignorePackages: ['logd', 'dart:async'], // Ignore internal packages
    ),
    handlers: [
      // Default handler: Boxed to console
      Handler(
        formatter: BoxFormatter(
          borderStyle: BorderStyle.rounded,
          lineLength: 100,
          useColors: stdout.supportsAnsiEscapes, // Auto-detect ANSI support
        ),
        sink: const ConsoleSink(),
      ),
    ],
  );
  // Log after global config (trace/debug dropped).
  globalLogger.debug('This debug should be dropped after config');
  globalLogger.info('This info should log with custom timestamp');

  // 4. Hierarchical Configuration and Inheritance.
  print('\n--- Hierarchical Configuration & Inheritance ---');
  // Configure parent 'app' – affects children dynamically.
  Logger.configure(
    'app',
    logLevel: LogLevel.warning, // Stricter than global
    timestamp: Timestamp.iso8601(
      timezone: Timezone.local(), // System local timezone
    ),
  );

  // Children inherit unless overridden.
  uiLogger.info('Info from uiLogger (dropped, inherits warning level)');
  uiLogger.warning('Warning from uiLogger (logs, inherited level allows)');

  // Override child 'app.api'.
  Logger.configure(
    'app.api',
    logLevel: LogLevel.debug, // Less strict
    includeFileLineInHeader: false, // Override header
  );
  apiLogger.debug('Debug from apiLogger (less strict due to override)');

  // 5. Stack Trace Integration.
  print('\n--- Stack Trace Integration ---');
  try {
    simulateError();
  } catch (e, stack) {
    appLogger.error(
      'Caught error with configured stack frames',
      error: e,
      stackTrace: stack,
    );
  }

  // 6. Multi-line Buffers for Atomic Logging.
  print('\n--- Multi-line Buffers ---');
  final infoBuffer = uiLogger.infoBuffer; // Null if level doesn't allow
  infoBuffer?.writeln('Multi-line info message:');
  infoBuffer?.writeln('- Part 1: Data loaded');
  infoBuffer?.writeln('- Part 2: Processing started');
  infoBuffer?.writeln('- Part 3: Complete');
  infoBuffer?.sink(); // Logs all at once or does nothing if null

  final errorBuffer = apiLogger.errorBuffer;
  errorBuffer?.writeln('Multi-line error details:');
  errorBuffer?.writeln('- Error code: 500');
  errorBuffer?.writeln('- Reason: Server timeout');
  errorBuffer?.sink();

  // 7. Custom Handlers: Formatters, Sinks, Filters.
  print('\n--- Custom Handlers ---');
  // JSON handler to file with filter.
  final jsonHandler = Handler(
    formatter: const JsonPrettyFormatter(), // Multi-line JSON
    sink: FileSink('app.log'), // To file
    filters: [const LevelFilter(LogLevel.warning)], // Warnings+
  );

  // Multi-sink with regex filter.
  final multiHandler = Handler(
    formatter: const JsonFormatter(), // Compact JSON
    sink: MultiSink([const ConsoleSink(), FileSink('app_multi.log')]),
    filters: [RegexFilter(RegExp(r'secret'), invert: true)], // Exclude 'secret'
  );

  // Apply to 'app.ui' (appends to inherited handlers).
  Logger.configure(
    'app.ui',
    handlers: [
      ...uiLogger.handlers, // Keep inherited
      jsonHandler,
      multiHandler,
    ],
  );

  uiLogger.warning('Warning to custom handlers (JSON to file, multi-sink)');
  uiLogger.info('Info with "secret" keyword (filtered by regex in multi)');

  // 8. Freezing Inheritance.
  print('\n--- Freezing Inheritance ---');
  // Before freeze.
  appLogger.info('Info before freeze (logs via inheritance)');
  // Freeze 'app' configs to children.
  appLogger.freezeInheritance();
  // Change parent.
  Logger.configure('app', logLevel: LogLevel.error);
  // Child retains frozen level.
  uiLogger.info(
    'Info after freeze (dropped due to parent change, but check if frozen retains previous)',
  );
  uiLogger.error('Error after freeze (logs)');

  // 9. Simulate uncaught error.
  print('\n--- Uncaught Error Demo ---');
  throw Exception('Simulated uncaught error (caught by attachment)');

  // Demo complete (won't reach if uncaught).
  // ignore: dead_code
  print('\nDemo complete. Check app.log and app_multi.log for file outputs.');
}

// Function to simulate an error for stack trace and error logging demo.
void simulateError() {
  throw Exception('Simulated error for logging demonstration');
}
