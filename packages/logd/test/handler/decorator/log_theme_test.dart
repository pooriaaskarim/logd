import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('LogColorScheme Tag-Specific Overrides', () {
    const infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('colorFor respects tag-specific overrides', () {
      const scheme = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        // Tag-specific overrides
        timestampColor: LogColor.brightBlack,
        levelColor: LogColor.brightBlue,
        loggerNameColor: LogColor.cyan,
        borderColor: LogColor.brightBlack,
      );

      // Base level color
      expect(
        scheme.colorFor(LogLevel.info, LogTag.none),
        equals(LogColor.blue),
      );

      // Tag-specific overrides
      expect(
        scheme.colorFor(LogLevel.info, LogTag.timestamp),
        equals(LogColor.brightBlack),
      );
      expect(
        scheme.colorFor(LogLevel.info, LogTag.level),
        equals(LogColor.brightBlue),
      );
      expect(
        scheme.colorFor(LogLevel.info, LogTag.loggerName),
        equals(LogColor.cyan),
      );
      expect(
        scheme.colorFor(LogLevel.info, LogTag.border),
        equals(LogColor.brightBlack),
      );

      // No override: falls back to base color
      expect(
        scheme.colorFor(LogLevel.info, LogTag.message),
        equals(LogColor.blue),
      );
    });

    test('colorFor falls back to base level color when no override', () {
      const scheme = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      // All tags should get base level color
      expect(
        scheme.colorFor(LogLevel.info, LogTag.timestamp),
        equals(LogColor.blue),
      );
      expect(
        scheme.colorFor(LogLevel.info, LogTag.level),
        equals(LogColor.blue),
      );
      expect(
        scheme.colorFor(LogLevel.info, LogTag.message),
        equals(LogColor.blue),
      );
    });

    test('StyleDecorator applies tag-specific colors', () {
      const customScheme = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        timestampColor: LogColor.brightBlack,
        levelColor: LogColor.brightCyan, // Different from base
      );

      const decorator =
          StyleDecorator(theme: LogTheme(colorScheme: customScheme));

      // Create a document with specific tags
      final doc = createTestDocument([]);
      try {
        final arena = LogArena.instance;
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

        // Rendered output might be split or joined depending on layout.
        // renderLines produces a List<String>.
        // We check if the expected ANSI codes are present in the output.
        final fullOutput = rendered.join('\n');

        // Timestamp should be dimmed (2) + brightBlack (90)
        expect(fullOutput, contains('\x1B[2m\x1B[90m'));
        // Level should be bold (1) + brightCyan (96)
        expect(fullOutput, contains('\x1B[1m\x1B[96m'));
        // Message should be blue (34)
        expect(fullOutput, contains('\x1B[34m'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('LogTheme respects custom logic via subclass', () {
      const theme = NoMessageTheme();
      final style = theme.getStyle(LogLevel.info, LogTag.message);
      expect(style.color, isNull); // Should be no color
    });

    test('LogTheme resolves defaults correctly', () {
      const theme = LogTheme(colorScheme: LogColorScheme.defaultScheme);
      final style = theme.getStyle(LogLevel.info, LogTag.message);
      expect(style.color, LogColor.blue); // Default scheme info is blue
    });

    test('LogColorScheme equality includes tag-specific overrides', () {
      const scheme1 = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        timestampColor: LogColor.brightBlack,
      );

      const scheme3 = LogColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        // No timestampColor override
      );

      expect(scheme1, isNot(equals(scheme3)));
    });
  });
}

class NoMessageTheme extends LogTheme {
  const NoMessageTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if ((tags & LogTag.message) != 0) {
      return const LogStyle(); // No style, no color
    }

    // For others, behave "normally" but let's just minimal implementation for
    // test
    var style = LogStyle(color: colorScheme.colorForLevel(level));

    if ((tags & LogTag.header) != 0) {
      style = LogStyle(
        color: style.color,
        bold: true,
        inverse: true, // Test expects inverse
      );
    }

    return style;
  }
}
