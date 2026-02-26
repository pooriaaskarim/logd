import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('PlainFormatter', () {
    const entry = LogEntry(
      loggerName: 'test.logger',
      origin: 'main.dart:10:5',
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 12:00:00',
    );

    test('formats basic entry correctly with default metadata', () {
      const formatter = PlainFormatter();
      final arena = LogArena.instance;
      final doc = arena.checkoutDocument();
      try {
        formatter.format(entry, doc, arena);
        final lines = renderLines(doc);

        expect(lines.length, equals(1));
        expect(
          lines.first,
          equals('[INFO] 2025-01-01 12:00:00 [test.logger] Hello World'),
        );
      } finally {
        doc.releaseRecursive(arena);
      }
    });

    test('can select metadata', () {
      const formatter = PlainFormatter(metadata: {LogMetadata.logger});
      final arena = LogArena.instance;
      final doc = arena.checkoutDocument();
      try {
        formatter.format(entry, doc, arena);
        final lines = renderLines(doc);

        // [INFO] is mandatory
        expect(lines.first, equals('[INFO] [test.logger] Hello World'));
      } finally {
        doc.releaseRecursive(arena);
      }
    });

    test('includes error and stack trace', () {
      final errorEntry = LogEntry(
        loggerName: 'test',
        origin: 'main',
        level: LogLevel.error,
        message: 'Kaboom',
        timestamp: 'now',
        error: 'Some error',
        stackTrace: StackTrace.fromString('stack line 1'),
      );

      const formatter = PlainFormatter(
        metadata: {LogMetadata.logger},
      );

      final arena = LogArena.instance;
      final doc = arena.checkoutDocument();
      try {
        formatter.format(errorEntry, doc, arena);
        final lines = renderLines(doc);

        expect(lines.length, equals(3));
        expect(lines[1], equals('Error: Some error'));
        expect(lines[2], contains('stack line 1'));
      } finally {
        doc.releaseRecursive(arena);
      }
    });
  });
}
