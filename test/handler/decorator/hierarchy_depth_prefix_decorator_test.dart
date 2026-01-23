import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('HierarchyDepthPrefixDecorator', () {
    final lines = [LogLine.text('msg')];

    LogEntry createEntry(final int depth) => LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'msg',
          timestamp: 'now',
          hierarchyDepth: depth,
        );

    test('adds no indentation at depth 0', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(lines, createEntry(0), mockContext).toList();
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('msg'));
    });

    test('adds indentation at depth 2 (default indent)', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(lines, createEntry(2), mockContext).toList();
      final rendered = renderLines(decorated);
      // Default is '│ ' (2 chars) * 2 = '│ │ '
      expect(rendered.first, equals('│ │ msg'));
    });

    test('respects custom indent', () {
      const decorator = HierarchyDepthPrefixDecorator(indent: '-');
      final decorated =
          decorator.decorate(lines, createEntry(3), mockContext).toList();
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('---msg'));
    });

    test('preserves tags', () {
      final taggedLines = [
        const LogLine([
          LogSegment('content', tags: {LogTag.message}),
        ]),
      ];
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(taggedLines, createEntry(1), mockContext).toList();

      // Check if any segment has the tag
      final hasTag = decorated.first.segments
          .any((final s) => s.tags.contains(LogTag.message));
      expect(hasTag, isTrue);
    });
  });
}
