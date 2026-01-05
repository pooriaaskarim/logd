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
  final levelFilteredHandler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
    filters: [
      const LevelFilter(LogLevel.warning), // Only warning and above
    ],
  );

  // Handler with regex filter (only messages containing "ERROR")
  final regexFilteredHandler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
    filters: [
      RegexFilter(RegExp(r'ERROR|CRITICAL', caseSensitive: false)),
    ],
  );

  // Handler with multiple filters
  final multiFilteredHandler = Handler(
    formatter: const PlainFormatter(),
    sink: const ConsoleSink(),
    filters: [
      const LevelFilter(LogLevel.info), // Info and above
      RegexFilter(RegExp(r'user|auth',
          caseSensitive: false)), // Must contain user or auth
    ],
  );

  Logger.configure('example.level', handlers: [levelFilteredHandler]);
  Logger.configure('example.regex', handlers: [regexFilteredHandler]);
  Logger.configure('example.multi', handlers: [multiFilteredHandler]);

  final levelLogger = Logger.get('example.level');
  final regexLogger = Logger.get('example.regex');
  final multiLogger = Logger.get('example.multi');

  print('=== Level Filter (warning+) ===');
  levelLogger.debug('This debug message is filtered out');
  levelLogger.info('This info message is filtered out');
  levelLogger.warning('This warning passes');
  levelLogger.error('This error passes');

  print('\n=== Regex Filter (ERROR|CRITICAL) ===');
  regexLogger.info('This is a normal message');
  regexLogger.warning('This is a warning');
  regexLogger.error('This is an ERROR message');
  regexLogger.error('This is a CRITICAL error');

  print('\n=== Multi Filter (info+ AND user|auth) ===');
  multiLogger.info('General system message');
  multiLogger.info('User login successful');
  multiLogger.warning('Authentication failed');
  multiLogger.error('Database error');
}
