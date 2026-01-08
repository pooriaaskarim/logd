import 'dart:convert';

import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('JsonFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
      hierarchyDepth: 0,
    );

    test('outputs compact JSON', () {
      const formatter = JsonFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['timestamp'], equals('2025-01-01 10:00:00'));
      expect(decoded['level'], equals('info'));
      expect(decoded['logger'], equals('test'));
      expect(decoded['origin'], equals('main.dart:10'));
      expect(decoded['message'], equals('Test message'));
      expect(decoded['error'], isNull);
      expect(decoded['stackTrace'], isNull);
    });

    test('includes error when present', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart:20',
        level: LogLevel.error,
        message: 'Failed',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        error: 'Connection failed',
        stackTrace: StackTrace.fromString('stack line 1\n  stack line 2'),
      );

      const formatter = JsonFormatter();
      final lines = formatter.format(errorEntry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['error'], equals('Connection failed'));
      expect(decoded['stackTrace'], equals('stack line 1\n  stack line 2'));
    });

    test('includes stack trace without error', () {
      final stackEntry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart:30',
        level: LogLevel.warning,
        message: 'Warning',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        stackTrace: StackTrace.fromString('stack line 1'),
      );

      const formatter = JsonFormatter();
      final lines = formatter.format(stackEntry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['stackTrace'], equals('stack line 1'));
      expect(decoded['error'], isNull);
    });
  });

  group('JsonPrettyFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
      hierarchyDepth: 0,
    );

    test('outputs formatted JSON with indentation', () {
      const formatter = JsonPrettyFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(1));
      final output = lines.map((final l) => l.toString()).join('\n');

      expect(output, contains('  "timestamp": '));
      expect(output, contains('  "level": '));
      expect(output, contains('  "logger": '));
      expect(output, contains('  "message": '));

      // Should be pretty-printed with 2-space indentation
      expect(output, contains('  '));
    });
  });

  group('JsonFormatter with all fields', () {
    test('includes all LogEntry fields', () {
      final entry = LogEntry(
        loggerName: 'app.service',
        origin: 'service.dart:42',
        level: LogLevel.debug,
        message: 'Processing request',
        timestamp: '2025-01-01 14:30:15.123',
        hierarchyDepth: 2,
        error: Exception('Validation error'),
        stackTrace: StackTrace.fromString('at validate\n  at process'),
      );

      const formatter = JsonFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['timestamp'], equals('2025-01-01 14:30:15.123'));
      expect(decoded['level'], equals('debug'));
      expect(decoded['logger'], equals('app.service'));
      expect(decoded['origin'], equals('service.dart:42'));
      expect(decoded['message'], equals('Processing request'));
      expect(decoded['error'], isNotNull);
      expect(decoded['stackTrace'], isNotNull);
    });
  });

  group('JsonSemanticFormatter', () {
    const entry = LogEntry(
      loggerName: 'app',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
      hierarchyDepth: 2,
    );

    test('includes semantic tags for each field', () {
      const formatter = JsonSemanticFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(0));
      final json = lines.map((final l) => l.toString()).join();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['fields'], isNotNull);
      final fields = decoded['fields'] as Map<String, dynamic>;

      // Check timestamp field
      expect(fields['timestamp'], isNotNull);
      final timestamp = fields['timestamp'] as Map<String, dynamic>;
      expect(timestamp['value'], equals('2025-01-01 10:00:00'));
      expect(timestamp['tags'], contains('header'));
      expect(timestamp['tags'], contains('timestamp'));

      // Check level field
      expect(fields['level'], isNotNull);
      final level = fields['level'] as Map<String, dynamic>;
      expect(level['value'], equals('info'));
      expect(level['tags'], contains('header'));
      expect(level['tags'], contains('level'));

      // Check logger field
      expect(fields['logger'], isNotNull);
      final logger = fields['logger'] as Map<String, dynamic>;
      expect(logger['value'], equals('app'));
      expect(logger['tags'], contains('header'));
      expect(logger['tags'], contains('loggerName'));

      // Check message field
      expect(fields['message'], isNotNull);
      final message = fields['message'] as Map<String, dynamic>;
      expect(message['value'], equals('Test message'));
      expect(message['tags'], contains('message'));
    });

    test('includes metadata', () {
      const formatter = JsonSemanticFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      final json = lines.map((final l) => l.toString()).join();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['metadata'], isNotNull);
      final metadata = decoded['metadata'] as Map<String, dynamic>;
      expect(metadata['hierarchyDepth'], equals(2));
    });

    test('prettyPrint option formats output', () {
      const formatter = JsonSemanticFormatter(prettyPrint: true);
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(10)); // Pretty JSON has many lines
      final output = lines.map((final l) => l.toString()).join('\n');
      expect(output, contains('  "fields"'));
      expect(output, contains('    "timestamp"'));
    });

    test('includes error and stackTrace with tags when present', () {
      final errorEntry = LogEntry(
        loggerName: 'app',
        origin: 'main.dart:20',
        level: LogLevel.error,
        message: 'Failed',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        error: 'Connection error',
        stackTrace: StackTrace.fromString('stack line'),
      );

      const formatter = JsonSemanticFormatter();
      final lines = formatter.format(errorEntry, mockContext).toList();

      final json = lines.map((final l) => l.toString()).join();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final fields = decoded['fields'] as Map<String, dynamic>;

      // Check error field
      expect(fields['error'], isNotNull);
      final error = fields['error'] as Map<String, dynamic>;
      expect(error['value'], equals('Connection error'));
      expect(error['tags'], contains('error'));

      // Check stackTrace field
      expect(fields['stackTrace'], isNotNull);
      final stackTrace = fields['stackTrace'] as Map<String, dynamic>;
      expect(stackTrace['value'], equals('stack line'));
      expect(stackTrace['tags'], contains('stackFrame'));
    });
  });
}
