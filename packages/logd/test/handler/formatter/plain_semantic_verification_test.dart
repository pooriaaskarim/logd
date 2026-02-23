import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('PlainFormatter Semantic Verification', () {
    // A standard entry with a long message
    const entry = LogEntry(
      loggerName: 'test.logger',
      origin: 'main.dart',
      level: LogLevel.info,
      message: 'Message line 1. Message line 2 is long enough to wrap.',
      timestamp: '2025-01-01',
      error: null,
      stackTrace: null,
    );

    test('maintains hanging indent in normal conditions', () {
      const formatter = PlainFormatter();
      final doc = formatter.format(entry);

      // Use TerminalLayout directly to verify output
      const layout = TerminalLayout(width: 60);
      final lines = layout.layout(doc, LogLevel.info).lines;

      // Line 1: Header + Message Part 1
      // Header: "[INFO] 2025-01-01 [test.logger] " (~31 chars)
      expect(
        lines[0].toString(),
        contains('[INFO] 2025-01-01 [test.logger] Message line 1.'),
      );

      // Line 2: indentation + Message Part 2
      // expect indentation of ~31 spaces
      final line2 = lines[1].toString();
      // "Message line 1. Message line" fits on line 1. " 2 is..." wraps.
      expect(line2.trimLeft(), startsWith('2 is long enough'));

      final indentLength = line2.length - line2.trimLeft().length;
      expect(indentLength, greaterThanOrEqualTo(30)); // Header width
    });

    test('falls back to vertical stack in narrow width', () {
      const formatter = PlainFormatter();
      final doc = formatter.format(entry);

      // Force narrow width where header (31 chars) > available width (30)
      const layout = TerminalLayout(width: 30);
      final lines = layout.layout(doc, LogLevel.info).lines;

      // Should NOT have big hanging indent because it falls back.
      // Line 1: Header part 1
      expect(lines[0].toString(), contains('[INFO]'));

      // Subsequent lines should contain message, but NOT indented by header
      // width.
      final msgLineIndex = lines
          .indexWhere((final l) => l.toString().contains('Message line 1'));
      expect(msgLineIndex, greaterThan(0));

      final msgLine = lines[msgLineIndex].toString();
      expect(msgLine.trimLeft(), startsWith('Message line 1'));

      // Verify indentation is small (0 or 1 space), definitely not 30
      final indentLength = msgLine.length - msgLine.trimLeft().length;
      expect(indentLength, lessThan(10));
    });

    test('calculates tab width correctly inside BoxDecorator', () {
      // Verify PhysicalLine.getVisibleLength logic directly
      // This ensures that when content is shifted (e.g. by Frame border +
      // space),
      // the tab expansion accounts for the shift.
      const line = PhysicalLine(
        segments: [
          StyledText('\t', tags: LogTag.none),
        ],
      );

      // Start 0: \t -> 8
      expect(line.getVisibleLength(startX: 0), 8);
      // Start 1: \t -> 8. Delta 7.
      expect(line.getVisibleLength(startX: 1), 7);
      // Start 2: \t -> 8. Delta 6. (Typical box scenario: Border + Space)
      expect(line.getVisibleLength(startX: 2), 6);
      // Start 8: \t -> 16. Delta 8.
      expect(line.getVisibleLength(startX: 8), 8);

      // Verify multi-segment accumulation
      // [INFO] (7 chars) + \t
      // Start 2:
      // [INFO] -> 2..9 (len 7)
      // \t -> 9..16 (len 7)
      // Total visible: 14.
      // Wait. [INFO] is 7 chars.
      // Text: "[INFO] "
      const line2 = PhysicalLine(
        segments: [
          StyledText('[INFO] ', tags: LogTag.none),
          StyledText('\t', tags: LogTag.none),
        ],
      );

      // Start 0: [INFO] (7) -> 7. Tab at 7 snaps to 8 (delta 1). Total 8.
      expect(line2.getVisibleLength(startX: 0), 8);

      // Start 2: [INFO] (7) -> 2..9. Tab at 9 snaps to 16 (delta 7). Total 14.
      // 7 (text) + 7 (tab) = 14.
      expect(line2.getVisibleLength(startX: 2), 14);

      // Verify truncate with startX
      // If we truncate to width 10 with startX=2.
      // [INFO] -> 7.
      // Tab at 9 -> starts at 16 (delta 7).
      // Total 14.
      // 14 > 10. Should truncate.
      // Truncate logic:
      // Seg 1 [INFO] (7). Fits inside 10.
      // Seg 2 \t. Start 9. Snaps to 16. Delta 7.
      // 7 + 7 = 14 > 10.
      // Truncate Seg 2.
      // Char \t. Width 7.
      // 0 + 7 <= 3 (remaining)? No.
      // So Seg 2 is empty.
      // Result: "[INFO] "
      final truncated = line2.truncate(10, startX: 2);
      expect(truncated.segments.length, 1);
      expect(truncated.segments[0].text, '[INFO] ');
    });
  });
}
