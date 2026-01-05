import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('HierarchyDepthPrefixDecorator', () {
    final lines = [LogLine.plain('msg')];

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
      final decorated = decorator.decorate(lines, createEntry(0)).first;
      expect(decorated.text, equals('msg'));
    });

    test('adds indentation at depth 2 (default indent)', () {
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated = decorator.decorate(lines, createEntry(2)).first;
      // Default is '│ ' (2 chars) * 2 = '│ │ '
      expect(decorated.text, equals('│ │ msg'));
    });

    test('respects custom prefix and indent', () {
      const decorator =
          HierarchyDepthPrefixDecorator(prefix: '> ', indent: '-');
      final decorated = decorator.decorate(lines, createEntry(3)).first;
      expect(decorated.text, equals('> ---msg'));
    });

    test('preserves tags', () {
      final taggedLines = [
        const LogLine('content', tags: {LogLineTag.message}),
      ];
      const decorator = HierarchyDepthPrefixDecorator();
      final decorated = decorator.decorate(taggedLines, createEntry(1)).first;
      expect(decorated.tags, contains(LogLineTag.message));
    });
  });
}
