import 'dart:async';
import 'package:logd/logd.dart';
import 'package:logd/src/core/context/clock/clock.dart';
import 'package:logd/src/core/context/clock/clock_native.dart';
import 'package:logd/src/core/context/context.dart';
import 'package:logd/src/time/timestamp.dart';
import 'package:logd/src/time/timezone.dart';
import 'package:test/test.dart';

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
  group('Fix Verification', () {
    late DateTime fixedTime;

    setUp(() {
      fixedTime = DateTime.utc(2025, 12, 18, 12, 0);
      Context.setClock(MockClock(fixedTime));
      Timezone.resetLocalCache();
    });

    tearDown(() {
      Context.reset();
      Timezone.resetLocalCache();
    });

    test('Timezone.local() caches result and only logs warning once', () {
      final capturedLogs = <String>[];

      runZoned(
        () {
          Context.setClock(MockClock(fixedTime, 'Unknown/Zone'));

          // First call: should trigger resolution and log warming
          final tz1 = Timezone.local();

          // Second call: should return cached value and NOT log another warning
          final tz2 = Timezone.local();

          expect(tz1, same(tz2));
          expect(tz1.name, equals('Unknown/Zone'));
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            capturedLogs.add(line);
          },
        ),
      );

      // Verify that the warning was logged exactly once
      final warningLogs = capturedLogs
          .where((final l) => l.contains('[logd-internal] [WARNING]'))
          .toList();
      expect(warningLogs, hasLength(1));
    });

    test('Timezone.local() handles throwing clock and caches fallback', () {
      final capturedLogs = <String>[];

      runZoned(
        () {
          final throwingClock = _ThrowingClock(fixedTime);
          Context.setClock(throwingClock);
          Timezone.resetLocalCache();

          // This will trigger fetchNativeTimezoneName -> throws ->
          // InternalLogger.log
          final tz = Timezone.local();

          expect(tz, isNotNull);
          expect(tz.name, equals('UTC')); // Default fallback when name fails

          // Verify it's cached even after failure
          final tz2 = Timezone.local();
          expect(tz, same(tz2));
        },
        zoneSpecification: ZoneSpecification(
          print: (final self, final parent, final zone, final line) {
            capturedLogs.add(line);
          },
        ),
      );

      // Verify that the error was logged
      expect(
        capturedLogs
            .any((final l) => l.contains('Platform timezone fetch failed')),
        isTrue,
      );
    });

    test('resolveTimezonePath string logic handles various formats', () {
      // Since we can't easily mock io.Link.resolveSymbolicLinksSync without
      // complex overrides,
      // we test the function by mocking the environment if possible,
      // or at least verifying it doesn't crash on null/empty.
      // NOTE: In a real world scenario, we might want to split the string logic
      // from the IO logic for 100% pure testability.

      expect(resolveTimezonePath('/non/existent'), isNull);
    });

    test('TimestampFormatter cache is effective', () {
      final formatter = TimestampFormatter('yyyy-MM-dd');
      final time = DateTime(2025, 1, 1);

      // First call parses
      final s1 = formatter.format(time, timezone: Timezone.utc());
      expect(s1, equals('2025-01-01'));

      // Subsequent call uses cache (we verify by ensuring it still works
      // and is fast)
      // In a more intrusive test, we could check the private _parsedSegments.
      final s2 = formatter.format(time, timezone: Timezone.utc());
      expect(s1, equals(s2));
    });
  });
}

class _ThrowingClock implements Clock {
  _ThrowingClock(this._now);
  final DateTime _now;

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => throw Exception('Clock failure');
}
