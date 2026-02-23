import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('SuffixDecorator', () {
    test('appends fixed suffix to each log line (alignToEnd: false)', () {
      const suffix = ' [SUFFIX]';
      const decorator = SuffixDecorator(suffix, aligned: false);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'hello',
        timestamp: '2025-01-01',
      );

      final lines = ['line 1', 'line 2'];
      final doc = createTestDocument(lines);
      final decoratedDoc = decorator.decorate(doc, entry);

      const layout = TerminalLayout(width: 80);
      final decorated = layout.layout(decoratedDoc, LogLevel.info).lines;

      expect(decorated.length, equals(2));
      expect(decorated[0].segments.last.text, equals(suffix));
      expect(decorated[1].segments.last.text, equals(suffix));
    });

    test('aligns suffix to far right when alignToEnd: true', () {
      const suffix = '!!';
      const decorator = SuffixDecorator(suffix, aligned: true);
      // Total area is 20. Suffix is 2. Formatter gets 18.
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );

      final lines = ['12345']; // Length 5
      final doc = createTestDocument(lines);
      final decoratedDoc = decorator.decorate(doc, entry);

      const layout = TerminalLayout(width: 20);
      final decorated = layout.layout(decoratedDoc, LogLevel.info).lines;

      // Content (5) + Padding (13) + Suffix (2) = 20 total (contentLimit)
      expect(decorated[0].visibleLength, equals(20));
      expect(decorated[0].segments[1].text, equals(' ' * 13));
      expect(decorated[0].segments.last.text, equals('!!'));
    });

    test('reports correct paddingWidth', () {
      const suffix = '123';
      const decorator = SuffixDecorator(suffix);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'hello',
        timestamp: '2025-01-01',
      );

      expect(decorator.paddingWidth(entry), equals(3));
    });

    test('composes correctly with BoxDecorator (attached suffix)', () {
      const box = BoxDecorator();
      const suffix = ' !!';
      const decorator = SuffixDecorator(suffix, aligned: false);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01',
      );

      // Handler evaluation order: ContentDecorator (Suffix) ->
      // StructuralDecorator (Box)
      final lines = ['test'];
      final suffixed =
          decorator.decorate(createTestDocument(lines), entry);
      final boxedDoc = box.decorate(suffixed, entry);

      const layout = TerminalLayout(width: 22);
      final boxed = layout.layout(boxedDoc, LogLevel.info).lines;

      // Box width: availableWidth (20) + 2 border = 22 total
      expect(boxed[0].visibleLength, equals(22));
      expect(boxed[1].segments[3].text, equals(' !!'));
    });
  });
}
