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

    test('emits semantic tags when color is true', () {
      const formatter = JsonPrettyFormatter(color: true);
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(0));
      bool foundTag = false;
      for (final line in lines) {
        for (final segment in line.segments) {
          if (segment.tags.contains(LogTag.jsonKey) ||
              segment.tags.contains(LogTag.jsonValue) ||
              segment.tags.contains(LogTag.jsonPunctuation)) {
            foundTag = true;
            break;
          }
        }
      }
      expect(foundTag, isTrue);
    });

    test('does not emit semantic tags when color is false', () {
      const formatter = JsonPrettyFormatter(color: false);
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(0));
      for (final line in lines) {
        for (final segment in line.segments) {
          expect(segment.tags.contains(LogTag.jsonKey), isFalse);
          expect(segment.tags.contains(LogTag.jsonValue), isFalse);
          expect(segment.tags.contains(LogTag.jsonPunctuation), isFalse);
        }
      }
    });

    test('prettyPrint produces indented output', () {
      const formatter = JsonPrettyFormatter(indent: '    ');
      final lines = formatter.format(entry, mockContext).toList();

      // Check if any line (except first/last) starts with the indent
      bool foundIndent = false;
      for (final line in lines) {
        final text = line.segments.map((final s) => s.text).join();
        if (text.startsWith('    "')) {
          foundIndent = true;
          break;
        }
      }
      expect(foundIndent, isTrue);
    });
  });
}
