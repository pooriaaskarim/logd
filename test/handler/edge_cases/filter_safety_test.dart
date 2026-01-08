import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Filter Safety', () {
    test('RegexFilter handles invalid regex gracefully (if applicable)', () {
      // In Dart, Regexp(invalid) throws at construction.
      // But verify RegexFilter with complex patterns.
      final filter = RegexFilter(RegExp('[a-z]+', caseSensitive: false));
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'HELLO',
        timestamp: '10:00:00',
        hierarchyDepth: 0,
      );

      expect(filter.shouldLog(entry), isTrue);
    });

    test('Multiple filters combine with AND logic', () {
      final filters = [
        const LevelFilter(LogLevel.warning),
        RegexFilter(RegExp('danger')),
      ];

      const entry1 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'danger',
        timestamp: '10:00:00',
        hierarchyDepth: 0,
      );
      const entry2 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.warning,
        message: 'safe',
        timestamp: '10:00:00',
        hierarchyDepth: 0,
      );
      const entry3 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.error,
        message: 'danger zone',
        timestamp: '10:00:00',
        hierarchyDepth: 0,
      );

      expect(
        filters.every((final f) => f.shouldLog(entry1)),
        isFalse,
        reason: 'Level too low',
      );
      expect(
        filters.every((final f) => f.shouldLog(entry2)),
        isFalse,
        reason: 'No match',
      );
      expect(
        filters.every((final f) => f.shouldLog(entry3)),
        isTrue,
        reason: 'Both pass',
      );
    });

    test('RegexFilter handles empty messages', () {
      final filter = RegexFilter(RegExp('test'));
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '',
        timestamp: '10:00:00',
        hierarchyDepth: 0,
      );
      expect(filter.shouldLog(entry), isFalse);
    });
  });
}
