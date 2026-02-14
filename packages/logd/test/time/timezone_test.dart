import 'package:logd/src/core/context/clock/clock.dart';
import 'package:logd/src/core/context/context.dart';
import 'package:logd/src/time/timezone.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockClock implements Clock {
  const MockClock(this._now, [this._timezoneName]);
  final DateTime _now;
  final String? _timezoneName;

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => _timezoneName;
}

void main() {
  group('Timezone', () {
    late DateTime fixedUtcTime;

    setUpAll(() {
      // Ensure database is initialized for tests
      tz_data.initializeTimeZones();
    });

    setUp(() {
      // Fixed UTC time for deterministic tests
      fixedUtcTime = DateTime.utc(2025, 3, 10, 12, 0);
      Context.setClock(MockClock(fixedUtcTime));
      Timezone.resetLocalCache();
    });

    tearDown(() {
      Context.reset();
      Timezone.resetLocalCache();
    });

    test('utc returns UTC with zero offset', () {
      final tz = Timezone.utc();
      expect(tz.name, equals('UTC'));
      expect(tz.offset, equals(Duration.zero));
      expect(tz.now, equals(fixedUtcTime));
    });

    test('named() returns known IANA timezones', () {
      final tz = Timezone.named('Asia/Tehran');
      expect(tz.name, equals('Asia/Tehran'));
      // Iran abolished DST, so it should be +03:30 fixed
      expect(tz.offset.inMinutes, equals(210));
    });

    test('named() throws on unknown name', () {
      expect(
        () => Timezone.named('Unknown/City'),
        throwsA(isA<tz.LocationNotFoundException>()),
      );
    });

    test('local() resolves to named timezone if system name matches IANA', () {
      // Mock known name
      Context.setClock(MockClock(fixedUtcTime, 'America/New_York'));
      final tzKnown = Timezone.local();
      expect(tzKnown.name, equals('America/New_York'));
      expect(
        tzKnown.offset.inHours,
        equals(-4),
      ); // DST in March 2025 (started March 9)
    });

    test('local() falls back to fixed offset if system name unknown', () {
      // Mock unknown name, but fixed offset
      Context.setClock(MockClock(fixedUtcTime, 'System/Unknown'));
      final tzFallback = Timezone.local();
      // Should create a fixed timezone with the system name (or UTC if null)
      // Since our mock returns null offset (systemTime.timeZoneOffset uses real
      // system)
      // We can't easily mock DateTime.timeZoneOffset without a real timezone
      // change or override.
      // But MockClock.now returns a DateTime that is UTC (created with .utc).
      // So timeZoneOffset of a UTC date is 0.
      expect(tzFallback.name, equals('System/Unknown'));
      expect(tzFallback.offset, equals(Duration.zero));
    });

    test('local() implicitly initializes database if needed', () {
      // We can't easily un-initialize, but we can verify it doesn't crash
      final tz = Timezone.local();
      expect(tz, isNotNull);
    });

    test('offset and now handle DST transitions (America/New_York)', () {
      final tz = Timezone.named('America/New_York');
      // DST Rules for NY 2025:
      // Starts: March 9, 02:00 local (07:00 UTC) -> +1 hour
      // Ends: Nov 2, 02:00 local -> -1 hour

      // Before DST (std: -05:00)
      Context.setClock(
        MockClock(DateTime.utc(2025, 3, 9, 6, 59)),
      );
      expect(tz.offset.inHours, equals(-5));

      // After DST Start (dst: -04:00)
      Context.setClock(MockClock(DateTime.utc(2025, 3, 9, 7, 0)));
      expect(tz.offset.inHours, equals(-4));

      // Before DST End (dst: -04:00)
      // End is Nov 2 local 02:00. This is Nov 2 06:00 UTC
      // (during DST -4) -> 07:00 UTC?
      // Wait. 02:00 EDT (-4) is 06:00 UTC.
      // At 02:00 EDT clocks go back to 01:00 EST.
      // So 06:00 UTC is the instant it becomes 01:00 EST (-5).

      // 05:59 UTC -> 01:59 EDT (-4)
      Context.setClock(MockClock(DateTime.utc(2025, 11, 2, 5, 59)));
      expect(tz.offset.inHours, equals(-4));

      // 06:00 UTC -> 01:00 EST (-5)
      Context.setClock(MockClock(DateTime.utc(2025, 11, 2, 6, 0)));
      expect(tz.offset.inHours, equals(-5));
    });

    test('offsetLiteral extensions', () {
      final tz = Timezone.named('Asia/Tehran');
      expect(tz.offsetLiteral, equals('+03:30'));
      expect(tz.iso8601OffsetLiteral, equals('+03:30'));

      final utc = Timezone.utc();
      expect(utc.iso8601OffsetLiteral, equals('Z'));
    });
  });
}
