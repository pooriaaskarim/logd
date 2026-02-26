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
      final doc = createTestDocument(lines);
      try {
        decorator.decorate(
          doc,
          createEntry(0),
          LogArena.instance,
        );
        final rendered = renderLines(doc);
        expect(rendered.first, equals('msg'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('adds indentation at depth 2 (default indent)', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final doc = createTestDocument(lines);
      try {
        decorator.decorate(
          doc,
          createEntry(2),
          LogArena.instance,
        );
        final rendered = renderLines(doc);
        // Default is '│ ' (2 chars) * 2 = '│ │ '
        expect(rendered.first, equals('│ │ msg'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('respects custom indent', () {
      const decorator = HierarchyDepthPrefixDecorator(indent: '-');
      final doc = createTestDocument(lines);
      try {
        decorator.decorate(
          doc,
          createEntry(3),
          LogArena.instance,
        );
        final rendered = renderLines(doc);
        expect(rendered.first, equals('---msg'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('preserves tags', () {
      final arena = LogArena.instance;
      final doc = arena.checkoutDocument();
      doc.nodes.add(
        arena.checkoutMessage()
          ..segments.add(const StyledText('content', tags: LogTag.message)),
      );

      try {
        // Check if any segment has the tag
        bool hasTag = false;
        for (final node in doc.nodes) {
          if (node is MessageNode) {
            if (node.segments
                .any((final s) => (s.tags & LogTag.message) != 0)) {
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
      } finally {
        doc.releaseRecursive(arena);
      }
    });
  });
}
