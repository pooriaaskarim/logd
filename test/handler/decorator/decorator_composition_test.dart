import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Decorator Composition', () {
    final lines = [LogLine.plain('msg line 1'), LogLine.plain('msg line 2')];
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
      hierarchyDepth: 0,
    );

    test('Order: BoxDecorator then AnsiColorDecorator colors the borders', () {
      final box = BoxDecorator(lineLength: 20, useColors: false);
      const color = AnsiColorDecorator(useColors: true);

      final boxed = box.decorate(lines, entry);
      final colored = color.decorate(boxed, entry).toList();

      // Should have top border, 2 content lines, bottom border = 4 lines
      expect(colored.length, equals(4));

      // Top border should be colored
      expect(colored[0].text, startsWith('\x1B[32m')); // Green
      expect(colored[0].text, contains('╭'));
      expect(colored[0].text, endsWith('\x1B[0m'));

      // Content lines should be colored (on the outside of the
      // box vertical bars)
      expect(colored[1].text, startsWith('\x1B[32m'));
      expect(colored[1].text, contains('│'));
      expect(colored[1].text, endsWith('\x1B[0m'));
    });

    test('Order: AnsiColorDecorator then BoxDecorator keeps borders plain', () {
      const color = AnsiColorDecorator(useColors: true);
      final box = BoxDecorator(lineLength: 20, useColors: false);

      final colored = color.decorate(lines, entry);
      final boxed = box.decorate(colored, entry).toList();

      expect(boxed.length, equals(4));

      // Top border should NOT be colored (because box was applied AFTER color)
      expect(boxed[0].text, isNot(startsWith('\x1B[32m')));
      expect(boxed[0].text, startsWith('╭'));

      // Content line should contain color codes INSIDE the box vertical bars
      expect(boxed[1].text, startsWith('│'));
      expect(boxed[1].text, contains('\x1B[32mmsg line 1\x1B[0m'));
      expect(boxed[1].text, endsWith('│'));
    });

    test('Multiple decorators apply sequentially', () {
      // Mock decorators to track application
      const decorator1 = PrefixDecorator('P1: ');
      const decorator2 = PrefixDecorator('P2: ');

      final result = decorator2
          .decorate(
            decorator1.decorate([LogLine.plain('msg')], entry),
            entry,
          )
          .first;

      expect(result.text, equals('P2: P1: msg'));
    });

    test('BoxDecorator handles already colored lines using padVisible', () {
      const color = AnsiColorDecorator(useColors: true);
      final box = BoxDecorator(lineLength: 20, useColors: false);

      final colored = color.decorate([LogLine.plain('abc')], entry).toList();
      final boxed = box.decorate(colored, entry).toList();

      final middleLine = boxed[1];
      expect(middleLine.visibleLength, equals(22));
      expect(middleLine.text.contains('\x1B[32mabc\x1B[0m'), isTrue);
      expect(middleLine.text, startsWith('│'));
      expect(middleLine.text, endsWith('│'));
    });
    test('BoxDecorator handles internal newlines in input strings', () {
      final box = BoxDecorator(lineLength: 20, useColors: false);
      // Formatter output shouldn't have newlines now, but for robustness:
      final lines = [LogLine.plain('line 1\nline 2')];
      // Note: BoxDecorator.decorate itself doesn't split anymore as per
      // our change because we expect Formatter to yield separate lines.
      // But we kept wrapVisible which handles it if text still has newlines.
      final boxed = box.decorate(lines, entry).toList();

      // Should have top, line 1, line 2, bottom = 4 lines
      expect(boxed.length, equals(4));
      expect(boxed[1].text, contains('line 1'));
      expect(boxed[1].text, startsWith('│'));
      expect(boxed[1].text, endsWith('│'));
      expect(boxed[2].text, contains('line 2'));
      expect(boxed[2].text, startsWith('│'));
      expect(boxed[2].text, endsWith('│'));
    });
  });
}
