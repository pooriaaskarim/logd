import 'package:logd/logd.dart';
import 'package:logd/src/core/clock/clock.dart';
import 'package:logd/src/core/context.dart';
import 'package:logd/src/time/timestamp.dart';
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
      TimestampFormatterCache.clear();
    });

    test('timestamp returns null for empty formatter', () {
      expect(Timestamp.none().timestamp, isNull);
    });

    test('timestamp for ISO8601', () {
      final ts = Timestamp.iso8601(timezone: fixedTimezone);
      expect(ts.timestamp, equals('2025-12-18T16:04:56.789+03:30'));
    });

    test('custom formatter with tokens and literals', () {
      const formatter = "yyyy-MM-dd 'at' HH:mm:ss.SSS ZZZ";
      final ts = Timestamp(formatter: formatter, timezone: fixedTimezone);
      expect(
        ts.timestamp,
        equals('2025-12-18 at 16:04:56.789 Asia/Tehran+03:30'),
      );
    });

    test('formatter parsing throws on unclosed quote', () {
      expect(
        () => Timestamp(formatter: "'unclosed").timestamp,
        throwsFormatException,
      );
    });

    test('formatter parsing throws on unrecognized token', () {
      expect(
        () => Timestamp(formatter: 'INVALID').timestamp,
        throwsFormatException,
      );
    });

    group('TimestampFormatterCache', () {
      test('reuses the same formatter instance for the same pattern', () {
        const pattern = 'yyyy-MM-dd';
        final f1 = TimestampFormatterCache.get(pattern);
        final f2 = TimestampFormatterCache.get(pattern);

        expect(f1, same(f2));
      });

      test('creates different instances for different patterns', () {
        final f1 = TimestampFormatterCache.get('yyyy-MM-dd');
        final f2 = TimestampFormatterCache.get('HH:mm:ss');

        expect(f1, isNot(same(f2)));
      });

      test('evicts the oldest entry when the cache limit is exceeded', () {
        // Cache limit is 50.
        final patterns = List.generate(50, (final i) => "pattern_$i");

        // Populate cache
        final firstInstance = TimestampFormatterCache.get(patterns[0]);
        for (final p in patterns.skip(1)) {
          TimestampFormatterCache.get(p);
        }

        // Current cache is full. Next one triggers eviction of the first one.
        TimestampFormatterCache.get('new_pattern');

        // Re-creating the first pattern should result in a new instance.
        final reCreatedInstance = TimestampFormatterCache.get(patterns[0]);
        expect(reCreatedInstance, isNot(same(firstInstance)));
      });

      test('clear removes all entries', () {
        const pattern = 'yyyy-MM-dd';
        final f1 = TimestampFormatterCache.get(pattern);
        TimestampFormatterCache.clear();
        final f2 = TimestampFormatterCache.get(pattern);

        expect(f1, isNot(same(f2)));
      });
    });
  });
}
