import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('StructuredFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart',
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 10:00:00',
    );

    test('formats header with correct sequence', () {
      const formatter = StructuredFormatter();
      final lines = formatter.format(entry, mockContext).toList();

      // Line 0: Timestamp
      expect(lines[0].toString(), startsWith('____'));
      expect(lines[0].toString(), contains('2025-01-01 10:00:00'));

      // Line 1: Level + Logger
      expect(lines[1].toString(), startsWith('____'));
      expect(lines[1].toString(), contains('[INFO]'));
      expect(lines[1].toString(), contains('[test]'));

      // Line 2: Origin
      expect(lines[2].toString(), startsWith('____'));
      expect(lines[2].toString(), contains('[main.dart]'));
    });

    test('wraps long message', () {
      const formatter = StructuredFormatter();
      const longEntry = LogEntry(
        loggerName: 't',
        origin: 'o',
        level: LogLevel.info,
        message: 'This is a very long message that should be wrapped.',
        timestamp: 'ts',
      );
      final lines = formatter
          .format(longEntry, const LogContext(availableWidth: 20))
          .toList();

      final msgStartIndex =
          lines.indexWhere((final l) => l.toString().startsWith('----|'));
      final msgLines = lines.sublist(msgStartIndex);

      expect(msgLines.length, greaterThan(1));
      for (final line in msgLines) {
        expect(line.visibleLength, lessThanOrEqualTo(20));
      }
    });
  });
}
