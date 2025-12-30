import 'package:logd/src/core/clock/clock.dart';
import 'package:logd/src/core/context.dart';
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
  group('Timezone', () {
    late DateTime fixedUtcTime;

    setUp(() {
      // Fixed UTC time for deterministic tests
      fixedUtcTime = DateTime.utc(2025, 3, 10, 12, 0);
      Context.setClock(MockClock(fixedUtcTime));
    });

    tearDown(() {
      Context.reset();
    });

    test('utc() returns UTC with zero offset', () {
      final tz = Timezone.utc();
      expect(tz.name, equals('UTC'));
      expect(tz.offset, equals(Duration.zero));
      expect(tz.now, equals(fixedUtcTime));
    });

    test('named() returns known timezones with rules', () {
      final tz = Timezone.named('Asia/Tehran');
      expect(tz.name, equals('Asia/Tehran'));
      expect(tz.offset.inMinutes, equals(3 * 60 + 30)); // +03:30
    });

    test('named() throws on unknown name', () {
      expect(() => Timezone.named('Unknown'), throwsArgumentError);
    });

    test('custom() creates fixed timezone without DST', () {
      final tz = Timezone(name: 'Custom', offset: '+02:00');
      expect(tz.name, equals('Custom'));
      expect(tz.offset.inHours, equals(2));
    });

    test('custom() creates DST timezone', () {
      const startRule = DSTTransitionRule(
        month: 3,
        weekday: DateTime.sunday,
        instance: 2,
        at: LocalTime(2, 0),
      );

      const endRule = DSTTransitionRule(
        month: 11,
        weekday: DateTime.sunday,
        instance: 1,
        at: LocalTime(2, 0),
      );

      final tz = Timezone(
        name: 'CustomDST',
        offset: '-05:00',
        dstOffsetDelta: '+01:00',
        dstStart: startRule,
        dstEnd: endRule,
      );
      expect(tz.offset.inHours, equals(-4));
    });

    test('custom() asserts on inconsistent DST params', () {
      expect(
        () => Timezone(
          name: 'Invalid',
          offset: '00:00',
          dstOffsetDelta: '+01:00',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('local() resolves to known DST if available, else fixed with warning',
        () {
      // Mock known name
      Context.setClock(MockClock(fixedUtcTime, 'America/New_York'));
      final tzKnown = Timezone.local();
      expect(tzKnown.name, equals('America/New_York'));

      // Mock unknown (triggers print warning, uses fixed)
      Context.setClock(MockClock(fixedUtcTime, 'Unknown'));
      final tzFallback = Timezone.local();
      expect(tzFallback.name, equals('Unknown'));
      expect(tzFallback.offset, isNotNull); // System offset
    });

    test('offset and now handle northern hemisphere DST', () {
      final tz = Timezone.named('America/New_York'); // -05:00 std, +1 DST
      // Before DST start
      // (March 10 is after 2nd Sun in Mar? Adjust date for test)
      Context.setClock(
        MockClock(DateTime.utc(2025, 3, 9, 6, 59)),
      ); // Before transition
      expect(tz.offset.inHours, equals(-5));

      // During DST
      Context.setClock(MockClock(DateTime.utc(2025, 6, 1)));
      expect(tz.offset.inHours, equals(-4)); // -05:00 +1

      // After DST end
      Context.setClock(MockClock(DateTime.utc(2025, 11, 2, 6, 0))); // After end
      expect(tz.offset.inHours, equals(-5));
    });

    test('offset and now handle southern hemisphere DST', () {
      final tz =
          Timezone.named('Australia/Sydney'); // +10:00 std, +1 DST (Oct-Apr)
      // During DST (Jan)
      Context.setClock(MockClock(DateTime.utc(2025, 1, 1)));
      expect(tz.offset.inHours, equals(11));

      // Before DST start (Sep, non-DST)
      Context.setClock(MockClock(DateTime.utc(2025, 9, 1)));
      expect(tz.offset.inHours, equals(10));
    });

    test('boundary semantics: inclusive start, exclusive end', () {
      final tz = Timezone.named('America/New_York');
      // Exact start transition (2nd Sun Mar, 2:00 local -> 3:00)
      final startUtc =
          DateTime.utc(2025, 3, 9, 7, 0); // 2:00 EST -> 3:00 EDT (UTC 7:00)
      Context.setClock(MockClock(startUtc));
      expect(tz.offset.inHours, equals(-4)); // Inclusive start: DST

      // Exact end transition (1st Sun Nov, 2:00 local back to 1:00)
      final endUtc = DateTime.utc(2025, 11, 3, 6, 0); // Adjust for exact
      Context.setClock(MockClock(endUtc));
      expect(tz.offset.inHours, equals(-5)); // Exclusive end: standard
    });

    test('offsetLiteral extensions', () {
      final tz = Timezone.named('Asia/Tehran');
      expect(tz.offsetLiteral, equals('+03:30'));
      expect(tz.iso8601OffsetLiteral, equals('+03:30'));
      expect(tz.rfc2822OffsetLiteral, equals('+0330'));

      final utc = Timezone.utc();
      expect(utc.iso8601OffsetLiteral, equals('Z'));
      expect(utc.rfc2822OffsetLiteral, equals('Z'));
    });

    test('TimezoneOffset.fromLiteral parses valid literals', () {
      expect(
        TimezoneOffset.fromLiteral('+03:30').offset.inMinutes,
        equals(210),
      );
      expect(
        TimezoneOffset.fromLiteral('-05:00').offset.inMinutes,
        equals(-300),
      );
      expect(TimezoneOffset.fromLiteral('00:00').offset, equals(Duration.zero));
    });

    test('TimezoneOffset.fromLiteral asserts on invalid', () {
      expect(
        () => TimezoneOffset.fromLiteral('+15:00'),
        throwsA(isA<AssertionError>()),
      ); // HH >14
      expect(
        () => TimezoneOffset.fromLiteral('+03:61'),
        throwsA(isA<AssertionError>()),
      ); // MM >59
    });

    // Indirect coverage for privates:
    // _daysInMonth, _getWeekday, _computeTransition
    test('internal date calculations via DST transitions', () {
      final tz = Timezone.named('Europe/Paris'); // Last Sun Mar/Oct, 1:00 UTC
      // March has 31 days, last Sun in Mar 2025 is 30th
      Context.setClock(
        MockClock(DateTime.utc(2025, 3, 30, 0, 59)),
      ); // Before start
      expect(tz.offset.inHours, equals(1));

      Context.setClock(
        MockClock(
          DateTime.utc(
            2025,
            3,
            30,
            1,
            0,
          ),
        ),
      ); // At start (UTC 1:00 -> 3:00 local)
      expect(tz.offset.inHours, equals(2));
    });
  });

  group('DST transitions', () {
    test('Europe/Paris northern hemisphere - before/after start', () {
      final tz = Timezone.named('Europe/Paris');
      // Last Sun Mar 2025: 30th
      // Transition at UTC 01:00 (local 02:00 CET to 03:00 CEST)
      Context.setClock(MockClock(DateTime.utc(2025, 3, 30, 0, 59))); // Before
      expect(tz.offset.inHours, equals(1)); // Standard CET +01:00

      Context.setClock(MockClock(DateTime.utc(2025, 3, 30, 1, 0))); // At start
      expect(tz.offset.inHours, equals(2)); // DST CEST +02:00
    });

    test('Europe/Paris - before/after end', () {
      final tz = Timezone.named('Europe/Paris');
      // Last Sun Oct 2025: 26th
      // Transition at UTC 01:00 (local 03:00 CEST back to 02:00 CET)
      Context.setClock(
        MockClock(
          DateTime.utc(2025, 10, 26, 0, 59),
        ),
      ); // Before end (during DST)
      expect(tz.offset.inHours, equals(2));

      Context.setClock(MockClock(DateTime.utc(2025, 10, 26, 1, 0))); // At end
      expect(tz.offset.inHours, equals(1)); // Back to standard
    });

    test('Europe/London northern hemisphere - before/after start', () {
      final tz = Timezone.named('Europe/London');
      // Transition at UTC 01:00 (local 01:00 GMT to 02:00 BST)
      Context.setClock(MockClock(DateTime.utc(2025, 3, 30, 0, 59)));
      expect(tz.offset.inHours, equals(0)); // Standard GMT +00:00

      Context.setClock(MockClock(DateTime.utc(2025, 3, 30, 1, 0)));
      expect(tz.offset.inHours, equals(1)); // DST BST +01:00
    });

    test('Europe/London - before/after end', () {
      final tz = Timezone.named('Europe/London');
      // Transition at UTC 01:00 (local 02:00 BST back to 01:00 GMT)
      Context.setClock(MockClock(DateTime.utc(2025, 10, 26, 0, 59)));
      expect(tz.offset.inHours, equals(1));

      Context.setClock(MockClock(DateTime.utc(2025, 10, 26, 1, 0)));
      expect(tz.offset.inHours, equals(0));
    });

    test('Australia/Sydney southern hemisphere - during/non-DST periods', () {
      final tz = Timezone.named('Australia/Sydney');
      // Jan 1 2025: During DST (Oct 2024 - Apr 2025), +11:00
      Context.setClock(MockClock(DateTime.utc(2025, 1, 1)));
      expect(tz.offset.inHours, equals(11));

      // Jun 1 2025: Non-DST (after Apr end, before Oct start), +10:00
      Context.setClock(MockClock(DateTime.utc(2025, 6, 1)));
      expect(tz.offset.inHours, equals(10));
    });

    test('Australia/Sydney - before/after start boundary', () {
      final tz = Timezone.named('Australia/Sydney');
      // First Sun Oct 2025: 5th
      // Transition at local 02:00 AEST (+10:00)
      // to 03:00 AEDT (+11:00) = UTC 2025-10-04 16:00
      Context.setClock(MockClock(DateTime.utc(2025, 10, 4, 15, 59)));
      expect(tz.offset.inHours, equals(10));

      Context.setClock(MockClock(DateTime.utc(2025, 10, 4, 16, 0)));
      expect(tz.offset.inHours, equals(11));
    });

    test('Australia/Sydney - before/after end boundary', () {
      final tz = Timezone.named('Australia/Sydney');
      // First Sun Apr 2025: 6th
      // Transition at local 03:00 AEDT (+11:00) back
      // to 02:00 AEST (+10:00) = UTC 2025-04-05 16:00
      Context.setClock(MockClock(DateTime.utc(2025, 4, 5, 15, 59)));
      expect(tz.offset.inHours, equals(11));

      Context.setClock(MockClock(DateTime.utc(2025, 4, 5, 16, 0)));
      expect(tz.offset.inHours, equals(10));
    });

    test('Asia/Jerusalem - Friday-based start/end', () {
      final tz = Timezone.named('Asia/Jerusalem');
      // Last Fri Mar 2025: 28th
      // Transition at local 02:00 IST (+02:00)
      // to 03:00 IDT (+03:00) = UTC 2025-03-28 00:00
      Context.setClock(MockClock(DateTime.utc(2025, 3, 27, 23, 59)));
      expect(tz.offset.inHours, equals(2));

      Context.setClock(MockClock(DateTime.utc(2025, 3, 28, 0, 0)));
      expect(tz.offset.inHours, equals(3));
    });

    test('leap year Feb last Sunday transition (custom rule)', () {
      // Custom for Feb last Sun at 02:00 local, standard +00:00, DST +01:00
      const startRule = DSTTransitionRule(
        month: 2,
        weekday: DateTime.sunday,
        instance: -1,
        at: LocalTime(2, 0),
      );
      const endRule = DSTTransitionRule(
        // Dummy end
        month: 12,
        weekday: DateTime.monday,
        instance: 1,
        at: LocalTime(3, 0),
      );
      final tz = Timezone(
        name: 'TestLeap',
        offset: '00:00',
        dstOffsetDelta: '+01:00',
        dstStart: startRule,
        dstEnd: endRule,
      );

      // 2024 leap: Feb 29 days, last Sun Feb 25
      // Transition at UTC 02:00 (since +00:00, subtract 0)
      Context.setClock(MockClock(DateTime.utc(2024, 2, 25, 1, 59)));
      expect(tz.offset.inHours, equals(0));

      Context.setClock(MockClock(DateTime.utc(2024, 2, 25, 2, 0)));
      expect(tz.offset.inHours, equals(1));
    });

    test('non-leap year Feb last Sunday transition (custom rule)', () {
      // Same custom rule
      const startRule = DSTTransitionRule(
        month: 2,
        weekday: DateTime.sunday,
        instance: -1,
        at: LocalTime(2, 0),
      );
      const endRule = DSTTransitionRule(
        // Dummy
        month: 12,
        weekday: DateTime.monday,
        instance: 1,
        at: LocalTime(3, 0),
      );
      final tz = Timezone(
        name: 'TestNonLeap',
        offset: '00:00',
        dstOffsetDelta: '+01:00',
        dstStart: startRule,
        dstEnd: endRule,
      );

      // 2025 non-leap: Feb 28 days, last Sun Feb 23
      Context.setClock(MockClock(DateTime.utc(2025, 2, 23, 1, 59)));
      expect(tz.offset.inHours, equals(0));

      Context.setClock(MockClock(DateTime.utc(2025, 2, 23, 2, 0)));
      expect(tz.offset.inHours, equals(1));
    });

    test('throws on invalid instance (too high for month)', () {
      const startRule = DSTTransitionRule(
        month: 2, // Feb 2025: 4 Sundays
        weekday: DateTime.sunday,
        instance: 5, // No 5th
        at: LocalTime(0, 0),
      );
      final tz = Timezone(
        name: 'TestInvalid',
        offset: '00:00',
        dstOffsetDelta: '+01:00',
        dstStart: startRule,
        dstEnd: const DSTTransitionRule(
          month: 12,
          weekday: 1,
          instance: 1,
          at: LocalTime(0, 0),
        ),
      );
      Context.setClock(MockClock(DateTime.utc(2025, 1, 1)));
      expect(() => tz.offset, throwsArgumentError); // In _computeTransition
    });

    test('fixed timezone no DST', () {
      final tz = Timezone.named('Asia/Tehran');
      Context.setClock(MockClock(DateTime.utc(2025, 3, 30, 0, 0))); // Arbitrary
      expect(tz.offset.inMinutes, equals(210)); // +03:30 fixed

      Context.setClock(MockClock(DateTime.utc(2025, 10, 26, 0, 0)));
      expect(tz.offset.inMinutes, equals(210)); // No change
    });
  });
}
