import 'package:meta/meta.dart';

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

/// Internal segment for parsed formatter (literal or token).
class _FormatSegment {
  const _FormatSegment(this.value, {this.isToken = false});

  final String value;
  final bool isToken;
}

/// A cache for [TimestampFormatter] instances.
///
/// This cache avoids re-parsing the same pattern multiple times by storing
/// and reusing [TimestampFormatter] instances.
@internal
class TimestampFormatterCache {
  const TimestampFormatterCache._();

  static const int _maxSize = 50;
  static final Map<String, TimestampFormatter> _cache = {};

  /// Gets a [TimestampFormatter] for the given [pattern] from the cache,
  /// or creates and caches a new one if it doesn't exist.
  static TimestampFormatter get(final String pattern) {
    if (!_cache.containsKey(pattern)) {
      if (_cache.length >= _maxSize) {
        final firstKey = _cache.keys.first;
        _cache.remove(firstKey);
      }
      _cache[pattern] = TimestampFormatter(pattern);
    }
    return _cache[pattern]!;
  }

  /// Clears the formatter cache.
  static void clear() => _cache.clear();
}

/// Internal formatter for converting DateTime to formatted strings.
///
/// This class handles pattern parsing and token replacement. It is used
/// internally by [Timestamp] and is not part of the public API.
class TimestampFormatter {
  /// [TimestampFormatter] with the given [pattern].
  const TimestampFormatter(this.pattern);

  /// The token based format pattern string.
  ///
  /// Tokens are **case-sensitive** and must match exactly.
  ///
  /// ### Date Tokens
  /// - **Year**: `yyyy` (2025), `yy` (25)
  /// - **Month**: `MMMM` (November), `MMM` (Nov), `MM` (11), `M` (11)
  /// - **Day**: `dd` (05), `d` (5)
  /// - **Weekday**: `EEEE` (Wednesday), `EEE` (Wed), `EE` (03), `E` (3)
  ///
  /// ### Time Tokens
  /// - **24-Hour**: `HH` (14), `H` (14)
  /// - **12-Hour**: `hhhh` (02AM), `hhh` (2AM), `hh` (02), `h` (2)
  /// - **AM/PM**: `A` (AM/PM), `a` (am/pm)
  /// - **Minutes**: `mm` (52), `m` (52)
  /// - **Seconds**: `ss` (01), `s` (1)
  ///
  /// ### Sub-Second Tokens
  /// - **Milliseconds**: `SSS` (123), `SS` (12), `S` (1)
  /// - **Microseconds**: `FFF` (456), `FF` (45), `F` (4)
  ///
  /// ### Timezone Tokens
  /// - `Z` (+03:30), `ZZ` (Asia/Tehran), `ZZZ` (Asia/Tehran+03:30)
  ///
  /// ## Literals and Escaping
  /// Non-alphabetical characters (e.g., `/`, `:`, ` `, `\n`) are treated as
  /// literals. To include text that contains letters, escape it with
  /// single quotes (e.g., `'Time:'`).
  final String pattern;

  /// ISO 8601 [Timestamp] (identical to RFC 3339).
  static const iso8601Pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS''z_iso8601";

  /// RFC 2822 / HTTP Date format
  static const rfc2822Pattern = "EEE, dd MMM yyyy HH:mm:ss z_rfc2822";

  /// Timestamp in milliseconds since epoch.
  static const epochPattern = 'EPOCH';

  /// Formats the given [time] using this formatter's pattern.
  ///
  /// Returns `null` if the pattern is empty.
  String? format(final DateTime time, {final Timezone? timezone}) {
    if (pattern.isEmpty) {
      return null;
    }

    if (pattern == epochPattern) {
      return time.millisecondsSinceEpoch.toString();
    }

    final parsedFormatter = _parseFormatter(pattern);
    final stringBuffer = StringBuffer();
    final tokenReplacements = _getReplacements(time, timezone);

    for (final segment in parsedFormatter) {
      if (segment.isToken) {
        final token = segment.value;
        if (tokenReplacements.containsKey(token)) {
          stringBuffer.write(tokenReplacements[token]);
        } else {
          throw FormatException(
            'Unrecognized token "$token" in timestamp format: "$pattern"',
          );
        }
      } else {
        stringBuffer.write(segment.value);
      }
    }
    return stringBuffer.toString();
  }

