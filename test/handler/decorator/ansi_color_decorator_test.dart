import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiColorDecorator', () {
    final lines = [LogLine.plain('line 1'), LogLine.plain('line 2')];
    const infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
      hierarchyDepth: 0,
    );

    test('adds colors when enabled', () {
      const decorator = AnsiColorDecorator(useColors: true);
      final decorated = decorator.decorate(lines, infoEntry).toList();

      expect(decorated.length, equals(2));
      // Just check if it contains color code and text.
      // Info level now defaults to blue (was green)
      expect(decorated[0].text, contains('\x1B[34m')); // Blue
      expect(decorated[0].text, endsWith('\x1B[0m'));
      expect(decorated[0].text, contains('line 1'));
    });

    test('different levels have different colors', () {
      const decorator = AnsiColorDecorator(useColors: true);

      final info = decorator.decorate([LogLine.plain('msg')], infoEntry).first;
      final error = decorator.decorate(
        [LogLine.plain('msg')],
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.error,
          message: 'msg',
          timestamp: 'now',
          hierarchyDepth: 0,
        ),
      ).first;
      final warning = decorator.decorate(
        [LogLine.plain('msg')],
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.warning,
          message: 'msg',
          timestamp: 'now',
          hierarchyDepth: 0,
        ),
      ).first;

      // Using default scheme: trace=green, debug=white, info=blue,
      // warning=yellow, error=red
      expect(info.text, contains('\x1B[34m')); // Blue
      expect(error.text, contains('\x1B[31m')); // Red
      expect(warning.text, contains('\x1B[33m')); // Yellow
    });

    test('skips coloring when disabled', () {
      const decorator = AnsiColorDecorator(useColors: false);
      final decorated = decorator.decorate(lines, infoEntry).toList();

      expect(decorated, equals(lines));
    });

    test('applies background color to header when enabled', () {
      const decorator = AnsiColorDecorator(
        useColors: true,
        config: AnsiColorConfig(headerBackground: true),
      );
      final headerLines = [
        const LogLine('Header 1', tags: {LogLineTag.header}),
        const LogLine('Message 1', tags: {LogLineTag.message}),
      ];

      final decorated = decorator.decorate(headerLines, infoEntry).toList();

      // Header line should have inverted color code (\x1B[7m)
      expect(decorated[0].text, contains('\x1B[7m'));
      expect(decorated[0].text, contains('Header 1'));

      // Message line should NOT have inverted color code
      expect(decorated[1].text, isNot(contains('\x1B[7m')));
      expect(decorated[1].text, contains('Message 1'));
    });
  });
}
