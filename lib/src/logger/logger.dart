import 'package:meta/meta.dart';

import '../core/utils.dart';
import '../handler/handler.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';
import '../time/timezone.dart';
import 'flutter_stubs.dart' if (dart.library.ui) 'flutter_stubs_flutter.dart'
    as flutter_stubs;

part 'internal_logger.dart';
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
  formatter: 'yyyy.MMM.dd Z HH:mm:ss.SSS',
  timezone: Timezone.local(),
);

const _defaultStackTraceParser = StackTraceParser(
  ignorePackages: ['logd', 'flutter'],
);
final _defaultHandlers = <Handler>[
  Handler(
    formatter: StructuredFormatter(),
    sink: const ConsoleSink(),
    decorators: [BoxDecorator()],
  ),
];

/// Internal configuration for a [Logger], holding optional fields that
/// can inherit from parent.
@internal
class LoggerConfig {
  /// Optional: Whether logging is enabled. Inherits from parent if null.
  bool? enabled;

  /// Optional: Minimum log level to process. Inherits from parent if null.
  LogLevel? logLevel;

  /// Optional: Include file/line in origin. Inherits from parent if null.
  bool? includeFileLineInHeader;

  /// Optional: Stack frames per level. Inherits from parent if null.
  Map<LogLevel, int>? stackMethodCount;

  /// Optional: Timestamp config. Inherits from parent if null.
  Timestamp? timestamp;

  /// Optional: Stack parser config. Inherits from parent if null.
  StackTraceParser? stackTraceParser;

  /// Optional: List of handlers. Inherits from parent if null.
  List<Handler>? handlers;

  /// Cache version tracker.
  int _version = 0;
}

/// Internal cache for resolved Logger configurations.
///
/// This cache manages the hierarchical resolution of logger settings
/// (inheritance) and avoids re-calculating resolved values on every access.
@internal
class LoggerCache {
  const LoggerCache._();

  static final Map<String, _ResolvedConfig> _cache = {};

  /// Resolves the effective [enabled] state for [loggerName].
  static bool enabled(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).enabled;

  /// Resolves the effective [LogLevel] for [loggerName].
  static LogLevel logLevel(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).logLevel;

  /// Resolves the effective [includeFileLineInHeader] for [loggerName].
  static bool includeFileLineInHeader(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).includeFileLineInHeader;

  /// Resolves the effective [stackMethodCount] for [loggerName].
  static Map<LogLevel, int> stackMethodCount(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).stackMethodCount;

  /// Resolves the effective [Timestamp] for [loggerName].
  static Timestamp timestamp(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).timestamp;

  /// Resolves the effective [StackTraceParser] for [loggerName].
  static StackTraceParser stackTraceParser(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).stackTraceParser;

  /// Resolves the effective [handlers] for [loggerName].
  static List<Handler> handlers(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).handlers;

  /// Internal: Resolves and caches the effective configuration for
  /// [loggerName]. Expects [loggerName] to be normalized.
  static _ResolvedConfig _resolve(final String loggerName) {
    final config =
        Logger._registry.putIfAbsent(loggerName, () => LoggerConfig());
    final cached = _cache[loggerName];

    if (cached != null && cached.version == config._version) {
      return cached;
    }

    // Resolve by walking hierarchy
    var currentName = loggerName;
    bool? resolvedEnabled;
    LogLevel? resolvedLogLevel;
    bool? resolvedIncludeFileLineInHeader;
    Map<LogLevel, int>? resolvedStackMethodCount;
    Timestamp? resolvedTimestamp;
    StackTraceParser? resolvedStackTraceParser;
    List<Handler>? resolvedHandlers;

    while (true) {
      final cSource = Logger._registry[currentName];
      if (cSource != null) {
        resolvedEnabled ??= cSource.enabled;
        resolvedLogLevel ??= cSource.logLevel;
        resolvedIncludeFileLineInHeader ??= cSource.includeFileLineInHeader;
        resolvedStackMethodCount ??= cSource.stackMethodCount;
        resolvedTimestamp ??= cSource.timestamp;
        resolvedStackTraceParser ??= cSource.stackTraceParser;
        resolvedHandlers ??= cSource.handlers;
      }

      final parentName = Logger._getParentName(currentName);
      if (parentName == null) {
        break;
      }
      currentName = parentName;
    }

    // Ensure resolved collections are unmodifiable
    // to prevent external mutation.
    final resolved = _ResolvedConfig(
      version: config._version,
      enabled:
          resolvedEnabled ?? !const bool.fromEnvironment('dart.vm.product'),
      logLevel: resolvedLogLevel ?? LogLevel.debug,
      includeFileLineInHeader: resolvedIncludeFileLineInHeader ?? false,
      stackMethodCount: Map.unmodifiable(
        resolvedStackMethodCount ?? _defaultStackMethodCount,
      ),
      timestamp: resolvedTimestamp ?? _defaultTimestamp,
      stackTraceParser: resolvedStackTraceParser ?? _defaultStackTraceParser,
      handlers: List.unmodifiable(resolvedHandlers ?? _defaultHandlers),
    );

    _cache[loggerName] = resolved;
    return resolved;
  }

