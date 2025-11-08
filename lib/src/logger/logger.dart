import 'dart:async';

import '../handler/handler.dart';
import '../stack_trace/stack_trace.dart';
import '../time/time.dart';
import 'flutter_stubs.dart' if (dart.library.ui) 'flutter_stubs_flutter.dart'
    as flutter_stubs;

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
  const Logger._({
    required this.name,
    final bool? enabled,
    final LogLevel? logLevel,
    final bool? includeFileLineInHeader,
    final Map<LogLevel, int>? stackMethodCount,
    final Timestamp? timestamp,
    final StackTraceParser? stackTraceParser,
    final List<Handler>? handlers,
  })  : _enabled = enabled,
        _logLevel = logLevel,
        _includeFileLineInHeader = includeFileLineInHeader,
        _stackMethodCount = stackMethodCount,
        _timestamp = timestamp,
        _stackTraceParser = stackTraceParser,
        _handlers = handlers;

  /// Internal registry of all available loggers.
  static final Map<String, Logger> _registry = {};

  /// Retrieves or creates a logger by name, with hierarchical inheritance.
  ///
  /// Intentions: Provides access to named loggers. If not existing, creates one
  /// inheriting from its parent (or global). Names are dot-separated for
  /// hierarchy (e.g., 'app.ui.button' inherits from 'app.ui').
  ///
  /// Parameters:
  /// - [name]: Optional logger name (defaults to global if null/empty/'global').
  ///
  /// How to use:
  /// - Basic: Logger.get('my.logger').info('Message');
  /// - Global: Logger.get() or Logger.global
  ///
  /// Returns: The logger instance.
  ///
  /// Example: final uiLogger = Logger.get('app.ui');
  static Logger get([final String? name]) {
    final normalized = _normalizeName(name);
    return _registry.putIfAbsent(
      normalized,
      () => Logger._(
        name: normalized,
      ),
    );
  }

  /// Configures a logger's properties, creating a new immutable instance.
  ///
  /// Intentions: Sets or updates logger configs. Unspecified parameters retain
  /// previous/existing values. Affects only this logger; use propagate() to
  /// apply to descendants if needed.
  ///
  /// Parameters:
  /// - [name]: The logger name to configure.
  /// - [enabled]: Whether logging is enabled.
  /// - [logLevel]: Minimum log level to process.
  /// - [includeFileLineInHeader]: Include file/line in origin.
  /// - [stackMethodCount]: Stack frames per level.
  /// - [timestamp]: Timestamp config.
  /// - [stackTraceParser]: Stack parser config.
  /// - [handlers]: List of handlers.
  ///
  /// How to use:
  /// - Logger.configure('app', minimumLevel: LogLevel.info);
  /// - Changes are immediate and dynamic for children via inheritance.
  ///
  /// Example: Logger.configure('global', enabled: false); // Disable all logging
  static void configure(
    final String name, {
    final bool? enabled,
    final LogLevel? logLevel,
    final bool? includeFileLineInHeader,
    final Map<LogLevel, int>? stackMethodCount,
    final Timestamp? timestamp,
    final StackTraceParser? stackTraceParser,
    final List<Handler>? handlers,
  }) {
    final normalized = _normalizeName(name);
    final logger = get(normalized);
    _registry[normalized] = Logger._(
      name: normalized,
      enabled: enabled ?? logger._enabled,
      logLevel: logLevel ?? logger._logLevel,
      includeFileLineInHeader:
          includeFileLineInHeader ?? logger._includeFileLineInHeader,
      stackMethodCount: stackMethodCount ?? logger._stackMethodCount,
      timestamp: timestamp ?? logger._timestamp,
      stackTraceParser: stackTraceParser ?? logger._stackTraceParser,
      handlers: handlers ?? logger._handlers,
    );
  }

  /// Logger's unique name.
  final String name;

  /// Parent logger for hierarchy (dynamically fetched).
  Logger? get _parent {
    final parentName = _getParentName(name);
    return parentName != null ? get(parentName) : null;
  }

  final bool? _enabled;

  /// Whether logging is enabled for this logger.
  bool get enabled =>
      _enabled ?? _parent?.enabled ?? !bool.fromEnvironment('dart.vm.product');
  final LogLevel? _logLevel;

  /// The minimum level to log (events below this are dropped).
  LogLevel get logLevel => _logLevel ?? _parent?.logLevel ?? LogLevel.debug;
  final bool? _includeFileLineInHeader;

  /// Whether to include file path and line number in the origin string.
  bool get includeFileLineInHeader =>
      _includeFileLineInHeader ?? _parent?.includeFileLineInHeader ?? false;
  final Map<LogLevel, int>? _stackMethodCount;

  /// Map of how many stack frames to include per log level.
  Map<LogLevel, int> get stackMethodCount =>
      _stackMethodCount ??
      _parent?.stackMethodCount ??
      _defaultStackMethodCount;
  final Timestamp? _timestamp;

  /// The timestamp formatter configuration.
  Timestamp? get timestamp =>
      _timestamp ?? _parent?.timestamp ?? _defaultTimestamp;
  final StackTraceParser? _stackTraceParser;

  /// The stack trace parser configuration.
  StackTraceParser get stackTraceParser =>
      _stackTraceParser ??
      _parent?.stackTraceParser ??
      _defaultStackTraceParser;
  final List<Handler>? _handlers;

  /// List of handlers to process log entries.
  List<Handler> get handlers =>
      _handlers ?? _parent?.handlers ?? _defaultHandlers;

  /// Freezes the current inherited configurations into descendant loggers.
  ///
  /// Intentions: "Bakes" this logger's effective (resolved) configs into
  /// children where not explicitly set, creating new child instances. Useful
  /// for performance (reduces getter chaining depth) or to snapshot state so
  /// future parent changes don't propagate dynamically. Since inheritance is
  /// runtime-resolved, this is optional for optimization or isolation.
  ///
  /// How to use:
  /// - Call on a logger to apply to all descendants recursively via registry.
  /// - Only sets null child fields to this logger's effective values.
  /// - No-op if children have all fields explicit.
  ///
  /// Example: parentLogger.freezeInheritance(); // Snapshots to subtree
  void freezeInheritance() {
    for (final key in _registry.keys.toList()) {
      if (key != name && key.startsWith('$name.')) {
        final child = _registry[key]!;
        _registry[key] = Logger._(
          name: child.name,
          enabled: child._enabled ?? enabled,
          logLevel: child._logLevel ?? logLevel,
          includeFileLineInHeader:
              child._includeFileLineInHeader ?? includeFileLineInHeader,
          stackMethodCount:
              child._stackMethodCount ?? Map.from(stackMethodCount),
          timestamp: child._timestamp ?? timestamp,
          stackTraceParser: child._stackTraceParser ?? stackTraceParser,
          handlers: child._handlers ?? List.from(handlers),
        );
      }
    }
  }

  /// Returns a buffer for building multi-line trace-level logs.
  ///
  /// Intentions: Allows accumulating multiple lines before logging to ensure
  /// atomic output, useful for complex trace messages. The buffer is null if
  /// logging is disabled.
  ///
  /// How to use:
  /// - Get the buffer: final buf = logger.traceBuffer;
  /// - Write lines: buf?.writeln('Line 1'); buf?.writeln('Line 2');
  /// - Sync to log: buf?.sync();
  ///
  /// Example: logger.traceBuffer?..writeln('Trace start')..sync();
  LogBuffer? get traceBuffer =>
      enabled ? LogBuffer._(this, LogLevel.trace) : null;

  /// Returns a buffer for building multi-line debug-level logs.
  ///
  /// Intentions: Similar to traceBuffer, but for debug messages. Helps in
  /// constructing detailed debug output without interleaving.
  ///
  /// Example: logger.debugBuffer?..writeln('Debug start')..sync();
  LogBuffer? get debugBuffer =>
      enabled ? LogBuffer._(this, LogLevel.debug) : null;

  /// Returns a buffer for building multi-line info-level logs.
  ///
  /// Intentions: For informational messages that may span multiple lines.
  ///
  /// Example: logger.infoBuffer?..writeln('Info start')..sync();
  LogBuffer? get infoBuffer =>
      enabled ? LogBuffer._(this, LogLevel.info) : null;

  /// Returns a buffer for building multi-line warning-level logs.
  ///
  /// Intentions: For warnings that require detailed, multi-line descriptions.
  ///
  /// Example: logger.warningBuffer?..writeln('Warning start')..sync();
  LogBuffer? get warningBuffer =>
      enabled ? LogBuffer._(this, LogLevel.warning) : null;

  /// Returns a buffer for building multi-line error-level logs.
  ///
  /// Intentions: For errors with stack traces or multi-line details.
  ///
  /// Example: logger.errorBuffer?..writeln('Error start')..sync();
  LogBuffer? get errorBuffer =>
      enabled ? LogBuffer._(this, LogLevel.error) : null;

  /// Logs a trace-level message.
  ///
  /// Intentions: For fine-grained diagnostic information, typically disabled
  /// in production. Optional error and stackTrace for context.
  ///
  /// Parameters:
  /// - [message]: The log message (converted to string).
  /// - [error]: Optional associated error object.
  /// - [stackTrace]: Optional stack trace (defaults to current).
  ///
  /// How to use: logger.trace('Trace event', error: e);
  void trace(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.trace, message, error, stackTrace);

  /// Logs a debug-level message.
  ///
  /// Intentions: For debugging information useful during development.
  ///
  /// Parameters: Same as trace.
  ///
  /// How to use: logger.debug('Debug info');
  void debug(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.debug, message, error, stackTrace);

  /// Logs an info-level message.
  ///
  /// Intentions: For general operational information.
  ///
  /// Parameters: Same as trace.
  ///
  /// How to use: logger.info('App started');
  void info(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.info, message, error, stackTrace);

  /// Logs a warning-level message.
  ///
  /// Intentions: For potential issues that don't halt execution.
  ///
  /// Parameters: Same as trace.
  ///
  /// How to use: logger.warning('Low memory', stackTrace: stack);
  void warning(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.warning, message, error, stackTrace);

  /// Logs an error-level message.
  ///
  /// Intentions: For errors that require attention, often with stack traces.
  ///
  /// Parameters: Same as trace.
  ///
  /// How to use: logger.error('Failed to load', error: e, stackTrace: stack);
  void error(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, message, error, stackTrace);

  /// Internal: Processes a log event, creating and dispatching a LogEntry.
  ///
  /// Checks enabled and level, extracts caller, builds entry, and sends to
  /// handlers.
  ///
  /// Parameters:
  /// - [level]: The log level.
  /// - [message]: The message object.
  /// - [error]: Optional error.
  /// - [stackTrace]: Optional or current stack trace.
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

  /// Internal: Builds the origin string from caller info.
  ///
  /// Includes class.method and optionally file:line if configured.
  String _buildOrigin(final CallbackInfo info) {
    var origin = info.className.isNotEmpty
        ? '${info.className}.${info.methodName}'
        : info.methodName;
    if (includeFileLineInHeader) {
      origin += ' (${info.filePath}:${info.lineNumber})';
    }
    return origin;
  }

  /// Internal: Extracts a limited number of stack frames based on level config.
  ///
  /// Parameters:
  /// - [level]: Determines frame count from stackMethodCount.
  /// - [stack]: The stack trace to parse.
  ///
  /// Returns: List of parsed frames or null if count is 0.
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
      return name == 'Global' ? null : 'Global';
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
    flutter_stubs.attachToFlutterErrors();
  }

  static void attachToUncaughtErrors() {
    runZonedGuarded(() {
      // App code
    }, (final error, final stack) {
      get().error('Uncaught error', error: error, stackTrace: stack);
    });
  }
}
