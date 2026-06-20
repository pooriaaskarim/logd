import 'package:meta/meta.dart';

import '../core/log_level.dart';
import '../core/utils/utils.dart';
import '../handler/handler.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';
import '../time/timezone.dart';
import 'flutter_stubs.dart' if (dart.library.ui) 'flutter_stubs_flutter.dart'
    as flutter_stubs;

export '../core/log_level.dart';

part 'internal_logger.dart';
part 'log_buffer.dart';
part 'log_entry.dart';

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

  /// Optional: Whether to automatically sink abandoned buffers.
  ///
  /// If true, buffers collected by GC will be logged with a warning.
  /// If false (default), data is lost and a severe error is logged.
  bool? autoSinkBuffer;

  /// Cache version tracker.
  int _version = 0;

  /// The set of fields that were populated by `freezeInheritance`.
  final Set<String> _frozenFields = {};

  /// Whether this logger was implicitly materialised by [Logger.get] without
  /// ever being explicitly configured via [Logger.configure].
  ///
  /// An implicit logger inherits everything from its ancestors and produces no
  /// explicit or frozen fields of its own. It is a phantom node in the
  /// registry and [Logger.exportHierarchy] marks it accordingly.
  bool _implicit = true;
}

/// Internal cache for resolved Logger configurations.
///
/// This cache manages the hierarchical resolution of logger settings
/// (inheritance) and avoids re-calculating resolved values on every access.
@internal
class LoggerCache {
  const LoggerCache._();

  static final Map<String, _ResolvedConfig> _cache = {};
  static final Map<String, Set<String>> _descendants = {};

  static List<String> _getAncestors(final String loggerName) {
    if (loggerName == 'global') {
      return const [];
    }
    final ancestors = <String>['global'];
    var current = loggerName;
    while (true) {
      final parent = Logger._getParentName(current);
      if (parent == null || parent == 'global') {
        break;
      }
      ancestors.add(parent);
      current = parent;
    }
    return ancestors;
  }

  static void _registerDescendant(final String loggerName) {
    for (final ancestor in _getAncestors(loggerName)) {
      _descendants.putIfAbsent(ancestor, () => {}).add(loggerName);
    }
  }

  static void _unregisterLogger(final String loggerName) {
    for (final ancestor in _getAncestors(loggerName)) {
      _descendants[ancestor]?.remove(loggerName);
    }
    _descendants.remove(loggerName);
  }

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

  /// Resolves the effective [autoSinkBuffer] for [loggerName].
  static bool autoSinkBuffer(final String loggerName) =>
      _resolve(Logger._normalizeName(loggerName)).autoSinkBuffer;

  /// Internal: Resolves and caches the effective configuration for
  /// [loggerName]. Expects [loggerName] to be normalized.
  @pragma('vm:prefer-inline')
  static _ResolvedConfig _resolve(final String loggerName) {
    if (!Logger._registry.containsKey(loggerName)) {
      Logger._registerLogger(loggerName);
    }
    final config = Logger._registry[loggerName]!;
    final cached = _cache[loggerName];

    if (cached != null && cached.version == config._version) {
      return cached;
    }

    return _resolveSlow(loggerName, config);
  }

