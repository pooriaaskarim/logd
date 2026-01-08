// Tests for Unicode and special character handling.
import 'package:logd/logd.dart';
import 'package:test/test.dart';
import '../decorator/mock_context.dart';

void main() {
  group('Unicode and Special Character Handling', () {
    test('handles Unicode characters correctly', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 40),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 40,
          ),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '你好世界 🌍',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      // Should handle Unicode without breaking box structure
      final topWidth = result[0].visibleLength;
      for (final line in result) {
        expect(line.visibleLength, equals(topWidth));
      }
    });

    test('handles emoji correctly', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 50),
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Emoji test: 🚀 🎉 ✅ ❌ ⚠️ 🔥',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      // Should not crash
      expect(formatted, isNotEmpty);
    });

    test('handles special ASCII characters', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 80),
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Special: !@#\$%^&*()_+-=[]{}|;:,.<>?',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext).toList();
      expect(formatted, isNotEmpty);
    });

    test('handles mixed Unicode and ASCII', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 60),
        decorators: const [
          ColorDecorator(),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Mixed: Hello 世界! 🎉 Special: !@#',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      expect(result, isNotEmpty);
    });

    test('handles long Unicode string with wrapping', () {
      final handler = Handler(
        formatter: StructuredFormatter(lineLength: 30),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
            lineLength: 30,
          ),
        ],
        sink: const ConsoleSink(),
      );

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: '长文本：这是一个非常长的中文消息，应该正确换行',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = handler.formatter.format(entry, mockContext);
      var lines = formatted;
      for (final decorator in handler.decorators) {
        lines = decorator.decorate(lines, entry, mockContext);
      }

      final result = lines.toList();
      final topWidth = result[0].visibleLength;
      // All lines should have consistent width
      for (final line in result) {
        expect(line.visibleLength, equals(topWidth));
      }
    });
  });
}
