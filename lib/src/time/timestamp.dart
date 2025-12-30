import 'timezone.dart';

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
const _iso8601Formatter = "yyyy-MM-dd'T'HH:mm:ss.SSS''z_iso8601";

/// RFC 2822 / HTTP Date format
const _rfc2822Formatter = "EEE, dd MMM yyyy HH:mm:ss z_rfc2822";

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
  /// - Sub-seconds
  ///   Assuming 123456 microseconds:
  ///   - Milliseconds:
  ///     + 'SSS' (123), 'SS' (12), 'S' (1)
  ///   - Microseconds:
  ///    + 'FFF' (456), 'FF' (45), 'F' (4)
  /// - Timezone:
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

  /// [Timezone] configuration to use for the timestamp.
  ///
  /// Allows overriding the system's default time zone for
  /// consistent logging across different environments or for specific regional
  /// requirements. If not set, falls back to local system time zone.
  final Timezone? timezone;

  /// Maximum size of the [_formatterCache].
  static const int _maxCacheSize = 50;

  /// Static cache for parsed formatters
  /// (key: formatter string, value: segments).
  static final Map<String, List<_FormatSegment>> _formatterCache = {};

  /// Retrieves cached parsed formatter (if any) or caches and returns it.
  List<_FormatSegment> _getParsedFormatter() {
    if (formatter.isEmpty) {
      return const [];
    }
    if (!_formatterCache.containsKey(formatter)) {
      if (_formatterCache.length >= _maxCacheSize) {
        final firstKey = _formatterCache.keys.first;
        _formatterCache.remove(firstKey);
      }
      _formatterCache[formatter] = _parseFormatter(formatter);
    }

    return _formatterCache[formatter]!;
  }

  /// Dictionary of defined format tokens
  Map<String, String> get _tokenReplacements {
    final now = (timezone ?? Timezone.local()).now;
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    final String hourInTwelveHourFormat =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}';
    final resolvedTimezone = timezone ?? Timezone.local();
    final millisecondsStr = now.millisecond.toString().padLeft(3, '0');
    final microsecondsStr = now.microsecond.toString().padLeft(3, '0');

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
      // Sub-seconds related tokens.
      'SSS': millisecondsStr,
      'SS': millisecondsStr.substring(0, 2),
      'S': millisecondsStr.substring(0, 1),
      'FFF': microsecondsStr,
      'FF': microsecondsStr.substring(0, 2),
      'F': microsecondsStr.substring(0, 1),
      // Timezone related tokens.
      'z_iso8601': resolvedTimezone.iso8601OffsetLiteral,
      'z_rfc2822': resolvedTimezone.rfc2822OffsetLiteral,
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
              (nextCharacterCode >= 97 && nextCharacterCode <= 122) ||
              nextCharacterCode == 95 || // Underscore
              (nextCharacterCode >= 48 && nextCharacterCode <= 57)) {
            // Digits 0-9
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
          throw FormatException(
            'Unrecognized sequence of letters "$potentialToken" in timestamp'
            ' format: "$format".'
            ' Non-token words must be escaped with single quotes.',
          );
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
