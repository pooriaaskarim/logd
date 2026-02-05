import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('HierarchyDepthPrefixDecorator', () {
    const structure = LogDocument(
      nodes: [
        MessageNode(segments: [StyledText('msg')]),
      ],
    );

    LogEntry createEntry(final int depth) {
      final name = depth == 0
          ? 'global'
          : List.generate(depth, (final i) => 'node$i').join('.');
      return LogEntry(
        loggerName: name,
        origin: 'test',
        level: LogLevel.info,
        message: 'msg',
        timestamp: 'now',
      );
    }

    test('adds no indentation at depth 0', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(structure, createEntry(0), mockContext);
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('msg'));
    });

    test('adds indentation at depth 2 (default indent)', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(structure, createEntry(2), mockContext);
      final rendered = renderLines(decorated);
      // Default is '│ ' (2 chars) * 2 = '│ │ '
      expect(rendered.first, equals('│ │ msg'));
    });

    test('respects custom indent', () {
      const decorator = HierarchyDepthPrefixDecorator(indent: '-');
      final decorated =
          decorator.decorate(structure, createEntry(3), mockContext);
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('---msg'));
      final container = decorated.nodes.first as IndentationNode;
      expect(container.children.length, equals(1));
    });

    test('preserves tags', () {
      const taggedStructure = LogDocument(
        nodes: [
          MessageNode(
            segments: [
              StyledText('content', tags: {LogTag.message}),
            ],
          ),
        ],
      );
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(taggedStructure, createEntry(1), mockContext);

      // Check if any segment has the tag (trawling through containers)
      bool hasTag(final LogNode node) {
        if (node is ContentNode) {
          return node.segments
              .any((final s) => s.tags.contains(LogTag.message));
        } else if (node is IndentationNode) {
          return node.children.any(hasTag);
        }
        return false;
      }

      final found = decorated.nodes.any(hasTag);
      expect(found, isTrue);
    });
  });
}
