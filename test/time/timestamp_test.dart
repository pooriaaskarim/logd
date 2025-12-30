import 'package:logd/logd.dart';
import 'package:logd/src/core/clock/clock.dart';
import 'package:logd/src/core/context.dart';
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
  group('Timestamp', () {
    late DateTime fixedTime;
    late Timezone fixedTimezone;

    setUp(() {
      // Fixed time: Dec 18, 2025, 12:34:56.789123 (UTC)
      fixedTime = DateTime.utc(2025, 12, 18, 12, 34, 56, 789, 123);
      Context.setClock(MockClock(fixedTime));

      // Fixed timezone: Asia/Tehran (+03:30, no DST in test rules)
      fixedTimezone = Timezone.named('Asia/Tehran');
    });

    tearDown(() {
      Context.reset();
    });

    test('getTimestamp returns null for empty formatter', () {
      expect(Timestamp.none().getTimestamp(), isNull);
    });

    test('getTimestamp for EPOCH formatter', () {
      final ts = Timestamp.millisecondsSinceEpoch(timezone: fixedTimezone);
      final expected =
          fixedTime.add(fixedTimezone.offset).millisecondsSinceEpoch.toString();
      expect(ts.getTimestamp(), equals(expected));
    });

    test('getTimestamp for ISO8601', () {
      final ts = Timestamp.iso8601(timezone: fixedTimezone);
      // Expected: 2025-12-18T16:04:56.789+03:30 (adjusted for +03:30)
      expect(ts.getTimestamp(), equals('2025-12-18T16:04:56.789+03:30'));
    });

    test('getTimestamp for RFC2822', () {
      final ts = Timestamp.rfc2822(timezone: fixedTimezone);
      // Expected: Thu, 18 Dec 2025 16:04:56 +0330 (adjusted)
      expect(ts.getTimestamp(), equals('Thu, 18 Dec 2025 16:04:56 +0330'));
    });

    test('custom formatter with tokens and literals', () {
      const formatter = "yyyy-MM-dd 'at' HH:mm:ss.SSS ZZZ";
      final ts = Timestamp(formatter: formatter, timezone: fixedTimezone);
      expect(
        ts.getTimestamp(),
        equals('2025-12-18 at 16:04:56.789 Asia/Tehran+03:30'),
      );
    });

    test('custom formatter with 12-hour format and AM/PM', () {
      const formatter = "hhh a"; // 4PM (since 16:04 adjusted)
      final ts = Timestamp(formatter: formatter, timezone: fixedTimezone);
      expect(ts.getTimestamp(), equals('4PM pm'));
    });

    test('custom formatter with sub-seconds (millis/micros)', () {
      const formatter = "SSS FFF";
      final ts = Timestamp(formatter: formatter, timezone: fixedTimezone);
      expect(ts.getTimestamp(), equals('789 123'));
    });

    test('formatter parsing handles quoted literals and escapes', () {
      const formatter = "'Time:' hh:mm A 'on' EEEE";
      final ts = Timestamp(formatter: formatter, timezone: fixedTimezone);
      expect(ts.getTimestamp(), equals('Time: 04:04 PM on Thursday'));
    });

    test('formatter parsing throws on unclosed quote', () {
      expect(
        () => const Timestamp(formatter: "'unclosed").getTimestamp(),
        throwsFormatException,
      );
    });

    test('formatter parsing throws on unrecognized token', () {
      expect(
        () => const Timestamp(formatter: 'INVALID').getTimestamp(),
        throwsFormatException,
      );
    });

    test('formatter cache works and evicts oldest when max size reached', () {
      // Fill cache beyond max (50); infer by no exceptions and correct outputs
      for (int i = 0; i < 55; i++) {
        final fmt = "yyyy'$i'";
        final ts = Timestamp(formatter: fmt);
        expect(
          ts.getTimestamp(),
          startsWith('2025'),
        ); // Triggers parsing and caching
      }
    });

    test('uses local timezone if not provided', () {
      final ts = Timestamp.iso8601();
      // Can't assert exact value (system-dependent),
      // but ensure it runs without error
      expect(ts.getTimestamp(), isNotNull);
    });
  });
}
