import 'dart:async';
import 'dart:isolate';

import 'package:logd/logd.dart';
import 'package:test/test.dart';

base class IsolateTestSink extends LogSink<LogDocument> {
  const IsolateTestSink(this.port);
  final SendPort port;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    port.send(entry.message);
  }
}

void main() {
  group('AsyncHandler Tests', () {
    setUp(() {
      Logger.reset();
    });

    test('should process and format logs on background isolate', () async {
      final receivePort = ReceivePort();
      final sink = IsolateTestSink(receivePort.sendPort);

      final asyncHandler = AsyncHandler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      final logger = Logger.get('async_logger');
      Logger.configure('async_logger', handlers: [asyncHandler]);

      logger.info('Hello from Async!');

      final completer = Completer<String>();
      receivePort.listen((final msg) {
        completer.complete(msg as String);
        receivePort.close();
      });

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result, equals('Hello from Async!'));

      await asyncHandler.dispose();
    });

    test('should respect handler level filters', () async {
      final receivePort = ReceivePort();
      final sink = IsolateTestSink(receivePort.sendPort);

      final asyncHandler = AsyncHandler(
        formatter: const PlainFormatter(),
        sink: sink,
        filters: const [
          ContextFilter('important', value: true),
        ],
      );

      final logger = Logger.get('filtered_async');
      Logger.configure('filtered_async', handlers: [asyncHandler]);

      // Should be filtered out
      logger
        ..info('Skip this')
        // Should log
        ..info('Log this', context: const {'important': true});

      final completer = Completer<String>();
      receivePort.listen((final msg) {
        completer.complete(msg as String);
        receivePort.close();
      });

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result, equals('Log this'));

      await asyncHandler.dispose();
    });
  });
}
