import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalLayout', () {
    test('Basic word wrapping', () {
      const layout = TerminalLayout(width: 10);
      const doc = LogDocument(nodes: [
        MessageNode(segments: [
          StyledText('hello world extra'),
        ],),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      // "hello " (6) fits
      // "world " (6) -> 6+6 > 10, so "world " moves to next line
      // "extra" fits in 3rd line
      expect(physical.lines.length, equals(3));
      expect(physical.lines[0].toString(), equals('hello '));
      expect(physical.lines[1].toString(), equals('world '));
      expect(physical.lines[2].toString(), equals('extra'));
    });

    test('Force-wraps ultra long words', () {
      const layout = TerminalLayout(width: 5);
      const doc = LogDocument(nodes: [
        MessageNode(segments: [
          StyledText('abcdefghij'),
        ],),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      expect(physical.lines.length, equals(2));
      expect(physical.lines[0].toString(), equals('abcde'));
      expect(physical.lines[1].toString(), equals('fghij'));
    });

    test('Box rendering with title', () {
      const layout = TerminalLayout(width: 20);
      const doc = LogDocument(nodes: [
        BoxNode(
          title: 'TITLE',
          children: [
            MessageNode(segments: [StyledText('hi')]),
          ],
        ),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      // Top border
      // Title bar
      // Middle border
      // Content row
      // Bottom border
      expect(physical.lines.length, equals(5));
      expect(physical.lines[0].toString(), contains('╭'));
      expect(physical.lines[1].toString(), contains('TITLE'));
      expect(physical.lines[2].toString(), contains('├'));
      expect(physical.lines[3].toString(), contains('│ hi'));
      expect(physical.lines[4].toString(), contains('╰'));
    });

    test('Indentation nesting', () {
      const layout = TerminalLayout(width: 20);
      const doc = LogDocument(nodes: [
        IndentationNode(
          indentString: '>> ',
          children: [
            MessageNode(segments: [StyledText('nested')]),
          ],
        ),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      expect(physical.lines.length, equals(1));
      expect(physical.lines[0].toString(), equals('>> nested'));
    });

    test('Unicode wide character handling', () {
      const layout = TerminalLayout(width: 10);
      // 🚀 is 2 width
      const doc = LogDocument(nodes: [
        MessageNode(segments: [
          StyledText('🚀 rockets'),
        ],),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      // "🚀 rockets" -> 2 + 1 (space) + 7 (rockets) = 10. Fits!
      expect(physical.lines.length, equals(1));
      expect(physical.lines[0].visibleLength, equals(10));
    });

    test('TAB handling', () {
      const layout = TerminalLayout(width: 20);
      const doc = LogDocument(nodes: [
        MessageNode(segments: [
          StyledText('a\tb'),
        ],),
      ],);

      final physical = layout.layout(doc, LogLevel.info);

      // "a" (1) + TAB (7) + "b" (1) = 9
      expect(physical.lines[0].visibleLength, equals(9));
    });
  });
}
