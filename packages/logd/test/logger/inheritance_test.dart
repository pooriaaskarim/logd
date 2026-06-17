import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    Logger.reset();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Baseline
  // ──────────────────────────────────────────────────────────────────────────

  test('freezeInheritance with partial child overrides', () {
    Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
    Logger.configure('app.ui', enabled: true);

    var child = Logger.get('app.ui');
    expect(child.enabled, isTrue);
    expect(child.logLevel, LogLevel.trace);

    Logger.get('app').freezeInheritance();

    child = Logger.get('app.ui');
    expect(child.enabled, isTrue);
    expect(child.logLevel, LogLevel.trace);

    Logger.configure('global', logLevel: LogLevel.error);

    child = Logger.get('app.ui');
    expect(child.logLevel, LogLevel.trace);
  });

  test('unfreezeInheritance restores dynamic resolution', () {
    Logger.configure('global', logLevel: LogLevel.trace, enabled: false);

    final child = Logger.get('app.ui');
    expect(child.logLevel, LogLevel.trace);
    expect(child.inheritedFields, contains('logLevel'));
    expect(child.frozenFields, isEmpty);

    Logger.get('app').freezeInheritance();
    expect(child.logLevel, LogLevel.trace);
    expect(child.inheritedFields, isNot(contains('logLevel')));
    expect(child.frozenFields, contains('logLevel'));

    Logger.configure('global', logLevel: LogLevel.error);
    expect(child.logLevel, LogLevel.trace);

    Logger.get('app').unfreezeInheritance();
    expect(child.frozenFields, isEmpty);
    expect(child.inheritedFields, contains('logLevel'));
    expect(child.logLevel, LogLevel.error);
  });

  test('explicit override clears frozen state', () {
    Logger.configure('global', logLevel: LogLevel.trace);

    final child = Logger.get('app.ui');
    expect(child.inheritedFields, contains('logLevel'));

    Logger.get('app').freezeInheritance();
    expect(child.frozenFields, contains('logLevel'));
    expect(child.explicitFields, isEmpty);

    Logger.configure('app.ui', logLevel: LogLevel.info);
    expect(child.frozenFields, isNot(contains('logLevel')));
    expect(child.explicitFields, contains('logLevel'));
  });

  test('monitoring and visualization export', () {
    Logger.configure('global', logLevel: LogLevel.trace);
    Logger.configure('app.ui', enabled: true);

    Logger.get('app').freezeInheritance();

    final hierarchy = Logger.exportHierarchy();
    expect(hierarchy.containsKey('global'), isTrue);
    expect(hierarchy.containsKey('app.ui'), isTrue);

    final appUi = hierarchy['app.ui'] as Map<String, dynamic>;
    expect(appUi['explicit'], contains('enabled'));
    expect(appUi['frozen'], contains('logLevel'));
    expect(appUi['inherited'], isNot(contains('enabled')));
    expect(appUi['inherited'], isNot(contains('logLevel')));
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 1A — exportHierarchy: effective values
  // ──────────────────────────────────────────────────────────────────────────

  group('exportHierarchy - effective values', () {
    test("every entry has an 'effective' key", () {
      Logger.configure('global', logLevel: LogLevel.warning);
      Logger.configure('app.ui', enabled: true);

      final hierarchy = Logger.exportHierarchy();
      for (final entry in hierarchy.values) {
        final map = entry as Map<String, dynamic>;
        expect(
          map.containsKey('effective'),
          isTrue,
          reason: 'each entry must have effective key',
        );
      }
    });

    test('effective logLevel matches resolved value', () {
      Logger.configure('global', logLevel: LogLevel.warning);
      final hierarchy = Logger.exportHierarchy();
      final global = hierarchy['global'] as Map<String, dynamic>;
      final effective = global['effective'] as Map<String, dynamic>;
      expect(effective['logLevel'], equals(Logger.get('global').logLevel.name));
    });

    test('effective enabled matches resolved value', () {
      Logger.configure('global', enabled: false);
      final hierarchy = Logger.exportHierarchy();
      final global = hierarchy['global'] as Map<String, dynamic>;
      final effective = global['effective'] as Map<String, dynamic>;
      expect(effective['enabled'], equals(Logger.get('global').enabled));
    });

    test('effective values remain accurate after freeze', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('app').freezeInheritance();
      Logger.configure('global', logLevel: LogLevel.error);

      final hierarchy = Logger.exportHierarchy();
      final app = hierarchy['app'] as Map<String, dynamic>;
      final effective = app['effective'] as Map<String, dynamic>;
      // 'app' has logLevel frozen to 'trace', so effective is trace
      expect(effective['logLevel'], equals('trace'));
    });

    test('effective values are JSON-serialisable primitives', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('app.ui', enabled: true);

      final hierarchy = Logger.exportHierarchy();
      for (final entry in hierarchy.values) {
        final map = entry as Map<String, dynamic>;
        final effective = map['effective'] as Map<String, dynamic>;
        for (final value in effective.values) {
          expect(
            value,
            anyOf(
              isA<bool>(),
              isA<String>(),
              isA<int>(),
              isA<Map>(),
              isA<List>(),
            ),
            reason: 'effective values must be JSON-serialisable',
          );
        }
        if (effective['stackMethodCount'] != null) {
          final smc = effective['stackMethodCount'] as Map;
          for (final k in smc.keys) {
            expect(k, isA<String>());
            expect(smc[k], isA<int>());
          }
        }
      }
    });

    test("entry has 'implicit' key defaulting to false for configured loggers",
        () {
      Logger.configure('global', logLevel: LogLevel.debug);
      final hierarchy = Logger.exportHierarchy();
      final global = hierarchy['global'] as Map<String, dynamic>;
      expect(global.containsKey('implicit'), isTrue);
      expect(global['implicit'], isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 1B — formatHierarchy / printHierarchy
  // ──────────────────────────────────────────────────────────────────────────

  group('formatHierarchy / printHierarchy', () {
    test('formatHierarchy returns a non-empty String', () {
      Logger.configure('global', logLevel: LogLevel.debug);
      final output = Logger.formatHierarchy();
      expect(output, isA<String>());
      expect(output.isNotEmpty, isTrue);
    });

    test('output contains each registered logger name', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('app.ui', enabled: true);
      Logger.get('app.network');

      final output = Logger.formatHierarchy();
      expect(output, contains('global'));
      expect(output, contains('app'));
      expect(output, contains('app.ui'));
      expect(output, contains('app.network'));
    });

    test('explicit fields appear with values in output', () {
      Logger.configure('global', logLevel: LogLevel.warning);
      final output = Logger.formatHierarchy();
      expect(output, contains('logLevel'));
      expect(output, contains('warning'));
    });

    test('frozen fields appear with values in output', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('app').freezeInheritance();
      final output = Logger.formatHierarchy();
      expect(output, contains('frozen'));
      expect(output, contains('logLevel'));
    });

    test('printHierarchy with sink routes output to provided sink', () {
      Logger.configure('global', logLevel: LogLevel.debug);
      final lines = <String>[];
      Logger.printHierarchy(sink: lines.add);
      expect(lines, isNotEmpty);
      expect(lines.first, contains('global'));
    });

    test('printHierarchy with no sink does not throw', () {
      Logger.configure('global', logLevel: LogLevel.debug);
      expect(() => Logger.printHierarchy(), returnsNormally);
    });

    test('printHierarchy output matches formatHierarchy', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('app.ui', enabled: true);
      String? sinkOutput;
      Logger.printHierarchy(sink: (final s) => sinkOutput = s);
      expect(sinkOutput, equals(Logger.formatHierarchy()));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 2A — unfreezeInheritance: selective fields
  // ──────────────────────────────────────────────────────────────────────────

  group('unfreezeInheritance - selective fields', () {
    test('selective unfreeze clears only specified fields', () {
      Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
      // Materialise child before freeze so it is in the registry.
      final child = Logger.get('app.ui');
      Logger.get('app').freezeInheritance();

      expect(child.frozenFields, containsAll(['logLevel', 'enabled']));

      Logger.get('app').unfreezeInheritance(fields: {'logLevel'});
      expect(child.frozenFields, isNot(contains('logLevel')));
      expect(child.frozenFields, contains('enabled'));
    });

    test('non-specified frozen fields remain frozen after selective unfreeze',
        () {
      Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
      // Materialise child before freeze.
      final child = Logger.get('app.ui');
      Logger.get('app').freezeInheritance();

      Logger.get('app').unfreezeInheritance(fields: {'logLevel'});

      // 'enabled' should still be frozen
      expect(child.frozenFields, contains('enabled'));
      expect(child.explicitFields, isNot(contains('enabled')));
    });

    test('selectively unfrozen field resolves dynamically from parent', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('app').freezeInheritance();

      final child = Logger.get('app.ui');
      expect(child.logLevel, LogLevel.trace);

      Logger.configure('global', logLevel: LogLevel.error);
      expect(child.logLevel, LogLevel.trace); // still frozen

      Logger.get('app').unfreezeInheritance(fields: {'logLevel'});
      expect(child.logLevel, LogLevel.error); // now dynamic again
    });

    test('unknown field names in fields set do not throw', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('app').freezeInheritance();
      expect(
        () => Logger.get('app').unfreezeInheritance(
          fields: {'logLevel', 'nonExistentField'},
        ),
        returnsNormally,
      );
    });

    test('full unfreeze (no fields arg) still clears everything', () {
      Logger.configure('global', logLevel: LogLevel.trace, enabled: false);
      Logger.get('app').freezeInheritance();

      final child = Logger.get('app.ui');
      Logger.get('app').unfreezeInheritance();
      expect(child.frozenFields, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 2B — unfreezeInheritance: includeSelf
  // ──────────────────────────────────────────────────────────────────────────

  group('unfreezeInheritance - includeSelf', () {
    test('includeSelf: false does not clear caller own frozen fields', () {
      Logger.configure('global', logLevel: LogLevel.trace);

      // Materialise 'app' BEFORE freezing so it appears in the registry.
      final app = Logger.get('app');
      Logger.get('global').freezeInheritance();

      expect(app.frozenFields, contains('logLevel'));

      // Unfreeze app subtree only (exclude self)
      app.unfreezeInheritance(includeSelf: false);

      // app itself should still have the frozen field
      expect(app.frozenFields, contains('logLevel'));
    });

    test('includeSelf: false still clears frozen fields on strict descendants',
        () {
      Logger.configure('global', logLevel: LogLevel.trace);

      // Materialise loggers before freeze.
      final app = Logger.get('app');
      final child = Logger.get('app.ui');
      Logger.get('global').freezeInheritance();

      expect(child.frozenFields, contains('logLevel'));

      app.unfreezeInheritance(includeSelf: false);
      expect(child.frozenFields, isNot(contains('logLevel')));
    });

    test('includeSelf: true (default) clears both self and descendants', () {
      Logger.configure('global', logLevel: LogLevel.trace);

      // Materialise before freeze.
      final app = Logger.get('app');
      final child = Logger.get('app.ui');
      Logger.get('global').freezeInheritance();

      expect(app.frozenFields, contains('logLevel'));
      expect(child.frozenFields, contains('logLevel'));

      app.unfreezeInheritance(); // default: includeSelf: true
      expect(app.frozenFields, isNot(contains('logLevel')));
      expect(child.frozenFields, isNot(contains('logLevel')));
    });

    test('combinaton: includeSelf: false + selective fields', () {
      Logger.configure('global', logLevel: LogLevel.trace, enabled: false);

      // Materialise both nodes before the freeze walk.
      final app = Logger.get('app');
      final child = Logger.get('app.ui');
      Logger.get('global').freezeInheritance();

      // Unfreeze only logLevel from descendants of app, not app itself
      app.unfreezeInheritance(fields: {'logLevel'}, includeSelf: false);

      // app should still have logLevel frozen
      expect(app.frozenFields, contains('logLevel'));
      // child should have logLevel unfrozen
      expect(child.frozenFields, isNot(contains('logLevel')));
      // child enabled should still be frozen
      expect(child.frozenFields, contains('enabled'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 3A — freezeInheritance: force + return count
  // ──────────────────────────────────────────────────────────────────────────

  group('freezeInheritance - force and return count', () {
    test('returns 0 when no null fields in any descendant', () {
      Logger.configure('global', logLevel: LogLevel.trace, enabled: true);
      Logger.get('app').freezeInheritance(); // first freeze — writes fields

      final count = Logger.get('app').freezeInheritance();
      // second call: all fields already frozen, no-op
      expect(count, equals(0));
    });

    test('returns > 0 when at least one field was written', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.configure('app.ui', enabled: true); // leave logLevel null

      final count = Logger.get('app').freezeInheritance();
      expect(count, greaterThan(0));
    });

    test(
        'force: true re-snapshots previously frozen fields after parent change',
        () {
      Logger.configure('global', logLevel: LogLevel.trace);

      // Materialise app.ui before freeze so it is in the registry.
      final child = Logger.get('app.ui');
      Logger.get('global').freezeInheritance();

      expect(child.logLevel, LogLevel.trace);

      // Parent changes
      Logger.configure('global', logLevel: LogLevel.error);
      expect(child.logLevel, LogLevel.trace); // still frozen

      // Re-snapshot from global (which dynamically resolves to 'error').
      Logger.get('global').freezeInheritance(force: true);
      // Now the frozen value should reflect the new effective value
      expect(child.logLevel, LogLevel.error);
    });

    test('force: true does NOT overwrite an explicitly configured field', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.configure('app.ui', logLevel: LogLevel.info); // explicit

      Logger.get('app').freezeInheritance(force: true);

      final child = Logger.get('app.ui');
      // explicit override must survive a force freeze
      expect(child.logLevel, LogLevel.info);
      expect(child.explicitFields, contains('logLevel'));
      expect(child.frozenFields, isNot(contains('logLevel')));
    });

    test('force: false (default) is no-op for already-frozen fields', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('app').freezeInheritance();

      Logger.configure('global', logLevel: LogLevel.error);

      final count = Logger.get('app').freezeInheritance(); // force: false
      expect(count, equals(0));

      final child = Logger.get('app.ui');
      expect(child.logLevel, LogLevel.trace); // unchanged
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Wave 4B — Ghost node detection + 'implicit' flag
  // ──────────────────────────────────────────────────────────────────────────

  group('ghost node detection - implicit flag', () {
    test('logger created by get() alone is marked implicit in export', () {
      Logger.get('app'); // no configure() call
      final hierarchy = Logger.exportHierarchy();
      final app = hierarchy['app'] as Map<String, dynamic>;
      expect(app['implicit'], isTrue);
    });

    test('logger created by configure() is NOT marked implicit', () {
      Logger.configure('app', logLevel: LogLevel.info);
      final hierarchy = Logger.exportHierarchy();
      final app = hierarchy['app'] as Map<String, dynamic>;
      expect(app['implicit'], isFalse);
    });

    test('implicit node frozen by freezeInheritance remains implicit', () {
      Logger.configure('global', logLevel: LogLevel.trace);
      Logger.get('global').freezeInheritance(); // 'app' was never configured
      final hierarchy = Logger.exportHierarchy();
      if (hierarchy.containsKey('app')) {
        final app = hierarchy['app'] as Map<String, dynamic>;
        // app got into the registry via LoggerCache resolution during freeze;
        // it was never explicitly touched, so it stays implicit
        expect(app['implicit'], isTrue);
      }
    });

    test('formatHierarchy labels implicit nodes', () {
      Logger.get('app'); // implicit
      Logger.configure('app.ui', enabled: true); // explicit
      final output = Logger.formatHierarchy();
      expect(output, contains('implicit'));
    });

    test('unfreezeInheritance on a non-implicit node keeps it non-implicit',
        () {
      Logger.configure('app', logLevel: LogLevel.info);
      Logger.get('app').freezeInheritance();
      Logger.get('app').unfreezeInheritance();

      final hierarchy = Logger.exportHierarchy();
      final app = hierarchy['app'] as Map<String, dynamic>;
      expect(app['implicit'], isFalse);
    });
  });
}
