import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    Logger.clearRegistry();
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
  });
}
