import 'package:logd/src/core/context/clock/clock.dart';
import 'package:test/test.dart';

void main() {
  group('SystemClock', () {
    const clock = SystemClock();

    test('now returns current time', () {
      final t1 = clock.now;
      // Allow execution time
      final t2 = DateTime.now();
      expect(t1.difference(t2).inSeconds.abs(), lessThan(5));
    });

    test('now returns new instance each call', () async {
      final t1 = clock.now;
      await Future.delayed(const Duration(milliseconds: 10));
      final t2 = clock.now;
      expect(t1, isNot(equals(t2)));
      expect(t2.isAfter(t1), isTrue);
    });

    test('timezoneName runs without error', () {
      // Result depends on the test environment (linux), could be UTC or local.
      // We just ensure it doesn't crash.
      final tz = clock.timezoneName;
      // It might be null or string
      if (tz != null) {
        expect(tz, isNotEmpty);
      }
    });
  });
}
