import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiColorDecorator', () {
    final lines = ['line 1', 'line 2'];

    test('adds colors when enabled', () {
      const decorator = AnsiColorDecorator(useColors: true);
      final decorated = decorator.decorate(lines, LogLevel.info).toList();

      expect(decorated.length, equals(2));
      expect(decorated[0], startsWith('\x1B[32m')); // Green
      expect(decorated[0], endsWith('\x1B[0m'));
      expect(decorated[0], contains('line 1'));
    });

    test('different levels have different colors', () {
      const decorator = AnsiColorDecorator(useColors: true);

      final info = decorator.decorate(['msg'], LogLevel.info).first;
      final error = decorator.decorate(['msg'], LogLevel.error).first;
      final warning = decorator.decorate(['msg'], LogLevel.warning).first;

      expect(info, contains('\x1B[32m')); // Green
      expect(error, contains('\x1B[31m')); // Red
      expect(warning, contains('\x1B[33m')); // Yellow
    });

    test('skips coloring when disabled', () {
      const decorator = AnsiColorDecorator(useColors: false);
      final decorated = decorator.decorate(lines, LogLevel.info).toList();

      expect(decorated, equals(lines));
    });
  });
}
