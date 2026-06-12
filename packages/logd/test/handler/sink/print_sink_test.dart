import 'dart:async';
import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('PrintSink', () {
    test('outputs logs using print()', () async {
      final logs = <String>[];
      const sink = PrintSink();

      await runZoned(
        () async {
          await sink.output(
            StandardDocument()
              ..nodes.addAll([
                MessageNode(segments: [const StyledText('Hello World')]),
              ]),
            LogEntry(
              loggerName: 'test',
              origin: 'test',
              level: LogLevel.info,
              message: 'Hello World',
              timestamp: '2026-03-22',
            ),
            LogLevel.info,
            const StandardPipelineFactory(),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            logs.add(line);
          },
        ),
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Hello World'));
      expect(logs.first.endsWith('\n'), isFalse);
    });

    test('respects usePrint in ConsoleSink', () async {
      final logs = <String>[];
      // Explicitly for print
      const sink = ConsoleSink(usePrint: true);

      await runZoned(
        () async {
          await sink.output(
            StandardDocument()
              ..nodes.addAll([
                MessageNode(segments: [const StyledText('Console Hello')]),
              ]),
            LogEntry(
              loggerName: 'test',
              origin: 'test',
              level: LogLevel.info,
              message: 'Console Hello',
              timestamp: '2026-03-22',
            ),
            LogLevel.info,
            const StandardPipelineFactory(),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            logs.add(line);
          },
        ),
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('Console Hello'));
    });
  });
}
