import 'dart:async';
import 'package:meta/meta.dart';

/// Ambient, scope-based structured logging context (Mapped Diagnostic Context).
///
/// [LogContext] allows attaching contextual key-value metadata (such as
/// `requestId`, `userId`, `traceId`, `tenant`) to an asynchronous execution
/// scope using Dart [Zone]s. Any log dispatched within that scope
/// automatically inherits the ambient context without needing to pass
/// `context: {...}` to every individual log call.
///
/// ### Basic Usage:
/// ```dart
/// await LogContext.run({'requestId': 'req-123', 'userId': 42}, () async {
///   logger.info('Starting checkout'); // Includes metadata automatically
///   await processOrder();             // Nested async calls inherit context
/// });
/// ```
///
/// ### Nested Scopes:
/// Scopes can be nested. Inner scopes inherit outer context values, and inner
/// keys override outer keys:
/// ```dart
/// LogContext.run({'tenant': 'acme', 'requestId': 'req-1'}, () {
///   logger.info('Tenant level'); // {'tenant': 'acme', 'requestId': 'req-1'}
///
///   LogContext.run({'requestId': 'req-2', 'op': 'sync'}, () {
///     logger.info('Nested'); // {'tenant': 'acme', 'requestId': 'req-2', 'op': 'sync'}
///   });
/// });
/// ```
///
/// ### Concurrency Safety:
/// Because [LogContext] utilizes Dart's [Zone] values, concurrent asynchronous
/// operations (e.g. concurrent HTTP server requests or `Future.wait`) maintain
/// strict isolation with zero cross-talk or race conditions.
@immutable
abstract final class LogContext {
  const LogContext._();

  static const Object _zoneKey = #_logd_context_zone_key;

  /// Returns the active ambient context map in the current execution [Zone],
  /// or `null` if no [LogContext] scope is active.
  static Map<String, dynamic>? get current =>
      Zone.current[_zoneKey] as Map<String, dynamic>?;

  /// Executes [body] within an ambient logging context containing [context].
  ///
  /// If an ambient [LogContext] is already active in the enclosing zone,
  /// the new [context] values are merged with the parent context, with
  /// keys in [context] taking precedence over parent keys.
  ///
  /// Returns the result of invoking [body].
  static R run<R>(
    final Map<String, dynamic> context,
    final R Function() body,
  ) {
    if (context.isEmpty) {
      return body();
    }

    final parent = current;
    final Map<String, dynamic> merged;
    if (parent == null || parent.isEmpty) {
      merged = Map<String, dynamic>.unmodifiable(context);
    } else {
      merged = Map<String, dynamic>.unmodifiable({...parent, ...context});
    }

    return runZoned(body, zoneValues: {_zoneKey: merged});
  }

  /// Merges an [explicit] call-site context map with an [ambient] zone context.
  ///
  /// If both are `null` or empty, returns `null` with zero allocation.
  /// If only one is present, returns that map directly.
  /// If both are present, returns a new map where [explicit] keys take
  /// precedence over [ambient] keys.
  static Map<String, dynamic>? merge(
    final Map<String, dynamic>? explicit, [
    final Map<String, dynamic>? ambient,
  ]) {
    final effectiveAmbient = ambient ?? current;

    if (effectiveAmbient == null || effectiveAmbient.isEmpty) {
      return explicit;
    }
    if (explicit == null || explicit.isEmpty) {
      return effectiveAmbient;
    }

    return {...effectiveAmbient, ...explicit};
  }
}
