import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('StructuredFormatter', () {
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'main.dart',
      level: LogLevel.info,
      message: 'Hello World',
      timestamp: '2025-01-01 10:00:00',
    );

    test('formats header with semantic segments', () {
      const formatter = StructuredFormatter();
      final structure = formatter.format(entry, mockContext);

      // Now nodes are wrapped in Decorated
      final decoratedHeader = structure.nodes.first as DecoratedNode;
      expect(decoratedHeader.leadingHint, equals('structured_separator'));

      final header = decoratedHeader.children.first as HeaderNode;
      final segments = header.segments;
      // Timestamp
      expect(
        segments.any((final s) => s.text.contains('2025-01-01 10:00:00')),
        isTrue,
      );
      // Level
      expect(segments.any((final s) => s.text.contains('[INFO]')), isTrue);
      // Logger
      expect(segments.any((final s) => s.text.contains('[test]')), isTrue);
      // Origin
      expect(segments.any((final s) => s.text.contains('[main.dart]')), isTrue);
    });

    test('emits message in body section', () {
      const formatter = StructuredFormatter();
      const longEntry = LogEntry(
        loggerName: 't',
        origin: 'o',
        level: LogLevel.info,
        message: 'This is a message.',
        timestamp: 'ts',
      );
      final structure = formatter.format(longEntry, mockContext);

      // Find the message decorated node
      final decoratedMessage = structure.nodes.firstWhere(
        (final node) =>
            node is DecoratedNode && node.leadingHint == 'structured_content',
      ) as DecoratedNode;

      final message = decoratedMessage.children.first as MessageNode;
      expect(message.segments.first.text, equals('This is a message.'));
    });
  });
}