  /// Invalidates the cache for a specific logger and all its descendants.
  static void invalidate(final String loggerName) {
    final normalized = Logger._normalizeName(loggerName);
    _cache.remove(normalized);
    for (final key in _cache.keys.toList()) {
      if (Logger._isDescendant(key, normalized)) {
        _cache.remove(key);
      }
    }
  }

  /// Clears the entire logger cache.
  static void clear() => _cache.clear();
}

/// Internal container for resolved logger settings.
class _ResolvedConfig {
  const _ResolvedConfig({
    required this.version,
    required this.enabled,
    required this.logLevel,
    required this.includeFileLineInHeader,
    required this.stackMethodCount,
    required this.timestamp,
    required this.stackTraceParser,
    required this.handlers,
  });

  final int version;
  final bool enabled;
  final LogLevel logLevel;
  final bool includeFileLineInHeader;
  final Map<LogLevel, int> stackMethodCount;
  final Timestamp timestamp;
  final StackTraceParser stackTraceParser;
  final List<Handler> handlers;
}

/// Main logd interface.
///
/// Use this class for logging operations. It provides methods to retrieve
/// loggers with hierarchical support, global fallback logger, and configuration
/// options.
///
/// This class acts as a proxy to the logger's configuration, resolving values
/// dynamically from the [Logger] tree hierarchy on each access for up-to-date
/// settings.
class Logger {
  const Logger._(this.name);

  /// Logger's unique name
  ///
  /// Names are Dot-separated, case-insensitive, normalized to lowercase.
  final String name;

  /// Internal: Registry of all available logger configs.
  static final Map<String, LoggerConfig> _registry = {};

  /// Retrieves or creates a logger by name, with hierarchical inheritance.
  ///
  /// Intentions: Provides access to named loggers. If not existing, creates one
  /// inheriting from its parent (or global). Names are dot-separated for
  /// hierarchy (e.g., 'app.ui.button' inherits from 'app.ui'). Names are
  /// case-insensitive and normalized to lowercase; prefer lowercase with
  /// underscores if multi-word (e.g., '**my_app**.ui').
  ///
  /// Parameters:
  /// - [name]: Optional logger name (defaults to global if null/empty/'global').
  ///
  /// How to use:
  /// - Basic: Logger.get('app').info('Message');
  /// - Global: Logger.get(), Logger.get(''), Logger.get('global')
  ///
  /// Returns: The logger instance.
  ///
  /// Example: final uiLogger = Logger.get('app.ui');
  static Logger get([final String? name]) {
    final normalized = _normalizeName(name);
    _registry.putIfAbsent(normalized, () => LoggerConfig());
    return Logger._(normalized);
  }

  /// Configures a logger's properties, updating the config in-place.
  ///
  /// Intentions: Sets or updates logger configs. Unspecified parameters retain
  /// previous/existing values. Affects logger and it's logger tree descendants
  /// where not explicitly set; use freezeInheritance() on any point on [Logger]
  /// tree to freeze current branch/leaf state.
  /// **Note**: Names are case-insensitive and normalized to lowercase.
  ///
  /// Parameters:
  /// - [name]: The logger name to configure (case-insensitive).
  /// - [enabled]: Whether logging is enabled.
  /// - [logLevel]: Minimum log level to process.
  /// - [includeFileLineInHeader]: Include file/line in origin.
  /// - [stackMethodCount]: Stack frames per level.
  /// - [timestamp]: Timestamp config.
  /// - [stackTraceParser]: Stack parser config.
  /// - [handlers]: List of handlers.
  ///
  /// How to use:
  /// - Logger.configure('app', logLevel: LogLevel.info);
  /// - Changes are immediate and dynamically inherited down Logger tree
  /// hierarchy where not explicitly set.
  ///
  /// Example: Logger.configure('global', enabled: false); // Disables all
  /// Loggers, except enabled explicitly.
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
    final config = _registry.putIfAbsent(normalized, () => LoggerConfig());

    bool changed = false;
    if (enabled != null && enabled != config.enabled) {
      config.enabled = enabled;
      changed = true;
    }
    if (logLevel != null && logLevel != config.logLevel) {
      config.logLevel = logLevel;
      changed = true;
    }
    if (includeFileLineInHeader != null &&
        includeFileLineInHeader != config.includeFileLineInHeader) {
      config.includeFileLineInHeader = includeFileLineInHeader;
      changed = true;
    }
    if (stackMethodCount != null &&
        !mapEquals(stackMethodCount, config.stackMethodCount)) {
      config.stackMethodCount = stackMethodCount;
      changed = true;
    }
    if (timestamp != null && timestamp != config.timestamp) {
      config.timestamp = timestamp;
      changed = true;
    }
    if (stackTraceParser != null &&
        stackTraceParser != config.stackTraceParser) {
      config.stackTraceParser = stackTraceParser;
      changed = true;
    }
    if (handlers != null && !listEquals(handlers, config.handlers)) {
      config.handlers = handlers;
      changed = true;
    }

