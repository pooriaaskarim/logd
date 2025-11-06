part of 'timestamp_formatter.dart';

/// Configuration for time zone, including name and offset.
class TimeZone {
  /// Predefined local time zone.
  factory TimeZone.local() => TimeZone._(getSystemTimeZoneName(), null);

  /// Predefined UTC time zone.
  factory TimeZone.utc() => TimeZone._('UTC', '+00:00');

  /// Creates a named time zone with offset.
  factory TimeZone.named(
    final String name,
    final String offsetLiteral,
  ) =>
      TimeZone._(name, offsetLiteral);

  /// Private constructor for TimeZone.
  TimeZone._(this.name, this.offsetLiteral)
      : _offset = offsetLiteral != null ? _TimeZoneOffset(offsetLiteral) : null;

  /// The name of the time zone (e.g., 'UTC', 'Asia/Kolkata'). If null, the system time zone name is used.
  final String? name;

  /// TimeZone Offset
  ///
  /// A string in the **±hh:mm** format.
  /// e.g.:
  ///      00:00 (UTC)
  ///     -05:00 (New York)
  ///     +04:00 (Oman)
  final String? offsetLiteral;

  /// TimeZoneOffset
  final _TimeZoneOffset? _offset;

  /// The offset from UTC.
  Duration? get offset => _offset?.offset;

  /// Cached system time zone name to avoid repeated expensive calls.
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

class _TimeZoneOffset {
  _TimeZoneOffset(this.offsetLiteral) {
    assert(
      _regex.hasMatch(offsetLiteral),
      'Invalid Offset Literal: $offsetLiteral',
    );

    final sign = offsetLiteral.startsWith('-') ? -1 : 1;
    final part = offsetLiteral.split(':');
    offset = Duration(
      hours: int.parse(part[0]),
      minutes: sign * int.parse(part[1]),
    );
  }

  final _regex = RegExp(
    '^(?:(?:[+-](?:1[0-4]|0[1-9]):[0-5][0-9])|00:00)\$',
    caseSensitive: false,
    multiLine: false,
    unicode: true,
  );

  /// TimeZone Offset
  ///
  /// A string in the **±hh:mm** format.
  /// e.g.:
  ///      00:00 (UTC)
  ///     -05:00 (New York)
  ///     +04:00 (Oman)
  final String offsetLiteral;

  /// Offset duration from UTC.
  late final Duration offset;
}
