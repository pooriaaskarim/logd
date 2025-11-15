part of 'time.dart';

/// Local time for transitions (hour:minute).
class LocalTime {
  const LocalTime(this.hour, this.minute)
      : assert(hour >= 0 && hour <= 23, 'Hour must be 0-23'),
        assert(minute >= 0 && minute <= 59, 'Minute must be 0-59');

  final int hour;
  final int minute;

  Duration toDuration() => Duration(hours: hour, minutes: minute);
}

/// Rule for DST transition (month, weekday, instance, local time).
class DSTTransitionRule {
  const DSTTransitionRule({
    required this.month,
    required this.weekday,
    required this.instance,
    required this.at,
  })  : assert(month >= 1 && month <= 12, 'Month must be 1-12'),
        assert(
          weekday >= DateTime.monday && weekday <= DateTime.sunday,
          'Weekday must be 1 (Monday) to 7 (Sunday)',
        ),
        assert(
          instance == -1 || (instance >= 1 && instance <= 5),
          'Instance must be 1-5 or -1 (last)',
        );

  /// Month (1-12).
  final int month;

  /// Weekday (DateTime.monday=1 to sunday=7).
  final int weekday;

  /// Week instance (1-5, -1 for last).
  final int instance;

  /// Local time of transition.
  final LocalTime at;
}

/// Rule for Daylight Saving Time (DST) in a [Timezone].
class DSTZoneRule {
  const DSTZoneRule({
    required this.standardOffset,
    this.dstDelta = const Duration(hours: 1),
    this.start,
    this.end,
  }) : assert(
          start == null && end == null || start != null && end != null,
          'Provide both start and end for DST, or neither for fixed',
        );

  /// Standard (non-DST) offset from UTC.
  final Duration standardOffset;

  /// DST offset addition (usually +1 hour).
  final Duration dstDelta;

  /// DST start rule (null for no DST).
  final DSTTransitionRule? start;

  /// DST end rule (null for no DST).
  final DSTTransitionRule? end;
}

/// Common fixed offsets (name to literal).
final Map<String, String> commonTimezones = {
  // UTC (00:00)
  'UTC': '00:00',
  // Europe & Africa
  'Europe/London': '+00:00',
  'Africa/Accra': '+00:00',
  'Europe/Paris': '+01:00',
  'Europe/Berlin': '+01:00',
  'Africa/Cairo': '+02:00',
  'Europe/Kiev': '+02:00',
  'Europe/Moscow': '+03:00',
  'Africa/Johannesburg': '+02:00',
  // Asia
  'Asia/Riyadh': '+03:00',
  'Asia/Tehran': '+03:30',
  'Asia/Dubai': '+04:00',
  'Asia/Kabul': '+04:30',
  'Asia/Kolkata': '+05:30',
  'Asia/Kathmandu': '+05:45',
  'Asia/Dhaka': '+06:00',
  'Asia/Bangkok': '+07:00',
  'Asia/Singapore': '+08:00',
  'Asia/Seoul': '+09:00',
  'Asia/Tokyo': '+09:00',
  // Australia & Pacific
  'Australia/Eucla': '+08:45',
  'Australia/Adelaide': '+09:30',
  'Australia/Sydney': '+10:00',
  'Pacific/Auckland': '+12:00',
  'Pacific/Fiji': '+12:00',
  'Pacific/Chatham': '+12:45',
  // America
  'America/St_Johns': '-03:30',
  'America/Sao_Paulo': '-03:00',
  'America/New_York': '-05:00',
  'America/Chicago': '-06:00',
  'America/Mexico_City': '-06:00',
  'America/Denver': '-07:00',
  'America/Los_Angeles': '-08:00',
  'America/Anchorage': '-09:00',
  'Pacific/Marquesas': '-09:30',
  'Pacific/Honolulu': '-10:00',
  // Other Pacific/GMT
  'Pacific/Midway': '-11:00',
  'Etc/GMT+12': '-12:00',
};

