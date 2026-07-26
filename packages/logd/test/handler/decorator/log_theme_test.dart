import 'package:logd/logd.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('LogColorScheme and LogTheme Tag Overrides', () {
    final infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('LogColorScheme provides 5-level color palette', () {
      const scheme = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      expect(scheme.colorForLevel(LogLevel.info), equals(LogColor.blue));
      expect(scheme.colorForLevel(LogLevel.error), equals(LogColor.red));
      expect(scheme.colorForLevel(LogLevel.warning), equals(LogColor.yellow));
      expect(scheme.colorForLevel(LogLevel.debug), equals(LogColor.white));
      expect(scheme.colorForLevel(LogLevel.trace), equals(LogColor.green));
    });

    test('StyleDecorator applies tag-specific LogStyle overrides', () {
      const customScheme = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      const customTheme = LogTheme(
        colorScheme: customScheme,
        timestampStyle: LogStyle(color: LogColor.brightBlack),
        levelStyle: LogStyle(color: LogColor.brightCyan, bold: true),
      );

      const decorator = StyleDecorator(customTheme);

      // Create a document with specific tags
      final doc = createTestDocument([]);
      try {
        final arena = Arena.instance;
        final header = arena.checkoutHeader();
        header.segments.addAll([
          const StyledText(
            '2024-01-01',
            tags: LogTag.header | LogTag.timestamp,
          ),
          const StyledText(' [INFO] ', tags: LogTag.header | LogTag.level),
        ]);
        doc.nodes.add(header);

        final msg = arena.checkoutMessage();
        msg.segments.add(const StyledText('Message', tags: LogTag.message));
        doc.nodes.add(msg);

        decorator.decorate(doc, infoEntry, arena);
        final rendered = renderLines(doc);

        final fullOutput = rendered.join('\n');

        // Timestamp should be dimmed (2) + brightBlack (90)
        expect(fullOutput, contains('\x1B[2m\x1B[90m'));
        // Level should be bold (1) + brightCyan (96)
        expect(fullOutput, contains('\x1B[1m\x1B[96m'));
        // Message should be blue (34)
        expect(fullOutput, contains('\x1B[34m'));
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('LogTheme respects custom logic via subclass', () {
      const theme = NoMessageTheme();
      final style = theme.getStyle(LogLevel.info, LogTag.message);
      expect(style.color, isNull);
    });

    test('LogTheme resolves defaults correctly', () {
      const theme = LogTheme(colorScheme: LogColorScheme.defaultScheme);
      final style = theme.getStyle(LogLevel.info, LogTag.message);
      expect(style.color, LogColor.blue);
    });

    test('LogColorScheme equality compares level colors', () {
      const scheme1 = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      const scheme2 = LogColorScheme(
        info: LogColor.cyan,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      expect(scheme1, isNot(equals(scheme2)));
    });
  });
}

class NoMessageTheme extends LogTheme {
  const NoMessageTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if ((tags & LogTag.message) != 0) {
      return const LogStyle();
    }

    var style = LogStyle(color: colorScheme.colorForLevel(level));

    if ((tags & LogTag.header) != 0) {
      style = LogStyle(
        color: style.color,
        bold: true,
        inverse: true,
      );
    }

    return style;
  }
}
