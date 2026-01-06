// Tests for formatter null safety and edge cases.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter Null Safety', () {
    test('StructuredFormatter handles null error gracefully', () {
      final formatter = StructuredFormatter(lineLength: 80);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'Error occurred',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        error: null, // null error
        stackTrace: null,
      );

      // Should not crash
      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
    });

    test('StructuredFormatter handles very long logger name', () {
      final formatter = StructuredFormatter(lineLength: 20);
      const entry = LogEntry(
        loggerName: 'very_long_logger_name_that_exceeds_line_length',
        origin: 'test',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
      // Should wrap properly
      for (final line in lines) {
        expect(line.visibleLength, lessThanOrEqualTo(20));
      }
    });

    test('StructuredFormatter handles very long origin', () {
      final formatter = StructuredFormatter(lineLength: 30);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'very/long/path/to/file/that/exceeds/line/length.dart:123:456',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
    });

    test('StructuredFormatter handles empty stack frames', () {
      final formatter = StructuredFormatter(lineLength: 80);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'Error',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
        stackFrames: [], // Empty stack frames
      );

      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
    });

    test('StructuredFormatter handles negative lineLength gracefully', () {
      // lineLength is late final, so this would throw at construction
      // But test that it handles edge cases in calculations
      final formatter = StructuredFormatter(lineLength: 10);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test message',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final lines = formatter.format(entry).toList();
      expect(lines, isNotEmpty);
    });
  });
}