/// Common DST rules for zones (based on 2025 patterns; gets updated).
///
/// Currently not planning to do runtime net calls, or use third-party
/// libraries, in favor of performance and maintainability.
/// [Timezone.custom()] is introduced for edge case scenarios if a
/// undefined Timezone is needed.
final Map<String, DSTZoneRule> commonDSTRules = {
  // No DST (fixed).
  'UTC':
      DSTZoneRule(standardOffset: TimezoneOffset.fromLiteral('00:00').offset),
  'Asia/Tehran':
      DSTZoneRule(standardOffset: TimezoneOffset.fromLiteral('+03:30').offset),
  'Asia/Kolkata':
      DSTZoneRule(standardOffset: TimezoneOffset.fromLiteral('+05:30').offset),
  'Asia/Tokyo':
      DSTZoneRule(standardOffset: TimezoneOffset.fromLiteral('+09:00').offset),
  'Asia/Dubai':
      DSTZoneRule(standardOffset: TimezoneOffset.fromLiteral('+04:00').offset),

  // North America (US/Canada).
  'America/New_York': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('-05:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: 2,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 11,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(2, 0),
    ),
  ),
  'America/Chicago': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('-06:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: 2,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 11,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(2, 0),
    ),
  ),
  'America/Los_Angeles': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('-08:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: 2,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 11,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(2, 0),
    ),
  ),

  // Europe.
  'Europe/Paris': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+01:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ), // UTC.
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ),
  ),
  'Europe/London': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+00:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ),
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ),
  ),
  'Europe/Berlin': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+01:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ),
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(1, 0),
    ),
  ),

  // Australia (observing states).
  'Australia/Sydney': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+10:00').offset,
    start: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 4,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(3, 0),
    ),
  ),
  'Australia/Adelaide': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+09:30').offset,
    start: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 4,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(3, 0),
    ),
  ),

  // New Zealand.
  'Pacific/Auckland': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+12:00').offset,
    start: const DSTTransitionRule(
      month: 9,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 4,
      weekday: DateTime.sunday,
      instance: 1,
      at: LocalTime(3, 0),
    ),
  ),

  // Israel.
  'Asia/Jerusalem': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+02:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.friday,
      instance: -1,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(2, 0),
    ),
  ),
  // Add more common as needed.
};

final _timezoneOffsetRegex = RegExp(
  '^(?:(?:[+-](?:1[0-4]|0[1-9]):[0-5][0-9])|[+-]?00:00)\$',
  caseSensitive: false,
  multiLine: false,
  unicode: true,
);

class TimezoneOffset {
  const TimezoneOffset._(this.offset);

  /// timezone Offset
  ///
  /// A string in the **±hh:mm** format.
  ///
  /// e.g.:
  /// 00:00 (UTC)
  /// -05:00 (New York)
  /// +04:00 (Oman)
  factory TimezoneOffset.fromLiteral(final String literal) {
    assert(
      _timezoneOffsetRegex.hasMatch(literal),
      'Invalid Offset Literal: $literal\n'
      'must be ±HH:MM where HH=01-14, MM=00-59,\n'
      'or (±)00:00 for UTC.',
    );
    final sign = literal.startsWith('-') ? -1 : 1;
    final part = literal.split(':');
    final offset = Duration(
      hours: int.parse(part[0]),
      minutes: sign * int.parse(part[1]),
    );
    return TimezoneOffset._(offset);
  }

  /// Offset duration from UTC.
  final Duration offset;
}

/// Timezone configuration.
///
/// [name] is the name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
/// [offset] is DST aware offset from "UTC+00:00".
///
/// [Timezone] handles DTC internally.
class Timezone {
  const Timezone._({
    required this.name,
    required final DSTZoneRule rule,
  }) : _rule = rule;

