import 'package:logd/logd.dart';
import 'package:logd/src/core/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Decorator Composition', () {
    final lines = ['msg line 1', 'msg line 2'];

    test('Order: BoxDecorator then AnsiColorDecorator colors the borders', () {
      final box = BoxDecorator(lineLength: 20, useColors: false);
      const color = AnsiColorDecorator(useColors: true);

      final boxed = box.decorate(lines, LogLevel.info);
      final colored = color.decorate(boxed, LogLevel.info).toList();

      // Should have top border, 2 content lines, bottom border = 4 lines
      expect(colored.length, equals(4));

      // Top border should be colored
      expect(colored[0], startsWith('\x1B[32m')); // Green
      expect(colored[0], contains('╭'));
      expect(colored[0], endsWith('\x1B[0m'));

      // Content lines should be colored (on the outside of the
      // box vertical bars)
      expect(colored[1], startsWith('\x1B[32m'));
      expect(colored[1], contains('│'));
      expect(colored[1], endsWith('\x1B[0m'));
    });

    test('Order: AnsiColorDecorator then BoxDecorator keeps borders plain', () {
      const color = AnsiColorDecorator(useColors: true);
      final box = BoxDecorator(lineLength: 20, useColors: false);

      final colored = color.decorate(lines, LogLevel.info);
      final boxed = box.decorate(colored, LogLevel.info).toList();

      expect(boxed.length, equals(4));

      // Top border should NOT be colored (because box was applied AFTER color)
      expect(boxed[0], isNot(startsWith('\x1B[32m')));
      expect(boxed[0], startsWith('╭'));

      // Content line should contain color codes INSIDE the box vertical bars
      expect(boxed[1], startsWith('│'));
      expect(boxed[1], contains('\x1B[32mmsg line 1\x1B[0m'));
      expect(boxed[1], endsWith('│'));
    });

    test('Multiple decorators apply sequentially', () {
      // Mock decorators to track application
      final decorator1 = _PrefixDecorator('P1: ');
      final decorator2 = _PrefixDecorator('P2: ');

      final result = decorator2
          .decorate(
            decorator1.decorate(['msg'], LogLevel.info),
            LogLevel.info,
          )
          .first;

      expect(result, equals('P2: P1: msg'));
    });

    test('BoxDecorator handles already colored lines using padVisible', () {
      const color = AnsiColorDecorator(useColors: true);
      final box = BoxDecorator(lineLength: 20, useColors: false);

      final colored = color
          .decorate(['abc'], LogLevel.info).toList(); // '\x1B[32mabc\x1B[0m'
      final boxed = box.decorate(colored, LogLevel.info).toList();

      // The middle line should be:
      // vertical bar (1) + colored 'abc' (12 technical, 3 visible) + 17
      // spaces + vertical bar (1)
      // Total technical length: 1 + 12 + 17 + 1 = 31
      // Total visible width: 1 + 3 + 17 + 1 = 22

      final middleLine = boxed[1];
      expect(middleLine.visibleLength, equals(22));
      expect(middleLine.contains('\x1B[32mabc\x1B[0m'), isTrue);
      expect(middleLine, startsWith('│'));
      expect(middleLine, endsWith('│'));
    });
    test('BoxDecorator handles internal newlines in input strings', () {
      final box = BoxDecorator(lineLength: 20, useColors: false);
      final lines = ['line 1\nline 2'];
      final boxed = box.decorate(lines, LogLevel.info).toList();

      // Should have top, line 1, line 2, bottom = 4 lines
      expect(boxed.length, equals(4));
      expect(boxed[1], contains('line 1'));
      expect(boxed[1], startsWith('│'));
      expect(boxed[1], endsWith('│'));
      expect(boxed[2], contains('line 2'));
      expect(boxed[2], startsWith('│'));
      expect(boxed[2], endsWith('│'));
    });
  });
}

class _PrefixDecorator implements LogDecorator {
  _PrefixDecorator(this.prefix);
  final String prefix;

  @override
  Iterable<String> decorate(
    final Iterable<String> lines,
    final LogLevel level,
  ) =>
      lines.map((final l) => '$prefix$l');
}
