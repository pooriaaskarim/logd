// Tests for RegexFilter exception handling.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('RegexFilter Exception Handling', () {
    test('handles regex that throws on match', () {
      // Some regex patterns can cause issues
      // This test verifies graceful handling
      final filter = RegexFilter(RegExp('.*')); // Should match everything
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'test message',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Should not throw
      expect(() => filter.shouldLog(entry), returnsNormally);
    });

    test('handles very long message with regex', () {
      final filter = RegexFilter(RegExp('error'));
      final longMessage = 'word ' * 10000 + 'error';
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: longMessage,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // Should not hang or throw
      expect(() => filter.shouldLog(entry), returnsNormally);
      expect(filter.shouldLog(entry), isTrue);
    });

    test('handles complex regex patterns', () {
      // Complex regex that might cause issues
      final filter = RegexFilter(RegExp(r'^[A-Z][a-z]+\s+\d+:\s+.*$'));
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Error 123: Something went wrong',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      expect(() => filter.shouldLog(entry), returnsNormally);
    });

    test('handles regex with special characters in message', () {
      final filter = RegexFilter(RegExp('[error]'));
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This contains [error] in brackets',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      expect(() => filter.shouldLog(entry), returnsNormally);
    });
  });
}
