part of 'time.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _abbreviatedMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _abbreviatedWeekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// ISO 8601 [Timestamp] (identical to RFC 3339).
const _iso8601Formatter = 'yyyy-MM-ddTHH:mm:ss.SSSZ';

/// RFC 2822 / HTTP Date format
const _rfc2822Formatter = 'EEE, dd MMM yyyy HH:mm:ss Z';

/// Timestamp in milliseconds since epoch.
const _epochFormatter = 'EPOCH';

/// Internal segment for parsed formatter (literal or token).
class _FormatSegment {
  const _FormatSegment(this.value, {this.isToken = false});

  final String value;
  final bool isToken;
}

/// A class for formatting timestamps with customizable patterns and timezone
/// support.
class Timestamp {
  const Timestamp({required this.formatter, this.timeZone});

  /// No TimeStamp
  factory Timestamp.none() => const Timestamp(formatter: '');

  /// ISO 8601 [Timestamp] (identical to RFC 3339: yyyy-MM-ddTHH:mm:ssZ).
  factory Timestamp.iso8601({final Timezone? timeZone}) => Timestamp(
        formatter: _iso8601Formatter,
        timeZone: timeZone,
      );

  /// RFC 3339 [Timestamp] (identical to ISO 8601: yyyy-MM-ddTHH:mm:ssZ).
  factory Timestamp.rfc3339({final Timezone? timeZone}) => Timestamp(
        formatter: _iso8601Formatter,
        timeZone: timeZone,
      );

  /// Timestamp in milliseconds since epoch.
  factory Timestamp.millisecondsSinceEpoch({final Timezone? timeZone}) =>
      Timestamp(
        formatter: _epochFormatter,
        timeZone: timeZone,
      );

  /// RFC 2822 / HTTP Date format (e.g., "Thu, 14 Nov 2025 15:30:45 +0300").
  factory Timestamp.rfc2822({final Timezone? timeZone}) => Timestamp(
        formatter: _rfc2822Formatter,
        timeZone: timeZone,
      );

  /// The format string defining the timestamp pattern.
  ///
  /// Intentions: This string allows users to specify a custom format for the
  /// timestamp output. It supports a variety of tokens for date, time, and
  /// timezone components, enabling flexible formatting tailored to specific
  /// needs, such as logging, reporting, or display purposes.
  /// Tokens are **case-sensitive** and must match exactly (e.g., 'yyyy' for
  /// full year, 'MM' for padded month).
  /// Non-token characters (e.g., '/', ':', ' ', '\n') are treated as literals
  /// and included in the output.
  ///
  /// Supported tokens:
  /// - Date:
  ///   + 'yyyy' (2025), 'yy' (25),\n
  ///   + 'MMMM' (November),'MMM' (Nov), 'MM' (11), 'M' (11),
  ///   + 'dd' (05), 'd' (5)
  ///   + 'EEEE' (Wednesday), 'EEE' (Wed), 'EE' (03), 'E' (3)
  /// - Time:
  ///   + 'HH' (14), 'H' (14),
  ///   + 'hhhh' (02AM), 'hhh' (2AM),'hh' (02), 'h' (2),
  ///     + 'a' AM/PM
  ///   + 'mm' (52), 'm' (52),
  ///   + 'ss' (01), 's' (1)
  /// - Milliseconds:
  ///   + 'SSS' (136), 'SS' (13), 'S' (1)
  /// - Microseconds:
  ///   + 'FFFFF' (000136), 'FFFF' (001), 'FFF' (013), 'FF' (136), 'F' (136)
  /// - Timezone:
  ///   + 'Z'   (+03:30),
  ///   + 'ZZ'  (Asia/Tehran),
  ///   + 'ZZZ' (Asia/Tehran+03:30)
  ///
  /// How to use:
  /// - Set via constructor: Timestamp(formatter: 'yyyy/MM/dd HH:mm:ss ZZZ')
  ///   - Example: 'yyyy-MM-dd HH:mm:ss Z' → '2025-11-05 12:52:01 +03:30'
  ///   - Example: 'hh:mm a ZZZ' → '11:13 PM'
  /// - If null or empty, no timestamp is generated.
  /// - Invalid tokens throw FormatException for safety.
  final String formatter;

  /// The time zone configuration to use for the timestamp.
  ///
  /// Intentions: Allows overriding the system's default time zone for
  /// consistent logging across different environments or for specific regional
  /// requirements. If not set, falls back to local system time zone.
  ///
  /// How to use:
  /// - Use predefined: Timezone.local (default), Timezone.utc
  /// - Custom: Timezone(name: 'PST', offsetLiteral: '-08:00', // DST)
  /// - Set via constructor: Timestamp(timeZone: Timezone.utc)
  /// - Affects timezone tokens like 'Z', 'ZZ', 'ZZZ'.
  final Timezone? timeZone;

  List<_FormatSegment> _getParsedFormatter() {
    if (formatter.isEmpty) {
      return const [];
    }
    return Time.formatterCache
        .putIfAbsent(formatter, () => _parseFormatter(formatter));
  }

