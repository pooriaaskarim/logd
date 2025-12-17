import 'package:meta/meta.dart';
import '../../logd.dart';
import 'time_native.dart' if (dart.library.html) 'time_web.dart' as platform_tz;

part 'timestamp.dart';
part 'timezone.dart';

/// A placeholder class for time-related functionalities.
class Time {
  const Time._();

  /// Returns current date and time.
  static DateTime Function() get timeProvider => _timeProvider;

  /// Internal: internal field to control [timeProvider] behaviour for testing.
  static DateTime Function() _timeProvider = DateTime.now;

  /// Internal: set [timeProvider] behaviour for testing.
  @visibleForTesting
  static void setTimeProvider(final DateTime Function() provider) {
    _timeProvider = provider;
  }

  /// Internal: reset [timeProvider] to default behaviour.
  @visibleForTesting
  static void resetTimeProvide() {
    _timeProvider = DateTime.now;
  }

  /// Tries to fetch system timezone name.
  ///
  /// Platform-specific logic in time_native.dart
  /// (non-web) or time_web.dart (web).
  /// Throws from fetchers caught here: logs warning, returns null.
  /// Override via setTimezoneNameFetcher for custom
  /// (e.g., tests/unsupported platforms).
  static String? Function() get timezoneNameFetcher => () {
        try {
          return _timezoneNameFetcher();
        } on Exception catch (e, s) {
          Logger.get().warning(
            'Could not retrieve Timezone from platform',
            error: e,
            stackTrace: s,
          );
          return null;
        }
      };

  /// Internal: internal field to control [timezoneNameFetcher] behavior.
  static String? Function() _timezoneNameFetcher = _systemTimezoneNameFetcher;

  /// Internal: set [timezoneNameFetcher] behaviour for testing.
  @visibleForTesting
  static void setTimezoneNameFetcher(final String? Function() fetcher) {
    _timezoneNameFetcher = fetcher;
  }

  /// Internal: reset [timezoneNameFetcher] behaviour to default.
  @visibleForTesting
  static void resetTimezoneNameFetcher() {
    _timezoneNameFetcher = _systemTimezoneNameFetcher;
  }

  /// Internal: default [timezoneNameFetcher] behaviour.
  static String _systemTimezoneNameFetcher() =>
      platform_tz.fetchNativeTimezoneName();
}
