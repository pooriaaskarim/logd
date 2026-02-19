import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:test/test.dart';

import '../decorator/mock_context.dart';
import '../test_helpers.dart';

void main() {
  group('ToonFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: '2025-01-01T10:00:00Z',
    );

    test('Output header once then rows with TAB delimiter (default)', () {
      const formatter = ToonFormatter();

      final lines = renderLines(formatter.format(entry, mockContext));

      // Header includes: timestamp,logger,origin,level,message,error,stackTrace
      expect(lines.length, equals(2));
      expect(
        lines[0],
        equals(
          'logs[]{timestamp,logger,origin,level,message,error,stackTrace}:',
        ),
      );

      // Row
      expect(
        lines[1],
        equals('"2025-01-01T10:00:00Z"\ttest\ttest\tINFO\tmsg\t\t'),
      );
    });

    test('Respects custom metadata selection', () {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.logger},
      );
      final lines = renderLines(formatter.format(entry, mockContext));

      expect(
        lines[0],
        equals('logs[]{logger,level,message,error,stackTrace}:'),
      );
      expect(lines[1], equals('test\tINFO\tmsg\t\t'));
    });

    test('Color=true emits semantic tags including metadata tags', () {
      const formatter = ToonFormatter(
        metadata: {LogMetadata.logger},
        color: true,
      );
      // Use TerminalLayout directly to check segments tags/text
      final layout = TerminalLayout(width: 80);
      final lines = layout
          .layout(formatter.format(entry, mockContext), LogLevel.info)
          .lines;

      // Row is index 1
      final row = lines[1];
      final rowSegs = row.segments;

      // Delimiter \t is at index 1, level is at index 2
      expect(rowSegs[0].text, equals('test'));
      expect(
        rowSegs[2].tags.contains(LogTag.level),
        isTrue,
      );
      expect(rowSegs[2].text, equals('INFO'));
      expect(rowSegs[2].tags, contains(LogTag.level));
    });

    test('Unwraps row even in narrow width (Semantic NoWrap)', () {
      const formatter = ToonFormatter(
        metadata: {}, // Only crucial content
      );
      const entryLong = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is a very long message',
        timestamp: 'now',
      );

      // We use a width that allows breaking at the TAB.
      // info (4) + \t (4) = 8.
      const context = LogContext(availableWidth: 8);

      // Use helper
      final lines = renderLines(formatter.format(entryLong, context));

      // The row line should NOT be truncated or wrapped despite width 8.
      // Expected: "INFO\tThis is a very long message"
      final row =
          lines.firstWhere((final l) => l.toString().startsWith('INFO'));

      expect(row.toString(), equals('INFO\tThis is a very long message\t\t'));
      // visibleLength should be full length
      expect(row.length, greaterThan(8));
    });

    test('ToonFormatter wraps content in narrow width instead of truncating',
        () {
      const formatter = ToonFormatter();
      const longEntry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is a very long message that should not be truncated',
        timestamp: 'ts',
      );

      // Width 20 is very narrow.
      final lines = renderLines(
        formatter.format(
          longEntry,
          const LogContext(availableWidth: 20),
        ),
        width: 20,
      );

      final row = lines.firstWhere((final l) => l.toString().contains('INFO'));

      // Should contain the full message, likely wrapped across key/value or just wrapped text.
      // But TOON is "one line" usually. If it wraps, it might be multiple physical lines.
      // renderLines flattens to physical lines.

      // We expect the DATA to be present.
      // If truncated, we might just see "INFO\tThis is a..."

      final fullOutput = lines.join('\n');
      expect(fullOutput, contains('truncated'));

      // Crucial check: verify that NO line exceeds the available width (20).
      // If it exceeds, it means it didn't wrap, which leads to truncation in Boxes.
      for (final line in lines) {
        // We strip ANSI codes for length check if possible, or just check raw length loosely if ANSI is minimal.
        // But renderLines returns ANSI string.
        // Assuming minimal ANSI, or just checking that it's not HUGE.
        // The message is ~60 chars. Width is 20.
        // If wrapped, max length should be ~20 (plus maybe a few invisible ANSI chars).
        // If not wrapped, it will be > 60.
        expect(line.length, lessThanOrEqualTo(35),
            reason: 'Line exceeded width: $line');
      }
    });
  });
}
