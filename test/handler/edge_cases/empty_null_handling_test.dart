// Tests for handling empty, null, and edge case messages.

import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Empty and Null Message Handling', () {
    test('handles empty string message', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      // Should not crash, may produce empty or minimal output
      expect(formatted, isA<List<LogLine>>());
    });

    test('handles whitespace-only message', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '   \n\t  ',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      expect(formatted, isA<List<LogLine>>());
    });

    test('handles very short message', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 80,
          ),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'x',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      // Should produce valid box even with single character
      expect(result.length, greaterThanOrEqualTo(3)); // top, content, bottom
    });

    test('handles message with only newlines', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '\n\n\n',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      // Should handle gracefully
      expect(formatted, isA<List<LogLine>>());
    });

    test('handles empty message with decorators', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        decorators: const [
          const ColorDecorator(),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      // Should not crash
      expect(result, isA<List<LogLine>>());
    });
  });
}
