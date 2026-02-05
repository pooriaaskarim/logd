import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

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

      const structure = LogDocument(
        nodes: [
          MessageNode(segments: [StyledText('line 1\nline 2')]),
        ],
      );
      final decorated = decorator.decorate(structure, entry, context);
      final rendered = renderLines(decorated);

      // Each rendered line should have the suffix appended
      expect(rendered[0], equals('line 1 [SUFFIX]'));
      expect(rendered[1], equals('line 2 [SUFFIX]'));
    });

    test('aligns suffix to far right when alignToEnd: true', () {
      const suffix = '!!';
      const decorator = SuffixDecorator(suffix, aligned: true);
      // Total area is 20. Suffix is 2.
      const context = LogContext(availableWidth: 20, contentLimit: 20);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );

      const structure = LogDocument(
        nodes: [
          MessageNode(segments: [StyledText('12345')]),
        ],
      );
      final decorated = decorator.decorate(structure, entry, context);

      // The decorator returns a DecoratedNode wrapping the message
      expect(decorated.nodes.first, isA<DecoratedNode>());
      final node = decorated.nodes.first as DecoratedNode;
      expect(node.trailing!.first.text, equals('!!'));
      expect(node.trailing!.first.tags, contains(LogTag.suffix));

      final rendered = renderLines(decorated, width: 20);
      // "12345" + padding + "!!" = 20
      // padding = 20 - 5 - 2 = 13
      expect(rendered.first, equals('12345' + (' ' * 13) + '!!'));
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

      const structure = LogDocument(
        nodes: [
          MessageNode(segments: [StyledText('test')]),
        ],
      );

      // In the new architecture, SuffixDecorator is a StructuralDecorator.
      // SuffixDecorator priority is 3 (unknown structural).
      // BoxDecorator priority is 1.
      // So Box applies first (wrapping content), then Suffix applies (wrapping box).
      final s1 = box.decorate(structure, entry, context);
      final s2 = suffixDecorator.decorate(s1, entry, context);

      expect(s2.nodes.first, isA<DecoratedNode>());
      final decorated = s2.nodes.first as DecoratedNode;
      expect(decorated.children.first, isA<BoxNode>());

      final rendered = renderLines(s2);
      // Every line of the box should have ' !!' appended
      for (final line in rendered) {
        expect(line, endsWith(' !!'));
      }
    });
  });
}
