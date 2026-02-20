import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('JsonPrettyFormatter Wisdom', () {

    test('compacts small composites onto a single line', () {
      const formatter = JsonPrettyFormatter(color: false);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        timestamp: '2025-01-01',
        level: LogLevel.info,
        message: 'Compact test',
        error: {'id': 1, 'v': 'a'},
      );

      final doc = formatter.format(entry);
      final output = render(doc, width: 80);

      // Should find "id":1 (compacted JSON doesn't always have spaces)
      expect(output.replaceAll(' ', ''), contains('"id":1,"v":"a"'));
    });

    test('sorts keys alphabetically when sortKeys is true', () {
      const formatter = JsonPrettyFormatter(sortKeys: true);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        timestamp: '2025-01-01',
        level: LogLevel.info,
        message: 'Sort test',
        error: {'z': 1, 'a': 2},
      );

      final doc = formatter.format(entry);
      final output = render(doc, width: 80).replaceAll(' ', '');

      final aIdx = output.indexOf('"a":2');
      final zIdx = output.indexOf('"z":1');
      expect(aIdx, isNot(-1));
      expect(zIdx, isNot(-1));
      expect(aIdx, lessThan(zIdx));
    });

    test('stacks keys above complex values exceeding threshold', () {
      const formatter = JsonPrettyFormatter(stackThreshold: 5);
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        timestamp: '2025-01-01',
        level: LogLevel.info,
        message: 'Stack test',
        error: {
          'long_key': {'nested': 1},
        },
      );

      final doc = formatter.format(entry);
      final output = render(doc, width: 80);

      // "long_key" (length 10) > 5, so it should be followed by a newline
      // before the next structural character '{'
      expect(output, contains('"long_key": \n'));
      expect(output, contains('{\n'));
    });

    test('handles multiline scalars as distinct blocks', () {
      const formatter = JsonPrettyFormatter();
      const entry = LogEntry(
        loggerName: 'test',
        origin: 'test.dart',
        timestamp: '2025-01-01',
        level: LogLevel.info,
        message: 'Multiline test',
        error: {'stack': 'line 1\nline 2'},
      );

      final doc = formatter.format(entry);
      final output = render(doc, width: 80);

      expect(output, contains('line 1'));
      expect(output, contains('line 2'));
    });
  });
}

String render(final LogDocument doc, {required final int width}) {
  final layout = TerminalLayout(width: width);
  return layout
      .layout(doc, LogLevel.info)
      .lines
      .map((final l) => l.toString())
      .join('\n');
}
