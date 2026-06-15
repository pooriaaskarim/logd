import 'package:logd/logd.dart';
import 'package:logd/src/core/context/clock/clock.dart';
import 'package:logd/src/core/context/context.dart';
import 'package:logd/src/time/timezone.dart';
import 'package:test/test.dart';

// Mock Clock that returns null for timezoneName
class FailClock extends Clock {
  final DateTime _now = DateTime(2023, 1, 1, 12, 0, 0);

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => null;
}

// Mock Clock that returns a name NOT in the database
class UnknownNameClock extends Clock {
  final DateTime _now = DateTime(2023, 1, 1, 12, 0, 0);

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => "Mars/Cydonia";
}

// Mock Clock that throws exception during timezoneName fetch
class ThrowingClock extends Clock {
  final DateTime _now = DateTime(2023, 1, 1, 12, 0, 0);

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => throw Exception("System failure");
}

// Mock Clock simulating what clock_native.dart does on iOS (issue #21):
// returns DateTime.now().timeZoneName — process-free and sandbox-safe.
class IosFallbackClock extends Clock {
  @override
  DateTime get now => DateTime.now();

  @override
  // ignore: override_on_non_overriding_member
  String? get timezoneName => DateTime.now().timeZoneName;
}

void main() {
  group('Timezone Failure Emulation', () {
    setUpAll(() {
      Timezone.ensureInitialized();
    });

    setUp(() {
      Timezone.resetLocalCache();
    });

    test('Falls back to system params when timezoneName is null', () {
      final clock = FailClock();
      Context.setClock(clock);

      final tz = Timezone.local();

      // When null, it falls back to systemTime.timeZoneName
      expect(tz.name, equals(clock.now.timeZoneName));
      expect(tz.offset, equals(clock.now.timeZoneOffset));
    });

    test('Falls back to fixed offset when timezoneName is unknown', () {
      final clock = UnknownNameClock();
      Context.setClock(clock);

      final tz = Timezone.local();

      // Should preserve the unknown name
      expect(tz.name, equals('Mars/Cydonia'));
      expect(tz.offset, equals(clock.now.timeZoneOffset));
    });

    test('Falls back to UTC when timezone fetch crashes', () {
      final clock = ThrowingClock();
      Context.setClock(clock);

      final tz = Timezone.local();

      // Crash -> Catch -> Name is null -> Fallback to 'UTC'
      // Wait, no. If crash happens in TRY block, assignment to
      // systemTimezoneName fails (remains null).
      // BUT, the catch block just logs.
      // The code then proceeds.
      // systemTimezoneName is null.
      // So `name: systemTimezoneName ?? 'UTC'` kicks in.
      expect(tz.name, equals('UTC'));
      expect(tz.offset, equals(clock.now.timeZoneOffset));
    });

    // Regression test for issue #21: iOS sandbox prohibits Process.runSync.
    // clock_native.dart now uses DateTime.now().timeZoneName on iOS, which
    // is process-free. This test verifies that path resolves without throwing.
    test('Resolves timezone from DateTime.now().timeZoneName (iOS path)', () {
      final clock = IosFallbackClock();
      Context.setClock(clock);

      // Should not throw — and should produce a valid Timezone.
      expect(() => Timezone.local(), returnsNormally);
      final tz = Timezone.local();
      // The resolved offset must match the system offset.
      expect(tz.offset, equals(clock.now.timeZoneOffset));
    });
  });
}
