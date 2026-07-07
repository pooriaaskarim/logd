import 'dart:async';
import 'dart:isolate';
import 'package:logd/logd.dart';
import 'package:test/test.dart';

base class StressSink extends LogSink<LogDocument> {
  StressSink(this.sendPort);
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

class WorkerPayload {
  WorkerPayload({required this.sendPort, required this.logCount});
  final SendPort sendPort;
  final int logCount;
}

void _workerEntryPoint(final WorkerPayload payload) {
  final sink = StressSink(payload.sendPort);
  Logger.configure(
    'worker',
    handlers: [
      Handler(formatter: const PlainFormatter(), sink: sink),
    ],
  );

  final logger = Logger.get('worker');
  for (var i = 0; i < payload.logCount; i++) {
    logger.info('msg_$i');
  }
}

void main() {
  group('Logger Multi-Isolate Stress Test', () {
    test('5 isolates logging concurrently', () async {
      final receivePort = ReceivePort();
      final receivedMsgs = <String>[];

      final completer = Completer<void>();
      receivePort.listen((final msg) {
        if (msg is String) {
          receivedMsgs.add(msg);
          if (receivedMsgs.length == 10000) {
            completer.complete();
          }
        }
      });

      final workers = <Isolate>[];
      for (var i = 0; i < 5; i++) {
        final payload =
            WorkerPayload(sendPort: receivePort.sendPort, logCount: 2000);
        final isolate = await Isolate.spawn(_workerEntryPoint, payload);
        workers.add(isolate);
      }

      // Wait for all messages to be received or timeout
      await completer.future.timeout(const Duration(seconds: 10));

      expect(receivedMsgs.length, equals(10000));

      // Clean up
      for (final worker in workers) {
        worker.kill();
      }
      receivePort.close();
    });
  });
}
