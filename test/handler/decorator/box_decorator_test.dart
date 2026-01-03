import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('BoxDecorator', () {
    final lines = [LogLine.plain('line 1'), LogLine.plain('line 2')];
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
      hierarchyDepth: 0,
    );

    test('adds rounded borders by default', () {
      final decorator = BoxDecorator(lineLength: 20);
      final boxed = decorator.decorate(lines, entry).toList();

      expect(boxed.first.text, startsWith('╭'));
      expect(boxed.last.text, startsWith('╰'));
      expect(boxed[1].text, startsWith('│'));
      expect(boxed[1].text, endsWith('│'));
    });

    test('respects sharp border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        borderStyle: BorderStyle.sharp,
      );
      final boxed = decorator.decorate(lines, entry).toList();

      expect(boxed.first.text, startsWith('┌'));
      expect(boxed.last.text, startsWith('└'));
    });

    test('respects double border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        borderStyle: BorderStyle.double,
      );
      final boxed = decorator.decorate(lines, entry).toList();

      expect(boxed.first.text, startsWith('╔'));
      expect(boxed.last.text, startsWith('╚'));
    });
  });
}
