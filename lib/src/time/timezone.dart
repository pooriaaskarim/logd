import 'package:meta/meta.dart';

import '../core/context/context.dart';
import '../logger/logger.dart';

/// Local wall time for transitions (hour:minute).
@immutable
class LocalTime {
  const LocalTime(this.hour, this.minute)
      : assert(hour >= 0 && hour <= 23, 'Hour must be 0-23'),
        assert(minute >= 0 && minute <= 59, 'Minute must be 0-59');

  final int hour;
  final int minute;

  Duration toDuration() => Duration(hours: hour, minutes: minute);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LocalTime &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Rule for DST transition.
@immutable
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

  /// Local wall time of transition.
  final LocalTime at;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is DSTTransitionRule &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          weekday == other.weekday &&
          instance == other.instance &&
          at == other.at;

  @override
  int get hashCode => Object.hash(month, weekday, instance, at);
}

/// Rule for Daylight Saving Time (DST) in a [Timezone].
@immutable
class DSTZoneRule {
  const DSTZoneRule({
    required this.standardOffset,
    this.dstDelta = const Duration(hours: 1),
    this.start,
    this.end,
  }) : assert(
          (start == null) == (end == null),
          'Both start and end must be provided for DST, or neither for fixed.',
        );

  /// Standard (non-DST) offset from UTC.
  final Duration standardOffset;

  /// DST offset addition (usually +1 hour).
  final Duration dstDelta;

  /// DST start rule (null for no DST).
  final DSTTransitionRule? start;