  static _ResolvedConfig _resolveSlow(
    final String loggerName,
    final LoggerConfig config,
  ) {
    // Resolve by walking hierarchy
    var currentName = loggerName;
    bool? resolvedEnabled;
    LogLevel? resolvedLogLevel;
    bool? resolvedIncludeFileLineInHeader;
    Map<LogLevel, int>? resolvedStackMethodCount;
    Timestamp? resolvedTimestamp;
    StackTraceParser? resolvedStackTraceParser;
    List<Handler>? resolvedHandlers;
    bool? resolvedAutoSinkBuffer;

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
        resolvedAutoSinkBuffer ??= cSource.autoSinkBuffer;
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
      enabled: resolvedEnabled ?? true,
      logLevel: resolvedLogLevel ?? LogLevel.debug,
      includeFileLineInHeader: resolvedIncludeFileLineInHeader ?? false,
      stackMethodCount: Map.unmodifiable(
        resolvedStackMethodCount ??
            Map.unmodifiable({
              LogLevel.trace: 0,
              LogLevel.debug: 0,
              LogLevel.info: 0,
              LogLevel.warning: 2,
              LogLevel.error: 8,
            }),
      ),
      timestamp: resolvedTimestamp ??
          Timestamp(
            formatter: 'yyyy.MMM.dd Z HH:mm:ss.SSS',
            timezone: Timezone.local(),
          ),
      stackTraceParser: resolvedStackTraceParser ??
          const StackTraceParser(
            ignorePackages: ['logd', 'flutter'],
          ),
      handlers: List.unmodifiable(
        resolvedHandlers ??
            <Handler>[
              const Handler(
                formatter: StructuredFormatter(),
                sink: ConsoleSink(),
                decorators: [BoxDecorator()],
              ),
            ],
      ),
      autoSinkBuffer: resolvedAutoSinkBuffer ?? false,
    );

    _cache[loggerName] = resolved;
    return resolved;
  }

  /// Invalidates the cache for a specific logger and all its descendants.
  static void invalidate(final String loggerName) {
    final normalized = Logger._normalizeName(loggerName);
    _cache.remove(normalized);
    final descendantsList = _descendants[normalized];
    if (descendantsList != null) {
      for (final descendant in descendantsList) {
        _cache.remove(descendant);
      }
    }
  }

  /// Clears the entire logger cache.
  static void clear() {
    _cache.clear();
    _descendants.clear();
  }
}

