import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('LogDocument equality and hashCode', () {
    const nodeA = MessageNode(segments: [StyledText('hello')]);
    const nodeB = MessageNode(segments: [StyledText('world')]);

    test('identical documents are equal', () {
      const doc1 = LogDocument(nodes: [nodeA]);
      const doc2 = LogDocument(nodes: [nodeA]);
      expect(doc1, equals(doc2));
      expect(doc1.hashCode, equals(doc2.hashCode));
    });

    test('documents with different nodes are not equal', () {
      const doc1 = LogDocument(nodes: [nodeA]);
      const doc2 = LogDocument(nodes: [nodeB]);
      expect(doc1, isNot(equals(doc2)));
    });

    test('documents with different metadata are not equal', () {
      const doc1 = LogDocument(nodes: [nodeA], metadata: {'key': 'value1'});
      const doc2 = LogDocument(nodes: [nodeA], metadata: {'key': 'value2'});
      expect(doc1, isNot(equals(doc2)));
    });

    test('documents with different metadata have different hashCodes', () {
      const doc1 = LogDocument(nodes: [nodeA], metadata: {'a': '1'});
      const doc2 = LogDocument(nodes: [nodeA], metadata: {'a': '2'});
      // hashCode collision is theoretically possible but astronomically
      // unlikely for these inputs — treat a collision here as a test failure.
      expect(doc1.hashCode, isNot(equals(doc2.hashCode)));
    });

    test('document with metadata equals itself', () {
      const doc = LogDocument(nodes: [nodeA], metadata: {'x': 42});
      expect(doc, equals(doc));
      expect(doc.hashCode, equals(doc.hashCode));
    });

    test('empty documents are equal', () {
      const doc1 = LogDocument(nodes: []);
      const doc2 = LogDocument(nodes: []);
      expect(doc1, equals(doc2));
      expect(doc1.hashCode, equals(doc2.hashCode));
    });
  });

  group('MapNode equality and hashCode', () {
    test('identical MapNodes are equal', () {
      const node1 = MapNode({'a': 1, 'b': 'hello'});
      const node2 = MapNode({'a': 1, 'b': 'hello'});
      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
    });

    test('MapNodes with different maps are not equal', () {
      const node1 = MapNode({'a': 1});
      const node2 = MapNode({'a': 2});
      expect(node1, isNot(equals(node2)));
    });

    test('MapNodes with different maps have different hashCodes', () {
      const node1 = MapNode({'level': 'info', 'message': 'alpha'});
      const node2 = MapNode({'level': 'error', 'message': 'alpha'});
      expect(node1.hashCode, isNot(equals(node2.hashCode)));
    });

    test('empty MapNodes are equal', () {
      const node1 = MapNode({});
      const node2 = MapNode({});
      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
    });

    test('MapNode with different tags is not equal', () {
      const node1 = MapNode({'a': 1}, tags: LogTag.header);
      const node2 = MapNode({'a': 1}, tags: LogTag.message);
      expect(node1, isNot(equals(node2)));
    });
  });

  group('ListNode equality and hashCode', () {
    test('identical ListNodes are equal', () {
      const node1 = ListNode([1, 2, 3]);
      const node2 = ListNode([1, 2, 3]);
      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
    });

    test('ListNodes with different lists are not equal', () {
      const node1 = ListNode([1, 2, 3]);
      const node2 = ListNode([1, 2, 4]);
      expect(node1, isNot(equals(node2)));
    });

    test('empty ListNodes are equal', () {
      const node1 = ListNode([]);
      const node2 = ListNode([]);
      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
    });
  });
}
