import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('BoxDecorator', () {
    final lines = ['line 1', 'line 2'];
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('adds rounded borders by default', () {
      const decorator = BoxDecorator();
      final boxed = decorator.decorate(
        createTestDocument(lines),
        entry,
      );
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('╭'));
      expect(rendered.last, startsWith('╰'));
      expect(rendered[1], startsWith('│'));
      expect(rendered[1], endsWith('│'));
    });

    test('respects sharp border style', () {
      const decorator = BoxDecorator(
        borderStyle: BorderStyle.sharp,
      );
      final boxed = decorator.decorate(
        createTestDocument(lines),
        entry,
      );
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('┌'));
      expect(rendered.last, startsWith('└'));
    });

    test('respects double border style', () {
      const decorator = BoxDecorator(
        borderStyle: BorderStyle.double,
      );
      final boxed = decorator.decorate(
        createTestDocument(lines),
        entry,
      );
      final rendered = renderLines(boxed);

      expect(rendered.first, startsWith('╔'));
      expect(rendered.last, startsWith('╚'));
    });
  });
}
