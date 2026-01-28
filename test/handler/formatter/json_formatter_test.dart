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
      
    );

    test('outputs compact JSON with default metadata', () {
      const formatter = JsonFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      // Metadata
      expect(decoded['timestamp'], equals('2025-01-01 10:00:00'));
      expect(decoded['logger'], equals('test'));
      expect(decoded['origin'], equals('main.dart:10'));

      // Crucial content
      expect(decoded['level'], equals('info'));
      expect(decoded['message'], equals('Test message'));

      expect(decoded['error'], isNull);
      expect(decoded['stackTrace'], isNull);
    });

    test('includes error when present regardless of metadata', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart:20',
        level: LogLevel.error,
        message: 'Failed',
        timestamp: '2025-01-01 10:00:00',
        
        error: 'Connection failed',
        stackTrace: StackTrace.fromString('stack line 1\n  stack line 2'),
      );

      const formatter = JsonFormatter(metadata: {});
      final lines = formatter.format(errorEntry, mockContext).toList();

      expect(lines.length, equals(1));
      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      // Crucial content always present
      expect(decoded['level'], equals('error'));
      expect(decoded['message'], equals('Failed'));
      expect(decoded['error'], equals('Connection failed'));
      expect(decoded['stackTrace'], equals('stack line 1\n  stack line 2'));

      // Metadata omitted
      expect(decoded.containsKey('timestamp'), isFalse);
    });
  });

  group('JsonPrettyFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
      
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
      expect(output, contains('  '));
    });
  });

  group('JsonSemanticFormatter tags', () {
    const entry = LogEntry(
      loggerName: 'app',
      origin: 'main.dart:10',
      level: LogLevel.info,
      message: 'Test message',
      timestamp: '2025-01-01 10:00:00',
      
    );

    test('emits semantic tags when color is true', () {
      const formatter = JsonPrettyFormatter(color: true);
      final lines = formatter.format(entry, mockContext).toList();

      expect(lines.length, greaterThan(0));
      bool foundKey = false;
      bool foundLevel = false;
      bool foundPunctuation = false;
      for (final line in lines) {
        for (final segment in line.segments) {
          if (segment.tags.contains(LogTag.key)) {
            foundKey = true;
          }
          if (segment.tags.contains(LogTag.level)) {
            foundLevel = true;
          }
          if (segment.tags.contains(LogTag.punctuation)) {
            foundPunctuation = true;
          }
        }
      }
      expect(foundKey, isTrue);
      expect(foundLevel, isTrue);
      expect(foundPunctuation, isTrue);
    });
  });

  group('JsonFormatter metadata selection', () {
    const entry = LogEntry(
      loggerName: 'app.service',
      origin: 'service.dart:42',
      level: LogLevel.info,
      message: 'Processing request',
      timestamp: '2025-01-01 14:30:15.123',
      
    );

    test('includes only specified metadata but always crucial content', () {
      const formatter = JsonFormatter(
        metadata: {LogMetadata.timestamp},
      );
      final lines = formatter.format(entry, mockContext).toList();

      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      // Metadata specified
      expect(decoded['timestamp'], equals('2025-01-01 14:30:15.123'));

      // Crucial content always there
      expect(decoded['level'], equals('info'));
      expect(decoded['message'], equals('Processing request'));

      // Other metadata omitted
      expect(decoded.containsKey('logger'), isFalse);
      expect(decoded.containsKey('origin'), isFalse);
    });

    test('empty metadata list still includes level and message', () {
      const formatter = JsonFormatter(metadata: {});
      final lines = formatter.format(entry, mockContext).toList();

      final json = lines.first.toString();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['level'], equals('info'));
      expect(decoded['message'], equals('Processing request'));
      expect(decoded.length, equals(2));
    });
  });
}
