part of 'time.dart';

/// Configuration for time zone, including name and offset.
class TimeZone {
  /// Predefined local time zone.
  factory TimeZone.local() {
    final systemTimeZoneName = getSystemTimeZoneName();
    return TimeZone._(systemTimeZoneName, null);
  }

  /// Predefined UTC time zone.
  factory TimeZone.utc() =>
      const TimeZone._('UTC', TimeZoneOffset._(Duration.zero));

  /// Private constructor for TimeZone.
  const TimeZone._(this.name, this._offset);

  /// TimeZone with [name] and offset from [offsetLiteral]
  ///
  /// [offsetLiteral] is string in the **±hh:mm** format.
  ///
  /// e.g.:
  ///      00:00 (UTC)
  ///     -05:00 (New York)
  ///     +04:00 (Oman)
  factory TimeZone(final String? name, final String? offsetLiteral) =>
      TimeZone._(
        name,
        offsetLiteral == null
            ? null
            : TimeZoneOffset.fromLiteral(offsetLiteral),
      );

  /// The name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
  ///
  /// This field is used in timestamp formatting for tokens like 'ZZ' or 'ZZZ'.
  final String? name;

  /// Internal: offset object; not directly accessible.
  final TimeZoneOffset? _offset;

  /// The offset from UTC as a Duration.
  ///
  /// Calculated from the offset literal or system timezone.
  /// + Example: Duration(hours: -5) for New York.
  Duration? get offset => _offset?.offset;

  /// Internal: Cached system time zone name to avoid repeated expensive calls.
  static String? _systemTimeZoneName;

  /// Retrieves the system time zone name, caching it for performance.
  static String getSystemTimeZoneName() {
    _systemTimeZoneName ??= _fetchSystemTimeZoneName();
    return _systemTimeZoneName!;
  }

  static String _fetchSystemTimeZoneName() {
    try {
      if (io.Platform.isAndroid) {
        final processResult =
            io.Process.runSync('getprop', ['persist.sys.timezone']);
        final timeZoneString = processResult.stdout.toString().trim();
        if (timeZoneString.isNotEmpty) {
          return timeZoneString;
        }
      } else if (io.Platform.isIOS || io.Platform.isMacOS) {
        final processResult =
            io.Process.runSync('systemsetup', ['-gettimezone']);
        final regexMatch = RegExp('Time Zone: (.+)')
            .firstMatch(processResult.stdout.toString());
        if (regexMatch != null) {
          return regexMatch.group(1)!;
        }
      } else if (io.Platform.isLinux) {
        final timeZoneFile = io.File('/etc/timezone');
        if (timeZoneFile.existsSync()) {
          return timeZoneFile.readAsStringSync().trim();
        }
        final processResult = io.Process.runSync(
          'timedatectl',
          ['show', '--value', '--property=Timezone'],
        );
        final timeZoneString = processResult.stdout.toString().trim();
        if (timeZoneString.isNotEmpty) {
          return timeZoneString;
        }
      } else if (io.Platform.isWindows) {
        final processResult = io.Process.runSync(
          'powershell',
          ['-Command', '[System.TimeZoneInfo]::Local.Id'],
        );
        final timeZoneString = processResult.stdout.toString().trim();
        if (timeZoneString.isNotEmpty) {
          return timeZoneString;
        }
      }
    } catch (_) {
      throw UnimplementedError('Could not retrieve TimeZone from platform');
    }
    return 'UTC';
  }
}

final _regex = RegExp(
  '^(?:(?:[+-](?:1[0-4]|0[1-9]):[0-5][0-9])|00:00)\$',
  caseSensitive: false,
  multiLine: false,
  unicode: true,
);

class TimeZoneOffset {
  const TimeZoneOffset._(this.offset);

  /// TimeZone Offset
  ///
  /// A string in the **±hh:mm** format.
  ///
  /// e.g.:
  ///      00:00 (UTC)
  ///     -05:00 (New York)
  ///     +04:00 (Oman)
  factory TimeZoneOffset.fromLiteral(final String literal) {
    assert(
      _regex.hasMatch(literal),
      'Invalid Offset Literal: $literal',
    );
    final sign = literal.startsWith('-') ? -1 : 1;
    final part = literal.split(':');
    final offset = Duration(
      hours: int.parse(part[0]),
      minutes: sign * int.parse(part[1]),
    );
    return TimeZoneOffset._(offset);
  }

  /// Offset duration from UTC.
  final Duration offset;
}
