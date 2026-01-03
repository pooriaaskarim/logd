import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('BoxDecorator', () {
    final lines = ['line 1', 'line 2'];

    test('adds rounded borders by default', () {
      final decorator = BoxDecorator(lineLength: 20, useColors: false);
      final boxed = decorator.decorate(lines, LogLevel.info).toList();

      expect(boxed.first, startsWith('╭'));
      expect(boxed.last, startsWith('╰'));
      expect(boxed[1], startsWith('│'));
      expect(boxed[1], endsWith('│'));
    });

    test('respects sharp border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        useColors: false,
        borderStyle: BorderStyle.sharp,
      );
      final boxed = decorator.decorate(lines, LogLevel.info).toList();

      expect(boxed.first, startsWith('┌'));
      expect(boxed.last, startsWith('└'));
    });

    test('respects double border style', () {
      final decorator = BoxDecorator(
        lineLength: 20,
        useColors: false,
        borderStyle: BorderStyle.double,
      );
      final boxed = decorator.decorate(lines, LogLevel.info).toList();

      expect(boxed.first, startsWith('╔'));
      expect(boxed.last, startsWith('╚'));
    });

    test('colors borders when enabled', () {
      final decorator = BoxDecorator(lineLength: 20, useColors: true);
      final boxed = decorator.decorate(lines, LogLevel.error).toList();

      expect(boxed.first, contains('\x1B[31m')); // Red for error
      expect(boxed.first, contains('╭'));
      expect(boxed.first, endsWith('\x1B[0m'));
    });
  });
}
