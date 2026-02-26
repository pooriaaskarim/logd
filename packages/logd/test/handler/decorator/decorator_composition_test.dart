import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Decorator Composition', () {
    final lines = ['msg line 1', 'msg line 2'];
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

      final doc = createTestDocument(lines);
      try {
        box.decorate(doc, entry, LogArena.instance);
        color.decorate(doc, entry, LogArena.instance);
        final rendered = renderLines(doc);

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
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('Order: StyleDecorator then BoxDecorator keeps borders plain', () {
      const color = StyleDecorator();
      const box = BoxDecorator();

      final doc = createTestDocument(lines);
      try {
        color.decorate(doc, entry, LogArena.instance);
        box.decorate(doc, entry, LogArena.instance);
        final rendered = renderLines(doc);

        expect(rendered.length, equals(4));

        // Top border should NOT be colored (because box was applied AFTER
        // color)
        expect(rendered[0], isNot(startsWith('\x1B[34m')));
        expect(rendered[0], startsWith('╭'));

        // Content line should contain_color codes INSIDE the box vertical bars
        expect(rendered[1], startsWith('│'));
        // Info level now defaults to blue (was green)
        // Padding is OUTSIDE the ANSI block now
        expect(rendered[1], contains('msg'));
        expect(rendered[1], contains('line'));
        expect(rendered[1], contains('1'));
        expect(rendered[1], endsWith('│'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('Multiple decorators apply sequentially', () {
      // track application
      const decorator1 = PrefixDecorator('P1: ');
      const decorator2 = PrefixDecorator('P2: ');

      final doc = createTestDocument(['msg']);
      try {
        decorator1.decorate(doc, entry, LogArena.instance);
        decorator2.decorate(doc, entry, LogArena.instance);

        final rendered = renderLines(doc);
        expect(rendered.first.trim(), equals('P2: P1: msg'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('BoxDecorator handles already colored lines using padVisible', () {
      const color = StyleDecorator();
      const box = BoxDecorator();

      final doc = createTestDocument(['abc']);
      try {
        color.decorate(doc, entry, LogArena.instance);
        box.decorate(doc, entry, LogArena.instance);
        final rendered = renderLines(doc);

        final middleLine = rendered[1]; // Use rendered string for check

        expect(
          middleLine.contains('abc'),
          isTrue,
        );
        expect(middleLine, startsWith('│'));
        expect(middleLine, endsWith('│'));

        // Check that ANSI codes are preserved and padding is correct
        // \x1B[34mabc\x1B[0m
        expect(middleLine, contains('\x1B[34m'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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

      final doc = createTestDocument(lines);
      try {
        // Pipeline execution: Box -> Color -> Hierarchy to ensure borders are
        // colored
        box.decorate(doc, deepEntry, LogArena.instance);
        ansi.decorate(doc, deepEntry, LogArena.instance);
        hierarchy.decorate(doc, deepEntry, LogArena.instance);

        final rendered = renderLines(doc);

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
          contains('msg'),
        );
        expect(
          content,
          contains('line'),
        );
        expect(
          content,
          contains('1'),
        );
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
