import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('StyleDecorator', () {
    final lines = ['line 1', 'line 2'];
    const infoEntry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('adds colors when enabled', () {
      const decorator = StyleDecorator();
      final doc = createTestDocument(lines);
      try {
        decorator.decorate(
          doc,
          infoEntry,
          LogArena.instance,
        );
        final rendered = renderLines(doc);

        expect(rendered.length, equals(2));
        // Just check if it contains color code and text.
        // Info level now defaults to blue (was green)
        expect(rendered[0], contains('\x1B[34m')); // Blue
        expect(rendered[0], endsWith('\x1B[0m'));
        expect(rendered[0], contains('line'));
        expect(rendered[0], contains('1'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
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

      final infoDoc = createTestDocument(['msg']);
      try {
        decorator.decorate(infoDoc, infoEntry, LogArena.instance);
        final info = renderLines(infoDoc).first;
        expect(info, contains('\x1B[34m')); // Blue
      } finally {
        infoDoc.releaseRecursive(LogArena.instance);
      }

      final errorDoc = createTestDocument(['msg']);
      try {
        decorator.decorate(
          errorDoc,
          const LogEntry(
            loggerName: 'test',
            origin: 'test',
            level: LogLevel.error,
            message: 'msg',
            timestamp: 'now',
          ),
          LogArena.instance,
        );
        final error = renderLines(errorDoc).first;
        expect(error, contains('\x1B[31m')); // Red
      } finally {
        errorDoc.releaseRecursive(LogArena.instance);
      }

      final warningDoc = createTestDocument(['msg']);
      try {
        decorator.decorate(
          warningDoc,
          const LogEntry(
            loggerName: 'test',
            origin: 'test',
            level: LogLevel.warning,
            message: 'msg',
            timestamp: 'now',
          ),
          LogArena.instance,
        );
        final warning = renderLines(warningDoc).first;
        expect(warning, contains('\x1B[33m')); // Yellow
      } finally {
        warningDoc.releaseRecursive(LogArena.instance);
      }
    });

    test('respects custom theme (no message coloring)', () {
      const decorator = StyleDecorator(
        theme: NoMessageTheme(),
      );
      final arena = LogArena.instance;
      final headerDoc = arena.checkoutDocument();
      headerDoc.nodes.add(
        arena.checkoutMessage()
          ..segments.add(const StyledText('Header 1', tags: LogTag.header)),
      );
      headerDoc.nodes.add(
        arena.checkoutMessage()
          ..segments.add(const StyledText('Message 1', tags: LogTag.message)),
      );

      try {
        decorator.decorate(
          headerDoc,
          infoEntry,
          arena,
        );
        final rendered = renderLines(headerDoc);

        // Header line should have inverted color code (\x1B[7m) - defined in NoMessageTheme
        expect(rendered[0], contains('\x1B[7m'));
        expect(rendered[0], contains('Header'));
        expect(rendered[0], contains('1'));

        // Message line should NOT have inverted color code AND no color at all
        // (if theme says so)
        // NoMessageTheme doesn't apply base color to message.
        expect(rendered[1], isNot(contains('\x1B[7m')));
        expect(
          rendered[1],
          isNot(contains('\x1B[34m')),
        ); // Check no blue either
        expect(rendered[1], contains('Message'));
        expect(rendered[1], contains('1'));
      } finally {
        headerDoc.releaseRecursive(arena);
      }
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
