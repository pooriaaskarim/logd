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
const _iso8601Formatter = "yyyy-MM-dd'T'HH:mm:ss.SSS''z";

/// RFC 2822 / HTTP Date format
const _rfc2822Formatter = 'EEE, dd MMM yyyy HH:mm:ss z';

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
  const Timestamp({required this.formatter, this.timezone});

  /// No TimeStamp
  factory Timestamp.none() => const Timestamp(formatter: '');

  /// ISO 8601 [Timestamp] (identical to RFC 3339:
  /// yyyy-MM-dd'T'HH:mm:ss.SSS''Z).
  factory Timestamp.iso8601({final Timezone? timezone}) => Timestamp(
        formatter: _iso8601Formatter,
        timezone: timezone,
      );

  /// RFC 3339 [Timestamp] (identical to ISO 8601:
  /// yyyy-MM-dd'T'HH:mm:ss.SSS''Z).
  factory Timestamp.rfc3339({final Timezone? timezone}) => Timestamp(
        formatter: _iso8601Formatter,
        timezone: timezone,
      );

  /// Timestamp in milliseconds since epoch.
  factory Timestamp.millisecondsSinceEpoch({final Timezone? timezone}) =>
      Timestamp(
        formatter: _epochFormatter,
        timezone: timezone,
      );

  /// RFC 2822 / HTTP Date format (e.g., "Thu, 14 Nov 2025 15:30:45 +0300").
  factory Timestamp.rfc2822({final Timezone? timezone}) => Timestamp(
        formatter: _rfc2822Formatter,
        timezone: timezone,
      );

  /// The format string defining the timestamp pattern.
  ///
  /// Intentions: This string allows users to specify a custom format for the
  /// timestamp output. It supports a variety of tokens for date, time, and
  /// timezone components, enabling flexible formatting tailored to specific
  /// needs, such as logging, reporting, or display purposes.
  ///
  /// Tokens are **case-sensitive** and must match exactly (e.g., 'yyyy' for
  /// full year, 'MM' for padded month).
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
  ///   + 'A' (AM/PM), 'a' (am/pm)
  ///   + 'mm' (52), 'm' (52),
  ///   + 'ss' (01), 's' (1)
  /// - Milliseconds:
  ///   + 'SSS' (136), 'SS' (13), 'S' (1)
  /// - Microseconds:
  ///   + 'FFFFF' (000136), 'FFFF' (001), 'FFF' (013), 'FF' (136), 'F' (136)
  /// - Timezone:
  ///   + 'z'   Standard Offset: ISO8601 or RFC2822 formatted timezone literal,
  ///   + 'Z'   (+03:30),
  ///   + 'ZZ'  (Asia/Tehran),
  ///   + 'ZZZ' (Asia/Tehran+03:30)
  ///
  ///
  /// **NOTE**: Non-token characters
  ///  + **Non-Alphabetical** e.g., (/), (:), ( ), (\n),
  ///
  /// or
  ///  + **Escaped single quoted words** e.g., (**'Time'**: hh:mm A),
  /// (**'on'** EEEE)
  ///
  /// are treated as literals and included in the output.
  ///
  /// How to use:
  /// - Set via constructor: Timestamp(formatter: 'yyyy/MM/dd HH:mm:ss ZZZ')
  ///   - Example: 'yyyy-MM-dd HH:mm:ss Z' → '2025-11-05 12:52:01 +03:30'
  ///   - Example: 'hh:mm a ZZZ' → '11:13 pm'
  ///   - Example: "'Time': hh:mm A" → 'Time: 11:13 PM'
  ///   - Example: "'on': EEEE" → 'on Wednesday'
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
  /// - Set via constructor: Timestamp(timezone: Timezone.utc)
  /// - Affects timezone tokens like 'Z', 'ZZ', 'ZZZ'.
  final Timezone? timezone;

  /// Retrieves cached parsed formatter (if any) or caches and returns it.
  List<_FormatSegment> _getParsedFormatter() {
    if (formatter.isEmpty) {
      return const [];
    }
    return Time._formatterCache
        .putIfAbsent(formatter, () => _parseFormatter(formatter));
  }

  /// Dictionary of defined format tokens
  Map<String, String> get _tokenReplacements {
    final now = (timezone ?? Timezone.local()).now;
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    final String hourInTwelveHourFormat =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}';
    final resolvedTimezone = timezone ?? Timezone.local();

    return <String, String>{
      // Date related tokens.
      'yyyy': now.year.toString().padLeft(4, '0'),
      'yy': (now.year % 100).toString().padLeft(2, '0'),
      'MMMM': _monthNames[now.month - 1],
      'MMM': _abbreviatedMonthNames[now.month - 1],
      'MM': now.month.toString().padLeft(2, '0'),
      'M': now.month.toString(),
      'dd': now.day.toString().padLeft(2, '0'),
      'd': now.day.toString(),
      'EEEE': _weekdayNames[now.weekday - 1],
      'EEE': _abbreviatedWeekdayNames[now.weekday - 1],
      'EE': now.weekday.toString().padLeft(2, '0'),
      'E': now.weekday.toString(),
      // Time related tokens.
      'HH': now.hour.toString().padLeft(2, '0'),
      'H': now.hour.toString(),
      'hhhh': '${hourInTwelveHourFormat.padLeft(2, '0')}$ampm',
      'hhh': '$hourInTwelveHourFormat$ampm',
      'hh': hourInTwelveHourFormat.padLeft(2, '0'),
      'h': hourInTwelveHourFormat,
      'A': ampm,
      'a': ampm.toLowerCase(),
      'mm': now.minute.toString().padLeft(2, '0'),
      'm': now.minute.toString(),
      'ss': now.second.toString().padLeft(2, '0'),
      's': now.second.toString(),
      'SSS': now.millisecond.toString().padLeft(3, '0'),
      'SS': (now.millisecond ~/ 10).toString().padLeft(2, '0'),
      'S': (now.millisecond ~/ 100).toString(),
      'FFFFFF': now.microsecond.toString().padLeft(6, '0'),
      'FFFFF': now.microsecond.toString().padLeft(5, '0'),
      'FFFF': now.microsecond.toString().padLeft(4, '0'),
      'FFF': now.microsecond.toString().padLeft(3, '0'),
      'FF': now.microsecond.toString().padLeft(2, '0'),
      'F': now.microsecond.toString(),
      // Timezone related tokens.
      'z': resolvedTimezone.standardOffsetLiteral(
        isIso8601: formatter == _iso8601Formatter,
        isRFC2822: formatter == _rfc2822Formatter,
      ),
      'Z': resolvedTimezone.offsetLiteral,
      'ZZ': resolvedTimezone.name,
      'ZZZ': resolvedTimezone.name + resolvedTimezone.offsetLiteral,
    };
  }

  /// Available format tokens.
  Set<String> get _knownTokens => _tokenReplacements.keys.toSet();

  List<_FormatSegment> _parseFormatter(final String format) {
    final segments = <_FormatSegment>[];
    final formatRunes = format.runes.toList();
    int index = 0;
    while (index < formatRunes.length) {
      final currentCharacterCode = formatRunes[index];
      final currentChar = String.fromCharCode(currentCharacterCode);
      if (currentChar == "'") {
        // Handle quoted literal
        final literalBuffer = StringBuffer();
        bool closed = false;
        index++; // Skip opening '
        while (index < formatRunes.length) {
          final nextCharCode = formatRunes[index];
          final nextChar = String.fromCharCode(nextCharCode);
          if (nextChar == "'") {
            index++;
            if (index < formatRunes.length &&
                String.fromCharCode(formatRunes[index]) == "'") {
              literalBuffer.write("'");
              index++;
            } else {
              closed = true;
              break;
            }
          } else {
            literalBuffer.write(nextChar);
            index++;
          }
        }
        if (!closed) {
          throw FormatException(
            'Unclosed quote in timestamp format: "$format"',
          );
        }
        if (literalBuffer.isNotEmpty) {
          segments.add(_FormatSegment(literalBuffer.toString()));
        }
      } else if ((currentCharacterCode >= 65 && currentCharacterCode <= 90) ||
          (currentCharacterCode >= 97 && currentCharacterCode <= 122)) {
        // Buffer consecutive letters
        final tokenBuffer = StringBuffer(currentChar);
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
        final potentialToken = tokenBuffer.toString();
        if (_knownTokens.contains(potentialToken)) {
          segments.add(_FormatSegment(potentialToken, isToken: true));
        } else {
          segments.add(_FormatSegment(potentialToken));
        }
      } else {
        // Buffer literals (non-letters, non-quotes)
        final literalBuffer = StringBuffer(currentChar);
        index++;
        while (index < formatRunes.length) {
          final nextCharacterCode = formatRunes[index];
          final nextChar = String.fromCharCode(nextCharacterCode);
          if (!((nextCharacterCode >= 65 && nextCharacterCode <= 90) ||
                  (nextCharacterCode >= 97 && nextCharacterCode <= 122)) &&
              nextChar != "'") {
            literalBuffer.write(nextChar);
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

  String? getTimestamp() {
    if (formatter.isEmpty) {
      return null;
    }

    if (formatter == _epochFormatter) {
      return (timezone ?? Timezone.local())
          .now
          .millisecondsSinceEpoch
          .toString();
    }

    final parsedFormatter = _getParsedFormatter();

    final stringBuffer = StringBuffer();
    final tokenReplacements = _tokenReplacements;
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
