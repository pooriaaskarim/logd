import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Node Tagging', () {
    test('LogNode stores tags', () {
      const node = HeaderNode(segments: [], tags: {LogTag.error});
      expect(node.tags, contains(LogTag.error));
    });

    test('HeaderNode has default header tag', () {
      const node = HeaderNode(segments: []);
      expect(node.tags, contains(LogTag.header));
    });

    test('MessageNode has default message tag', () {
      const node = MessageNode(segments: []);
      expect(node.tags, contains(LogTag.message));
    });

    test('ErrorNode has default error tag', () {
      const node = ErrorNode(segments: []);
      expect(node.tags, contains(LogTag.error));
    });

    test('BoxNode correctly handles tags', () {
      const node = BoxNode(
        children: [],
        tags: {LogTag.error},
      );
      expect(node.tags, contains(LogTag.error));
    });

    test('IndentationNode correctly handles tags', () {
      const node = IndentationNode(
        children: [],
        tags: {LogTag.hierarchy},
      );
      expect(node.tags, contains(LogTag.hierarchy));
    });

    test('MetadataNode correctly handles tags', () {
      const node = MetadataNode(
        segments: [],
        tags: {LogTag.origin},
      );
      expect(node.tags, contains(LogTag.origin));
    });

    test('Equality includes tags', () {
      const node1 = MessageNode(segments: [], tags: {LogTag.message});
      const node2 = MessageNode(segments: [], tags: {LogTag.message});
      const node3 = MessageNode(segments: [], tags: {LogTag.error});

      expect(node1, equals(node2));
      expect(node1, isNot(equals(node3)));
    });
  });
}
