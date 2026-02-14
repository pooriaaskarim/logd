// Example: Filtered Logging
//
// Demonstrates:
// - LevelFilter to restrict log levels
// - RegexFilter to filter by message content
// - Multiple filters (AND behavior)
//
// Expected: Only matching logs are processed

import 'package:logd/logd.dart';

void main() async {
  // Handler with level filter (only warnings and errors)
  const levelFilteredHandler = Handler(
    formatter: PlainFormatter(),
    sink: ConsoleSink(),
    filters: [
      LevelFilter(LogLevel.warning), // Only warning and above
    ],
  );

  // Handler with regex filter (only messages containing "ERROR")
  final regexFilteredHandler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
    filters: [
      RegexFilter(RegExp('ERROR|CRITICAL', caseSensitive: false)),
    ],
  );

  // Handler with multiple filters
  final multiFilteredHandler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
    filters: [
      const LevelFilter(LogLevel.info), // Info and above
      RegexFilter(
        RegExp(
          'user|auth',
          caseSensitive: false,
        ),
      ), // Must contain user or auth
    ],
  );

  Logger.configure('example.level', handlers: [levelFilteredHandler]);
  Logger.configure('example.regex', handlers: [regexFilteredHandler]);
  Logger.configure('example.multi', handlers: [multiFilteredHandler]);

  final levelLogger = Logger.get('example.level');
  final regexLogger = Logger.get('example.regex');
  final multiLogger = Logger.get('example.multi');

  print('=== Level Filter (warning+) ===');
  levelLogger
    ..debug('This debug message is filtered out')
    ..info('This info message is filtered out')
    ..warning('This warning passes')
    ..error('This error passes');

  print('\n=== Regex Filter (ERROR|CRITICAL) ===');
  regexLogger
    ..info('This is a normal message')
    ..warning('This is a warning')
    ..error('This is an ERROR message')
    ..error('This is a CRITICAL error');

  print('\n=== Multi Filter (info+ AND user|auth) ===');
  multiLogger
    ..info('General system message')
    ..info('User login successful')
    ..warning('Authentication failed')
    ..error('Database error');
}