  /// System time zone.
  ///
  /// Tries to resolve to a DST-aware timezone base on the platform.
  /// if failed, falls back to fixed time zone with current system time zone.
  factory Timezone.local() {
    final systemTimezoneName = getSystemTimezoneName();
    if (commonTimezones.containsKey(systemTimezoneName)) {
      return Timezone.named(systemTimezoneName);
    }
    final offset = Time.timeProvider().timeZoneOffset;
    return Timezone._(
      name: systemTimezoneName,
      rule: DSTZoneRule(standardOffset: offset),
    );
  }

  /// UTC time zone (fixed).
  factory Timezone.utc() => const Timezone._(
        name: 'UTC',
        rule: DSTZoneRule(standardOffset: Duration.zero),
      );

  /// Fixed time zone from name and offset literal.
  @Deprecated('Use Timezone.custom() instead.')
  factory Timezone([
    final String name = 'UTC',
    final String offsetLiteral = '00:00',
  ]) =>
      Timezone._(
        name: name,
        rule: DSTZoneRule(
          standardOffset: TimezoneOffset.fromLiteral(offsetLiteral).offset,
        ),
      );

  /// Named (DST-aware) [Timezone] for common time zones,
  /// falls back to fixed if no rule.
  factory Timezone.named(final String name) {
    final rule = commonDSTRules[name] ??
        DSTZoneRule(
          standardOffset:
              TimezoneOffset.fromLiteral(commonTimezones[name] ?? '00:00')
                  .offset,
        );
    return Timezone._(name: name, rule: rule);
  }

  factory Timezone.custom({
    final String name = 'UTC',
    final String offsetLiteral = '00:00',
    final String? dstOffsetLiteral,
    final DSTTransitionRule? start,
    final DSTTransitionRule? end,
  }) {
    assert(
      (dstOffsetLiteral == null && start == null && end == null) ||
          (dstOffsetLiteral != null && start != null && end != null),
      'Set dstOffsetLiteral, start, and end for DST Timezones.',
    );
    final standardOffset = TimezoneOffset.fromLiteral(offsetLiteral).offset;
    if (dstOffsetLiteral == null) {
      return Timezone._(
        name: name,
        rule: DSTZoneRule(standardOffset: standardOffset),
      );
    } else {
      final dstOffset = TimezoneOffset.fromLiteral(dstOffsetLiteral).offset;
      final dstDelta = dstOffset - standardOffset;

      return Timezone._(
        name: name,
        rule: DSTZoneRule(
          standardOffset: standardOffset,
          dstDelta: dstDelta,
          start: start,
          end: end,
        ),
      );
    }
  }

  /// The name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
  ///
  /// This field is used in timestamp formatting for tokens like 'ZZ' or 'ZZZ'.
  final String name;

  /// DST rule (always non-null; start/end null for fixed).
  final DSTZoneRule _rule;

  DateTime get now {
    final utcNow = Time.timeProvider().toUtc();
    final offset = computeOffset(utcNow);
    return utcNow.add(offset);
  }

  /// Computes offset from UTC for a given date-time (dynamic for DST).
  Duration computeOffset(final DateTime utcDt) {
    if (_rule.start == null) {
      return _rule.standardOffset;
    }

    // Iterative computation to handle DST correctly
    var offset = _rule.standardOffset;
    var localDt = utcDt.add(offset);

    var start = _computeTransition(localDt.year, _rule.start!);
    var end = _computeTransition(localDt.year, _rule.end!);

    final isNorthern = _rule.start!.month < _rule.end!.month;
    var isDST = isNorthern
        ? localDt.isAfter(start) && localDt.isBefore(end)
        : localDt.isAfter(start) || localDt.isBefore(end);

    if (isDST) {
      offset += _rule.dstDelta;
      localDt = utcDt.add(offset);

      // Recompute with adjusted year if crossed boundary
      start = _computeTransition(localDt.year, _rule.start!);
      end = _computeTransition(localDt.year, _rule.end!);

      isDST = isNorthern
          ? localDt.isAfter(start) && localDt.isBefore(end)
          : localDt.isAfter(start) || localDt.isBefore(end);

      if (!isDST) {
        // Ambiguity (e.g., fall-back overlap): Default to standard
        offset = _rule.standardOffset;
      }
    } else {
      // Check for spring-forward gap: Assume DST and recheck
      final dstOffset = _rule.standardOffset + _rule.dstDelta;
      final localDtDst = utcDt.add(dstOffset);

      start = _computeTransition(localDtDst.year, _rule.start!);
      end = _computeTransition(localDtDst.year, _rule.end!);

      final isDSTAssumed = isNorthern
          ? localDtDst.isAfter(start) && localDtDst.isBefore(end)
          : localDtDst.isAfter(start) || localDtDst.isBefore(end);

      if (isDSTAssumed) {
        // In the gap: Use DST offset
        offset = dstOffset;
      }
    }

    return offset;
  }

