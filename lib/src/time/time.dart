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

  /// Internal: fetches timezone name.
  static String? Function() _timezoneNameFetcher = _systemTimezoneNameFetcher;

  @visibleForTesting
  static set timezoneNameFetcher(final String? Function() fetcher) {
    _timezoneNameFetcher = fetcher;
  }

  @visibleForTesting
  static void resetTimezoneNameFetcher() {
    _timezoneNameFetcher = _timezoneNameFetcher;
  }

  static String _systemTimezoneNameFetcher() =>
      platform_tz.fetchNativeTimezoneName();

  /// Static cache for parsed formatters (key: formatter string, value: segments).
  static final Map<String, List<_FormatSegment>> _formatterCache = {};
}
