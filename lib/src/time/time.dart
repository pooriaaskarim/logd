import 'package:meta/meta.dart';
import '../../logd.dart';
import 'time_native.dart' if (dart.library.html) 'time_web.dart' as platform_tz;

part 'timestamp.dart';
part 'timezone.dart';

/// A placeholder class for time-related functionality.
class Time {
  const Time._();

  /// Returns current date and time.
  static DateTime Function() timeProvider = DateTime.now;

  @visibleForTesting
  static void setTimeProvider(final DateTime Function() provider) {
    timeProvider = provider;
  }

  @visibleForTesting
  static void resetTimeProvide() {
    timeProvider = DateTime.now;
  }

  /// Tries to fetch system timezone name.
  ///
  /// Platform-specific logic in time_native.dart
  /// (non-web) or time_web.dart (web).
  /// Throws from fetchers caught here: logs warning, returns null.
  /// Override via setTimeZoneNameFetcher for custom
  /// (e.g., tests/unsupported platforms).
  static String? Function() get systemTimezoneNameFetcher => () {
        try {
          return _systemTimezoneNameFetcher();
        } on Exception catch (e, s) {
          Logger.get().warning(
            'Could not retrieve TimeZone from platform',
            error: e,
            stackTrace: s,
          );
          return null;
        }
      };

  /// Internal: fetches timezone name.
  static String? Function() _systemTimezoneNameFetcher =
      _systemTimeZoneNameFetcher;

  @visibleForTesting
  static set systemTimezoneNameFetcher(final String? Function() fetcher) {
    _systemTimezoneNameFetcher = fetcher;
  }

  @visibleForTesting
  static void resetTimeZoneNameFetcher() {
    _systemTimezoneNameFetcher = _systemTimeZoneNameFetcher;
  }

  static String _systemTimeZoneNameFetcher() =>
      platform_tz.fetchNativeTimeZoneName();

  /// Static cache for parsed formatters (key: formatter string, value: segments).
  static final Map<String, List<_FormatSegment>> formatterCache = {};
}