    if (changed) {
      config._version++;
      LoggerCache.invalidate(normalized);
    }
  }

  /// Internal: Checks if a name is a descendant of parent.
  static bool _isDescendant(final String child, final String parent) {
    if (parent == 'global') {
      return child != 'global';
    }
    return child.startsWith('$parent.');
  }

  /// Whether logging is enabled for this logger.
  bool get enabled => LoggerCache.enabled(name);

  /// The minimum level to log (events below this are dropped).
  LogLevel get logLevel => LoggerCache.logLevel(name);

  /// Whether to include file path and line number in the origin string.
  bool get includeFileLineInHeader => LoggerCache.includeFileLineInHeader(name);

  /// Map of how many stack frames to include per log level.
  Map<LogLevel, int> get stackMethodCount => LoggerCache.stackMethodCount(name);

  /// The timestamp formatter configuration.
  Timestamp get timestamp => LoggerCache.timestamp(name);

  /// The stack trace parser configuration.
  StackTraceParser get stackTraceParser => LoggerCache.stackTraceParser(name);

  /// List of handlers to process log entries.
  List<Handler> get handlers => LoggerCache.handlers(name);

  /// Freezes the current inherited configurations into descendant loggers.
  ///
  /// Intentions: "Bakes" this logger's effective configs down the Logger tree
  /// hierarchy where children are not explicitly set.
  /// Useful for performance (reduces resolution depth) or to snapshot state so
  /// future parent changes don't propagate dynamically.
  ///
  /// How to use:
  /// - Call on a logger to apply to all descendants recursively via registry.
  /// - Only sets null child fields to this logger's effective values.
  /// - No-op if children have all fields explicit.
  ///
  /// Example: parentLogger.freezeInheritance(); // Snapshots to subtree
  void freezeInheritance() {
    for (final key in _registry.keys.toList()) {
      if (key == name || _isDescendant(key, name)) {
        final childConfig = _registry[key]!
          ..enabled ??= enabled
          ..logLevel ??= logLevel
          ..includeFileLineInHeader ??= includeFileLineInHeader
          ..stackMethodCount ??= Map.from(stackMethodCount)
          ..timestamp ??= timestamp
          ..stackTraceParser ??= stackTraceParser
          ..handlers ??= List.from(handlers);
        // Since we set fields, bump version and clear cache
        childConfig._version++;
        LoggerCache.invalidate(key);
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
      _log(LogLevel.trace, message, error, stackTrace).catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

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
      _log(LogLevel.debug, message, error, stackTrace).catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

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
      _log(LogLevel.info, message, error, stackTrace).catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

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
      _log(LogLevel.warning, message, error, stackTrace).catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

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
      _log(LogLevel.error, message, error, stackTrace).catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

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
  Future<void> _log(
    final LogLevel level,
    final Object? message,
    final Object? error,
    final StackTrace? stackTrace,
  ) async {
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
      timestamp: timestamp.timestamp ?? '',
      origin: _buildOrigin(caller),
      hierarchyDepth: name == 'global' ? 0 : name.split('.').length,
      stackFrames: _extractStackFrames(level, stackTrace ?? StackTrace.current),
      error: error,
      stackTrace: stackTrace,
    );
    for (final handler in handlers) {
      try {
        await handler.log(entry);
      } catch (e, s) {
        InternalLogger.log(
          LogLevel.error,
          'Handler failure: ${handler.runtimeType}',
          error: e,
          stackTrace: s,
        );
      }
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

  /// Internal: Helper for retrieving parent name.
  static String? _getParentName(final String name) {
    final parts = name.split('.');
    if (parts.length <= 1) {
      return name == 'global' ? null : 'global';
    }
    return parts.sublist(0, parts.length - 1).join('.');
  }

  /// Internal: Normalizes logger name to lowercase for case-insensitivity.
  ///
  /// Resolves null, empty strings and any form of 'global' to 'global'.
  static String _normalizeName([final String? name]) {
    final lower = name?.toLowerCase() ?? 'global';
    return lower.isEmpty ? 'global' : lower;
  }

  /// Attach to Flutter errors.
  static void attachToFlutterErrors() {
    flutter_stubs.attachToFlutterErrors();
  }

  /// Internal: Clears the registry (used for tests).
  @visibleForTesting
  static void clearRegistry() {
    _registry.clear();
    LoggerCache.clear();
  }
}
