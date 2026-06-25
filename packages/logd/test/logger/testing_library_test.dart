import 'package:logd/logd.dart';
import 'package:logd/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Testing Utilities Tests', () {
    setUp(() {
      Logger.reset();
    });

    test('TestLogger and CaptureSink should capture logs correctly', () async {
      final testLogger = TestLogger('test_utils');
      addTearDown(testLogger.dispose);
      expect(testLogger.logs, isEmpty);

      testLogger.logger.info('Hello world', context: {'key': 'value'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(testLogger.logs, hasLength(1));

      final log = testLogger.logs.first;
      expect(log.level, equals(LogLevel.info));
      expect(log.message, equals('Hello world'));
      expect(log.loggerName, equals('test_utils'));
      expect(log.context, equals({'key': 'value'}));

      testLogger.clear();
      expect(testLogger.logs, isEmpty);
    });

    test('CaptureSink.clear() removes all logs and new logs are captured',
        () async {
      final testLogger = TestLogger('test_clear');
      addTearDown(testLogger.dispose);

      testLogger.logger.info('First message');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(testLogger.logs, hasLength(1));

      testLogger.clear();
      expect(testLogger.logs, isEmpty);

      testLogger.logger.warning('After clear');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(testLogger.logs, hasLength(1));
      expect(testLogger.logs.first.message, equals('After clear'));
      expect(testLogger.logs.first.level, equals(LogLevel.warning));
    });

    test(
        'hasLog matcher should match level, message (String, RegExp, Matcher)'
        ' and context', () async {
      final testLogger = TestLogger('test_matcher');
      addTearDown(testLogger.dispose);

      testLogger.logger
          .info('Click event fired', context: {'action': 'click', 'id': 42});
      testLogger.logger.warning('Deprecated API usage');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Match by level only
      expect(testLogger, hasLog(level: LogLevel.info));
      expect(testLogger, hasLog(level: LogLevel.warning));

      // Match by exact message
      expect(testLogger, hasLog(message: 'Click event fired'));

      // Match by RegExp
      expect(testLogger, hasLog(message: RegExp(r'event \w+')));

      // Match by Matcher
      expect(testLogger, hasLog(message: contains('Deprecated')));

      // Match by logger name
      expect(testLogger, hasLog(loggerName: 'test_matcher'));

      // Match by partial context
      expect(testLogger, hasLog(context: {'action': 'click'}));
      expect(testLogger, hasLog(context: {'id': 42}));
      expect(testLogger, hasLog(context: {'action': 'click', 'id': 42}));

      // Compound matching
      expect(
        testLogger,
        hasLog(
          level: LogLevel.info,
          message: 'Click event fired',
          context: {'action': 'click'},
        ),
      );

      // Non-matches
      expect(testLogger, isNot(hasLog(level: LogLevel.error)));
      expect(testLogger, isNot(hasLog(message: 'Not present')));
      expect(testLogger, isNot(hasLog(loggerName: 'other')));
      expect(testLogger, isNot(hasLog(context: {'other': 'value'})));
    });

    test('hasLog mismatch description matches expected format', () async {
      final testLogger = TestLogger('mismatch_logger');
      addTearDown(testLogger.dispose);

      testLogger.logger.info('Some message');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final matcher = hasLog(level: LogLevel.error);
      final description = StringDescription();
      matcher.describeMismatch(testLogger, description, {}, false);

      expect(description.toString(), contains('has logs:'));
      expect(
        description.toString(),
        contains('[INFO] [mismatch_logger]: "Some message"'),
      );
    });

    test('TestLogger.dispose() removes logger from global registry', () {
      final testLogger = TestLogger('dispose_test_logger');
      expect(
        Logger.get('dispose_test_logger').name,
        equals('dispose_test_logger'),
      );

      testLogger.dispose();

      // After dispose, configuring the same name should work cleanly
      // (no leftover state - configure succeeds without error)
      expect(
        () => Logger.configure('dispose_test_logger', logLevel: LogLevel.info),
        returnsNormally,
      );
    });
  });
}