  /// Dictionary of defined format tokens.
  Map<String, String> _getReplacements(
    final DateTime time,
    final Timezone? timezone,
  ) {
    final ampm = time.hour < 12 ? 'AM' : 'PM';
    final String hourInTwelveHourFormat =
        '${time.hour % 12 == 0 ? 12 : time.hour % 12}';
    final resolvedTimezone = timezone ?? Timezone.local();
    final millisecondsStr = time.millisecond.toString().padLeft(3, '0');
    final microsecondsStr = time.microsecond.toString().padLeft(3, '0');

    return <String, String>{
      // Date related tokens.
      'yyyy': time.year.toString().padLeft(4, '0'),
      'yy': (time.year % 100).toString().padLeft(2, '0'),
      'MMMM': _monthNames[time.month - 1],
      'MMM': _abbreviatedMonthNames[time.month - 1],
      'MM': time.month.toString().padLeft(2, '0'),
      'M': time.month.toString(),
      'dd': time.day.toString().padLeft(2, '0'),
      'd': time.day.toString(),
      'EEEE': _weekdayNames[time.weekday - 1],
      'EEE': _abbreviatedWeekdayNames[time.weekday - 1],
      'EE': time.weekday.toString().padLeft(2, '0'),
      'E': time.weekday.toString(),
      // Time related tokens.
      'HH': time.hour.toString().padLeft(2, '0'),
      'H': time.hour.toString(),
      'hhhh': '${hourInTwelveHourFormat.padLeft(2, '0')}$ampm',
      'hhh': '$hourInTwelveHourFormat$ampm',
      'hh': hourInTwelveHourFormat.padLeft(2, '0'),
      'h': hourInTwelveHourFormat,
      'A': ampm,
      'a': ampm.toLowerCase(),
      'mm': time.minute.toString().padLeft(2, '0'),
      'm': time.minute.toString(),
      'ss': time.second.toString().padLeft(2, '0'),
      's': time.second.toString(),
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
  Set<String> get _knownTokens =>
      _getReplacements(DateTime.now(), null).keys.toSet();

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
}

/// A class for formatting timestamps with customizable patterns and timezone
/// support.
///
/// The [Timestamp] class allows you to define how timestamps are formatted
/// and which timezone they should use. It supports a wide variety of tokens
/// for date, time, and timezone components, enabling logging,
/// reporting, or displaying timestamps in various formats.
///
/// ## Basic Usage
///
/// ```dart
/// // Simple timestamp with default local timezone
/// final ts = Timestamp(formatter: 'yyyy-MM-dd HH:mm:ss');
/// print(ts.timestamp); // "2025-11-05 12:52:01"
///
/// // With specific timezone
/// final tsTehran = Timestamp(
///   formatter: 'yyyy-MM-dd HH:mm:ss Z',
///   timezone: Timezone.named('Asia/Tehran'),
/// );
/// print(tsTehran.timestamp); // "2025-11-05 12:52:01 +03:30"
/// ```
///
/// ## Supported Format Tokens
///
/// Tokens are **case-sensitive** and must match exactly.
///
/// ### Date Tokens
/// - **Year**:
///   - `yyyy` → Full year (2025)
///   - `yy` → Two-digit year (25)
/// - **Month**:
///   - `MMMM` → Full month name (November)
///   - `MMM` → Abbreviated month (Nov)
///   - `MM` → Zero-padded month (11)
///   - `M` → Month without padding (11)
/// - **Day**:
///   - `dd` → Zero-padded day (05)
///   - `d` → Day without padding (5)
/// - **Weekday**:
///   - `EEEE` → Full weekday name (Wednesday)
///   - `EEE` → Abbreviated weekday (Wed)
///   - `EE` → Zero-padded weekday number (03)
///   - `E` → Weekday number (3, where 1=Monday)
///
/// ### Time Tokens
/// - **24-Hour Format**:
///   - `HH` → Zero-padded hour (14)
///   - `H` → Hour without padding (14)
/// - **12-Hour Format**:
///   - `hhhh` → Padded hour with AM/PM (02AM)
///   - `hhh` → Hour with AM/PM (2AM)
///   - `hh` → Zero-padded hour (02)
///   - `h` → Hour without padding (2)
/// - **AM/PM**:
///   - `A` → Uppercase (AM, PM)
///   - `a` → Lowercase (am, pm)
/// - **Minutes**:
///   - `mm` → Zero-padded minutes (52)
///   - `m` → Minutes without padding (52)
/// - **Seconds**:
///   - `ss` → Zero-padded seconds (01)
///   - `s` → Seconds without padding (1)
///
/// ### Sub-Second Tokens
/// Assuming 123456 microseconds:
/// - **Milliseconds**:
///   - `SSS` → Full milliseconds (123)
///   - `SS` → First two digits (12)
///   - `S` → First digit (1)
/// - **Microseconds**:
///   - `FFF` → Full microseconds (456)
///   - `FF` → First two digits (45)
///   - `F` → First digit (4)
///
/// ### Timezone Tokens
/// - `Z` → Offset literal (+03:30)
/// - `ZZ` → Timezone name (Asia/Tehran)
/// - `ZZZ` → Name with offset (Asia/Tehran+03:30)
///
/// ## Literals and Escaping
///
/// Non-alphabetical characters (e.g., `/`, `:`, ` `, `\n`) are treated as
/// literals and included in the output as-is.
///
/// To include text that contains letters, escape it with single quotes:
///
/// ```dart
/// // Using literals
/// Timestamp(formatter: 'yyyy/MM/dd HH:mm:ss')
/// // Output: "2025/11/05 12:52:01"
///
/// // Using escaped text
/// Timestamp(formatter: "'Time:' hh:mm A")
/// // Output: "Time: 12:52 PM"
///
/// Timestamp(formatter: "'on' EEEE")
/// // Output: "on Wednesday"
/// ```
///
/// ## Factory Constructors
///
/// For common formats, use the provided factory constructors:
///
/// ```dart
/// // ISO 8601 / RFC 3339
/// Timestamp.iso8601()
/// // Output: "2025-12-18T16:04:56.789+03:30"
///
/// // RFC 2822 / HTTP Date
/// Timestamp.rfc2822()
/// // Output: "Thu, 18 Dec 2025 16:04:56 +0330"
///
/// // Unix epoch milliseconds
/// Timestamp.millisecondsSinceEpoch()
/// // Output: "1734530696789"
///
/// // No timestamp
/// Timestamp.none()
/// // Output: null
/// ```
///
/// ## Timezone Handling
///
/// The [timezone] parameter allows you to override the system's default
/// timezone. This is useful for:
/// - Consistent logging across different server locations
/// - Displaying times in a specific region regardless of server timezone
/// - File rotation with timezone-aware filenames
///
/// ```dart
/// // Server in UTC, but want timestamps in Tehran time
/// final ts = Timestamp(
///   formatter: 'yyyy-MM-dd HH:mm:ss Z',
///   timezone: Timezone.named('Asia/Tehran'),
/// );
/// ```
///
/// If [timezone] is not specified, the local system timezone is used.
///
/// ## Error Handling
///
/// - Empty pattern returns `null`
/// - Unclosed quotes throw [FormatException]
/// - Unrecognized tokens throw [FormatException]
///
/// ```dart
/// // This throws FormatException
/// Timestamp(formatter: "'unclosed").timestamp;
///
/// // This throws FormatException
/// Timestamp(formatter: 'INVALID_TOKEN').timestamp;
/// ```
class Timestamp {
  /// The [formatter] parameter is a pattern string that defines how the
  /// timestamp should be formatted. See below for the supported tokens.
  ///
  /// The [timezone] parameter specifies which timezone to use for the
  /// timestamp. If not provided, the local system timezone is used.
  ///
  /// Example:
  /// ```dart
  /// final ts = Timestamp(
  ///   formatter: 'yyyy-MM-dd HH:mm:ss.SSS Z',
  ///   timezone: Timezone.named('Asia/Tehran'),
  /// );
  /// ```
  ///
  /// ## Supported Format Tokens
  ///
  /// Tokens are **case-sensitive** and must match exactly.
  ///
  /// ### Date Tokens
  /// - **Year**: `yyyy` (2025), `yy` (25)
  /// - **Month**: `MMMM` (November), `MMM` (Nov), `MM` (11), `M` (11)
  /// - **Day**: `dd` (05), `d` (5)
  /// - **Weekday**: `EEEE` (Wednesday), `EEE` (Wed), `EE` (03), `E` (3)
  ///
  /// ### Time Tokens
  /// - **24-Hour**: `HH` (14), `H` (14)
  /// - **12-Hour**: `hhhh` (02AM), `hhh` (2AM), `hh` (02), `h` (2)
  /// - **AM/PM**: `A` (AM/PM), `a` (am/pm)
  /// - **Minutes**: `mm` (52), `m` (52)
  /// - **Seconds**: `ss` (01), `s` (1)
  ///
  /// ### Sub-Second Tokens
  /// - **Milliseconds**: `SSS` (123), `SS` (12), `S` (1)
  /// - **Microseconds**: `FFF` (456), `FF` (45), `F` (4)
  ///
  /// ### Timezone Tokens
  /// - `Z` (+03:30), `ZZ` (Asia/Tehran), `ZZZ` (Asia/Tehran+03:30)
  ///
  /// ## Literals and Escaping
  /// Non-alphabetical characters (e.g., `/`, `:`, ` `, `\n`) are
  /// treated as literals.To include text that contains letters, escape it
  /// with single quotes (e.g., `'Time:'`).
  Timestamp({
    required final String formatter,
    this.timezone,
  }) : formatter = TimestampFormatterCache.get(formatter);

  /// Creates a [Timestamp] that produces no output.
  ///
  /// The [timestamp] getter will return `null`.
  factory Timestamp.none() => Timestamp(formatter: '');

  /// Creates a [Timestamp] using ISO 8601 format (identical to RFC 3339).
  ///
  /// Format: `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`
  ///
  /// Example output: `2025-12-18T16:04:56.789+03:30`
  factory Timestamp.iso8601({final Timezone? timezone}) => Timestamp(
        formatter: TimestampFormatter.iso8601Pattern,
        timezone: timezone,
      );

  /// Creates a [Timestamp] using RFC 3339 format (identical to ISO 8601).
  ///
  /// Format: `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`
  ///
  /// Example output: `2025-12-18T16:04:56.789+03:30`
  factory Timestamp.rfc3339({final Timezone? timezone}) => Timestamp(
        formatter: TimestampFormatter.iso8601Pattern,
        timezone: timezone,
      );

  /// Creates a [Timestamp] that outputs milliseconds since Unix epoch.
  ///
  /// Example output: `1734530696789`
  factory Timestamp.millisecondsSinceEpoch({final Timezone? timezone}) =>
      Timestamp(
        formatter: TimestampFormatter.epochPattern,
        timezone: timezone,
      );

  /// Creates a [Timestamp] using RFC 2822 / HTTP Date format.
  ///
  /// Format: `EEE, dd MMM yyyy HH:mm:ss z_rfc2822`
  ///
  /// Example output: `Thu, 18 Dec 2025 16:04:56 +0330`
  factory Timestamp.rfc2822({final Timezone? timezone}) => Timestamp(
        formatter: TimestampFormatter.rfc2822Pattern,
        timezone: timezone,
      );

  /// [TimestampFormatter] for formatting timestamps.
  final TimestampFormatter formatter;

  /// The timezone configuration for this timestamp.
  ///
  /// Allows overriding the system's default timezone for consistent logging
  /// across different environments or for specific regional requirements.
  ///
  /// If not set, falls back to the local system timezone.
  final Timezone? timezone;

  /// Gets the current timestamp using this configuration.
  ///
  /// Uses the configured [timezone] (or local if not set) to get the current
  /// time, then formats it using the formatter pattern.
  ///
  /// Returns `null` if the formatter pattern is empty.
  String? get timestamp =>
      formatter.format((timezone ?? Timezone.local()).now, timezone: timezone);
}
