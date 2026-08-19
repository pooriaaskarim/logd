// ignore_for_file: cascade_invocations
import 'package:logd/logd.dart';
import 'package:logd/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Lazy Stack Trace & includeOrigin Bypass', () {
    setUp(() {
      Logger.reset();
    });

    test('default configuration has includeOrigin == true and extracts origin',
        () async {
      final sink = CaptureSink();
      Logger.configure(
        'test.default_origin',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final logger = Logger.get('test.default_origin');
      expect(logger.includeOrigin, isTrue);

      logger.info('Testing default origin');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.origin, isNotEmpty);
      expect(sink.logs.first.origin, contains('main'));
    });

    test('includeOrigin: false produces empty origin without dropping log',
        () async {
      final sink = CaptureSink();
      Logger.configure(
        'test.no_origin',
        includeOrigin: false,
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final logger = Logger.get('test.no_origin');
      expect(logger.includeOrigin, isFalse);

      logger.info('Testing without origin');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.origin, isEmpty);
      expect(sink.logs.first.message, equals('Testing without origin'));
    });

    test('includeOrigin: false with explicit stackTrace preserves stackTrace',
        () async {
      final sink = CaptureSink();
      Logger.configure(
        'test.explicit_stack',
        includeOrigin: false,
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final logger = Logger.get('test.explicit_stack');
      final stack = StackTrace.current;

      logger.error('Error with stack', stackTrace: stack);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.origin, isEmpty);
      expect(sink.logs.first.stackTrace, equals(stack));
    });

    test(
        'includeOrigin: false with stackMethodCount > 0 '
        'collects frames without origin', () async {
      final sink = CaptureSink();
      Logger.configure(
        'test.frames_only',
        includeOrigin: false,
        stackMethodCount: const {
          LogLevel.warning: 3,
        },
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: sink,
          ),
        ],
      );

      final logger = Logger.get('test.frames_only');
      logger.warning('Warning with frames');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sink.logs, hasLength(1));
      expect(sink.logs.first.origin, isEmpty);
    });

    test('hierarchical inheritance and override for includeOrigin', () {
      Logger.configure('app', includeOrigin: false);
      Logger.configure('app.network.http', includeOrigin: true);

      expect(Logger.get('app').includeOrigin, isFalse);
      expect(Logger.get('app.service').includeOrigin, isFalse);
      expect(Logger.get('app.network.http').includeOrigin, isTrue);
      expect(Logger.get('app.network.http.client').includeOrigin, isTrue);
    });

    test('freezeInheritance and unfreezeInheritance for includeOrigin', () {
      Logger.configure('parent', includeOrigin: false);
      Logger.get('parent.child'); // materialize child

      expect(Logger.get('parent.child').includeOrigin, isFalse);

      // Freeze on parent
      Logger.get('parent').freezeInheritance();
      expect(
        Logger.get('parent.child').frozenFields,
        contains('includeOrigin'),
      );

      // Mutate parent
      Logger.configure('parent', includeOrigin: true);

      // Child should keep frozen value (false)
      expect(Logger.get('parent.child').includeOrigin, isFalse);

      // Unfreeze child
      Logger.get('parent.child').unfreezeInheritance();
      expect(
        Logger.get('parent.child').frozenFields,
        isNot(contains('includeOrigin')),
      );

      // Now child inherits parent's updated value (true)
      expect(Logger.get('parent.child').includeOrigin, isTrue);
    });

    test('pattern configuration with includeOrigin', () {
      Logger.configurePattern('worker.*', includeOrigin: false);

      expect(Logger.get('worker.task1').includeOrigin, isFalse);
      expect(Logger.get('worker.task2').includeOrigin, isFalse);
      expect(Logger.get('other.service').includeOrigin, isTrue);
    });
  });
}