  /// DST end rule (null for no DST).
  final DSTTransitionRule? end;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is DSTZoneRule &&
          runtimeType == other.runtimeType &&
          standardOffset == other.standardOffset &&
          dstDelta == other.dstDelta &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(standardOffset, dstDelta, start, end);
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
final Map<String, DSTZoneRule> _commonDSTRules = {
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
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(3, 0),
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
      at: LocalTime(2, 0),
    ),
  ),
  'Europe/Berlin': DSTZoneRule(
    standardOffset: TimezoneOffset.fromLiteral('+01:00').offset,
    start: const DSTTransitionRule(
      month: 3,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(2, 0),
    ),
    end: const DSTTransitionRule(
      month: 10,
      weekday: DateTime.sunday,
      instance: -1,
      at: LocalTime(3, 0),
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
  '^(?:[+-](?:0[0-9]|1[0-4]):(?:00|15|30|45)|[+-]?00:00)\$',
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
@immutable
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
    String formatOffset(final Duration offset) {
      final hours = offset.inHours.abs();
      final minutes = offset.inMinutes.abs() % 60;
      final sign = offset.isNegative ? '-' : '+';
      return '$sign${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}';
    }

    final systemTime = Context.clock.now;
    final systemTimezoneName =
        Context.clock.timezoneName ?? systemTime.timeZoneName;

    if (_commonDSTRules.containsKey(systemTimezoneName)) {
      return Timezone.named(systemTimezoneName);
    }

    final systemTimezoneOffset = systemTime.timeZoneOffset;

    InternalLogger.log(
      LogLevel.warning,
      'Timezone "$systemTimezoneName" not found in DST rules. '
      'Using fixed offset ${formatOffset(systemTimezoneOffset)}. '
      'DST transitions will not be handled automatically. '
      'Consider using Timezone.named() with a supported timezone or '
      'Timezone() factory to define custom DST rules.',
    );

    return Timezone._(
      name: systemTimezoneName,
      rule: DSTZoneRule(standardOffset: systemTimezoneOffset),
    );
  }

  /// UTC time zone (fixed).
  factory Timezone.utc() => const Timezone._(
        name: 'UTC',
        rule: DSTZoneRule(standardOffset: Duration.zero),
      );

  /// Factory for custom [Timezone].
  ///
  /// + [name] is the name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
  /// + [offset] offset from "UTC+00:00". (e.g., '00:00' '+05:30').
  /// + [dstOffsetDelta] DST offset from [offset] (null for no DST).
  /// (e.g., '+01:00').
  /// + [dstStart] DST start rule (null for no DST).
  /// + [dstEnd] DST end rule (null for no DST).
  factory Timezone({
    required final String name,
    required final String offset,
    final String? dstOffsetDelta,
    final DSTTransitionRule? dstStart,
    final DSTTransitionRule? dstEnd,
  }) {
    assert(
      (dstOffsetDelta == null && dstStart == null && dstEnd == null) ||
          (dstOffsetDelta != null && dstStart != null && dstEnd != null),
      'Set dstOffsetDelta, dstStart, and dstEnd for DST Timezones.',
    );
    final offsetDuration = TimezoneOffset.fromLiteral(offset).offset;
    if (dstOffsetDelta == null) {
      return Timezone._(
        name: name,
        rule: DSTZoneRule(standardOffset: offsetDuration),
      );
    } else {
      final dstOffsetDuration =
          TimezoneOffset.fromLiteral(dstOffsetDelta).offset;

      return Timezone._(
        name: name,
        rule: DSTZoneRule(
          standardOffset: offsetDuration,
          dstDelta: dstOffsetDuration,
          start: dstStart,
          end: dstEnd,
        ),
      );
    }
  }

  /// Named (DST-aware) [Timezone] for common time zones.
  ///
  ///   ## UTC (00:00)
  ///   + 'UTC'                  - 00:00
  ///   ## Europe & Africa
  ///   + 'Europe/London'        - +00:00
  ///   + 'Africa/Accra'         - +00:00
  ///   + 'Europe/Paris'         - +01:00
  ///   + 'Europe/Berlin'        - +01:00
  ///   + 'Africa/Cairo'         - +02:00
  ///   + 'Europe/Kiev'          - +02:00
  ///   + 'Europe/Moscow'        - +03:00
  ///   + 'Africa/Johannesburg'  - +02:00
  ///   ## Asia
  ///   + 'Asia/Riyadh'          - +03:00
  ///   + 'Asia/Tehran'          - +03:30
  ///   + 'Asia/Dubai'           - +04:00
  ///   + 'Asia/Kabul'           - +04:30
  ///   + 'Asia/Kolkata'         - +05:30
  ///   + 'Asia/Kathmandu'       - +05:45
  ///   + 'Asia/Dhaka'           - +06:00
  ///   + 'Asia/Bangkok'         - +07:00
  ///   + 'Asia/Singapore'       - +08:00
  ///   + 'Asia/Seoul'           - +09:00
  ///   + 'Asia/Tokyo'           - +09:00
  ///   ## Australia & Pacific
  ///   + 'Australia/Eucla'      - +08:45
  ///   + 'Australia/Adelaide'   - +09:30
  ///   + 'Australia/Sydney'     - +10:00
  ///   + 'Pacific/Auckland'     - +12:00
  ///   + 'Pacific/Fiji'         - +12:00
  ///   + 'Pacific/Chatham'      - +12:45
  ///   ## America
  ///   + 'America/St_Johns'     - -03:30
  ///   + 'America/Sao_Paulo'    - -03:00
  ///   + 'America/New_York'     - -05:00
  ///   + 'America/Chicago'      - -06:00
  ///   + 'America/Mexico_City'  - -06:00
  ///   + 'America/Denver'       - -07:00
  ///   + 'America/Los_Angeles'  - -08:00
  ///   + 'America/Anchorage'    - -09:00
  ///   + 'Pacific/Marquesas'    - -09:30
  ///   + 'Pacific/Honolulu'     - -10:00
  ///   // Other Pacific/GMT
  ///   + 'Pacific/Midway'       - -11:00
  ///   + 'Etc/GMT+12'           - -12:00
  factory Timezone.named(final String name) {
    if (_commonDSTRules.containsKey(name)) {
      final rule = _commonDSTRules[name] ??
          DSTZoneRule(
            standardOffset:
                TimezoneOffset.fromLiteral(commonTimezones[name] ?? '00:00')
                    .offset,
          );
      return Timezone._(name: name, rule: rule);
    }
    throw ArgumentError.value(
      name,
      'name',
      'Unknown timezone name. Supported timezones include: '
          '${_commonDSTRules.keys.take(5).join(", ")}, ... '
          'See commonDSTRules and commonTimezones for full list.',
    );
  }

  /// The name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
  ///
  /// This field is used in timestamp formatting for tokens like 'ZZ' or 'ZZZ'.
  final String name;

  /// DST rule (always non-null; start/end null for fixed).
  final DSTZoneRule _rule;

  /// Returns the current time in this timezone.
  DateTime get now {
    final utcNow = Context.clock.now.toUtc();
    final currentOffset = _computeOffset(utcNow);

    final localInstant = utcNow.add(currentOffset);

    return localInstant;
  }

  /// Timezone offset.
  Duration get offset => _computeOffset(Context.clock.now.toUtc());

  int _daysInMonth(final int year, final int month) {
    final nextMonth = DateTime.utc(year, month + 1, 0);
    return nextMonth.day;
  }

  int _getWeekday(final int year, final int month, final int day) =>
      DateTime.utc(year, month, day).weekday;
  // int _getWeekday(final int year, final int month, final int day) {
  //   int m = month;
  //   int y = year;
  //
  //   // Zeller's congruence treats Jan/Feb as months 13/14 of previous year
  //   if (m == 1 || m == 2) {
  //     m += 12;
  //     y--;
  //   }
  //
  //   final int century = y ~/ 100;
  //   final int yearOfCentury = y % 100;
  //
  //   // Zeller's formula
  //   final int zellerH = (day +
  //           (13 * (m + 1) ~/ 5) +
  //           yearOfCentury +
  //           (yearOfCentury ~/ 4) +
  //           (century ~/ 4) +
  //           (5 * century)) %
  //       7;
  //
  //   // Zeller's h: 0=Sat, 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri
  //   // Dart weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  //   // Mapping: (h + 5) % 7 + 1
  //   //   h=0 (Sat) → 5+1=6 ✓
  //   //   h=1 (Sun) → 6+1=7 ✓
  //   //   h=2 (Mon) → 0+1=1 ✓
  //   return ((zellerH + 5) % 7) + 1;
  // }

  /// Computes transition DateTime (as UTC instant) for year and rule, using
  /// the pre-transition local offset.
  DateTime _computeTransition(
    final int year,
    final DSTTransitionRule r,
    final Duration offsetFromUTC,
  ) {
    int day = 1;
    if (r.instance > 0) {
      int count = 0;
      final int maxDay = _daysInMonth(year, r.month);
      for (int d = 1; d <= maxDay; d++) {
        if (_getWeekday(year, r.month, d) == r.weekday) {
          count++;
          if (count == r.instance) {
            day = d;
            break;
          }
        }
      }
      if (count < r.instance) {
        throw ArgumentError(
          'No ${r.instance}th weekday ${r.weekday} in month ${r.month},'
          ' year $year.',
        );
      }
    } else if (r.instance == -1) {
      final int maxDay = _daysInMonth(year, r.month);
      for (int d = maxDay; d >= 1; d--) {
        if (_getWeekday(year, r.month, d) == r.weekday) {
          day = d;
          break;
        }
      }
      if (day == 1) {
        throw ArgumentError(
          'No last weekday ${r.weekday} in month ${r.month}, year $year',
        );
      }
    }

    final localTransitionTime = DateTime.utc(
      year,
      r.month,
      day,
      r.at.hour,
      r.at.minute,
    );

    return localTransitionTime.subtract(offsetFromUTC);
  }

  /// Computes offset from UTC for a given [DateTime].
  ///
  /// Returns [Duration] representing how far ahead/behind UTC this timezone is
  /// at the specified instant, accounting for DST if applicable.
  ///
  /// **DST Transition Handling:**
  /// - Northern Hemisphere (start < end month): DST is [start, end)
  /// within same year
  /// - Southern Hemisphere (start > end month): DST wraps year boundary
  ///   - Uses previous year's start and current year's end for dates before
  ///   end month
  ///   - Uses current year's start and next year's end for dates after
  ///   start month
  ///
  /// **Boundary Semantics:**
  /// - Start transition instant: First moment of DST (inclusive)
  /// - End transition instant: First moment of standard time (exclusive of DST)
  Duration _computeOffset(final DateTime utcDt) {
    if (_rule.start == null || _rule.end == null) {
      return _rule.standardOffset;
    }

    final year = utcDt.year;
    final isSouthernHemisphere = _rule.start!.month > _rule.end!.month;

    if (isSouthernHemisphere) {
      // Southern Hemisphere: DST spans year boundary
      // Check two possible DST periods:
      // 1. Previous year's start → Current year's end
      // 2. Current year's start → Next year's end

      final start1 = _computeTransition(
        year - 1,
        _rule.start!,
        _rule.standardOffset,
      );
      final end1 = _computeTransition(
        year,
        _rule.end!,
        _rule.standardOffset + _rule.dstDelta,
      );

      if ((utcDt.isAtSameMomentAs(start1) || utcDt.isAfter(start1)) &&
          utcDt.isBefore(end1)) {
        return _rule.standardOffset + _rule.dstDelta;
      }

      // Period 2
      final start2 = _computeTransition(
        year,
        _rule.start!,
        _rule.standardOffset,
      );
      final end2 = _computeTransition(
        year + 1,
        _rule.end!,
        _rule.standardOffset + _rule.dstDelta,
      );

      if ((utcDt.isAtSameMomentAs(start2) || utcDt.isAfter(start2)) &&
          utcDt.isBefore(end2)) {
        return _rule.standardOffset + _rule.dstDelta;
      }

      return _rule.standardOffset;
    } else {
      // Northern Hemisphere: DST within same year
      final startTransitionUtc = _computeTransition(
        year,
        _rule.start!,
        _rule.standardOffset,
      );
      final endTransitionUtc = _computeTransition(
        year,
        _rule.end!,
        _rule.standardOffset + _rule.dstDelta,
      );
      final isDST = (utcDt.isAtSameMomentAs(startTransitionUtc) ||
              utcDt.isAfter(startTransitionUtc)) &&
          utcDt.isBefore(endTransitionUtc);
      final result =
          isDST ? _rule.standardOffset + _rule.dstDelta : _rule.standardOffset;
      return result;
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Timezone &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _rule == other._rule;

  @override
  int get hashCode => Object.hash(name, _rule);
}

extension OffsetLiteralExt on Timezone {
  /// Timezone offset literal.
  String get offsetLiteral {
    final current = offset;
    final timezoneOffsetHours = current.inHours.abs();
    final timezoneOffsetMinutes = current.inMinutes.abs() % 60;
    final timezoneOffsetSign = current.isNegative ? '-' : '+';
    return '$timezoneOffsetSign'
        '${timezoneOffsetHours.toString().padLeft(2, '0')}:'
        '${timezoneOffsetMinutes.toString().padLeft(2, '0')}';
  }

  /// ISO8601 offset literal
  String get iso8601OffsetLiteral {
    final currentOffset = offset;
    if (currentOffset.inMinutes == 0) {
      return 'Z';
    }
    final timezoneOffsetHours = currentOffset.inHours.abs();
    final timezoneOffsetMinutes = currentOffset.inMinutes.abs() % 60;
    final timezoneOffsetSign = currentOffset.isNegative ? '-' : '+';
    return '$timezoneOffsetSign'
        '${timezoneOffsetHours.toString().padLeft(2, '0')}'
        ':'
        '${timezoneOffsetMinutes.toString().padLeft(2, '0')}';
  }

  /// RFC2822 offset literal
  String get rfc2822OffsetLiteral {
    final currentOffset = offset;
    if (currentOffset.inMinutes == 0) {
      return 'Z';
    }
    final timezoneOffsetHours = currentOffset.inHours.abs();
    final timezoneOffsetMinutes = currentOffset.inMinutes.abs() % 60;
    final timezoneOffsetSign = currentOffset.isNegative ? '-' : '+';
    return '$timezoneOffsetSign'
        '${timezoneOffsetHours.toString().padLeft(2, '0')}'
        '${timezoneOffsetMinutes.toString().padLeft(2, '0')}';
  }
}
