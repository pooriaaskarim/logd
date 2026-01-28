import 'package:logd/logd.dart';
import 'package:logd/src/core/utils/utils.dart';
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
      final sink = MemorySink((final line) => logs.add(line.toString()));

      final handler = Handler(
        formatter: const PlainFormatter(
          metadata: {},
        ),
        decorators: const [
          BoxDecorator(),
        ],
        sink: sink,
        lineLength: 20,
      );

      const entry = LogEntry(
        level: LogLevel.info,
        message: 'Hello 🚀', // 8 visible chars
        loggerName: 'test',
        origin: 'main',
        timestamp: '10:00:00',
        
      );

      await handler.log(entry);

      // Width should be max(20, visibleLength('Hello 🚀 World') + 2)
      // visibleLength('Hello 🚀 World') = 14 (Hello=5, space=1,
      // rocket=2, World=5)
      // Content width = 14. Box borders add 2. Total width = 16.
      // But handler.lineLength is 20.
      for (final line in logs) {
        expect(line.visibleLength, equals(20));
        expect(RegExp('^[╭│╰]').hasMatch(line), isTrue);
        expect(RegExp(r'[╮│╯]$').hasMatch(line), isTrue);
      }
    });
  });
}

final class MemorySink extends LogSink {
  MemorySink(this.onLog);
  final Function(LogLine) onLog;

  @override
  int get preferredWidth => 80;

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    for (final line in lines) {
      onLog(line);
    }
  }
}
