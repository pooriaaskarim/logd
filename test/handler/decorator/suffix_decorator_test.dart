import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('SuffixDecorator', () {
    test('appends fixed suffix to each log line (alignToEnd: false)', () {
      const suffix = ' [SUFFIX]';
      const decorator = SuffixDecorator(suffix, aligned: false);
      const context = LogContext(availableWidth: 100);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'hello',
        timestamp: '2025-01-01',
      );

      final lines = [LogLine.text('line 1'), LogLine.text('line 2')];
      final decorated = decorator.decorate(lines, entry, context).toList();

      expect(decorated.length, equals(2));
      expect(decorated[0].segments.last.text, equals(suffix));
      expect(decorated[1].segments.last.text, equals(suffix));
    });

    test('aligns suffix to far right when alignToEnd: true', () {
      const suffix = '!!';
      const decorator = SuffixDecorator(suffix, aligned: true);
      // Total area is 20. Suffix is 2. Formatter gets 18.
      const context = LogContext(availableWidth: 18, contentLimit: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );

      final lines = [LogLine.text('12345')]; // Length 5
      final decorated = decorator.decorate(lines, entry, context).toList();

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
      const suffixDecorator = SuffixDecorator(suffix, aligned: false);
      const context = LogContext(availableWidth: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'test',
        timestamp: '2025-01-01',
      );

      // Handler evaluation order: ContentDecorator (Suffix) ->
      // StructuralDecorator (Box)
      final lines = [LogLine.text('test')];
      final suffixed = suffixDecorator.decorate(lines, entry, context);
      final boxed = box.decorate(suffixed, entry, context).toList();

      // Box width: availableWidth (20) + 2 border = 22 total
      expect(boxed[0].visibleLength, equals(22));
      expect(boxed[1].segments[2].text, equals(' !!'));
    });
  });
}
