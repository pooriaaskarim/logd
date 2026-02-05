import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('BoxDecorator', () {
    const lines = LogDocument(
      nodes: [
        MessageNode(segments: [StyledText('line 1')]),
        MessageNode(segments: [StyledText('line 2')]),
      ],
    );
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
        lines,
        entry,
        const LogContext(availableWidth: 20),
      );

      expect(boxed.nodes.first, isA<BoxNode>());
      final container = boxed.nodes.first as BoxNode;
      expect(container.border, equals(BoxBorderStyle.rounded));

      // Visual parity check
      const encoder = AnsiEncoder();
      final rendered = encoder.encode(boxed, LogLevel.info).split('\n');
      expect(rendered.first, contains('─'));
      expect(rendered.first, contains('╭'));
    });

    test('respects sharp border style', () {
      const decorator = BoxDecorator(
        border: BoxBorderStyle.sharp,
      );
      final boxed = decorator.decorate(
        lines,
        entry,
        const LogContext(availableWidth: 20),
      );
      final container = boxed.nodes.first as BoxNode;
      expect(container.border, equals(BoxBorderStyle.sharp));

      const encoder = AnsiEncoder();
      final rendered = encoder.encode(boxed, LogLevel.info).split('\n');
      expect(rendered.first, contains('┌'));
    });

    test('respects double border style', () {
      const decorator = BoxDecorator(
        border: BoxBorderStyle.double,
      );
      final boxed = decorator.decorate(
        lines,
        entry,
        const LogContext(availableWidth: 20),
      );
      final container = boxed.nodes.first as BoxNode;
      expect(container.border, equals(BoxBorderStyle.double));

      const encoder = AnsiEncoder();
      final rendered = encoder.encode(boxed, LogLevel.info).split('\n');
      expect(rendered.first, contains('╔'));
    });
  });
}
