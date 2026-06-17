import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    Logger.reset();
  });

  group('Logger Logic', () {
    test('enabled is true by default', () {
      final logger = Logger.get('new.logger');
      expect(logger.enabled, isTrue);
    });

    test('validates logger names', () {
      // Normalization handles case
      expect(
        () => Logger.get('ValidName'),
        returnsNormally,
        reason: 'Should normalize to validname',
      );
      expect(() => Logger.get('valid.name'), returnsNormally);
      expect(() => Logger.get('my_app'), returnsNormally);

      // Invalid structures
      expect(() => Logger.get('Invalid..Name'), throwsArgumentError);
      expect(() => Logger.get('.invalid'), throwsArgumentError);
      expect(() => Logger.get('invalid.'), throwsArgumentError);
      expect(() => Logger.get('in valid'), throwsArgumentError);
      expect(() => Logger.get('!nv@lid'), throwsArgumentError);
    });

    test('reset() clears active registry configurations globally', () {
      Logger.configure('app.test', enabled: false);
      expect(Logger.get('app.test').enabled, isFalse);

      Logger.reset();

      // Confirms the registry is wiped and the config resolved is the default
      // (true)
      expect(Logger.get('app.test').enabled, isTrue);
    });

    test('reset(subtree) clears only the specified subtree', () {
      Logger.configure('app.ui', enabled: false);
      Logger.configure('app.network', enabled: false);
      Logger.configure('db', enabled: false);

      expect(Logger.get('app.ui').enabled, isFalse);
      expect(Logger.get('app.network').enabled, isFalse);
      expect(Logger.get('db').enabled, isFalse);

      // Reset only the 'app' subtree (this should reset app.ui and app.network)
      Logger.reset('app');

      expect(Logger.get('app.ui').enabled, isTrue);
      expect(Logger.get('app.network').enabled, isTrue);
      // db was NOT part of 'app' subtree, so it must still be disabled
      expect(Logger.get('db').enabled, isFalse);

      // Now reset everything
      Logger.reset();
      expect(Logger.get('db').enabled, isTrue);
    });
  });
}
