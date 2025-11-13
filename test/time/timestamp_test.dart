import 'package:logd/src/time/time.dart';
import 'package:test/test.dart';

void main() {
  // Fixed date: November 12, 2025, 14:30:45.678 (UTC base).
  final fixedDate = DateTime.utc(2025, 11, 12, 14, 30, 45, 678);

  setUp(() {
    Time.setTimeProvider(() => fixedDate);
  });

  tearDown(() {
    Time.setTimeProvider(DateTime.now);
  });

  group('Timestamp Formatting - Basic Tokens', () {
    test('Formats full year and short year', () {
      const ts = Timestamp(formatter: 'yyyy yy');
      expect(ts.getTimestamp(), '2025 25');
    });

    test('Formats month names and numbers', () {
      const ts = Timestamp(formatter: 'MMMM MMM MM M');
      expect(ts.getTimestamp(), 'November Nov 11 11');
    });

    test('Formats day with and without padding', () {
      const ts = Timestamp(formatter: 'dd d');
      expect(ts.getTimestamp(), '12 12');
    });

    test('Formats 24-hour time with and without padding', () {
      const ts = Timestamp(formatter: 'HH H mm m ss s');
      expect(ts.getTimestamp(), '14 14 30 30 45 45');
    });

    test('Includes literal characters', () {
      const ts = Timestamp(formatter: 'yyyy/MM/dd HH:mm:ss');
      expect(ts.getTimestamp(), '2025/11/12 14:30:45');
    });
  });

  group('Timestamp Formatting - 12-Hour and AM/PM', () {
    test('Formats 12-hour with padding and AM/PM', () {
      const ts = Timestamp(formatter: 'hhhh hhh hh h a');
      expect(ts.getTimestamp(), '02PM 2PM 02 2 PM');
    });

    test('Handles noon and midnight', () {
      final midnight = DateTime.utc(2025, 11, 12, 0, 0, 0);
      Time.setTimeProvider(() => midnight);
      const tsMidnight = Timestamp(formatter: 'hh a');
      expect(tsMidnight.getTimestamp(), '12 AM');

      final noon = DateTime.utc(2025, 11, 12, 12, 0, 0);
      Time.setTimeProvider(() => noon);
      const tsNoon = Timestamp(formatter: 'hh a');
      expect(tsNoon.getTimestamp(), '12 PM');
    });
  });

  group('Timestamp Formatting - Milliseconds', () {
    test('Formats milliseconds with varying padding', () {
      const ts = Timestamp(formatter: 'SSSS SSS SS S');
      expect(ts.getTimestamp(), '0678 678 67 6');
    });

    test('Handles low milliseconds', () {
      final lowMs = DateTime.utc(2025, 11, 12, 14, 30, 45, 5);
      Time.setTimeProvider(() => lowMs);
      const ts = Timestamp(formatter: 'SSSS SSS SS S');
      expect(ts.getTimestamp(), '0005 005 00 0');
    });
  });

  group('Timestamp Formatting - Timezone Tokens', () {
    test('Formats offset with Z', () {
      final ts = Timestamp(
        formatter: 'Z',
        timeZone: TimeZone('UTC', '00:00'),
      );
      expect(ts.getTimestamp(), '+00:00');

      final tsNegative = Timestamp(
        formatter: 'Z',
        timeZone: TimeZone('PST', '-08:00'),
      );
      expect(tsNegative.getTimestamp(), '-08:00');
    });

    test('Formats name with ZZ and combined with ZZZ', () {
      final ts = Timestamp(
        formatter: 'ZZ ZZZ',
        timeZone: TimeZone('Asia/Tehran', '+03:30'),
      );
      expect(ts.getTimestamp(), 'Asia/Tehran Asia/Tehran+03:30');
    });

    test('Falls back to local if no timezone provided', () {
      const ts = Timestamp(formatter: 'Z');
      // Fixed to UTC, so +00:00.
      expect(ts.getTimestamp(), '+00:00');
    });
  });

  group('Timestamp - Edge Cases and Errors', () {
    test('Returns null for empty or none formatter', () {
      const tsEmpty = Timestamp(formatter: '');
      expect(tsEmpty.getTimestamp(), isNull);

      final tsNone = Timestamp.none();
      expect(tsNone.getTimestamp(), isNull);
    });

    test('Throws FormatException on invalid tokens', () {
      const ts = Timestamp(formatter: 'invalid');
      expect(ts.getTimestamp, throwsFormatException);
    });

    test('Handles mixed valid/invalid', () {
      const ts = Timestamp(formatter: 'yyyy invalid');
      expect(ts.getTimestamp, throwsFormatException);
    });

    test('Treats non-letter characters as literals', () {
      const ts = Timestamp(formatter: 'yyyy-##-dd');
      expect(ts.getTimestamp(), '2025-##-12');
    });
  });
}
