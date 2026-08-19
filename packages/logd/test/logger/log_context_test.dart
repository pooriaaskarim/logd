// ignore_for_file: cascade_invocations
import 'dart:async';
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';
import 'package:test/test.dart';

void main() {
  group('LogContext (Ambient Structured MDC)', () {
    setUp(() {
      Logger.reset();
    });

    test('LogContext.current is null outside any scope', () {
      expect(LogContext.current, isNull);
    });

    test('LogContext.run sets ambient context for synchronous execution', () {
      final sink = CaptureSink();
      Logger.configure(
        'sync.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      LogContext.run({'requestId': 'req-101', 'env': 'prod'}, () {
        expect(
          LogContext.current,
          equals({'requestId': 'req-101', 'env': 'prod'}),
        );
        Logger.get('sync.test').info('Synchronous step');
      });

      expect(LogContext.current, isNull);
      expect(sink.logs, hasLength(1));
      expect(
        sink.logs.first.context,
        equals({'requestId': 'req-101', 'env': 'prod'}),
      );
    });

    test('LogContext.run propagates across asynchronous awaits and microtasks',
        () async {
      final sink = CaptureSink();
      Logger.configure(
        'async.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      await LogContext.run({'traceId': 'trace-999'}, () async {
        Logger.get('async.test').info('Before await');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        Logger.get('async.test').info('After delay');
        await Future<void>.microtask(() {});
        Logger.get('async.test').info('After microtask');
      });

      expect(sink.logs, hasLength(3));
      for (final log in sink.logs) {
        expect(log.context, equals({'traceId': 'trace-999'}));
      }
    });

    test('Nested LogContext scopes merge and shadow outer keys correctly', () {
      final sink = CaptureSink();
      Logger.configure(
        'nested.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      LogContext.run({'tenant': 'acme', 'version': 1}, () {
        Logger.get('nested.test').info('Outer level');

        LogContext.run({'version': 2, 'user': 'alice'}, () {
          Logger.get('nested.test').info('Inner level');
        });

        Logger.get('nested.test').info('Back to outer level');
      });

      expect(sink.logs, hasLength(3));
      expect(
        sink.logs[0].context,
        equals({'tenant': 'acme', 'version': 1}),
      );
      expect(
        sink.logs[1].context,
        equals({'tenant': 'acme', 'version': 2, 'user': 'alice'}),
      );
      expect(
        sink.logs[2].context,
        equals({'tenant': 'acme', 'version': 1}),
      );
    });

    test('Concurrent async branches maintain strict Zone isolation', () async {
      final sink = CaptureSink();
      Logger.configure(
        'concurrent.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final taskA = LogContext.run({'worker': 'A', 'step': 0}, () async {
        for (var i = 1; i <= 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          Logger.get('concurrent.test').info('Task A iteration $i');
        }
      });

      final taskB = LogContext.run({'worker': 'B', 'step': 0}, () async {
        for (var i = 1; i <= 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          Logger.get('concurrent.test').info('Task B iteration $i');
        }
      });

      await Future.wait([taskA, taskB]);

      expect(sink.logs, hasLength(6));
      final logsA =
          sink.logs.where((final l) => l.message.contains('Task A')).toList();
      final logsB =
          sink.logs.where((final l) => l.message.contains('Task B')).toList();

      expect(logsA, hasLength(3));
      for (final log in logsA) {
        expect(log.context, equals({'worker': 'A', 'step': 0}));
      }

      expect(logsB, hasLength(3));
      for (final log in logsB) {
        expect(log.context, equals({'worker': 'B', 'step': 0}));
      }
    });

    test('Call-site explicit context merges and overrides ambient context', () {
      final sink = CaptureSink();
      Logger.configure(
        'override.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      LogContext.run({'requestId': 'req-1', 'status': 'pending'}, () {
        Logger.get('override.test').info(
          'Updated',
          context: {'status': 'completed', 'durationMs': 120},
        );
      });

      expect(sink.logs, hasLength(1));
      expect(
        sink.logs.first.context,
        equals({
          'requestId': 'req-1',
          'status': 'completed',
          'durationMs': 120,
        }),
      );
    });

    test('ContextFilter correctly evaluates ambient context', () {
      final sink = CaptureSink();
      Logger.configure(
        'filter.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            filters: const [
              ContextFilter('env', value: 'prod'),
            ],
            sink: sink,
          ),
        ],
      );

      final logger = Logger.get('filter.test');

      LogContext.run({'env': 'dev'}, () {
        logger.info('Dev log');
      });

      LogContext.run({'env': 'prod'}, () {
        logger.info('Prod log');
      });

      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.message, equals('Prod log'));
    });

    test('JsonFormatter serializes ambient context seamlessly', () {
      final sink = CaptureSink();
      Logger.configure(
        'json.context',
        handlers: [
          Handler(
            formatter: const JsonFormatter(),
            sink: sink,
          ),
        ],
      );

      LogContext.run({'service': 'auth', 'ip': '192.168.1.1'}, () {
        Logger.get('json.context').info('Login attempt');
      });

      expect(sink.logs, hasLength(1));
      expect(
        sink.logs.first.context,
        equals({'service': 'auth', 'ip': '192.168.1.1'}),
      );
    });

    test('Empty LogContext.run is a transparent no-op', () {
      final sink = CaptureSink();
      Logger.configure(
        'empty.test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final result = LogContext.run({}, () {
        Logger.get('empty.test').info('No context');
        return 42;
      });

      expect(result, equals(42));
      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.context, isNull);
    });
  });
}
