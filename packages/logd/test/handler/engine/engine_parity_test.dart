import 'package:logd/logd.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

base class RecordingSink extends LogSink<LogDocument> {
  final List<List<String>> outputs = [];

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    // We capture the rendered output because the semantic nodes
    // will be reset if we are using the ArenaEngine.
    outputs.add(renderLines(document));
  }
}

void main() {
  group('Engine Parity Verification', () {
    const formatter = StructuredFormatter();
    final entry = LogEntry(
      loggerName: 'ParityTest',
      origin: 'parity.dart:1:1',
      level: LogLevel.info,
      message: 'Verifying that StandardEngine and ArenaEngine produce '
          'identical output.',
      timestamp: '2025-01-01 12:00:00',
    );

    test('StandardEngine vs ArenaEngine (Structured)', () async {
      final standardSink = RecordingSink();
      final arenaSink = RecordingSink();

      final standardHandler = Handler(
        formatter: formatter,
        sink: standardSink,
        engine: const StandardEngine(),
      );

      final arenaHandler = Handler(
        formatter: formatter,
        sink: arenaSink,
        engine: const ArenaEngine(),
      );

      await standardHandler.log(entry);
      await arenaHandler.log(entry);

      expect(arenaSink.outputs.length, 1);
      expect(standardSink.outputs.length, 1);

      // Compare the rendered lines (Physical Parity)
      expect(arenaSink.outputs.first, standardSink.outputs.first);
    });

    test('StandardEngine vs ArenaEngine (Plain)', () async {
      const plainFormatter = PlainFormatter();
      final standardSink = RecordingSink();
      final arenaSink = RecordingSink();

      final standardHandler = Handler(
        formatter: plainFormatter,
        sink: standardSink,
        engine: const StandardEngine(),
      );

      final arenaHandler = Handler(
        formatter: plainFormatter,
        sink: arenaSink,
        engine: const ArenaEngine(),
      );

      await standardHandler.log(entry);
      await arenaHandler.log(entry);

      expect(arenaSink.outputs.first, standardSink.outputs.first);
    });

    group('Engine Stability', () {
      test('ArenaEngine deterministic release', () async {
        final sink = RecordingSink();
        final handler = Handler(
          formatter: const StructuredFormatter(),
          sink: sink,
          engine: const ArenaEngine(),
        );

        final arena = Arena.instance;
        final initialPoolSize = arena.poolSize;

        await handler.log(entry);

        // Verify that the document and nodes were released back to the pool
        expect(arena.poolSize, greaterThanOrEqualTo(initialPoolSize));
      });
    });
  });
}