  List<_FormatSegment> _parseFormatter(final String format) {
    final segments = <_FormatSegment>[];
    final formatRunes = format.runes.toList();
    int index = 0;
    while (index < formatRunes.length) {
      final currentCharacterCode = formatRunes[index];
      if ((currentCharacterCode >= 65 && currentCharacterCode <= 90) ||
          (currentCharacterCode >= 97 && currentCharacterCode <= 122)) {
        final tokenBuffer =
            StringBuffer(String.fromCharCode(currentCharacterCode));
        index++;
        while (index < formatRunes.length) {
          final nextCharacterCode = formatRunes[index];
          if ((nextCharacterCode >= 65 && nextCharacterCode <= 90) ||
              (nextCharacterCode >= 97 && nextCharacterCode <= 122)) {
            tokenBuffer.write(String.fromCharCode(nextCharacterCode));
            index++;
          } else {
            break;
          }
        }
        segments.add(_FormatSegment(tokenBuffer.toString(), isToken: true));
      } else {
        final literalBuffer =
            StringBuffer(String.fromCharCode(currentCharacterCode));
        index++;
        while (index < formatRunes.length) {
          final nextCharacterCode = formatRunes[index];
          if (!((nextCharacterCode >= 65 && nextCharacterCode <= 90) ||
              (nextCharacterCode >= 97 && nextCharacterCode <= 122))) {
            literalBuffer.write(String.fromCharCode(nextCharacterCode));
            index++;
          } else {
            break;
          }
        }
        segments.add(_FormatSegment(literalBuffer.toString()));
      }
    }
    return segments;
  }

  DateTime get _currentDateTime {
    final dateTime = Time.timeProvider();
    if (timeZone == null) {
      return dateTime;
    } else {
      return dateTime.toUtc().add(timeZone?.offset ?? Duration.zero);
    }
  }

  String? getTimestamp() {
    if (formatter.isEmpty) {
      return null;
    }
    final ampm = _currentDateTime.hour < 12 ? 'AM' : 'PM';
    final String hourInTwelveHourFormat =
        '${_currentDateTime.hour % 12 == 0 ? 12 : _currentDateTime.hour % 12}';
    final resolvedTimeZone = timeZone ?? Timezone.local();

    if (formatter == _iso8601Formatter) {
      return '${_currentDateTime.year.toString().padLeft(4, '0')}'
          '-${_currentDateTime.month.toString().padLeft(2, '0')}'
          '-${_currentDateTime.day.toString().padLeft(2, '0')}'
          'T${_currentDateTime.hour.toString().padLeft(2, '0')}'
          ':${_currentDateTime.minute.toString().padLeft(2, '0')}'
          ':${_currentDateTime.second.toString().padLeft(2, '0')}'
          '.${_currentDateTime.millisecond.toString().padLeft(3, '0')}'
          '${resolvedTimeZone.offsetLiteral}';
    } else if (formatter == _epochFormatter) {
      return _currentDateTime.millisecondsSinceEpoch.toString();
    }

    final tokenReplacements = <String, String>{
      // Date related tokens.
      'yyyy': _currentDateTime.year.toString().padLeft(4, '0'),
      'yy': (_currentDateTime.year % 100).toString().padLeft(2, '0'),
      'MMMM': _monthNames[_currentDateTime.month - 1],
      'MMM': _abbreviatedMonthNames[_currentDateTime.month - 1],
      'MM': _currentDateTime.month.toString().padLeft(2, '0'),
      'M': _currentDateTime.month.toString(),
      'dd': _currentDateTime.day.toString().padLeft(2, '0'),
      'd': _currentDateTime.day.toString(),
      'EEEE': _weekdayNames[_currentDateTime.weekday - 1],
      'EEE': _abbreviatedWeekdayNames[_currentDateTime.weekday - 1],
      'EE': _currentDateTime.weekday.toString().padLeft(2, '0'),
      'E': _currentDateTime.weekday.toString(),
      // Time related tokens.
      'HH': _currentDateTime.hour.toString().padLeft(2, '0'),
      'H': _currentDateTime.hour.toString(),
      'hhhh': '${hourInTwelveHourFormat.padLeft(2, '0')}$ampm',
      'hhh': '$hourInTwelveHourFormat$ampm',
      'hh': hourInTwelveHourFormat.padLeft(2, '0'),
      'h': hourInTwelveHourFormat,
      'a': ampm,
      'mm': _currentDateTime.minute.toString().padLeft(2, '0'),
      'm': _currentDateTime.minute.toString(),
      'ss': _currentDateTime.second.toString().padLeft(2, '0'),
      's': _currentDateTime.second.toString(),
      'SSS': _currentDateTime.millisecond.toString().padLeft(3, '0'),
      'SS': (_currentDateTime.millisecond ~/ 10).toString().padLeft(2, '0'),
      'S': (_currentDateTime.millisecond ~/ 100).toString(),
      'FFFFF': _currentDateTime.microsecond.toString().padLeft(5, '0'),
      'FFFF': _currentDateTime.microsecond.toString().padLeft(4, '0'),
      'FFF': _currentDateTime.microsecond.toString().padLeft(3, '0'),
      'FF': _currentDateTime.microsecond.toString().padLeft(2, '0'),
      'F': _currentDateTime.microsecond.toString(),
      // Timezone related tokens.
      'Z': resolvedTimeZone.offsetLiteral,
      'ZZ': resolvedTimeZone.name,
      'ZZZ': resolvedTimeZone.name + resolvedTimeZone.offsetLiteral,
    };

    final parsedFormatter = _getParsedFormatter();

    final stringBuffer = StringBuffer();
    for (final segment in parsedFormatter) {
      if (segment.isToken) {
        final token = segment.value;
        if (tokenReplacements.containsKey(token)) {
          stringBuffer.write(tokenReplacements[token]);
        } else {
          throw FormatException(
            'Unrecognized token "$token" in timestamp format: "$formatter"',
          );
        }
      } else {
        stringBuffer.write(segment.value);
      }
    }
    return stringBuffer.toString();
  }
}
