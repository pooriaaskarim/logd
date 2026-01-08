import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('BoxDecorator', () {
    final lines = [LogLine.text('line 1'), LogLine.text('line 2')];
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
      final boxed = decorator.decorate(lines, entry, mockContext).toList();
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('╭'));
      expect(rendered.last, startsWith('╰'));
      expect(rendered[1], startsWith('│'));
      expect(rendered[1], endsWith('│'));
    });

    test('respects sharp border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        borderStyle: BorderStyle.sharp,
      );
      final boxed = decorator.decorate(lines, entry, mockContext).toList();
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('┌'));
      expect(rendered.last, startsWith('└'));
    });

    test('respects double border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        borderStyle: BorderStyle.double,
      );
      final boxed = decorator.decorate(lines, entry, mockContext).toList();
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('╔'));
      expect(rendered.last, startsWith('╚'));
    });
  });
}
