import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart'; // Access internal types
import 'package:test/test.dart';

void main() {
  group('LogBuffer Auto-Sink & Reuse', () {
    late Logger logger;

    setUp(() {
      Logger.clearRegistry();
      logger = Logger.get('test_auto_sink');
    });

    test('should function as a normal StringBuffer', () {
      final buf = logger.infoBuffer!;
      expect(buf.isEmpty, isTrue);

      buf.write('Hello');
      expect(buf.length, 5);
      expect(buf.toString(), 'Hello');

      buf.clear();
      expect(buf.isEmpty, isTrue);
    });

    test('should sink normally when requested', () {
      final buf = logger.infoBuffer!
        ..write('Manual sink')

        // We can't easily capture the output here without mocking
        // InternalLogger or Logger's sink mechanism,
        // but we can verify state changes in LogBuffer.
        // This test mainly verifies no exceptions are thrown.
        ..sink();

      expect(buf.isEmpty, isTrue);
    });

    test('should allow reusing buffer after sink', () {
      final buf = logger.infoBuffer!

        // First use
        ..write('First message')
        ..sink();
      expect(buf.isEmpty, isTrue);

      // Reuse
      buf.write('Second message');
      expect(buf.toString(), 'Second message');
      buf.sink();
      expect(buf.isEmpty, isTrue);
    });

    test('should respect autoSinkBuffer configuration', () {
      // Default is false
      expect(logger.autoSinkBuffer, isFalse);

      // Change to true
      Logger.configure(logger.name, autoSinkBuffer: true);
      expect(logger.autoSinkBuffer, isTrue);

      // Verify it persists in hierarchy/cache
      final childLogger = Logger.get('${logger.name}.child');
      expect(childLogger.autoSinkBuffer, isTrue);
    });

    test('should support error and stackTrace fields', () {
      final buf = logger.infoBuffer!;
      final error = Exception('Test error');
      final stack = StackTrace.current;

      buf
        ..write('Message with context')
        ..error = error
        ..stackTrace = stack;

      expect(buf.error, equals(error));
      expect(buf.stackTrace, equals(stack));

      // Sink should clear deeper fields too
      buf.sink();
      expect(buf.isEmpty, isTrue);
      expect(buf.error, isNull);
      expect(buf.stackTrace, isNull);
    });

    // Note: We cannot deterministically test the Finalizer (auto-sink) logic
    // in a unit test environment without forcing GC.
    // The implementation relies on the platform's Finalizer guarantee.
  });
}
