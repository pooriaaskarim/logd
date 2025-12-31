part of 'logger.dart';

/// Internal logger for logd to avoid circularity.
///
/// Prints directly to console with a prefix.
@internal
class InternalLogger {
  const InternalLogger._();

  /// Logs a message directly to console.
  static void log(
    final LogLevel level,
    final String message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) {
    // ignore: avoid_print
    print('[logd-internal] [${level.name.toUpperCase()}]: $message');
    if (error != null) {
      // ignore: avoid_print
      print('[logd-internal] [Error]: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('[logd-internal] [Stack Trace]:\n$stackTrace');
    }
  }
}
