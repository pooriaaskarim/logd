import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('StructuredFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart',
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 10:00:00',
      hierarchyDepth: 0,
    );

    test('formats header with correct prefix', () {
      final formatter = StructuredFormatter(lineLength: 80);
      final lines = formatter.format(entry).toList();

      expect(lines[0].text, startsWith('____'));
      expect(lines[0].text, contains('[test]'));
      expect(lines[0].text, contains('[INFO]'));
    });

    test('wraps long message', () {
      final formatter = StructuredFormatter(lineLength: 20);
      const longEntry = LogEntry(
        loggerName: 't',
        origin: 'o',
        level: LogLevel.info,
        message: 'This is a very long message that should be wrapped.',
        timestamp: 'ts',
        hierarchyDepth: 0,
      );
      final lines = formatter.format(longEntry).toList();

      final msgStartIndex =
          lines.indexWhere((final l) => l.text.startsWith('----|'));
      final msgLines = lines.sublist(msgStartIndex);

      expect(msgLines.length, greaterThan(1));
      for (final line in msgLines) {
        expect(line.visibleLength, lessThanOrEqualTo(20));
      }
    });
  });
}
