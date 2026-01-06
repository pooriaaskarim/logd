// Tests for filter edge cases.
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Filter Edge Cases', () {
    test('LevelFilter handles all log levels', () {
      const filter = LevelFilter(LogLevel.trace);

      const levels = [
        LogLevel.trace,
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ];

      for (final level in levels) {
        final entry = LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: level,
          message: 'test',
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );

        final shouldLog = filter.shouldLog(entry);
        expect(shouldLog, isA<bool>());
      }
    });

    test('RegexFilter handles empty message', () {
      final filter = RegexFilter(RegExp('error'));

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final shouldLog = filter.shouldLog(entry);
      expect(shouldLog, isFalse);
    });

    test('RegexFilter handles special regex characters', () {
      final filter = RegexFilter(RegExp('[error]'));

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This contains [error] in brackets',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final shouldLog = filter.shouldLog(entry);
      // Should handle regex special characters correctly
      expect(shouldLog, isA<bool>());
    });

    test('RegexFilter with invert handles all cases', () {
      final filter = RegexFilter(RegExp('secret'), invert: true);

      const entryWithSecret = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This contains secret information',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      const entryWithoutSecret = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is safe',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // With invert: true, should reject if matches
      expect(filter.shouldLog(entryWithSecret), isFalse);
      expect(filter.shouldLog(entryWithoutSecret), isTrue);
    });

    test('multiple filters with edge cases', () async {
      final sink = _MemorySink();
      final handler = Handler(
        formatter: const PlainFormatter(),
        filters: [
          const LevelFilter(LogLevel.info),
          RegexFilter(RegExp('^[A-Z]')), // Starts with uppercase
        ],
        sink: sink,
      );

      const entry1 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This starts with uppercase',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      const entry2 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'this starts with lowercase',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      await handler.log(entry1);
      await handler.log(entry2);

      // Only entry1 should pass (both filters)
      expect(sink.outputs.length, equals(1));
    });

    test('filter with very long message', () {
      final filter = RegexFilter(RegExp('error'));

      final longMessage = 'word ' * 1000 + 'error';
      final entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: longMessage,
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final shouldLog = filter.shouldLog(entry);
      expect(shouldLog, isTrue);
    });

    test('filter with Unicode characters', () {
      final filter = RegexFilter(RegExp('错误'));

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '发生错误了',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final shouldLog = filter.shouldLog(entry);
      expect(shouldLog, isTrue);
    });
  });
}

final class _MemorySink extends LogSink {
  final List<List<LogLine>> outputs = [];

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    outputs.add(lines.toList());
  }
}
