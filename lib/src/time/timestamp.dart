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
  'December'
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
  'Dec'
];

/// A class for formatting timestamps with customizable patterns and timezone
/// support.
class Timestamp {
  const Timestamp({this.formatter, this.timeZone});

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
  /// - Time:
  ///   + 'HH' (14), 'H' (14),
  ///   + 'hhhh' (02AM), 'hhh' (2AM),'hh' (02), 'h' (2),
  ///     + 'a' AM/PM
  ///   + 'mm' (52), 'm' (52),
  ///   + 'ss' (01), 's' (1)
  /// - Milliseconds:
  ///   + 'SSSS' (1367), 'SSS' (136), 'SS' (13), 'S' (1)
  /// - Timezone:
  ///   + 'Z'   (+03:30),
  ///   + 'ZZ'  (Asia/Tehran),
  ///   + 'ZZZ' (Asia/Tehran+03:30)
  ///
  /// How to use:
  /// - Set via constructor: TimestampFormatter(formatter:
  /// 'yyyy/MM/dd HH:mm:ss ZZZ')
  ///   - Example: 'yyyy-MM-dd HH:mm:ss Z' → '2025-11-05 12:52:01 +03:30'
  ///   - Example: 'hh:mm a ZZZ' → '11:13 PM'
  /// - If null or empty, no timestamp is generated.
  /// - Invalid tokens throw FormatException for safety.
  final String? formatter;

  /// The time zone configuration to use for the timestamp.
  ///
  /// Intentions: Allows overriding the system's default time zone for
  /// consistent logging across different environments or for specific regional
  /// requirements. If not set, falls back to local system time zone.
  ///
  /// How to use:
  /// - Use predefined: TimeZone.local (default), TimeZone.utc
  /// - Custom: TimeZone.named('PST', Duration(hours: -8))
  /// - Set via constructor: TimestampFormatter(timeZone: TimeZone.utc)
  /// - Affects timezone tokens like 'Z', 'ZZ', 'ZZZ'.
  final TimeZone? timeZone;

  DateTime get _currentDateTime =>
      DateTime.now().toUtc().add(timeZone?.offset ?? Duration.zero);

  String? getTimestamp() {
    final formatString = formatter;
    if (formatString == null || formatString.isEmpty) {
      return null;
    }

    final milliseconds = _currentDateTime.millisecond;
    final ampm = _currentDateTime.hour < 12 ? 'AM' : 'PM';
    final String hourInTwelveHourFormat =
        '${_currentDateTime.hour % 12 == 0 ? 12 : _currentDateTime.hour % 12}'
        '$ampm';

    final resolvedTimeZone = timeZone ?? TimeZone.local();
    final timeZoneOffset =
        resolvedTimeZone.offset ?? _currentDateTime.timeZoneOffset;
    final timeZoneName = resolvedTimeZone.name ?? '';
    final timeZoneOffsetHours = timeZoneOffset.inHours.abs();
    final timeZoneOffsetMinutes = timeZoneOffset.inMinutes.abs() % 60;
    final offsetSign = timeZoneOffset.isNegative ? '-' : '+';

    final tokenReplacements = <String, String>{
      'yyyy': _currentDateTime.year.toString().padLeft(4, '0'),
      'yy': (_currentDateTime.year % 100).toString().padLeft(2, '0'),
      'MMMM': _monthNames[_currentDateTime.month - 1],
      'MMM': _abbreviatedMonthNames[_currentDateTime.month - 1],
      'MM': _currentDateTime.month.toString().padLeft(2, '0'),
      'M': _currentDateTime.month.toString(),
      'dd': _currentDateTime.day.toString().padLeft(2, '0'),
      'd': _currentDateTime.day.toString(),
      'HH': _currentDateTime.hour.toString().padLeft(2, '0'),
      'H': _currentDateTime.hour.toString(),
      'hhhh': hourInTwelveHourFormat.padLeft(4, '0'),
      'hhh': hourInTwelveHourFormat.padLeft(3, '0'),
      'hh': hourInTwelveHourFormat.padLeft(2, '0'),
      'h': hourInTwelveHourFormat,
      'a': ampm,
      'mm': _currentDateTime.minute.toString().padLeft(2, '0'),
      'm': _currentDateTime.minute.toString(),
      'ss': _currentDateTime.second.toString().padLeft(2, '0'),
      's': _currentDateTime.second.toString(),
      'SSSS': milliseconds.toString().padLeft(4, '0'),
      'SSS': milliseconds.toString().padLeft(3, '0'),
      'SS': (milliseconds ~/ 10).toString().padLeft(2, '0'),
      'S': (milliseconds ~/ 100).toString(),
      'Z':
          '$offsetSign${timeZoneOffsetHours.toString().padLeft(2, '0')}:${timeZoneOffsetMinutes.toString().padLeft(2, '0')}',
      'ZZ': timeZoneName,
      'ZZZ':
          '$timeZoneName$offsetSign${timeZoneOffsetHours.toString().padLeft(2, '0')}:${timeZoneOffsetMinutes.toString().padLeft(2, '0')}',
    };

    final stringBuffer = StringBuffer();
    final formatRunes = formatString.runes.toList();
    int index = 0;
    while (index < formatRunes.length) {
      final currentCharacter = String.fromCharCode(formatRunes[index]);
      final currentCharacterCode = currentCharacter.codeUnitAt(0);
      if ((currentCharacterCode >= 65 && currentCharacterCode <= 90) ||
          (currentCharacterCode >= 97 && currentCharacterCode <= 122)) {
        final tokenBuffer = StringBuffer(currentCharacter);
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
        final tokenString = tokenBuffer.toString();
        if (tokenReplacements.containsKey(tokenString)) {
          stringBuffer.write(tokenReplacements[tokenString]);
        } else {
          throw FormatException(
              'Unrecognized token "$tokenString" in timestamp format: "$formatString"');
        }
      } else {
        stringBuffer.write(currentCharacter);
        index++;
      }
    }
    return stringBuffer.toString();
  }
}
