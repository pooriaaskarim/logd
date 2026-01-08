import 'package:logd/logd.dart';
import 'package:test/test.dart';
import 'mock_context.dart';

void main() {
  group('ColorScheme Tag-Specific Overrides', () {
    const infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
      hierarchyDepth: 0,
    );

    test('colorFor respects tag-specific overrides', () {
      const scheme = ColorScheme(
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
        scheme.colorFor(LogLevel.info, {}),
        equals(LogColor.blue),
      );

      // Tag-specific overrides
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.timestamp}),
        equals(LogColor.brightBlack),
      );
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.level}),
        equals(LogColor.brightBlue),
      );
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.loggerName}),
        equals(LogColor.cyan),
      );
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.border}),
        equals(LogColor.brightBlack),
      );

      // No override: falls back to base color
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.message}),
        equals(LogColor.blue),
      );
    });

    test('colorFor falls back to base level color when no override', () {
      const scheme = ColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
      );

      // All tags should get base level color
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.timestamp}),
        equals(LogColor.blue),
      );
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.level}),
        equals(LogColor.blue),
      );
      expect(
        scheme.colorFor(LogLevel.info, {LogTag.message}),
        equals(LogColor.blue),
      );
    });

    test('ColorDecorator applies tag-specific colors', () {
      const customScheme = ColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        timestampColor: LogColor.brightBlack,
        levelColor: LogColor.brightCyan, // Different from base
      );

      const decorator = ColorDecorator(colorScheme: customScheme);

      final lines = [
        const LogLine([
          LogSegment('2024-01-01', tags: {LogTag.header, LogTag.timestamp}),
          LogSegment(' [INFO] ', tags: {LogTag.header, LogTag.level}),
          LogSegment('Message', tags: {LogTag.message}),
        ]),
      ];

      final decorated =
          decorator.decorate(lines, infoEntry, mockContext).toList();
      final rendered = renderLines(decorated);

      // Timestamp should be dimmed (2) + brightBlack (90)
      expect(rendered[0], contains('\x1B[2m\x1B[90m'));
      // Level should be bold (1) + brightCyan (96)
      expect(rendered[0], contains('\x1B[1m\x1B[96m'));
      // Message should be blue (34)
      expect(rendered[0], contains('\x1B[34m'));
    });

    test('ColorConfig.shouldColor filters correctly', () {
      const config = ColorConfig(
        colorTimestamp: false,
        colorLevel: true,
        colorMessage: true,
      );

      expect(config.shouldColor({LogTag.timestamp}), isFalse);
      expect(config.shouldColor({LogTag.level}), isTrue);
      expect(config.shouldColor({LogTag.message}), isTrue);
      expect(config.shouldColor({LogTag.loggerName}), isTrue); // Default true
    });

    test('ColorDecorator respects ColorConfig.shouldColor', () {
      const decorator = ColorDecorator(
        config: ColorConfig(
          colorTimestamp: false,
          colorLevel: true,
          colorMessage: false,
        ),
      );

      final lines = [
        const LogLine([
          LogSegment('2024-01-01', tags: {LogTag.header, LogTag.timestamp}),
          LogSegment(' [INFO] ', tags: {LogTag.header, LogTag.level}),
          LogSegment('Message', tags: {LogTag.message}),
        ]),
      ];

      final decorated =
          decorator.decorate(lines, infoEntry, mockContext).toList();
      final rendered = renderLines(decorated);

      final output = rendered[0];

      // Should NOT color timestamp (plain text)
      expect(output, startsWith('2024-01-01'));
      // Should color level with bold
      expect(output, contains('\x1B[1m\x1B[34m [INFO] \x1B[0m'));
      // Should NOT color message
      expect(output, endsWith('Message'));
    });

    test('ColorScheme equality includes tag-specific overrides', () {
      const scheme1 = ColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        timestampColor: LogColor.brightBlack,
      );

      const scheme2 = ColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        timestampColor: LogColor.brightBlack,
      );

      const scheme3 = ColorScheme(
        info: LogColor.blue,
        error: LogColor.red,
        warning: LogColor.yellow,
        debug: LogColor.white,
        trace: LogColor.green,
        // No timestampColor override
      );

      expect(scheme1, equals(scheme2));
      expect(scheme1, isNot(equals(scheme3)));
    });
  });
}
