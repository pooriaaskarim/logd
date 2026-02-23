import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('StyleDecorator', () {
    final lines = [LogLine.text('line 1'), LogLine.text('line 2')];
    const infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('adds colors when enabled', () {
      const decorator = StyleDecorator();
      final decorated =
          decorator.decorate(lines, infoEntry, mockContext).toList();
      final rendered = renderLines(decorated);

      expect(rendered.length, equals(2));
      // Just check if it contains color code and text.
      // Info level now defaults to blue (was green)
      expect(rendered[0], contains('\x1B[34m')); // Blue
      expect(rendered[0], endsWith('\x1B[0m'));
      expect(rendered[0], contains('line 1'));
    });

    test('different levels have different colors', () {
      const decorator = StyleDecorator(
        theme: LogTheme(
          colorScheme: LogColorScheme(
            trace: LogColor.green,
            debug: LogColor.white,
            info: LogColor.blue,
            warning: LogColor.yellow,
            error: LogColor.red,
          ),
        ),
      );

      final info = renderLines(
        decorator.decorate([LogLine.text('msg')], infoEntry, mockContext),
      ).first;
      final error = renderLines(
        decorator.decorate(
          [LogLine.text('msg')],
          const LogEntry(
            loggerName: 'test',
            origin: 'test',
            level: LogLevel.error,
            message: 'msg',
            timestamp: 'now',
          ),
          mockContext,
        ),
      ).first;
      final warning = renderLines(
        decorator.decorate(
          [LogLine.text('msg')],
          const LogEntry(
            loggerName: 'test',
            origin: 'test',
            level: LogLevel.warning,
            message: 'msg',
            timestamp: 'now',
          ),
          mockContext,
        ),
      ).first;

      // Using default scheme: trace=green, debug=white, info=blue,
      // warning=yellow, error=red
      expect(info, contains('\x1B[34m')); // Blue
      expect(error, contains('\x1B[31m')); // Red
      expect(warning, contains('\x1B[33m')); // Yellow
    });

    test('respects custom theme (no message coloring)', () {
      const decorator = StyleDecorator(
        theme: NoMessageTheme(),
      );
      final headerLines = [
        const LogLine([
          LogSegment('Header 1', tags: {LogTag.header}),
        ]),
        const LogLine([
          LogSegment('Message 1', tags: {LogTag.message}),
        ]),
      ];

      final decorated =
          decorator.decorate(headerLines, infoEntry, mockContext).toList();
      final rendered = renderLines(decorated);

      // Header line should have inverted color code (\x1B[7m) - defined in NoMessageTheme
      expect(rendered[0], contains('\x1B[7m'));
      expect(rendered[0], contains('Header 1'));

      // Message line should NOT have inverted color code AND no color at all
      // (if theme says so)
      // NoMessageTheme doesn't apply base color to message.
      expect(rendered[1], isNot(contains('\x1B[7m')));
      expect(rendered[1], isNot(contains('\x1B[34m'))); // Check no blue either
      expect(rendered[1], contains('Message 1'));
    });
  });
}

class NoMessageTheme extends LogTheme {
  const NoMessageTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    if (tags.contains(LogTag.message)) {
      return const LogStyle(); // No style, no color
    }

    // For others, behave "normally" but let's just minimal implementation for
    // test
    var style = LogStyle(color: colorScheme.colorForLevel(level));

    if (tags.contains(LogTag.header)) {
      style = LogStyle(
        color: style.color, bold: true, inverse: true, // Test expects inverse
      );
    }

    return style;
  }
}
