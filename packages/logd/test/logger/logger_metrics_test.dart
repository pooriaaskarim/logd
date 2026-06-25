import 'dart:async';
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerMetrics Tests', () {
    setUp(() {
      Logger.reset();
      LoggerMetrics.reset();
    });

    test('should track cache hits, misses, and invalidations', () {
      expect(LoggerMetrics.cacheHits, equals(0));
      expect(LoggerMetrics.cacheMisses, equals(0));
      expect(LoggerMetrics.cacheInvalidations, equals(0));

      // 1. Resolve first time -> cache miss
      final logger = Logger.get('app.ui.button');
      final _ = logger.logLevel;
      expect(LoggerMetrics.cacheMisses, equals(1));
      expect(LoggerMetrics.cacheHits, equals(0));

      // 2. Resolve second time -> cache hit
      final res2 = logger.logLevel;
      expect(res2, isNotNull);
      expect(LoggerMetrics.cacheMisses, equals(1));
      expect(LoggerMetrics.cacheHits, equals(1));

      // 3. Configure/Invalidate -> cache invalidation
      Logger.configure(
        'app.ui',
        logLevel: LogLevel.warning,
      );
      expect(
        LoggerMetrics.cacheInvalidations,
        equals(1),
      ); // app.ui.button was removed

      // 4. Resolve again -> cache miss
      final res3 = logger.logLevel;
      expect(res3, isNotNull);
      expect(LoggerMetrics.cacheMisses, equals(2));
      expect(LoggerMetrics.cacheHits, equals(1));
    });

    test('should track handler failures', () async {
      expect(LoggerMetrics.handlerFailures, equals(0));

      Logger.configure(
        'fail_logger',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: FailingSink(),
          ),
        ],
      );

      Logger.get('fail_logger').info('Should fail');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(LoggerMetrics.handlerFailures, equals(1));
    });

    test('should track buffer allocations and releases', () {
      expect(LoggerMetrics.bufferAllocations, equals(0));
      expect(LoggerMetrics.bufferReleases, equals(0));

      final logger = Logger.get('buf_logger');
      final buf = logger.infoBuffer;
      expect(buf, isNotNull);
      expect(LoggerMetrics.bufferAllocations, equals(1));
      expect(LoggerMetrics.bufferReleases, equals(0));

      buf!
        ..writeln('hello')
        ..sink(); // Sinking also recycles it back to the pool
      expect(LoggerMetrics.bufferAllocations, equals(1));
      expect(LoggerMetrics.bufferReleases, equals(1));
    });

    test('should track drops for below-level and disabled loggers', () async {
      expect(LoggerMetrics.drops, equals(0));

      Logger.configure(
        'drop_logger',
        logLevel: LogLevel.error,
        handlers: [
          const Handler(
            formatter: PlainFormatter(),
            sink: ConsoleSink(),
          ),
        ],
      );

      // trace and debug are below error level → should be dropped
      Logger.get('drop_logger').trace('below level');
      Logger.get('drop_logger').debug('also below level');
      Logger.get('drop_logger').info('still below level');

      expect(LoggerMetrics.drops, equals(3));

      // error should go through, not dropped
      Logger.get('drop_logger').error('this goes through');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(LoggerMetrics.drops, equals(3)); // unchanged
    });

    test('should track drops when logger is disabled', () {
      expect(LoggerMetrics.drops, equals(0));

      Logger.configure(
        'disabled_logger',
        enabled: false,
        handlers: [
          const Handler(
            formatter: PlainFormatter(),
            sink: ConsoleSink(),
          ),
        ],
      );

      Logger.get('disabled_logger').info('dropped due to disabled');
      Logger.get('disabled_logger').error('also dropped');
      expect(LoggerMetrics.drops, equals(2));
    });

    test('toJson() returns all counters with correct keys', () async {
      Logger.configure(
        'json_test_logger',
        logLevel: LogLevel.error,
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: FailingSink(),
          ),
        ],
      );

      // Trigger: 1 miss (first resolution), 1 hit (second access)
      final logger = Logger.get('json_test_logger');
      // ignore: unused_local_variable
      final level1 = logger.logLevel; // first access (cache miss)
      // ignore: unused_local_variable
      final level2 = logger.logLevel; // second access (cache hit)

      // Trigger: 1 drop (info below error level)
      logger.info('dropped');

      // Trigger: 1 handler failure + fallback
      final originalFallback = Logger.fallbackHandler;
      Logger.fallbackHandler = null; // silence stdout during test
      addTearDown(() => Logger.fallbackHandler = originalFallback);
      logger.error('triggers handler failure');
      await Future.delayed(const Duration(milliseconds: 100));

      final json = LoggerMetrics.toJson();

      expect(json, containsPair('cacheHits', greaterThan(0)));
      expect(json, containsPair('cacheMisses', greaterThan(0)));
      expect(json, containsPair('handlerFailures', equals(1)));
      expect(json, containsPair('drops', equals(1)));
      expect(
        json.keys,
        containsAll(<String>[
          'cacheHits',
          'cacheMisses',
          'cacheInvalidations',
          'handlerFailures',
          'bufferAllocations',
          'bufferReleases',
          'bufferLeaks',
          'drops',
        ]),
      );
    });
  });
}

base class FailingSink extends LogSink<LogDocument> {
  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    throw Exception('Simulated failure');
  }
}