  /// Computes transition DateTime for year and rule.
  DateTime _computeTransition(final int year, final DSTTransitionRule r) {
    int day = 1;
    if (r.instance > 0) {
      // Nth weekday.
      var current = DateTime(year, r.month, 1);
      int count = 0;
      while (current.month == r.month) {
        if (current.weekday == r.weekday) {
          count++;
          if (count == r.instance) {
            day = current.day;
            break;
          }
        }
        current = current.add(const Duration(days: 1));
      }
      if (count < r.instance) {
        throw ArgumentError(
          'No ${r.instance}th weekday ${r.weekday} in month ${r.month},'
          ' year $year',
        );
      }
    } else if (r.instance == -1) {
      // Last weekday
      var current = DateTime(year, r.month + 1, 0); // Last day of month
      while (current.weekday != r.weekday && current.month == r.month) {
        current = current.subtract(const Duration(days: 1));
      }
      if (current.month != r.month) {
        throw ArgumentError(
          'No last weekday ${r.weekday} in month ${r.month}, year $year',
        );
      }
      day = current.day;
    }

    return DateTime(year, r.month, day).add(r.at.toDuration());
  }

  /// Timezone offset.
  Duration get offset => computeOffset(Time.timeProvider());

  /// Timezone offset literal.
  String get offsetLiteral {
    final timezoneOffset = offset;
    final timezoneOffsetHours = timezoneOffset.inHours.abs();
    final timezoneOffsetMinutes = timezoneOffset.inMinutes.abs() % 60;
    final timezoneOffsetSign = timezoneOffset.isNegative ? '-' : '+';
    return '$timezoneOffsetSign'
        '${timezoneOffsetHours.toString().padLeft(2, '0')}:'
        '${timezoneOffsetMinutes.toString().padLeft(2, '0')}';
  }

  /// Standard offset literal
  String standardOffsetLiteral({
    final bool isIso8601 = false,
    final bool isRFC2822 = false,
  }) {
    assert(
      !isIso8601 || !isRFC2822,
      'Stick to one standard when retrieving timezone offset literal.',
    );

    final timezoneOffset = offset;
    if ((isIso8601 || isRFC2822) && timezoneOffset.inMinutes == 0) {
      return 'Z';
    }
    final timezoneOffsetHours = timezoneOffset.inHours.abs();
    final timezoneOffsetMinutes = timezoneOffset.inMinutes.abs() % 60;
    final timezoneOffsetSign = timezoneOffset.isNegative ? '-' : '+';
    return '$timezoneOffsetSign'
        '${timezoneOffsetHours.toString().padLeft(2, '0')}'
        '${!isRFC2822 ? ':' : ''}'
        '${timezoneOffsetMinutes.toString().padLeft(2, '0')}';
  }

  /// Cached system time zone name.
  static String? _systemTimezoneName;

  /// Retrieves the system time zone name, caching it.
  static String getSystemTimezoneName() => _systemTimezoneName ??=
      Time.timezoneNameFetcher() ?? Time.timeProvider().timeZoneName;

  @visibleForTesting
  static void clearSystemTimezoneCache() {
    _systemTimezoneName = null;
  }
}
