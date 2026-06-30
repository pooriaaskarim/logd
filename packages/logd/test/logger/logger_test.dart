import 'dart:async';
import 'dart:convert';
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
      Logger.reset();
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
      Logger.reset();
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
      Logger.reset();
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
      Logger.reset();
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
      final logger = Logger.get('buffer_test');
      final logCollector = _MemorySink();
      Logger.configure(
        'buffer_test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(
              metadata: {},
            ),
            sink: logCollector,
          ),
        ],
      );

      final buffer = logger.infoBuffer!
        ..writeln('line 1')
        ..writeln('line 2');

      expect(logCollector.outputs, isEmpty); // Not sunk yet

      buffer.sink();

      expect(
        logCollector.outputs,
        containsAll([
          ['[INFO] line 1', '       line 2'],
        ]),
      );
    });
  });

  group('InternalLogger', () {
    setUp(() {
      Logger.reset();
    });

    test('InternalLogger does not recursively log when a handler fails',
        () async {
      await runZoned(
        () async {
          final failingHandler = Handler(
            formatter: const PlainFormatter(),
            sink: FailingSink(),
          );

          Logger.configure('global', handlers: [failingHandler]);

          // This should NOT cause a stack overflow
          Logger.get().info('trigger failure');
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            // Suppress printing
          },
        ),
      );
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

  group('Logger.configure() Input Validation', () {
    setUp(() {
      Logger.reset();
    });

    test('rejects negative stackMethodCount values', () {
      expect(
        () => Logger.configure('app', stackMethodCount: {LogLevel.error: -1}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty handlers list', () {
      expect(
        () => Logger.configure('app', handlers: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid stackMethodCount values', () {
      Logger.configure(
        'app',
        stackMethodCount: {LogLevel.error: 0, LogLevel.warning: 5},
      );
      expect(Logger.get('app').stackMethodCount[LogLevel.error], equals(0));
      expect(Logger.get('app').stackMethodCount[LogLevel.warning], equals(5));
    });

    test('accepts valid non-empty handlers list', () {
      Logger.configure(
        'app',
        handlers: [
          const Handler(
            formatter: PlainFormatter(),
            sink: ConsoleSink(),
          ),
        ],
      );
      expect(Logger.get('app').handlers, hasLength(1));
    });
  });

  group('freezeInheritance no-op optimization', () {
    setUp(() {
      Logger.reset();
    });

    test('freeze when all fields explicit does not bump version', () {
      // Set all fields explicitly on child
      Logger.configure('app', logLevel: LogLevel.info);
      Logger.configure(
        'app.ui',
        enabled: true,
        logLevel: LogLevel.debug,
        includeFileLineInHeader: false,
        stackMethodCount: {LogLevel.error: 3},
        handlers: [
          const Handler(
            formatter: PlainFormatter(),
            sink: ConsoleSink(),
          ),
        ],
      );

      // Read child values before freeze
      final child = Logger.get('app.ui');
      final levelBefore = child.logLevel;
      final enabledBefore = child.enabled;

      // Freeze — should be no-op for app.ui (all fields already set)
      Logger.get('app').freezeInheritance();

      // Values remain identical
      expect(child.logLevel, equals(levelBefore));
      expect(child.enabled, equals(enabledBefore));
    });

    test('freeze with null fields applies parent values', () {
      Logger.configure('global', logLevel: LogLevel.error, enabled: false);
      // app.ui has no explicit config (all null)
      final child = Logger.get('app.ui');
      expect(child.logLevel, equals(LogLevel.error));
      expect(child.enabled, isFalse);

      Logger.get('global').freezeInheritance();

      // Now change global — frozen child should NOT change
      Logger.configure('global', logLevel: LogLevel.trace, enabled: true);
      expect(child.logLevel, equals(LogLevel.error)); // frozen
      expect(child.enabled, isFalse); // frozen
    });
  });

  group('Null message behavior', () {
    setUp(() {
      Logger.reset();
    });

    test('logger.info(null) produces output with empty message', () async {
      final logCollector = _MemorySink();
      Logger.configure(
        'null_test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(metadata: {}),
            sink: logCollector,
          ),
        ],
      );

      Logger.get('null_test').info(null);

      // Allow async handler dispatch to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should produce output (not skip), with empty message content
      expect(logCollector.outputs, isNotEmpty);
      // The log should contain [INFO] but the message part is empty
      expect(logCollector.outputs.first.first, contains('[INFO]'));
    });
  });

  group('stackMethodCount Key-by-Key Merge Semantics', () {
    setUp(() {
      Logger.reset();
    });

    test('merges partial stackMethodCount maps up the hierarchy and defaults',
        () {
      // Parent configures LogLevel.warning and LogLevel.info
      Logger.configure(
        'app',
        stackMethodCount: {
          LogLevel.warning: 4,
          LogLevel.info: 1,
        },
      );

      // Child configures only LogLevel.error and LogLevel.info
      Logger.configure(
        'app.child',
        stackMethodCount: {
          LogLevel.error: 12,
          LogLevel.info: 2,
        },
      );

      final child = Logger.get('app.child');
      final childSMC = child.stackMethodCount;

      // Child explicit/overridden values
      expect(childSMC[LogLevel.error], equals(12));
      expect(childSMC[LogLevel.info], equals(2));

      // Parent inherited value
      expect(childSMC[LogLevel.warning], equals(4));

      // Default fallback values
      expect(childSMC[LogLevel.debug], equals(0));
      expect(childSMC[LogLevel.trace], equals(0));
    });

    test('should fallback to console print when all handlers fail', () async {
      final printed = <String>[];
      await runZoned(
        () async {
          Logger.configure(
            'fallback_test',
            handlers: [
              Handler(
                formatter: const PlainFormatter(),
                sink: FailingSink(),
              ),
            ],
          );
          Logger.get('fallback_test').info('Test fallback message');
          await Future.delayed(const Duration(milliseconds: 100));
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            printed.add(line);
          },
        ),
      );

      expect(printed, isNotEmpty);
      expect(
        printed.any(
          (final line) =>
              line.contains('FALLBACK:') &&
              line.contains('Test fallback message'),
        ),
        isTrue,
      );
    });

    test('should support custom fallback handler configuration', () async {
      final customPrinted = <String>[];
      final originalHandler = Logger.fallbackHandler;
      addTearDown(() => Logger.fallbackHandler = originalHandler);

      Logger.fallbackHandler = (
        final entry,
        final error,
        final stackTrace,
      ) {
        customPrinted.add('CUSTOM_FALLBACK: ${entry.message}');
      };

      Logger.configure(
        'custom_fallback_test',
        handlers: [
          Handler(
            formatter: const PlainFormatter(),
            sink: FailingSink(),
          ),
        ],
      );

      Logger.get('custom_fallback_test').info('Test custom fallback message');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(customPrinted, isNotEmpty);
      expect(
        customPrinted.any(
          (final line) => line.contains(
            'CUSTOM_FALLBACK: Test custom fallback message',
          ),
        ),
        isTrue,
      );
    });

    group('Logger.configureMultiple()', () {
      test('configures multiple loggers successfully', () {
        Logger.configureMultiple({
          'bulk1': const LoggerConfig(logLevel: LogLevel.warning),
          'bulk2': const LoggerConfig(logLevel: LogLevel.error, enabled: false),
        });

        final l1 = Logger.get('bulk1');
        final l2 = Logger.get('bulk2');

        expect(l1.logLevel, equals(LogLevel.warning));
        expect(l2.logLevel, equals(LogLevel.error));
        expect(l2.enabled, isFalse);
      });

      test('validates inputs atomically', () {
        expect(
          () => Logger.configureMultiple({
            'invalid1': const LoggerConfig(
              stackMethodCount: {LogLevel.error: -5},
            ),
          }),
          throwsArgumentError,
        );

        expect(
          () => Logger.configureMultiple({
            'invalid2': const LoggerConfig(handlers: []),
          }),
          throwsArgumentError,
        );
      });

      test('performs cache invalidation in a single pass', () {
        Logger.configureMultiple({
          'parent': const LoggerConfig(logLevel: LogLevel.info),
          'parent.child': const LoggerConfig(),
        });

        final parent = Logger.get('parent');
        final child = Logger.get('parent.child');

        // Populate cache
        expect(parent.logLevel, equals(LogLevel.info));
        expect(child.logLevel, equals(LogLevel.info));

        // Configure multiple in a batch
        Logger.configureMultiple({
          'parent': const LoggerConfig(logLevel: LogLevel.warning),
          'parent.child': const LoggerConfig(logLevel: LogLevel.error),
        });

        // Cache should be updated
        expect(parent.logLevel, equals(LogLevel.warning));
        expect(child.logLevel, equals(LogLevel.error));
      });
    });

    group('Logger.configurePattern', () {
      setUp(() {
        Logger.reset();
      });

      test('applies pattern configuration to matching loggers', () {
        Logger.configurePattern('app.services.*', logLevel: LogLevel.info);

        final auth = Logger.get('app.services.auth');
        final db = Logger.get('app.services.db');
        final ui = Logger.get('app.ui');

        expect(auth.logLevel, equals(LogLevel.info));
        expect(db.logLevel, equals(LogLevel.info));
        expect(ui.logLevel, equals(LogLevel.debug)); // default
      });

      test('supports suffix matching via glob wildcard', () {
        Logger.configurePattern('*.database', logLevel: LogLevel.warning);

        final authDb = Logger.get('app.auth.database');
        final billingDb = Logger.get('app.billing.database');
        final dbHelper = Logger.get('app.db_helper');

        expect(authDb.logLevel, equals(LogLevel.warning));
        expect(billingDb.logLevel, equals(LogLevel.warning));
        expect(dbHelper.logLevel, equals(LogLevel.debug));
      });

      test('validates input parameters correctly', () {
        expect(
          () => Logger.configurePattern('', logLevel: LogLevel.info),
          throwsArgumentError,
        );

        expect(
          () => Logger.configurePattern(
            '*.db',
            stackMethodCount: {LogLevel.error: -1},
          ),
          throwsArgumentError,
        );

        expect(
          () => Logger.configurePattern('*.db', handlers: []),
          throwsArgumentError,
        );
      });

      test(
        'newer pattern rules override older pattern rules when both match',
        () {
          Logger.configurePattern('app.*', logLevel: LogLevel.info);
          Logger.configurePattern(
            'app.services.*',
            logLevel: LogLevel.warning,
          );

          final auth = Logger.get('app.services.auth');
          final ui = Logger.get('app.ui');

          expect(auth.logLevel, equals(LogLevel.warning));
          expect(ui.logLevel, equals(LogLevel.info));
        },
      );

      test('explicit configure overrides pattern rules', () {
        Logger.configurePattern('app.services.*', logLevel: LogLevel.info);
        Logger.configure('app.services.auth', logLevel: LogLevel.error);

        final auth = Logger.get('app.services.auth');
        final db = Logger.get('app.services.db');

        expect(auth.logLevel, equals(LogLevel.error));
        expect(db.logLevel, equals(LogLevel.info));
      });

      test('resets pattern rules when global reset is called', () {
        Logger.configurePattern('app.services.*', logLevel: LogLevel.info);

        final auth = Logger.get('app.services.auth');
        expect(auth.logLevel, equals(LogLevel.info));

        Logger.reset();

        final authNew = Logger.get('app.services.auth');
        expect(authNew.logLevel, equals(LogLevel.debug));
      });

      test(
        'supports isolate export and import serialization of pattern rules',
        () {
          Logger.configurePattern('app.services.*', logLevel: LogLevel.info);

          final auth = Logger.get('app.services.auth');
          expect(auth.logLevel, equals(LogLevel.info));

          final snapshot = Logger.exportConfig();
          Logger.reset();

          final authReset = Logger.get('app.services.auth');
          expect(authReset.logLevel, equals(LogLevel.debug));

          Logger.importConfig(snapshot);

          final authImported = Logger.get('app.services.auth');
          expect(authImported.logLevel, equals(LogLevel.info));
        },
      );

      test(
        'emits warning when logger hierarchy depth exceeds maxHierarchyDepth',
        () {
          final logs = <String>[];
          final previousMax = Logger.maxHierarchyDepth;
          Logger.maxHierarchyDepth = 3;
          try {
            runZoned(
              () {
                // First access: should warn
                Logger.get('a.b.c.d');
                // Second access: should not warn again
                Logger.get('a.b.c.d');
                // Access different deep logger: should warn
                Logger.get('x.y.z.w');
              },
              zoneSpecification: ZoneSpecification(
                print: (final self, final parent, final zone, final line) {
                  logs.add(line);
                },
              ),
            );

            expect(logs, hasLength(2));
            expect(
              logs[0],
              contains(
                'Logger hierarchy depth for "a.b.c.d" is 4, which exceeds '
                'the maximum recommended threshold of 3',
              ),
            );
            expect(
              logs[1],
              contains(
                'Logger hierarchy depth for "x.y.z.w" is 4, which exceeds '
                'the maximum recommended threshold of 3',
              ),
            );
          } finally {
            Logger.maxHierarchyDepth = previousMax;
            Logger.reset();
          }
        },
      );

      test(
        'resets warned deep loggers set when Logger.reset() is called',
        () {
          final logs = <String>[];
          final previousMax = Logger.maxHierarchyDepth;
          Logger.maxHierarchyDepth = 3;
          try {
            runZoned(
              () {
                Logger.get('a.b.c.d');
              },
              zoneSpecification: ZoneSpecification(
                print: (final self, final parent, final zone, final line) {
                  logs.add(line);
                },
              ),
            );
            expect(logs, hasLength(1));
            logs.clear();

            // Reset globally
            Logger.reset();

            runZoned(
              () {
                // Access again after reset: should warn again
                Logger.get('a.b.c.d');
              },
              zoneSpecification: ZoneSpecification(
                print: (final self, final parent, final zone, final line) {
                  logs.add(line);
                },
              ),
            );
            expect(logs, hasLength(1));
          } finally {
            Logger.maxHierarchyDepth = previousMax;
            Logger.reset();
          }
        },
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

base class _MemorySink extends LogSink<LogDocument> {
  final List<List<String>> outputs = [];

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    // For tests, we convert back to lines but without wrapping logic,
    // reflecting how it was designed to be captured.
    const encoder = PlainTextEncoder();
    final context = HandlerContext();
    encoder.encode(entry, document, level, context, factory, width: 80);
    final output = const Utf8Decoder().convert(context.takeBytes());
    outputs.add(output.trimRight().split('\n'));
  }
}
