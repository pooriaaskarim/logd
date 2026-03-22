import 'package:meta/meta.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/context/context.dart';
import '../logger/logger.dart';

/// Timezone configuration using IANA Time Zone Database.
///
/// Wraps [tz.Location] to provide timezone calculations.
@immutable
class Timezone {
  /// System time zone.
  ///
  /// Tries to resolve to a DST-aware timezone based on the platform.
  /// If failed, falls back to fixed time zone with current system time zone.
  /// System time zone.
  ///
  /// Tries to resolve to a DST-aware timezone based on the platform.
  /// If failed, falls back to fixed time zone with current system time zone.
  factory Timezone.local() {
    if (_localCache != null) {
      return _localCache!;
    }

    // Ensure initialized if not already, to make sure we can find locations.
    if (!_isInitialized) {
      // We implicitly initialize here for convenience if the user forgot.
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }

    final systemTime = Context.clock.now;
    String? systemTimezoneName;
    try {
      systemTimezoneName =
          Context.clock.timezoneName ?? systemTime.timeZoneName;
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'Platform timezone fetch failed',
        error: e,
        stackTrace: s,
      );
    }

    if (systemTimezoneName != null) {
      try {
        final location = tz.getLocation(systemTimezoneName);
        return _localCache = Timezone._(location);
      } catch (e, s) {
        InternalLogger.log(
          LogLevel.error,
          'Timezone "$systemTimezoneName" not found in database.',
          error: e,
          stackTrace: s,
        );
      }
    }

    final systemTimezoneOffset = systemTime.timeZoneOffset;

    InternalLogger.log(
        LogLevel.warning,
        'Timezone "$systemTimezoneName" not found in database. '
        'Using fixed offset ${systemTimezoneOffset.formatOffset}. '
        'DST transitions will not be handled automatically. '
        'Ensure Timezone.ensureInitialized() is called or the name is valid.');

    return _localCache = Timezone._fixed(
      systemTimezoneOffset,
      name: systemTimezoneName ?? 'UTC',
    );
  }

  /// UTC time zone (fixed).
  factory Timezone.utc() => Timezone._(tz.UTC);

  /// Named (DST-aware) [Timezone] from IANA database.
  ///
  /// Throws [tz.LocationNotFoundException] if the location is not found.
  factory Timezone.named(final String name) {
    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }
    return Timezone._(tz.getLocation(name));
  }

  /// Creates a fixed offset timezone.
  ///
  /// Does not support DST transitions.
  factory Timezone._fixed(
    final Duration offset, {
    final String name = 'Fixed',
  }) {
    final fixedLocation = tz.Location(name, [
      tz.minTime,
    ], [
      0,
    ], [
      tz.TimeZone(
        offset,
        isDst: false,
        abbreviation: 'FIX',
      ),
    ]);
    return Timezone._(fixedLocation);
  }

  const Timezone._(this._location);

  /// Ensures the timezone database is initialized.
  ///
  /// This must be called at least once before using [Timezone.named] or
  /// [Timezone.local] if they rely on the database.
  ///
  /// Takes an optional [database] bytes if you want to load a custom one.
  /// If null, loads the default 'latest' database bundled with the package.
  static void ensureInitialized([final List<int>? database]) {
    if (!_isInitialized) {
      if (database != null) {
        tz.initializeDatabase(database);
      } else {
        tz_data.initializeTimeZones();
      }
      _isInitialized = true;
    }
  }

  static bool _isInitialized = false;

  static Timezone? _localCache;

  /// Resets the local timezone cache.
  @visibleForTesting
  static void resetLocalCache() => _localCache = null;

  /// The underlying [tz.Location].
  final tz.Location _location;

  /// The name of the time zone (e.g., 'UTC', 'Asia/Kolkata').
  String get name => _location.name;

  /// Returns the current time in this timezone.
  DateTime get now {
    final utcNow = Context.clock.now.toUtc();
    final tzDateTime = tz.TZDateTime.from(utcNow, _location);
    return tzDateTime;
  }

  /// Timezone offset at the current time.
  Duration get offset {
    final utcNow = Context.clock.now.toUtc();
    final tzDateTime = tz.TZDateTime.from(utcNow, _location);
    return tzDateTime.timeZoneOffset;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is Timezone &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
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
    final s = offsetLiteral;
    return s.replaceAll(':', '');
  }
}

extension TimezoneOffsetExt on Duration {
  String get formatOffset {
    final hours = inHours.abs();
    final minutes = inMinutes.abs() % 60;
    final sign = isNegative ? '-' : '+';
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}
