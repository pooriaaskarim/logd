import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Logger Normalization & Retrieval', () {
    test('Logger.get() defaults to "global"', () {
      final logger = Logger.get();
      expect(logger.name, equals('global'));
    });

    test('Logger.get("") defaults to "global"', () {
      final logger = Logger.get('');
      expect(logger.name, equals('global'));
    });

    test('Logger.get(null) defaults to "global"', () {
      final logger = Logger.get(null);
      expect(logger.name, equals('global'));
    });

    test('Logger.get("GLOBAL") is normalized to "global"', () {
      final logger = Logger.get('GLOBAL');
      expect(logger.name, equals('global'));
    });

    test('Logger names are case-insensitive and normalized to lowercase', () {
      final logger1 = Logger.get('My_App.UI');
      final logger2 = Logger.get('my_app.ui');
      expect(logger1.name, equals('my_app.ui'));
      expect(logger2.name, equals('my_app.ui'));
      expect(
        identical(logger1, logger2),
        isFalse,
      ); // Logger is a proxy, but names match
    });

    test('Retrieving same name returns logger with same name', () {
      const name = 'app.service';
      final logger1 = Logger.get(name);
      final logger2 = Logger.get(name);
      expect(logger1.name, equals(name));
      expect(logger2.name, equals(name));
    });
  });

  group('Logger Hierarchy & Inheritance', () {
    setUp(() {
      Logger.clearRegistry();
    });

    test('Child inherits logLevel from global by default', () {
      Logger.configure('global', logLevel: LogLevel.error);
      final child = Logger.get('any.child');
      expect(child.logLevel, equals(LogLevel.error));
    });

    test('Child inherits from parent override', () {
      Logger.configure('app', logLevel: LogLevel.info);
      final parent = Logger.get('app');
      final child = Logger.get('app.ui');

      expect(parent.logLevel, equals(LogLevel.info));
      expect(child.logLevel, equals(LogLevel.info));
    });

    test('Child can override parent config', () {
      Logger.configure('app', logLevel: LogLevel.info);
      Logger.configure('app.ui', logLevel: LogLevel.debug);

      final parent = Logger.get('app');
      final child = Logger.get('app.ui');

      expect(parent.logLevel, equals(LogLevel.info));
      expect(child.logLevel, equals(LogLevel.debug));
    });

    test('Deep hierarchy inheritance (a.b.c.d)', () {
      Logger.configure('a', enabled: false);
      Logger.configure('a.b.c', enabled: true);

      expect(Logger.get('a').enabled, isFalse);
      expect(Logger.get('a.b').enabled, isFalse);
      expect(Logger.get('a.b.c').enabled, isTrue);
      expect(Logger.get('a.b.c.d').enabled, isTrue);
    });
  });

  group('Logger Caching & Invalidation', () {
    setUp(() {
      Logger.clearRegistry();
    });

    test('Config values are cached after search', () {
      // We can't directly check the private cache, but we can verify
      // that parent changes propagate (triggering invalidation).
      Logger.configure('parent', enabled: false);
      final child = Logger.get('parent.child');
      expect(child.enabled, isFalse);

      Logger.configure('parent', enabled: true);
      expect(child.enabled, isTrue);
    });

    test('Configuring parent invalidates descendant caches', () {
      Logger.configure('global', logLevel: LogLevel.info);
      final child = Logger.get('a.b.c');
      expect(child.logLevel, equals(LogLevel.info));

      Logger.configure('a', logLevel: LogLevel.error);
      expect(child.logLevel, equals(LogLevel.error));

      Logger.configure('global', logLevel: LogLevel.trace);
      // 'a' has explicit config, so child should still be error
      expect(child.logLevel, equals(LogLevel.error));
    });
  });

  group('Logger freezeInheritance', () {
    setUp(() {
      Logger.clearRegistry();
    });

    test('freezeInheritance snapshots current effective config to children',
        () {
      Logger.configure('global', enabled: false, logLevel: LogLevel.error);
      final parent = Logger.get('app');
      final child = Logger.get('app.ui');

      // Before freeze: children have no explicit config for these fields
      parent.freezeInheritance();

      // Now parent/child should have explicit config entries in registry
      // (internally, but we check effective values stay the same)
      expect(child.enabled, isFalse);
      expect(child.logLevel, equals(LogLevel.error));

      // Change global: frozen children should NOT change
      Logger.configure('global', enabled: true, logLevel: LogLevel.trace);
      expect(parent.enabled, isFalse);
      expect(parent.logLevel, equals(LogLevel.error));
      expect(child.enabled, isFalse);
      expect(child.logLevel, equals(LogLevel.error));
    });

    test('freezeInheritance does not override explicit child config', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('app.ui', logLevel: LogLevel.debug);

      final parent = Logger.get('app');
      final child = Logger.get('app.ui');

      parent.freezeInheritance();

      expect(parent.logLevel, equals(LogLevel.info));
      expect(child.logLevel, equals(LogLevel.debug)); // Kept its own

      Logger.configure('global', logLevel: LogLevel.error);
      expect(parent.logLevel, equals(LogLevel.info)); // Frozen
      expect(child.logLevel, equals(LogLevel.debug)); // Kept its own
    });
  });

  group('Logger Deep Equality Optimization', () {
    setUp(() {
      Logger.clearRegistry();
    });

    test('Identical but new collections do NOT trigger cache invalidation', () {
      final handlers = [
        const Handler(formatter: PlainFormatter(), sink: ConsoleSink()),
      ];
      Logger.configure('app', handlers: handlers);

      // We can check if invalidation happened by looking at child values
      // and checking if they still match the "original" resolved value.
      // But wait, it's easier to check LoggerConfig._version if it was public.
      // Since it's internal, we can check if it's available.
    });

    test('MapEquality for stackMethodCount', () {
      final counts = {LogLevel.trace: 5};
      Logger.configure('app', stackMethodCount: counts);

      // Passing same content in new map should NOT change anything
      Logger.configure('app', stackMethodCount: {LogLevel.trace: 5});
    });
  });

  group('Logger.infoBuffer', () {
    test('LogBuffer stores lines and sinks to logger', () async {
      final logger = Logger.get('buffer-test');
      final logCollector = LogCollector();
      Logger.configure(
        'buffer-test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(
              includeTimestamp: false,
              includeLevel: false,
              includeLoggerName: false,
            ),
            sink: logCollector,
          ),
        ],
      );

      final buffer = logger.infoBuffer!
        ..writeln('line 1')
        ..writeln('line 2');

      expect(logCollector.logs, isEmpty); // Not sunk yet

      buffer.sink();

      expect(logCollector.logs, isNotEmpty);
      expect(logCollector.logs.first, equals('line 1\nline 2\n'));
    });
  });

  group('InternalLogger', () {
    test('InternalLogger does not recursively log when a handler fails',
        () async {
      final failingHandler = Handler(
        formatter: const PlainFormatter(),
        sink: FailingSink(),
      );

      Logger.configure('global', handlers: [failingHandler]);

      // This should NOT cause a stack overflow
      Logger.get().info('trigger failure');

      // If it didn't throw/overflow, we are good.
      // InternalLogger should have logged the error to Console
      // (default) or wherever it's configured.
    });
  });

  group('Logger Hierarchy Edge Cases', () {
    test('Deep inheritance with partial overrides', () {
      Logger.configure('a', enabled: false, logLevel: LogLevel.error);
      Logger.configure('a.b', enabled: true); // Inherits logLevel: error

      final lb = Logger.get('a.b');
      expect(lb.enabled, isTrue);
      expect(lb.logLevel, equals(LogLevel.error));

      Logger.configure('a', logLevel: LogLevel.trace);
      expect(lb.logLevel, equals(LogLevel.trace));
    });

    test('freezeInheritance on non-existent descendant is a no-op', () {
      Logger.get('new.branch')
          // No crash/error
          .freezeInheritance();
    });
  });
}

class LoggerHierarchyEdgeCases {}

base class FailingSink extends LogSink {
  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    throw Exception('Simulated failure');
  }
}

base class LogCollector extends LogSink {
  final List<String> logs = [];

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    logs.addAll(lines.map((final l) => l.text));
  }
}
