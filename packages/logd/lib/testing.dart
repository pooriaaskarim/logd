import 'package:matcher/matcher.dart';
import 'logd.dart';

/// Represents a logged entry captured in tests.
class CapturedLog {
  /// Creates a new [CapturedLog] instance.
  CapturedLog({
    required this.level,
    required this.message,
    required this.loggerName,
    required this.origin,
    this.error,
    this.stackTrace,
    this.context,
  });

  /// The level of this log event.
  final LogLevel level;

  /// The formatted message string.
  final String message;

  /// The name of the logger.
  final String loggerName;

  /// The file/class origin header.
  final String origin;

  /// The optional associated error.
  final Object? error;

  /// The optional associated stack trace.
  final StackTrace? stackTrace;

  /// The optional associated context map.
  final Map<String, dynamic>? context;
}

/// A [LogSink] that captures all logged entries in memory for verification
/// in unit tests.
///
/// Each [Handler] invocation appends a [CapturedLog] to [logs].
/// Note that because [Handler] executes asynchronously, logs may not be
/// visible until the current microtask queue drains. In tests, await
/// a short [Future.delayed] or use `await Future.value()` after the
/// log call to ensure the sink has received the entry before asserting.
///
/// ```dart
/// final sink = CaptureSink();
/// logger.info('hello');
/// await Future.value(); // drain microtask queue
/// expect(sink, hasLog(message: 'hello'));
/// ```
base class CaptureSink extends LogSink<LogDocument> {
  /// The list of captured log events.
  final List<CapturedLog> logs = [];

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    logs.add(
      CapturedLog(
        level: level,
        message: entry.message,
        loggerName: entry.loggerName,
        origin: entry.origin,
        error: entry.error,
        stackTrace: entry.stackTrace,
        context: entry.context != null
            ? Map<String, dynamic>.from(entry.context!)
            : null,
      ),
    );
  }

  /// Clears all captured logs.
  void clear() {
    logs.clear();
  }
}

/// A convenience wrapper that creates an isolated logger with a [CaptureSink]
/// for unit testing.
///
/// On construction, [TestLogger] calls [Logger.configure] to register the
/// logger globally by [name]. This means the name is visible to the entire
/// [Logger] registry for the lifetime of the test.
///
/// **Always call [dispose] in a `tearDown` or `addTearDown` callback** to
/// remove the logger registration and avoid name collisions across tests:
///
/// ```dart
/// late TestLogger testLogger;
///
/// setUp(() => testLogger = TestLogger('my_logger'));
/// tearDown(() => testLogger.dispose());
/// ```
class TestLogger {
  /// Creates a [TestLogger] and configures it with a [CaptureSink].
  TestLogger(this.name) {
    Logger.configure(
      name,
      handlers: [
        Handler(
          formatter: const PlainFormatter(),
          sink: sink,
        ),
      ],
    );
  }

  /// The name of the logger under test.
  final String name;

  /// The sink capturing logs.
  final CaptureSink sink = CaptureSink();

  /// Gets the [Logger] instance.
  Logger get logger => Logger.get(name);

  /// Gets the list of captured logs.
  List<CapturedLog> get logs => sink.logs;

  /// Clears all captured logs.
  void clear() => sink.clear();

  /// Removes this logger's configuration from the global [Logger] registry.
  ///
  /// Call this in `tearDown` / `addTearDown` to prevent name collisions
  /// across tests. Equivalent to `Logger.reset(name)`.
  void dispose() => Logger.reset(name);
}

/// A custom matcher to verify logs captured in tests.
///
/// Can match against [TestLogger], [CaptureSink], `List<CapturedLog>`,
/// or a single [CapturedLog].
Matcher hasLog({
  final LogLevel? level,
  final Object? message,
  final String? loggerName,
  final Map<String, dynamic>? context,
}) =>
    _HasLogMatcher(
      level: level,
      message: message,
      loggerName: loggerName,
      context: context,
    );

class _HasLogMatcher extends Matcher {
  _HasLogMatcher({
    this.level,
    this.message,
    this.loggerName,
    this.context,
  });

  final LogLevel? level;
  final Object? message;
  final String? loggerName;
  final Map<String, dynamic>? context;

  @override
  bool matches(final dynamic item, final Map<dynamic, dynamic> matchState) {
    final List<CapturedLog> logs;
    if (item is TestLogger) {
      logs = item.logs;
    } else if (item is CaptureSink) {
      logs = item.logs;
    } else if (item is Iterable<CapturedLog>) {
      logs = item.toList();
    } else if (item is CapturedLog) {
      logs = [item];
    } else {
      return false;
    }

    return logs.any((final log) {
      if (level != null && log.level != level) {
        return false;
      }
      if (loggerName != null && log.loggerName != loggerName) {
        return false;
      }
      if (message != null) {
        final msg = message;
        if (msg is String && log.message != msg) {
          return false;
        } else if (msg is RegExp && !msg.hasMatch(log.message)) {
          return false;
        } else if (msg is Matcher && !msg.matches(log.message, matchState)) {
          return false;
        } else if (msg is! String &&
            msg is! RegExp &&
            msg is! Matcher &&
            log.message != msg.toString()) {
          return false;
        }
      }
      if (context != null) {
        if (log.context == null) {
          return false;
        }
        for (final entry in context!.entries) {
          if (log.context![entry.key] != entry.value) {
            return false;
          }
        }
      }
      return true;
    });
  }

  @override
  Description describe(final Description description) {
    description.add('contains a log');
    final specs = <String>[];
    if (level != null) {
      specs.add('level: ${level!.name}');
    }
    if (message != null) {
      specs.add('message: $message');
    }
    if (loggerName != null) {
      specs.add('loggerName: $loggerName');
    }
    if (context != null) {
      specs.add('context: $context');
    }
    if (specs.isNotEmpty) {
      description.add(' matching [${specs.join(", ")}]');
    }
    return description;
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    if (item is! TestLogger &&
        item is! CaptureSink &&
        item is! Iterable<CapturedLog> &&
        item is! CapturedLog) {
      return mismatchDescription.add(
        'is not a TestLogger, CaptureSink, '
        'CapturedLog, or List<CapturedLog>',
      );
    }
    final List<CapturedLog> logs;
    if (item is TestLogger) {
      logs = item.logs;
    } else if (item is CaptureSink) {
      logs = item.logs;
    } else if (item is Iterable<CapturedLog>) {
      logs = item.toList();
    } else {
      logs = [item as CapturedLog];
    }
    if (logs.isEmpty) {
      return mismatchDescription.add('has no logs');
    }
    mismatchDescription.add('has logs:\n');
    for (final log in logs) {
      final contextStr = log.context != null ? ', context: ${log.context}' : '';
      final upperLevel = log.level.name.toUpperCase();
      mismatchDescription.add(
        '  - [$upperLevel] [${log.loggerName}]: '
        '"${log.message}"$contextStr\n',
      );
    }
    return mismatchDescription;
  }
}
