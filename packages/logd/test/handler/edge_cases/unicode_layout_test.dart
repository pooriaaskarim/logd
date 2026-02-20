import 'package:logd/logd.dart';
import 'package:logd/src/core/utils/utils.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Unicode Layout Verification', () {
    test('visibleLength handles emojis correctly (cell width)', () {
      expect('🍎'.visibleLength, equals(2));
      expect('🍎🍏'.visibleLength, equals(4));
      expect('Hello 🚀 World'.visibleLength, equals(14));
    });

    test('wrapVisible respects Unicode cell width boundaries', () {
      const message = '🍎🍏🍋🍐';
      // If width is 3 units:
      // Line 1: 🍎 (2 units) + space for one unit (but next is 🍏 which is 2)
      // Line 2: 🍏
      // ...
      final lines = message.wrapVisible(3).toList();
      expect(lines.length, equals(4));
      expect(lines[0], equals('🍎'));
      expect(lines[1], equals('🍏'));
    });

    test('BoxDecorator handles emojis correctly in width calculation',
        () async {
      final logs = <String>[];
      final sink = MemorySink(
        (final line) => logs.add(line.toString()),
        preferredWidth: 20,
      );

      final handler = Handler(
        formatter: const PlainFormatter(
          metadata: {},
        ),
        decorators: const [
          BoxDecorator(),
        ],
        sink: sink,
      );

      const entry = LogEntry(
        level: LogLevel.info,
        message: 'Hello 🚀', // 8 visible chars
        loggerName: 'test',
        origin: 'main',
        timestamp: '10:00:00',
      );

      await handler.log(entry);

      // Width should be max(20, visibleLength('Hello 🚀') + 2)
      // visibleLength('Hello 🚀') = 8. Box borders add 2. Total width = 10.
      // But sink.preferredWidth is 20.
      for (final line in logs) {
        expect(line.visibleLength, equals(20));
        // Use contains to be ANSI-insensitive or strip ANSI for match
        expect(line.contains(RegExp('[╭│╰]')), isTrue);
      }
    });
  });
}

final class MemorySink extends LogSink<LogDocument> {
  MemorySink(this.onLog, {this.preferredWidth = 80});
  final Function(Object) onLog;
  final int preferredWidth;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level, {
    final LogContext? context,
  }) async {
    const encoder = AnsiEncoder();
    final output = encoder.encode(document, level, width: preferredWidth);
    onLog(output);
  }
}
