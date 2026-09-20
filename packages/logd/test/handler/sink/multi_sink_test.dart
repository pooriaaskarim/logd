import 'package:logd/logd.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

final class _SpySink extends LogSink<LogDocument> {
  _SpySink({super.enabled});

  final List<LogEntry> receivedEntries = [];
  bool disposed = false;
  bool shouldThrow = false;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    if (shouldThrow) {
      throw StateError('Simulated child sink failure');
    }
    receivedEntries.add(entry);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

void main() {
  group('MultiSink', () {
    late LogEntry testEntry;
    late LogDocument testDocument;
    const factory = StandardPipelineFactory();

    setUp(() {
      testEntry = LogEntry(
        loggerName: 'test',
        origin: 'multi_sink_test.dart',
        level: LogLevel.info,
        message: 'hello multi-sink',
        timestamp: '2026-09-20T12:00:00.000Z',
      );
      testDocument = createTestDocument(['hello multi-sink']);
    });

    tearDown(() {
      testDocument.releaseRecursive(Arena.instance);
    });

    group('Constructor constraints', () {
      test('throws ArgumentError if sinks list is empty', () {
        expect(
          () => MultiSink(const []),
          throwsA(
            isA<ArgumentError>().having(
              (final e) => e.message,
              'message',
              contains('MultiSink must have at least one sink'),
            ),
          ),
        );
      });

      test('throws ArgumentError if sinks contains another MultiSink', () {
        final innerSink = MultiSink([_SpySink()]);
        expect(
          () => MultiSink([innerSink]),
          throwsA(
            isA<ArgumentError>().having(
              (final e) => e.message,
              'message',
              contains('Recursive MultiSink is not allowed'),
            ),
          ),
        );
      });
    });

    group('Broadcasting behavior', () {
      test('broadcasts document to all child sinks', () async {
        final sink1 = _SpySink();
        final sink2 = _SpySink();
        final multiSink = MultiSink([sink1, sink2]);

        await multiSink.output(
          testDocument,
          testEntry,
          LogLevel.info,
          factory,
        );

        expect(sink1.receivedEntries, hasLength(1));
        expect(sink1.receivedEntries.first.message, equals('hello multi-sink'));
        expect(sink2.receivedEntries, hasLength(1));
        expect(sink2.receivedEntries.first.message, equals('hello multi-sink'));
      });

      test('skips child sinks that have enabled: false', () async {
        final activeSink = _SpySink();
        final disabledSink = _SpySink(enabled: false);
        final multiSink = MultiSink([activeSink, disabledSink]);

        await multiSink.output(
          testDocument,
          testEntry,
          LogLevel.info,
          factory,
        );

        expect(activeSink.receivedEntries, hasLength(1));
        expect(disabledSink.receivedEntries, isEmpty);
      });

      test('does nothing when MultiSink itself has enabled: false', () async {
        final sink1 = _SpySink();
        final sink2 = _SpySink();
        final multiSink = MultiSink([sink1, sink2], enabled: false);

        await multiSink.output(
          testDocument,
          testEntry,
          LogLevel.info,
          factory,
        );

        expect(sink1.receivedEntries, isEmpty);
        expect(sink2.receivedEntries, isEmpty);
      });

      test('does nothing when document has no nodes', () async {
        final sink = _SpySink();
        final multiSink = MultiSink([sink]);
        final emptyDoc = StandardDocument();

        await multiSink.output(
          emptyDoc,
          testEntry,
          LogLevel.info,
          factory,
        );

        expect(sink.receivedEntries, isEmpty);
      });
    });

    group('Error isolation', () {
      test(
          'child failure does not prevent other children from receiving output',
          () async {
        final failingSink = _SpySink()..shouldThrow = true;
        final healthySink = _SpySink();
        final multiSink = MultiSink([failingSink, healthySink]);

        // Must not rethrow unhandled
        await expectLater(
          multiSink.output(
            testDocument,
            testEntry,
            LogLevel.info,
            factory,
          ),
          completes,
        );

        expect(failingSink.receivedEntries, isEmpty);
        expect(healthySink.receivedEntries, hasLength(1));
        expect(
          healthySink.receivedEntries.first.message,
          equals('hello multi-sink'),
        );
      });
    });

    group('Lifecycle & disposal', () {
      test('dispose cascades to all child sinks', () async {
        final sink1 = _SpySink();
        final sink2 = _SpySink();
        final multiSink = MultiSink([sink1, sink2]);

        expect(sink1.disposed, isFalse);
        expect(sink2.disposed, isFalse);

        await multiSink.dispose();

        expect(sink1.disposed, isTrue);
        expect(sink2.disposed, isTrue);
      });
    });

    group('Equality and HashCode', () {
      test('matches instances with identical children and enabled flag', () {
        const console1 = ConsoleSink();
        const console2 = ConsoleSink();
        final multi1 = MultiSink(const [console1]);
        final multi2 = MultiSink(const [console2]);
        final multiDifferent = MultiSink(const [console1], enabled: false);

        expect(multi1, equals(multi2));
        expect(multi1.hashCode, equals(multi2.hashCode));
        expect(multi1, isNot(equals(multiDifferent)));
      });
    });

    group('Serialization registry roundtrip', () {
      test('serializes and deserializes MultiSink with nested sinks', () {
        LoggerSerializationRegistry.ensureInitialized();

        final multiSink = MultiSink(const [
          ConsoleSink(lineLength: 100),
          ConsoleSink(lineLength: 80),
        ]);

        final serialized = LoggerSerializationRegistry.serializeSink(multiSink);
        expect(serialized['type'], equals('MultiSink'));
        final config = serialized['config'] as Map<String, dynamic>;
        expect(config['sinks'], isA<List>());
        expect(config['sinks'] as List, hasLength(2));

        final deserialized =
            LoggerSerializationRegistry.deserializeSink(serialized);
        expect(deserialized, isA<MultiSink>());
        final deserializedMulti = deserialized as MultiSink;
        expect(deserializedMulti.sinks, hasLength(2));
        expect(deserializedMulti.sinks[0], isA<ConsoleSink>());
        expect(deserializedMulti.sinks[1], isA<ConsoleSink>());
      });
    });
  });
}
