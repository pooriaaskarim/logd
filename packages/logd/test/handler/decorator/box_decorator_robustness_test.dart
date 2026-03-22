import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  group('BoxDecorator Robustness', () {
    test(
        'BoxDecorator with PlainFormatter and long message should '
        'not break the box', () {
      const formatter = PlainFormatter();
      const box = BoxDecorator();

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'This is a very long message that definitely exceeds the '
            '40 characters limit of the box decorator and should '
            'be handled gracefully.',
        timestamp: '2025-01-01 10:00:00',
      );

      final doc = formatDoc(formatter, entry);
      try {
        box.decorate(doc, entry, LogArena.instance);

        const layout = TerminalLayout(width: 40);
        final physical = layout.layout(doc, LogLevel.info);
        final boxedLines = physical.lines;

        // Check top/bottom border length
        final topWidth = boxedLines[0].visibleLength;

        for (int i = 0; i < boxedLines.length; i++) {
          final line = boxedLines[i];
          expect(
            line.visibleLength,
            equals(topWidth),
            reason: 'Line $i has inconsistent width: ${line.visibleLength}'
                ' vs $topWidth',
          );
        }
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test(
        'BoxDecorator with JsonFormatter (long line) should '
        'wrap internal content', () {
      const formatter = JsonFormatter();
      const box = BoxDecorator();

      const entry = LogEntry(
        loggerName: 'very_long_logger_name_that_will_push_json_over_the_limit',
        origin: 'some_long_file_path.dart',
        level: LogLevel.error,
        message: 'Status 500: Database connection failed unexpectedly.',
        timestamp: '2025-01-01 10:00:00',
      );

      final doc = formatDoc(formatter, entry);
      try {
        box.decorate(doc, entry, LogArena.instance);

        const layout = TerminalLayout(width: 30);
        final physical = layout.layout(doc, LogLevel.info);
        final boxedLines = physical.lines;

        // Box should have consistent width across all lines
        final boxWidth = boxedLines[0].visibleLength;
        for (int i = 0; i < boxedLines.length; i++) {
          final line = boxedLines[i];
          expect(
            line.visibleLength,
            equals(boxWidth),
            reason: 'All box lines should have the same width',
          );
        }
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
