import 'dart:async';
import 'dart:isolate';
import 'package:logd/logd.dart';
import 'package:test/test.dart';

base class ConcurrencyStressSink extends LogSink<LogDocument> {
  ConcurrencyStressSink(this.sendPort);
  final SendPort sendPort;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    sendPort.send(entry.message);
  }
}

class TestWorkerPayload {
  TestWorkerPayload({
    required this.sendPort,
    required this.exportedConfig,
    required this.iterations,
  });
  final SendPort sendPort;
  final Map<String, dynamic> exportedConfig;
  final int iterations;
}

void _configImporterWorker(final TestWorkerPayload payload) {
  LoggerSerializationRegistry.registerSink<ConcurrencyStressSink>(
    type: 'ConcurrencyStressSink',
    fromJson: (final json) => ConcurrencyStressSink(ReceivePort().sendPort),
    toJson: (final val) => <String, dynamic>{},
  );

  final sink = ConcurrencyStressSink(payload.sendPort);
  // Initial configuration import
  Logger.importConfig(payload.exportedConfig);

  // Rapidly configure, log, and export/import configs
  for (var i = 0; i < payload.iterations; i++) {
    Logger.configure(
      'worker_$i',
      logLevel: LogLevel.debug,
      handlers: [
        Handler(formatter: const PlainFormatter(), sink: sink),
      ],
    );

    Logger.configurePattern(
      'worker_*',
      logLevel: LogLevel.warning,
    );

    Logger.get('worker_$i').warning('msg_$i');

    final exported = Logger.exportConfig();
    Logger.importConfig(exported);
  }
}

void main() {
  LoggerSerializationRegistry.registerSink<ConcurrencyStressSink>(
    type: 'ConcurrencyStressSink',
    fromJson: (final json) => ConcurrencyStressSink(ReceivePort().sendPort),
    toJson: (final val) => <String, dynamic>{},
  );

  group('Logger Concurrency & Invalidation Stress Tests', () {
    tearDown(() {
      Logger.reset();
    });

    test('Concurrent async configurations in single isolate', () async {
      // Create concurrent Futures that mutate the registry and
      // resolve logs at the same time.
      final futures = <Future<void>>[];

      // Configure base
      Logger.configure('global', logLevel: LogLevel.info);

      for (var i = 0; i < 50; i++) {
        final id = i;
        futures.add(
          Future(() async {
            // Perform configure pattern
            Logger.configurePattern(
              'services.db.$id.*',
              logLevel: LogLevel.warning,
            );

            // Get logger and log
            Logger.get('services.db.$id.postgres')
                .warning('warning from db $id');

            // Configure individual
            Logger.configure(
              'services.db.$id.postgres',
              logLevel: LogLevel.error,
            );

            // Get again
            final updatedLogger = Logger.get('services.db.$id.postgres');
            expect(updatedLogger.logLevel, equals(LogLevel.error));

            // Configure multiple
            Logger.configureMultiple({
              'services.auth.$id': const LoggerConfig(logLevel: LogLevel.info),
              'services.cache.$id':
                  const LoggerConfig(logLevel: LogLevel.debug),
            });

            // Invalidation verification
            final authLogger = Logger.get('services.auth.$id');
            expect(authLogger.logLevel, equals(LogLevel.info));
          }),
        );
      }

      await Future.wait(futures);
    });

    test('Multi-isolate concurrent configuration export/import', () async {
      final receivePort = ReceivePort();
      final receivedMsgs = <String>[];
      final completer = Completer<void>();

      const iterations = 100;
      const workerCount = 5;
      const expectedMsgCount = workerCount * iterations;

      receivePort.listen((final msg) {
        if (msg is String) {
          receivedMsgs.add(msg);
          if (receivedMsgs.length == expectedMsgCount) {
            completer.complete();
          }
        }
      });

      // Prepare initial config
      Logger.configure('global', logLevel: LogLevel.info);
      final initialConfig = Logger.exportConfig();

      final workers = <Isolate>[];
      for (var i = 0; i < workerCount; i++) {
        final payload = TestWorkerPayload(
          sendPort: receivePort.sendPort,
          exportedConfig: initialConfig,
          iterations: iterations,
        );
        final isolate = await Isolate.spawn(_configImporterWorker, payload);
        workers.add(isolate);
      }

      // Wait for all messages or timeout
      await completer.future.timeout(const Duration(seconds: 15));

      expect(receivedMsgs.length, equals(expectedMsgCount));

      // Clean up isolates
      for (final worker in workers) {
        worker.kill();
      }
      receivePort.close();
    });
  });
}
