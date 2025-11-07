import 'dart:async';

import 'package:flutter/foundation.dart';

import '../handler/handler.dart';
import '../stack_trace/stack_trace.dart';
import '../time/time.dart';

part 'log_buffer.dart';
part 'log_entry.dart';
part 'log_level.dart';

const _defaultStackMethodCount = {
  LogLevel.trace: 0,
  LogLevel.debug: 0,
  LogLevel.info: 0,
  LogLevel.warning: 2,
  LogLevel.error: 8,
};

final _defaultTimestamp = Timestamp(
  formatter: 'yyyy.MMM.dd\nZZ HH:mm:ss.SSSS',
  timeZone: TimeZone('NY', '-05:00'),
);

const _defaultStackTraceParser = StackTraceParser(
  ignorePackages: ['logd', 'flutter'],
);

final _defaultHandlers = <Handler>[
  Handler(
    formatter: BoxFormatter(),
    sink: const ConsoleSink(),
  ),
];

/// Main logd interface.
///
/// Use this class for logging operations. It provides methods to retrieve
/// loggers with hierarchical support, global fallback logger, and configuration
/// options.
class Logger {
  Logger._({
    required this.name,
    required this.enabled,
    required this.logLevel,
    required this.includeFileLineInHeader,
    required this.stackMethodCount,
    required this.timestamp,
    required this.stackTraceParser,
    required this.handlers,
  });

  static final Map<String, Logger> _registry = {};

  static Logger get global => get('global');

  static Logger get([final String? name]) {
    final normalized = _normalizeName(name);
    return _registry.putIfAbsent(normalized, () {
      final parentName = _getParentName(normalized);
      final parent = parentName != null ? get(parentName) : null;

      return Logger._(
        name: normalized,
        enabled: parent?.enabled ?? kDebugMode,
        logLevel: parent?.logLevel ?? LogLevel.debug,
        includeFileLineInHeader: parent?.includeFileLineInHeader ?? false,
        stackMethodCount: parent?.stackMethodCount ?? _defaultStackMethodCount,
        timestamp: parent?.timestamp ?? _defaultTimestamp,
        stackTraceParser: parent?.stackTraceParser ?? _defaultStackTraceParser,
        handlers: parent?.handlers ?? _defaultHandlers,
      );
    });
  }

  static void configure(
    final String name, {
    final bool? enabled,
    final LogLevel? minimumLevel,
    final bool? includeFileLineInHeader,
    final Map<LogLevel, int>? stackMethodCount,
    final Timestamp? timestampFormatter,
    final StackTraceParser? stackTraceParser,
    final List<Handler>? handlers,
  }) {
    final normalized = _normalizeName(name);
    final existing = get(normalized);

    _registry[normalized] = Logger._(
      name: normalized,
      enabled: enabled ?? existing.enabled,
      logLevel: minimumLevel ?? existing.logLevel,
      includeFileLineInHeader:
          includeFileLineInHeader ?? existing.includeFileLineInHeader,
      stackMethodCount: stackMethodCount ?? existing.stackMethodCount,
      timestamp: timestampFormatter ?? existing.timestamp,
      stackTraceParser: stackTraceParser ?? existing.stackTraceParser,
      handlers: handlers ?? existing.handlers,
    );
  }

  /// Logger's unique name.
  final String name;

  /// Whether logging is enabled for this logger.
  final bool enabled;

  /// The minimum level to log (events below this are dropped).
  final LogLevel logLevel;

  /// Whether to include file path and line number in the origin string.
  final bool includeFileLineInHeader;

  /// Map of how many stack frames to include per log level.
  final Map<LogLevel, int> stackMethodCount;

  /// The timestamp formatter configuration.
  final Timestamp? timestamp;

  /// The stack trace parser configuration.
  final StackTraceParser stackTraceParser;

  /// List of handlers to process log entries.
  final List<Handler> handlers;

  LogBuffer? get traceBuffer =>
      enabled ? LogBuffer._(this, LogLevel.trace) : null;
  LogBuffer? get debugBuffer =>
      enabled ? LogBuffer._(this, LogLevel.debug) : null;
  LogBuffer? get infoBuffer =>
      enabled ? LogBuffer._(this, LogLevel.info) : null;
  LogBuffer? get warningBuffer =>
      enabled ? LogBuffer._(this, LogLevel.warning) : null;
  LogBuffer? get errorBuffer =>
      enabled ? LogBuffer._(this, LogLevel.error) : null;

  void trace(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.trace, message, error, stackTrace);

  void debug(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.debug, message, error, stackTrace);

  void info(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.info, message, error, stackTrace);

  void warning(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.warning, message, error, stackTrace);

  void error(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(
    final LogLevel level,
    final Object? message,
    final Object? error,
    final StackTrace? stackTrace,
  ) {
    if (!enabled || level.index < logLevel.index) {
      return;
    }

    final caller = stackTraceParser.extractCaller(
      stackTrace: stackTrace ?? StackTrace.current,
      skipFrames: 1,
    );
    if (caller == null) {
      return;
    }

    final entry = LogEntry(
      loggerName: name,
      level: level,
      message: message?.toString() ?? '',
      timestamp: timestamp?.getTimestamp() ?? '',
      origin: _buildOrigin(caller),
      hierarchyDepth: (name.isEmpty || name.toLowerCase() == 'global')
          ? 0
          : name.split('.').length,
      stackFrames: _extractStackFrames(level, stackTrace ?? StackTrace.current),
      error: error,
      stackTrace: stackTrace,
    );

    for (final handler in handlers) {
      handler.log(entry);
    }
  }

  String _buildOrigin(final CallbackInfo info) {
    var origin = info.className.isNotEmpty
        ? '${info.className}.${info.methodName}'
        : info.methodName;
    if (includeFileLineInHeader) {
      origin += ' (${info.filePath}:${info.lineNumber})';
    }
    return origin;
  }

  List<CallbackInfo>? _extractStackFrames(
    final LogLevel level,
    final StackTrace stack,
  ) {
    final count = stackMethodCount[level] ?? 0;
    if (count == 0) {
      return null;
    }

    final lines = stack.toString().split('\n');
    int index =
        lines.indexWhere((final line) => line.contains('Logger._log')) + 1;
    final frames = <CallbackInfo>[];
    const parser = StackTraceParser();
    int added = 0;

    while (index < lines.length && added < count) {
      final frame = lines[index++].trim();
      if (frame.isEmpty) {
        continue;
      }
      final info = parser.parseFrame(frame);
      if (info != null) {
        frames.add(info);
        added++;
      }
    }
    return frames.isEmpty ? null : frames;
  }

  /// Helper for retrieving parent name.
  static String? _getParentName(final String name) {
    final parts = name.split('.');
    if (parts.length <= 1) {
      return null;
    }
    return parts.sublist(0, parts.length - 1).join('.');
  }

  static String _normalizeName([final String? name]) {
    if (name == null || name.isEmpty || name.toLowerCase() == 'global') {
      return 'Global';
    }
    return name;
  }

  static void attachToFlutterErrors() {
    FlutterError.onError = (final details) {
      global.error('Flutter error',
          error: details.exception, stackTrace: details.stack);
    };
  }

  static void attachToUncaughtErrors() {
    runZonedGuarded(() {
      // App code
    }, (final error, final stack) {
      global.error('Uncaught error', error: error, stackTrace: stack);
    });
  }
}
