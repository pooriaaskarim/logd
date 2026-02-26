import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

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
      final doc = formatDoc(formatter, entry);
      try {
        final lines = renderLines(doc);

        // Line 0: Timestamp
        expect(lines[0], startsWith('____'));
        expect(lines[0], contains('2025-01-01 10:00:00'));

        // Line 1: Level + Logger
        expect(lines[1], startsWith('____'));
        expect(lines[1], contains('[INFO]'));
        expect(lines[1], contains('[test]'));

        // Line 2: Origin
        expect(lines[2], startsWith('____'));
        expect(lines[2], contains('[main.dart]'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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
      final doc = formatDoc(formatter, longEntry);
      try {
        final lines = renderLines(
          doc,
          width: 20,
        );

        final msgStartIndex =
            lines.indexWhere((final l) => l.startsWith('----|'));
        final msgLines = lines.sublist(msgStartIndex);

        expect(msgLines.length, greaterThan(1));
        for (final line in msgLines) {
          expect(line.length, greaterThan(0));
        }
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
