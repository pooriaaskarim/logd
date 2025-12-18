import 'package:logd/src/time/time.dart';
import 'package:test/test.dart';

void main() {
  group('Time', () {
    tearDown(() {
      Time.resetTimeProvider();
      Time.resetTimezoneNameFetcher();
    });

    test('timeProvider returns current time by default', () {
      final now = DateTime.now();
      final provided = Time.timeProvider();
      expect(provided.difference(now).inMilliseconds, lessThan(100));
    });

    test('setTimeProvider overrides and reset restores', () {
      final fixed = DateTime(2025);
      Time.setTimeProvider(() => fixed);
      expect(Time.timeProvider(), equals(fixed));

      Time.resetTimeProvider();
      expect(Time.timeProvider().year, equals(DateTime.now().year));
    });

    test('timezoneNameFetcher calls underlying and handles exceptions', () {
      // Mock success
      Time.setTimezoneNameFetcher(() => 'Test/Zone');
      expect(Time.timezoneNameFetcher(), equals('Test/Zone'));

      // Mock exception (logs warning, returns null)
      Time.setTimezoneNameFetcher(() => throw Exception('Fail'));
      expect(Time.timezoneNameFetcher(), isNull); // Caught and null

      Time.resetTimezoneNameFetcher();
      // Default: platform-dependent, but ensure it runs (coverage)
      expect(() => Time.timezoneNameFetcher(), returnsNormally);
    });
  });
}
