import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('HierarchyDepthPrefixDecorator', () {
    final lines = ['msg'];

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
      final decorated = decorator.decorate(
        createTestDocument(lines),
        createEntry(0),
        LogArena.instance,
      );
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('msg'));
    });

    test('adds indentation at depth 2 (default indent)', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated = decorator.decorate(
        createTestDocument(lines),
        createEntry(2),
        LogArena.instance,
      );
      final rendered = renderLines(decorated);
      // Default is '│ ' (2 chars) * 2 = '│ │ '
      expect(rendered.first, equals('│ │ msg'));
    });

    test('respects custom indent', () {
      const decorator = HierarchyDepthPrefixDecorator(indent: '-');
      final decorated = decorator.decorate(
        createTestDocument(lines),
        createEntry(3),
        LogArena.instance,
      );
      final rendered = renderLines(decorated);
      expect(rendered.first, equals('---msg'));
    });

    test('preserves tags', () {
      final doc = LogDocument(
        nodes: <LogNode>[
          MessageNode(
            segments: [
              const StyledText('content', tags: LogTag.message),
            ],
          ),
        ],
      );

      const decorator = HierarchyDepthPrefixDecorator();
      final decorated =
          decorator.decorate(doc, createEntry(1), LogArena.instance);
      // final rendered = renderLines(decorated); // Not used

      // Check if any segment has the tag
      bool hasTag = false;
      for (final node in decorated.nodes) {
        if (node is MessageNode) {
          if (node.segments.any((final s) => (s.tags & LogTag.message) != 0)) {
            hasTag = true;
          }
        } else if (node is LayoutNode) {
          for (final child in node.children) {
            if (child is MessageNode) {
              if (child.segments
                  .any((final s) => (s.tags & LogTag.message) != 0)) {
                hasTag = true;
              }
            }
          }
        }
      }
      expect(hasTag, isTrue);
    });
  });
}