/// Internal container for resolved logger settings.
@immutable
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
    required this.autoSinkBuffer,
  });

  final int version;
  final bool enabled;
  final LogLevel logLevel;
  final bool includeFileLineInHeader;
  final Map<LogLevel, int> stackMethodCount;
  final Timestamp timestamp;
  final StackTraceParser stackTraceParser;
  final List<Handler> handlers;
  final bool autoSinkBuffer;
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
  /// Valid names must match `^[a-z0-9_]+(\.[a-z0-9_]+)*$`.
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
  static void _registerLogger(final String name) {
    if (!_registry.containsKey(name)) {
      _registry[name] = LoggerConfig();
      LoggerCache._registerDescendant(name);
    }
  }

  /// - Basic: Logger.get('app').info('Message');
  /// - Global: Logger.get(), Logger.get(''), Logger.get('global')
  ///
  /// Returns: The logger instance.
  ///
  /// Example: final uiLogger = Logger.get('app.ui');
  static Logger get([final String? name]) {
    final normalized = _normalizeName(name);
    _registerLogger(normalized);
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
  /// - [stackMethodCount]: Stack frames per level. Values must be non-negative.
  /// - [timestamp]: Timestamp config.
  /// - [stackTraceParser]: Stack parser config.
  /// - [handlers]: List of handlers. Must not be empty if provided.
  /// - [autoSinkBuffer]: Whether to auto-sink abandoned buffers.
  ///
  /// Throws [ArgumentError] if:
  /// - Any [stackMethodCount] value is negative.
  /// - [handlers] is an empty list.
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
    final bool? autoSinkBuffer,
  }) {
    // Input validation
    if (stackMethodCount != null) {
      for (final entry in stackMethodCount.entries) {
        if (entry.value < 0) {
          throw ArgumentError.value(
            entry.value,
            'stackMethodCount[${entry.key}]',
            'Stack method count cannot be negative',
          );
        }
      }
    }
    if (handlers != null && handlers.isEmpty) {
      throw ArgumentError.value(
        handlers,
        'handlers',
        'Handlers list cannot be empty',
      );
    }

    final normalized = _normalizeName(name);
    _registerLogger(normalized);
    final config = _registry[normalized]!
      // Mark as explicitly configured (not a ghost/implicit node).
      .._implicit = false;

    bool changed = false;
    if (enabled != null) {
      final removed = config._frozenFields.remove('enabled');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'enabled' was frozen; configure() has promoted "
          "it to explicit. Call unfreezeInheritance() first to restore dynamic "
          'resolution instead.',
        );
      }
      if (enabled != config.enabled || removed) {
        config.enabled = enabled;
        changed = true;
      }
    }
    if (logLevel != null) {
      final removed = config._frozenFields.remove('logLevel');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'logLevel' was frozen; configure() has promoted "
          "it to explicit. Call unfreezeInheritance() first to restore dynamic "
          'resolution instead.',
        );
      }
      if (logLevel != config.logLevel || removed) {
        config.logLevel = logLevel;
        changed = true;
      }
    }
    if (includeFileLineInHeader != null) {
      final removed = config._frozenFields.remove('includeFileLineInHeader');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'includeFileLineInHeader' was frozen; "
          'configure() has promoted it to explicit. Call '
          'unfreezeInheritance() first to restore dynamic resolution instead.',
        );
      }
      if (includeFileLineInHeader != config.includeFileLineInHeader ||
          removed) {
        config.includeFileLineInHeader = includeFileLineInHeader;
        changed = true;
      }
    }
    if (stackMethodCount != null) {
      final removed = config._frozenFields.remove('stackMethodCount');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'stackMethodCount' was frozen; configure() has "
          "promoted it to explicit. Call unfreezeInheritance() first to "
          'restore dynamic resolution instead.',
        );
      }
      if (!mapEquals(stackMethodCount, config.stackMethodCount) || removed) {
        config.stackMethodCount = stackMethodCount;
        changed = true;
      }
    }
    if (timestamp != null) {
      final removed = config._frozenFields.remove('timestamp');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'timestamp' was frozen; configure() has "
          "promoted it to explicit. Call unfreezeInheritance() first to "
          'restore dynamic resolution instead.',
        );
      }
      if (timestamp != config.timestamp || removed) {
        config.timestamp = timestamp;
        changed = true;
      }
    }
    if (stackTraceParser != null) {
      final removed = config._frozenFields.remove('stackTraceParser');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'stackTraceParser' was frozen; configure() has "
          "promoted it to explicit. Call unfreezeInheritance() first to "
          'restore dynamic resolution instead.',
        );
      }
      if (stackTraceParser != config.stackTraceParser || removed) {
        config.stackTraceParser = stackTraceParser;
        changed = true;
      }
    }
    if (handlers != null) {
      final removed = config._frozenFields.remove('handlers');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'handlers' was frozen; configure() has promoted "
          "it to explicit. Call unfreezeInheritance() first to restore dynamic "
          'resolution instead.',
        );
      }
      if (!listEquals(handlers, config.handlers) || removed) {
        config.handlers = handlers;
        changed = true;
      }
    }
    if (autoSinkBuffer != null) {
      final removed = config._frozenFields.remove('autoSinkBuffer');
      if (removed) {
        InternalLogger.log(
          LogLevel.warning,
          "'$normalized' field 'autoSinkBuffer' was frozen; configure() has "
          "promoted it to explicit. Call unfreezeInheritance() first to "
          'restore dynamic resolution instead.',
        );
      }
      if (autoSinkBuffer != config.autoSinkBuffer || removed) {
        config.autoSinkBuffer = autoSinkBuffer;
        changed = true;
      }
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
  ///
  /// **Note**: Returns an **unmodifiable** map.
  @pragma('vm:prefer-inline')
  Map<LogLevel, int> get stackMethodCount => LoggerCache.stackMethodCount(name);

  /// The timestamp formatter configuration.
  Timestamp get timestamp => LoggerCache.timestamp(name);

  /// The stack trace parser configuration.
  StackTraceParser get stackTraceParser => LoggerCache.stackTraceParser(name);

  /// List of handlers to process log entries.
  ///
  /// **Note**: Returns an **unmodifiable** list.
  @pragma('vm:prefer-inline')
  List<Handler> get handlers => LoggerCache.handlers(name);

  /// Whether to auto-sink abandoned buffers.
  bool get autoSinkBuffer => LoggerCache.autoSinkBuffer(name);

  /// Freezes the current inherited configurations into descendant loggers.
  ///
  /// "Bakes" this logger's effective configs down the logger tree where
  /// children have not explicitly set a field. Useful for performance (reduces
  /// resolution depth) or to snapshot state so future parent changes don't
  /// propagate dynamically.
  ///
  /// Parameters:
  /// - [force]: When `true`, re-snapshots fields that are already frozen on
  ///   descendants (updates them to this logger's current effective value).
  ///   Explicit user overrides are **never** overwritten by [force].
  ///   Defaults to `false` (original behaviour — skips already-set fields).
  ///
  /// Returns the total number of fields written across all affected
  /// descendants. A return value of `0` means the call was a complete no-op.
  ///
  /// How to use:
  /// - Call on a logger to apply to all descendants recursively via registry.
  /// - `force: true` is useful after a parent config change to re-snapshot.
  ///
  /// Example:
  ///   final written = parentLogger.freezeInheritance();
  ///   parentLogger.freezeInheritance(force: true); // re-snapshot
  int freezeInheritance({final bool force = false}) {
    final callerConfig = _registry[name];
    if (callerConfig != null &&
        callerConfig._implicit &&
        callerConfig._frozenFields.isEmpty) {
      InternalLogger.log(
        LogLevel.warning,
        "freezeInheritance() called on implicit node '$name'. "
        'This node was never explicitly configured. The freeze will propagate '
        "resolved defaults. Consider calling Logger.configure('$name', ...) "
        'first if intentional.',
      );
    }

    int writtenCount = 0;
    for (final key in _registry.keys.toList()) {
      if (key == name || _isDescendant(key, name)) {
        final childConfig = _registry[key]!;
        bool changed = false;

        // Helper: should this field be written?
        // force=false → only if null; force=true → if null OR already frozen
        // (but never if explicitly set by user).
        bool shouldWrite({
          required final String field,
          required final bool isNull,
        }) =>
            isNull || (force && childConfig._frozenFields.contains(field));

        if (shouldWrite(
          field: 'enabled',
          isNull: childConfig.enabled == null,
        )) {
          childConfig.enabled = enabled;
          childConfig._frozenFields.add('enabled');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'logLevel',
          isNull: childConfig.logLevel == null,
        )) {
          childConfig.logLevel = logLevel;
          childConfig._frozenFields.add('logLevel');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'includeFileLineInHeader',
          isNull: childConfig.includeFileLineInHeader == null,
        )) {
          childConfig.includeFileLineInHeader = includeFileLineInHeader;
          childConfig._frozenFields.add('includeFileLineInHeader');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'stackMethodCount',
          isNull: childConfig.stackMethodCount == null,
        )) {
          childConfig.stackMethodCount = Map.from(stackMethodCount);
          childConfig._frozenFields.add('stackMethodCount');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'timestamp',
          isNull: childConfig.timestamp == null,
        )) {
          childConfig.timestamp = timestamp;
          childConfig._frozenFields.add('timestamp');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'stackTraceParser',
          isNull: childConfig.stackTraceParser == null,
        )) {
          childConfig.stackTraceParser = stackTraceParser;
          childConfig._frozenFields.add('stackTraceParser');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'handlers',
          isNull: childConfig.handlers == null,
        )) {
          childConfig.handlers = List.from(handlers);
          childConfig._frozenFields.add('handlers');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'autoSinkBuffer',
          isNull: childConfig.autoSinkBuffer == null,
        )) {
          childConfig.autoSinkBuffer = autoSinkBuffer;
          childConfig._frozenFields.add('autoSinkBuffer');
          changed = true;
          writtenCount++;
        }
        if (changed) {
          childConfig._version++;
          LoggerCache.invalidate(key);
        }
      }
    }
    return writtenCount;
  }

  /// Unfreezes configurations that were previously frozen on descendant
  /// loggers.
  ///
  /// Reverts fields populated by [freezeInheritance] back to `null`, restoring
  /// Unfreezes configurations that were previously frozen on descendant
  /// loggers.
  ///
  /// Reverts fields populated by [freezeInheritance] back to `null`, restoring
  /// dynamic resolution from ancestor loggers. Fields that were explicitly
  /// configured by the user are not affected.
  ///
  /// Parameters:
  /// - [fields]: Optional set of field names to selectively unfreeze. When
  ///   provided, only those named fields are cleared — all other frozen fields
  ///   are left intact. Unknown field names are silently ignored.
  ///   When `null` (default), all frozen fields are cleared.
  /// - [includeSelf]: Whether to also unfreeze the receiver's own frozen
  ///   fields. Defaults to `true`. Pass `false` to restrict the operation to
  ///   strict descendants only.
  ///
  /// Example:
  ///   // Full subtree unfreeze (default)
  ///   logger.unfreezeInheritance();
  ///   // Unfreeze only logLevel, excluding self
  ///   logger.unfreezeInheritance(fields: {'logLevel'}, includeSelf: false);
  void unfreezeInheritance({
    final Set<String>? fields,
    final bool includeSelf = true,
  }) {
    for (final key in _registry.keys.toList()) {
      final isSelf = key == name;
      if ((isSelf && !includeSelf) || (!isSelf && !_isDescendant(key, name))) {
        continue;
      }
      final childConfig = _registry[key]!;
      bool changed = false;
      if (childConfig._frozenFields.isNotEmpty) {
        // Determine which frozen fields to actually clear.
        final toClear = fields == null
            ? Set.of(childConfig._frozenFields)
            : childConfig._frozenFields.intersection(fields);

        for (final field in toClear) {
          switch (field) {
            case 'enabled':
              childConfig.enabled = null;
            case 'logLevel':
              childConfig.logLevel = null;
            case 'includeFileLineInHeader':
              childConfig.includeFileLineInHeader = null;
            case 'stackMethodCount':
              childConfig.stackMethodCount = null;
            case 'timestamp':
              childConfig.timestamp = null;
            case 'stackTraceParser':
              childConfig.stackTraceParser = null;
            case 'handlers':
              childConfig.handlers = null;
            case 'autoSinkBuffer':
              childConfig.autoSinkBuffer = null;
          }
          childConfig._frozenFields.remove(field);
          changed = true;
        }
      }
      if (changed) {
        childConfig._version++;
        LoggerCache.invalidate(key);
      }
    }
  }

  /// The set of fields that have been explicitly configured on this logger.
  Set<String> get explicitFields {
    final config = _registry[name];
    if (config == null) {
      return const {};
    }
    final fields = <String>{};
    if (config.enabled != null && !config._frozenFields.contains('enabled')) {
      fields.add('enabled');
    }
    if (config.logLevel != null && !config._frozenFields.contains('logLevel')) {
      fields.add('logLevel');
    }
    if (config.includeFileLineInHeader != null &&
        !config._frozenFields.contains('includeFileLineInHeader')) {
      fields.add('includeFileLineInHeader');
    }
    if (config.stackMethodCount != null &&
        !config._frozenFields.contains('stackMethodCount')) {
      fields.add('stackMethodCount');
    }
    if (config.timestamp != null &&
        !config._frozenFields.contains('timestamp')) {
      fields.add('timestamp');
    }
    if (config.stackTraceParser != null &&
        !config._frozenFields.contains('stackTraceParser')) {
      fields.add('stackTraceParser');
    }
    if (config.handlers != null && !config._frozenFields.contains('handlers')) {
      fields.add('handlers');
    }
    if (config.autoSinkBuffer != null &&
        !config._frozenFields.contains('autoSinkBuffer')) {
      fields.add('autoSinkBuffer');
    }
    return fields;
  }

  /// The set of fields that were frozen on this logger by [freezeInheritance].
  Set<String> get frozenFields {
    final config = _registry[name];
    if (config == null) {
      return const {};
    }
    return Set.unmodifiable(config._frozenFields);
  }

  /// The set of fields that are currently inherited from ancestor loggers.
  Set<String> get inheritedFields {
    final config = _registry[name];
    if (config == null) {
      return const {
        'enabled',
        'logLevel',
        'includeFileLineInHeader',
        'stackMethodCount',
        'timestamp',
        'stackTraceParser',
        'handlers',
        'autoSinkBuffer',
      };
    }
    final fields = <String>{};
    if (config.enabled == null) {
      fields.add('enabled');
    }
    if (config.logLevel == null) {
      fields.add('logLevel');
    }
    if (config.includeFileLineInHeader == null) {
      fields.add('includeFileLineInHeader');
    }
    if (config.stackMethodCount == null) {
      fields.add('stackMethodCount');
    }
    if (config.timestamp == null) {
      fields.add('timestamp');
    }
    if (config.stackTraceParser == null) {
      fields.add('stackTraceParser');
    }
    if (config.handlers == null) {
      fields.add('handlers');
    }
    if (config.autoSinkBuffer == null) {
      fields.add('autoSinkBuffer');
    }
    return fields;
  }

  /// Exports the registry configuration hierarchy.
  ///
  /// Returns a map representation of the active loggers and their configuration
  /// states, including explicit, frozen, inherited, and effective fields.
  ///
  /// Each entry contains:
  /// - `'explicit'`: Fields explicitly set by [Logger.configure] on this node.
  /// - `'frozen'`: Fields baked in by [freezeInheritance].
  /// - `'inherited'`: Fields resolved dynamically from ancestor loggers.
  /// - `'implicit'`: `true` if this logger was only materialised by
  ///   [Logger.get] and was never passed to [Logger.configure].
  /// - `'effective'`: Resolved field values as JSON-serialisable primitives.
  ///   Useful for crash diagnostics and debug overlays.
  static Map<String, dynamic> exportHierarchy() {
    final map = <String, dynamic>{};
    final sortedKeys = _registry.keys.toList()..sort();
    for (final n in sortedKeys) {
      final logger = Logger.get(n);
      final config = _registry[n]!;

      // Build effective map with JSON-serialisable primitives.
      final smc = logger.stackMethodCount;
      final effective = <String, dynamic>{
        'enabled': logger.enabled,
        'logLevel': logger.logLevel.name,
        'includeFileLineInHeader': logger.includeFileLineInHeader,
        'stackMethodCount': {
          for (final e in smc.entries) e.key.name: e.value,
        },
        'timestamp': logger.timestamp.formatter.pattern,
        'stackTraceParser': logger.stackTraceParser.ignorePackages.toString(),
        'handlers': logger.handlers
            .map(
              (final h) => '${h.formatter.runtimeType}(${h.sink.runtimeType})',
            )
            .toList(),
        'autoSinkBuffer': logger.autoSinkBuffer,
      };

      map[n] = {
        'explicit': logger.explicitFields.toList(),
        'frozen': logger.frozenFields.toList(),
        'inherited': logger.inheritedFields.toList(),
        'implicit': config._implicit,
        'effective': effective,
      };
    }
    return map;
  }

  /// Returns a formatted string representation of the active logger hierarchy.
  ///
  /// Each line includes the logger name, its depth-indented short name, field
  /// state annotations (explicit / frozen) with their current values, and an
  /// `(implicit)` label for loggers that were never explicitly configured.
  ///
  /// This is the pure string-builder counterpart to [printHierarchy]. Use it
  /// to embed hierarchy output in crash reports, debug overlays, or tests.
  static String formatHierarchy() {
    final hierarchy = exportHierarchy();
    final sortedKeys = hierarchy.keys.toList()..sort();
    final buf = StringBuffer();
    for (final key in sortedKeys) {
      final data = hierarchy[key] as Map<String, dynamic>;
      final indent = '  ' * (key.split('.').length - 1);
      final displayName = key.split('.').last;
      final isImplicit = data['implicit'] as bool;
      final effective = data['effective'] as Map<String, dynamic>;

      final details = <String>[];
      final explicit = (data['explicit'] as List).cast<String>();
      final frozen = (data['frozen'] as List).cast<String>();

      if (explicit.isNotEmpty) {
        final annotations =
            explicit.map((final f) => '$f=${effective[f]}').join(', ');
        details.add('explicit: $annotations');
      }
      if (frozen.isNotEmpty) {
        final annotations =
            frozen.map((final f) => '$f=${effective[f]}').join(', ');
        details.add('frozen: $annotations');
      }

      final implicitLabel = isImplicit ? ' (implicit)' : '';
      final suffix = details.isEmpty ? '' : ' [${details.join(" | ")}]';
      buf.writeln('$indent- $displayName ($key)$implicitLabel$suffix');
    }
    return buf.toString().trimRight();
  }

  /// Prints a visual representation of the active logger hierarchy.
  ///
  /// By default routes output through [InternalLogger] at the debug level so
  /// it is test-capturable and production-safe. Pass a custom [sink] to
  /// redirect output (e.g. `debugPrint`, or a list collector in tests).
  ///
  /// Use [formatHierarchy] directly to obtain the string without side-effects.
  static void printHierarchy({final void Function(String)? sink}) {
    final output = formatHierarchy();
    if (sink != null) {
      sink(output);
    } else {
      InternalLogger.log(LogLevel.debug, 'Logger hierarchy:\n$output');
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
  /// - Sink to log: buf?.sink();
  ///
  /// Example: logger.traceBuffer?..writeln('Trace start')..sink();
  LogBuffer? get traceBuffer =>
      enabled ? LogBuffer._(this, LogLevel.trace) : null;

  /// Returns a buffer for building multi-line debug-level logs.
  ///
  /// Intentions: Similar to traceBuffer, but for debug messages. Helps in
  /// constructing detailed debug output without interleaving.
  ///
  /// Example: logger.debugBuffer?..writeln('Debug start')..sink();
  LogBuffer? get debugBuffer =>
      enabled ? LogBuffer._(this, LogLevel.debug) : null;

  /// Returns a buffer for building multi-line info-level logs.
  ///
  /// Intentions: For informational messages that may span multiple lines.
  ///
  /// Example: logger.infoBuffer?..writeln('Info start')..sink();
  LogBuffer? get infoBuffer =>
      enabled ? LogBuffer._(this, LogLevel.info) : null;

  /// Returns a buffer for building multi-line warning-level logs.
  ///
  /// Intentions: For warnings that require detailed, multi-line descriptions.
  ///
  /// Example: logger.warningBuffer?..writeln('Warning start')..sink();
  LogBuffer? get warningBuffer =>
      enabled ? LogBuffer._(this, LogLevel.warning) : null;

  /// Returns a buffer for building multi-line error-level logs.
  ///
  /// Intentions: For errors with stack traces or multi-line details.
  ///
  /// Example: logger.errorBuffer?..writeln('Error start')..sink();
  LogBuffer? get errorBuffer =>
      enabled ? LogBuffer._(this, LogLevel.error) : null;

  /// Logs a trace-level message.
  ///
  /// Intentions: For fine-grained diagnostic information.
  /// Optional error and stackTrace for context.
  ///
  /// Parameters:
  /// - [message]: The log message (converted to string).
  /// - [error]: Optional associated error object.
  /// - [stackTrace]: Optional stack trace (defaults to current).
  ///
  /// How to use: logger.trace('Trace event', error: e);
  void trace(
    final Object? message, {
    final Map<String, dynamic>? context,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.trace, message, error, stackTrace, context)
          .catchError((final e) {
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
    final Map<String, dynamic>? context,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.debug, message, error, stackTrace, context)
          .catchError((final e) {
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
    final Map<String, dynamic>? context,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.info, message, error, stackTrace, context)
          .catchError((final e) {
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
    final Map<String, dynamic>? context,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.warning, message, error, stackTrace, context)
          .catchError((final e) {
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
    final Map<String, dynamic>? context,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, message, error, stackTrace, context)
          .catchError((final e) {
        InternalLogger.log(LogLevel.error, 'Logging failure', error: e);
      });

  /// Internal: Processes a log event, creating and dispatching a LogEntry.
  ///
  /// Checks enabled and level, extracts caller, builds entry, and sends to
  /// handlers.
  ///
  /// **Null messages**: A `null` message produces an empty string in the
  /// log output. It is not converted to `"null"` and is not skipped.
  ///
  /// Parameters:
  /// - [level]: The log level.
  /// - [message]: The message object (null produces an empty string).
  /// - [error]: Optional error.
  /// - [stackTrace]: Optional or current stack trace.
  Future<void> _log(
    final LogLevel level,
    final Object? message,
    final Object? error,
    final StackTrace? stackTrace, [
    final Map<String, dynamic>? context,
  ]) async {
    if (!enabled || level.index < logLevel.index) {
      return;
    }
    final frameCount = stackMethodCount[level] ?? 0;
    final parsed = stackTraceParser.parse(
      stackTrace: stackTrace ?? StackTrace.current,
      skipFrames: 1,
      maxFrames: frameCount,
    );
    if (parsed.caller == null) {
      return;
    }
    final entry = Arena.instance.checkoutLogEntry(
      loggerName: name,
      level: level,
      message: message?.toString() ?? '',
      timestamp: timestamp.timestamp ?? '',
      origin: _buildOrigin(parsed.caller!),
      stackFrames: parsed.frames.isEmpty ? null : parsed.frames,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    try {
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
    } finally {
      Arena.instance.releaseLogEntry(entry);
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

  /// Internal: Helper for retrieving parent name.
  static String? _getParentName(final String name) {
    if (name == 'global') {
      return null;
    }
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1) {
      return 'global';
    }
    return name.substring(0, lastDot);
  }

  /// Internal: Normalizes logger name to lowercase for case-insensitivity.
  ///
  /// Resolves null, empty strings and any form of 'global' to 'global'.
  static String _normalizeName([final String? name]) {
    final lower = name?.toLowerCase() ?? 'global';
    final normalized = lower.isEmpty ? 'global' : lower;

    if (!_nameRegex.hasMatch(normalized)) {
      throw ArgumentError.value(
          name,
          'name',
          'Logger name must be strictly alphanumeric (with underscores) '
              'and separated by dots (e.g. "app.ui.widget"). '
              'Invalid name: "$normalized"');
    }

    return normalized;
  }

  static final _nameRegex = RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)*$');

  /// Attach to Flutter errors.
  static void attachToFlutterErrors() {
    flutter_stubs.attachToFlutterErrors();
  }

  /// Clears the logger registry for the specified [loggerName] and all its
  /// descendants, restoring them to default unresolved settings.
  ///
  /// If [loggerName] is not specified (or is `'global'`), the entire registry
  /// is cleared.
  ///
  /// WARNING: This will remove custom configurations and cached resolution
  /// states.
  static void reset([final String? loggerName]) {
    final name = loggerName == null ? 'global' : _normalizeName(loggerName);
    if (name == 'global') {
      _registry.clear();
      LoggerCache.clear();
    } else {
      LoggerCache.invalidate(name);
      _registry.remove(name);
      LoggerCache._unregisterLogger(name);
      for (final key in _registry.keys.toList()) {
        if (_isDescendant(key, name)) {
          _registry.remove(key);
          LoggerCache._unregisterLogger(key);
        }
      }
    }
  }
}
