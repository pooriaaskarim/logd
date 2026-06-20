import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  setUp(Logger.reset);

  group('Descendant Invalidation Correctness', () {
    test('invalidates cache for direct children', () {
      Logger.configure('parent', logLevel: LogLevel.info);
      final parent = Logger.get('parent');
      final child = Logger.get('parent.child');

      // Access properties to populate cache
      expect(parent.logLevel, LogLevel.info);
      expect(child.logLevel, LogLevel.info);

      // Reconfigure parent
      Logger.configure('parent', logLevel: LogLevel.warning);

      // Check that both parent and child are updated (invalidated in cache)
      expect(parent.logLevel, LogLevel.warning);
      expect(child.logLevel, LogLevel.warning);
    });

    test('invalidates cache for deeply nested descendants', () {
      Logger.configure('parent', logLevel: LogLevel.info);
      final child = Logger.get('parent.child.grandchild.greatgrandchild');

      expect(child.logLevel, LogLevel.info);

      Logger.configure('parent', logLevel: LogLevel.error);

      expect(child.logLevel, LogLevel.error);
    });

    test('does not invalidate siblings or parent when sibling is configured',
        () {
      Logger.configure('parent', logLevel: LogLevel.info);
      final sibling1 = Logger.get('parent.sib1');
      final sibling2 = Logger.get('parent.sib2');

      expect(sibling1.logLevel, LogLevel.info);
      expect(sibling2.logLevel, LogLevel.info);

      Logger.configure('parent.sib1', logLevel: LogLevel.error);

      expect(sibling1.logLevel, LogLevel.error);
      expect(sibling2.logLevel, LogLevel.info); // sibling2 unaffected
      expect(Logger.get('parent').logLevel, LogLevel.info); // parent unaffected
    });

    test('correctly updates descendants index on reset', () {
      Logger.configure('parent', logLevel: LogLevel.info);
      final child = Logger.get('parent.child');

      expect(child.logLevel, LogLevel.info);

      // Reset parent (removes parent and descendants from registry and
      // invalidates)
      Logger.reset('parent');

      // Set different configuration on global
      Logger.configure('global', logLevel: LogLevel.warning);

      // If registry/index was successfully cleaned up, parent/child will
      //resolve to global's warning
      expect(Logger.get('parent').logLevel, LogLevel.warning);
      expect(Logger.get('parent.child').logLevel, LogLevel.warning);
    });
  });
}
