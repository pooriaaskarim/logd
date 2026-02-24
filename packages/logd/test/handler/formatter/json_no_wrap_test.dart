import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('JsonFormatter NoWrap Audit', () {
    test('JsonFormatter allows wrapping (no noWrap tag)', () {
      const formatter = JsonFormatter();
      const entryLong = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'This is a very long message that would normally wrap',
        timestamp: 'now',
      );

      // Width 10 is very small.

      const layout = TerminalLayout(width: 10);
      final lines = layout
          .layout(
            formatter.format(entryLong, LogArena.instance),
            LogLevel.info,
          )
          .lines;

      // Because it wraps paragraph-style, it might produce multiple lines
      // if the layout engine decides to wrap the StyledText segments.
      // However, StyledText wrapping happens in TerminalLayout, NOT in
      // format().
      // format() returns a ParagraphNode.
      // So here we check tags to ensure NO noWrap tag is present.

      final segments = lines.first.segments;
      for (final s in segments) {
        expect((s.tags & LogTag.noWrap) == 0, isTrue);
      }
    });
  });
}
