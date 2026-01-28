import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('Decorator Composition', () {
    final lines = [LogLine.text('msg line 1'), LogLine.text('msg line 2')];
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
      
    );

    test('Order: BoxDecorator then StyleDecorator colors the borders', () {
      const box = BoxDecorator();
      const color = StyleDecorator();

      final boxed = box.decorate(lines, entry, mockContext);
      final colored = color.decorate(boxed, entry, mockContext).toList();
      final rendered = renderLines(colored);

      // Should have top border, 2 content lines, bottom border = 4 lines
      expect(rendered.length, equals(4));

      // Top border should be colored and dimmed
      // Info level now defaults to blue (was green)
      expect(rendered[0], startsWith('\x1B[34m')); // Dim + Blue
      expect(rendered[0], contains('╭'));
      expect(rendered[0], endsWith('\x1B[0m'));

      // Content lines should be colored and dimmed (borders)
      // box vertical bars)
      expect(rendered[1], startsWith('\x1B[34m')); // Dim + Blue
      expect(rendered[1], contains('│'));
      expect(rendered[1], endsWith('\x1B[0m'));
    });

    test('Order: StyleDecorator then BoxDecorator keeps borders plain', () {
      const color = StyleDecorator();
      const box = BoxDecorator();

      final colored = color.decorate(lines, entry, mockContext);
      final boxed = box.decorate(colored, entry, mockContext).toList();
      final rendered = renderLines(boxed);

      expect(rendered.length, equals(4));

      // Top border should NOT be colored (because box was applied AFTER color)
      expect(rendered[0], isNot(startsWith('\x1B[34m')));
      expect(rendered[0], startsWith('╭'));

      // Content line should contain_color codes INSIDE the box vertical bars
      expect(rendered[1], startsWith('│'));
      // Info level now defaults to blue (was green)
      // Padding is OUTSIDE the ANSI block now
      expect(rendered[1], contains('\x1B[34mmsg line 1\x1B[0m'));
      expect(rendered[1], endsWith('│'));
    });

    test('Multiple decorators apply sequentially', () {
      // Mock decorators to track application
      const decorator1 = PrefixDecorator('P1: ');
      const decorator2 = PrefixDecorator('P2: ');

      final result = decorator2
          .decorate(
            decorator1.decorate([LogLine.text('msg')], entry, mockContext),
            entry,
            mockContext,
          )
          .first;

      // Note: PrefixDecorator adds header LogSegment, LogLine.toString() joins
      // them.
      // renderLines also joins them.
      // If mockContext.supportsAnsi is true, and header is colored?
      // PrefixDecorator uses `LogTag.header`. StyleDecorator is NOT involved
      // here?
      // Wait, PrefixDecorator assigns `tags: {LogTag.header}`.
      // IF we used StyleDecorator it would color it. But here we don't.
      // So renderLines output is plain.
      expect(result.toString(), equals('P2: P1: msg'));
    });

    test('BoxDecorator handles already colored lines using padVisible', () {
      const color = StyleDecorator();
      const box = BoxDecorator();

      final colored =
          color.decorate([LogLine.text('abc')], entry, mockContext).toList();
      final boxed = box.decorate(colored, entry, mockContext).toList();
      final rendered = renderLines(boxed);

      final middleLine = boxed[1];
      // visibleLength should be 80 (availableWidth) + 2 borders = 82.
      expect(
        middleLine.visibleLength,
        equals(82),
      );

      final renderedMiddle = rendered[1];
      // Info level now defaults to blue (was green)
      expect(
        renderedMiddle.contains('\x1B[34mabc\x1B[0m'),
        isTrue,
      );
      expect(renderedMiddle, startsWith('│'));
      expect(renderedMiddle, endsWith('│'));
    });

    test('Best Practice Order: Box -> Ansi -> Hierarchy', () {
      // 1. Color Content
      const ansi = StyleDecorator();
      // 2. Box it (with its own border color)
      const box = BoxDecorator();
      // 3. Indent it
      const hierarchy = HierarchyDepthPrefixDecorator(indent: '>> ');
      const deepEntry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
        
      );

      // Pipeline execution
      // Pipeline execution: Box -> Color -> Hierarchy to ensure borders are
      // colored
      final s1 = box.decorate(lines, deepEntry, mockContext);
      final s2 = ansi.decorate(s1, deepEntry, mockContext);
      final finalOutput =
          hierarchy.decorate(s2, deepEntry, mockContext).toList();
      final rendered = renderLines(finalOutput);

      expect(rendered.length, equals(4));

      // Check indentation exists on ALL lines (outside the box)
      for (final line in rendered) {
        expect(line, startsWith('>> '));
      }

      // Check top border: Indent -> Color -> TopLeft
      // Note: BoxDecorator applies color to the border characters.
      final top = rendered[0];
      // Info level now defaults to blue (was green), hierarchy is plain
      expect(top, startsWith('>> \x1B[34m'));
      expect(top, contains('╭'));

      // Check content line: Indent -> BorderColor -> Vertical -> Reset
      // -> ContentColor -> Msg
      final content = rendered[1];
      expect(content, startsWith('>> '));
      expect(content, contains('│'));
      // Info level now defaults to blue (was green)
      expect(
        content,
        contains('\x1B[34mmsg line 1\x1B[0m'),
      ); // Colored content
    });
  });
}
