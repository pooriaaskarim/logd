import '../../logger/logger.dart';
import 'clock_native.dart' if (dart.library.html) 'clock_web.dart'
    as platform_tz;

/// Abstract interface for time-related operations.
///
/// Provides an abstraction over the system clock to facilitate testing.
/// Use [Clock.now] to retrieve the current date and time.
abstract class Clock {
  const Clock();

  /// Returns the current date and time.
  DateTime get now;

  /// Returns the name of the system timezone (e.g., "America/Los_Angeles").
  /// return null if timezone cannot be determined.
  String? get timezoneName;
}

/// Default implementation of [Clock] using the system clock.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime get now => DateTime.now();

  @override
  String? get timezoneName {
    try {
      return platform_tz.fetchNativeTimezoneName();
    } on Exception catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'Platform timezone fetch failed',
        error: e,
        stackTrace: s,
      );
      // Return null on failure as per interface contract.
      return null;
    }
  }
}
