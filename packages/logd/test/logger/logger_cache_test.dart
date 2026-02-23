import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerCache', () {
    setUp(() {
      Logger.clearRegistry();
    });

    tearDown(() {
      Logger.clearRegistry();
    });

    test('resolves default values for global logger', () {
      // Global is created by default if not exists
      expect(LoggerCache.enabled('global'), isTrue);
      expect(LoggerCache.logLevel('global'), equals(LogLevel.debug));
      expect(LoggerCache.handlers('global'), isNotEmpty);
    });

    test('inherits value from parent', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.get('app.ui'); // Creates app.ui and implicitly its parents

      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.info));
    });

    test('overrides parent value', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('app', logLevel: LogLevel.warning);

      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.warning));
    });

    test('invalidates cache when configuration changes', () {
      Logger.configure('global', logLevel: LogLevel.info);
      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.info));

      Logger.configure('global', logLevel: LogLevel.error);
      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.error));
    });

    test('invalidates cache for descendants only', () {
      Logger.configure('global', logLevel: LogLevel.info);
      Logger.configure('other', logLevel: LogLevel.debug);

      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.info));
      expect(LoggerCache.logLevel('other.sub'), equals(LogLevel.debug));

      Logger.configure('app', logLevel: LogLevel.warning);

      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.warning));
      expect(LoggerCache.logLevel('other.sub'), equals(LogLevel.debug));
    });

    test('freezeInheritance invalidates cache correctly', () {
      Logger.configure('global', logLevel: LogLevel.info);
      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.info));

      Logger.get('app').freezeInheritance();

      // Now app.ui has an explicit (frozen) logLevel in LoggerConfig
      // so future changes to global should not affect app.ui
      Logger.configure('global', logLevel: LogLevel.error);

      expect(LoggerCache.logLevel('app.ui'), equals(LogLevel.info));
    });

    test('clear clears the cache', () {
      Logger.configure('global', logLevel: LogLevel.info);
      expect(LoggerCache.logLevel('global'), equals(LogLevel.info));

      LoggerCache.clear();
      // Accessing again should re-resolve (which should still be info unless
      // configured changed)
      expect(LoggerCache.logLevel('global'), equals(LogLevel.info));
    });
  });
}
