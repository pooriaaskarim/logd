import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('BoxDecorator Robustness', () {
    test(
        'BoxDecorator with PlainFormatter and long message should '
        'not break the box', () {
      const formatter = PlainFormatter();
      final box = BoxDecorator(lineLength: 40);

      const entry = LogEntry(
        loggerName: 'test',
        origin: 'main.dart',
        level: LogLevel.info,
        message: 'This is a very long message that definitely exceeds the '
            '40 characters limit of the box decorator and should '
            'be handled gracefully.',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = formatter.format(entry);
      final boxed = box.decorate(formatted, entry).toList();

      // Check top/bottom border length
      final topWidth = boxed[0].visibleLength;

      for (int i = 0; i < boxed.length; i++) {
        final line = boxed[i];
        print('Line $i: ${line.visibleLength} chars | ${line.text}');
        expect(
          line.visibleLength,
          equals(topWidth),
          reason: 'Line $i has inconsistent width: ${line.visibleLength}'
              ' vs $topWidth',
        );
      }
    });

    test(
        'BoxDecorator with JsonFormatter (long line) should '
        'wrap internal content', () {
      const formatter = JsonFormatter();
      final box = BoxDecorator(lineLength: 30);

      const entry = LogEntry(
        loggerName: 'very_long_logger_name_that_will_push_json_over_the_limit',
        origin: 'some_long_file_path.dart',
        level: LogLevel.error,
        message: 'Status 500: Database connection failed unexpectedly.',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      final formatted = formatter.format(entry);
      final boxed = box.decorate(formatted, entry).toList();

      for (int i = 0; i < boxed.length; i++) {
        final line = boxed[i];
        expect(line.visibleLength, equals(boxed[0].visibleLength));
      }
    });
  });
}
