import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlEncoder Enhanced', () {
    late LogPipelineFactory factory;
    late HandlerContext context;

    setUp(() {
      factory = const StandardEngine().factory;
      context = factory.checkoutContext();
    });

    test('preamble contains LOGD header and theme variables', () {
      const theme = LogTheme(
        colorScheme: LogColorScheme(
          trace: LogColor.green,
          debug: LogColor.white,
          info: LogColor.blue,
          warning: LogColor.yellow,
          error: LogColor.red,
        ),
      );
      const HtmlEncoder(theme: theme, title: 'Test Log')
          .preamble(context, LogLevel.info, factory);
      final output = String.fromCharCodes(context.takeBytes());

      expect(output, contains('<title>Test Log</title>'));
      expect(output, contains('LOGD'));
      expect(output, contains('log-session-header'));
      expect(output, contains('--info: #3b82f6')); // Blue in _colorMap
    });

    test('renders Structured-like header with details/summary', () {
      final document = factory.checkoutDocument();
      final header = factory.checkoutHeader()
        ..segments.add(const StyledText('Header Content', tags: LogTag.header));
      document.nodes
        ..add(header)
        ..add(
          factory.checkoutMessage()
            ..segments.add(const StyledText('Message Content')),
        );

      const HtmlEncoder().encode(
        const LogEntry(
          level: LogLevel.info,
          message: 'Message Content',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:42',
        ),
        document,
        LogLevel.info,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());

      expect(output, contains('<details open>'));
      expect(output, contains('<summary class="log-entry-summary">'));
      expect(output, contains('<div class="log-entry-body">'));
      expect(output, contains('Message Content'));
    });

    test('renders multi-line Structured headers in summary', () {
      final document = factory.checkoutDocument();
      document.nodes
        ..add(
          factory.checkoutHeader()
            ..segments.add(const StyledText('Header 1', tags: LogTag.header)),
        )
        ..add(
          factory.checkoutHeader()
            ..segments.add(const StyledText('Header 2', tags: LogTag.header)),
        )
        ..add(
          factory.checkoutMessage()..segments.add(const StyledText('Body')),
        );

      const HtmlEncoder().encode(
        const LogEntry(
          level: LogLevel.info,
          message: 'Body',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:42',
        ),
        document,
        LogLevel.info,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());
      expect(output, contains('Header 1'));
      expect(output, contains('Header 2'));
      expect(output, contains('<div class="log-entry-body">'));
      expect(output, contains('Body'));
    });

    test('renders SectionNode with Kinetic Indigo classes', () {
      final document = factory.checkoutDocument();
      final summary = factory.checkoutHeader()
        ..segments.add(const StyledText('Summary', tags: LogTag.header));
      final section = factory.checkoutSection()
        ..summary = summary
        ..children.add(
          factory.checkoutMessage()..segments.add(const StyledText('Child')),
        );
      document.nodes.add(section);

      const HtmlEncoder().encode(
        const LogEntry(
          level: LogLevel.info,
          message: 'msg',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:1',
        ),
        document,
        LogLevel.info,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());

      expect(output, contains('<details class="log-section" open>'));
      expect(output, contains('<summary class="log-section-summary">'));
      expect(output, contains('<div class="log-section-body">'));
      expect(output, contains('Summary'));
      expect(output, contains('Child'));
    });

    test('zero-shift indicators use negative absolute positioning', () {
      const HtmlEncoder().preamble(context, LogLevel.info, factory);
      final output = String.fromCharCodes(context.takeBytes());

      expect(output, contains('.log-entry-summary::before'));
      expect(output, contains('position: absolute'));
      expect(output, contains('left: -1.25rem'));
    });

    test('Boxed structured logs use box-aware internal collapsing', () {
      final document = factory.checkoutDocument();
      final box = factory.checkoutBox();

      // Headers inside the box
      box.children
        ..add(
          factory.checkoutHeader()
            ..segments.add(const StyledText('Box Header', tags: LogTag.header)),
        )
        ..add(
          factory.checkoutMessage()
            ..segments.add(const StyledText('Box Content')),
        );

      document.nodes.add(box);

      const HtmlEncoder().encode(
        const LogEntry(
          level: LogLevel.warning,
          message: 'Box Content',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:42',
        ),
        document,
        LogLevel.warning,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());
      expect(output, contains('<fieldset class="log-box'));
      expect(output, contains('<summary class="log-entry-summary">'));
      expect(output, contains('Box Header'));
      expect(output, contains('<div class="log-entry-body">'));
      expect(output, contains('Box Content'));
    });

    test('filler lines inherit level-aware colors', () {
      const theme = LogTheme(
        colorScheme: LogColorScheme(
          trace: LogColor.green,
          debug: LogColor.white,
          info: LogColor.blue,
          warning: LogColor.yellow,
          error: LogColor.red,
        ),
      );
      final document = factory.checkoutDocument();
      final row = factory.checkoutRow();
      row.children
        ..add(
          factory.checkoutHeader()
            ..segments.add(const StyledText('H', tags: LogTag.header)),
        )
        ..add(FillerNode('_', tags: LogTag.header));
      document.nodes.add(row);

      const HtmlEncoder(theme: theme).encode(
        const LogEntry(
          level: LogLevel.info,
          message: '',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:42',
        ),
        document,
        LogLevel.info,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());
      expect(output, contains('log-header-filler'));
      expect(output, contains('border-bottom-color: #3b82f6'));
    });
    test('renders MapNode with responsive wrapping and magic highlighting', () {
      final document = factory.checkoutDocument();
      document.nodes.add(
        factory.checkoutMap()
          ..map = {
            'level': 'info',
            'message': 'test message',
            'custom': 123,
            'nested': {'a': true},
          },
      );

      const HtmlEncoder().encode(
        const LogEntry(
          level: LogLevel.info,
          message: 'msg',
          loggerName: 'test',
          timestamp: '2026-03-22',
          origin: 'test.dart:1',
        ),
        document,
        LogLevel.info,
        context,
        factory,
      );

      final output = String.fromCharCodes(context.takeBytes());

      // Check structure
      expect(output, contains('<div class="log-line log-map">'));
      expect(output, contains('<span class="log-punct"'));
      expect(output, contains('{</span>'));

      // Check semantic highlighting for common keys
      expect(output, contains('class="log-level log-key log-punct"'));
      expect(output, contains('class="log-message log-key log-punct"'));

      // Check normal keys
      expect(output, contains('class="log-key log-punct"'));
      // for 'custom' and 'nested'

      // Check responsive wrapping class
      expect(output, contains('class="log-line log-map"'));
    });
  });
}
