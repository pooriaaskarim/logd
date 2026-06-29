import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../core/log_level.dart';
import '../core/theme/log_theme.dart';
import '../core/utils/utils.dart';
import '../handler/handler.dart';
import '../stack_trace/stack_trace.dart';
import '../time/timestamp.dart';
import '../time/timezone.dart';

export '../core/log_level.dart';

part 'internal_logger.dart';
part 'log_buffer.dart';
part 'log_entry.dart';
part 'serialization_registry.dart';

/// Configuration overrides for a [Logger], holding optional fields that
/// can inherit from parent.
@immutable
class LoggerConfig {
  factory LoggerConfig.fromJson(final Map<String, dynamic> json) {
    final handlersJson = json['handlers'] as List?;
    final handlers = handlersJson?.map((final hMap) {
      final h = Map<String, dynamic>.from(hMap as Map);
      return Handler(
        formatter: LoggerSerializationRegistry.deserializeFormatter(
          Map<String, dynamic>.from(h['formatter'] as Map),
        ),
        sink: LoggerSerializationRegistry.deserializeSink(
          Map<String, dynamic>.from(h['sink'] as Map),
        ),
        filters: (h['filters'] as List)
            .map(
              (final f) => LoggerSerializationRegistry.deserializeFilter(
                Map<String, dynamic>.from(f as Map),
              ),
            )
            .toList(),
        decorators: (h['decorators'] as List)
            .map(
              (final d) => LoggerSerializationRegistry.deserializeDecorator(
                Map<String, dynamic>.from(d as Map),
              ),
            )
            .toList(),
        engine: LoggerSerializationRegistry.deserializeEngine(
          Map<String, dynamic>.from(h['engine'] as Map),
        ),
      );
    }).toList();

    final smcJson = json['stackMethodCount'] as Map?;
    final smc = smcJson == null
        ? null
        : <LogLevel, int>{
            for (final entry in smcJson.entries)
              LogLevel.values.byName(entry.key as String): entry.value as int,
          };

    final tsJson = json['timestamp'] as Map?;
    final timestamp = tsJson == null
        ? null
        : Timestamp(
            formatter: tsJson['formatter'] as String,
            timezone: tsJson['timezone'] != null
                ? Timezone.named(tsJson['timezone'] as String)
                : null,
          );

    final stJson = json['stackTraceParser'] as Map?;
    final stackTraceParser = stJson == null
        ? null
        : StackTraceParser(
            ignorePackages: List<String>.from(stJson['ignorePackages'] as List),
            includeAsyncOrigin: stJson['includeAsyncOrigin'] as bool? ?? false,
          );

    return LoggerConfig(
      enabled: json['enabled'] as bool?,
      logLevel: json['logLevel'] != null
          ? LogLevel.values.byName(json['logLevel'] as String)
          : null,
      includeFileLineInHeader: json['includeFileLineInHeader'] as bool?,
      stackMethodCount: smc,
      timestamp: timestamp,
      stackTraceParser: stackTraceParser,
      handlers: handlers,
      autoSinkBuffer: json['autoSinkBuffer'] as bool?,
      version: json['version'] as int? ?? 0,
      frozenFields: Set<String>.from(json['frozenFields'] as List? ?? const []),
      implicit: json['implicit'] as bool? ?? true,
    );
  }

  /// Creates a [LoggerConfig].
  const LoggerConfig({
    this.enabled,
    this.logLevel,
    this.includeFileLineInHeader,
    this.stackMethodCount,
    this.timestamp,
    this.stackTraceParser,
    this.handlers,
    this.autoSinkBuffer,
    this.version = 0,
    this.frozenFields = const {},
    this.implicit = true,
  });

  /// Optional: Whether logging is enabled. Inherits from parent if null.
  final bool? enabled;

  /// Optional: Minimum log level to process. Inherits from parent if null.
  final LogLevel? logLevel;

  /// Optional: Include file/line in origin. Inherits from parent if null.
  final bool? includeFileLineInHeader;

  /// Optional: Stack frames per level. Inherits from parent if null.
  final Map<LogLevel, int>? stackMethodCount;

  /// Optional: Timestamp config. Inherits from parent if null.
  final Timestamp? timestamp;

  /// Optional: Stack parser config. Inherits from parent if null.
  final StackTraceParser? stackTraceParser;

  /// Optional: List of handlers. Inherits from parent if null.
  final List<Handler>? handlers;

  /// Optional: Whether to automatically sink abandoned buffers.
  ///
  /// If true, buffers collected by GC will be logged with a warning.
  /// If false (default), data is lost and a severe error is logged.
  final bool? autoSinkBuffer;

  /// Cache version tracker.
  final int version;

  /// The set of fields that were populated by `freezeInheritance`.
  final Set<String> frozenFields;

  /// Whether this logger was implicitly materialised by [Logger.get] without
  /// ever being explicitly configured via [Logger.configure].
  ///
  /// An implicit logger inherits everything from its ancestors and produces no
  /// explicit or frozen fields of its own. It is a phantom node in the
  /// registry and [Logger.exportHierarchy] marks it accordingly.
  final bool implicit;

  /// Creates a copy of this [LoggerConfig] with updated fields.
  LoggerConfig copyWith({
    final Object? enabled = const Object(),
    final Object? logLevel = const Object(),
    final Object? includeFileLineInHeader = const Object(),
    final Object? stackMethodCount = const Object(),
    final Object? timestamp = const Object(),
    final Object? stackTraceParser = const Object(),
    final Object? handlers = const Object(),
    final Object? autoSinkBuffer = const Object(),
    final int? version,
    final Set<String>? frozenFields,
    final bool? implicit,
  }) =>
      LoggerConfig(
        enabled: enabled == const Object() ? this.enabled : (enabled as bool?),
        logLevel: logLevel == const Object()
            ? this.logLevel
            : (logLevel as LogLevel?),
        includeFileLineInHeader: includeFileLineInHeader == const Object()
            ? this.includeFileLineInHeader
            : (includeFileLineInHeader as bool?),
        stackMethodCount: stackMethodCount == const Object()
            ? this.stackMethodCount
            : (stackMethodCount as Map<LogLevel, int>?),
        timestamp: timestamp == const Object()
            ? this.timestamp
            : (timestamp as Timestamp?),
        stackTraceParser: stackTraceParser == const Object()
            ? this.stackTraceParser
            : (stackTraceParser as StackTraceParser?),
        handlers: handlers == const Object()
            ? this.handlers
            : (handlers as List<Handler>?),
        autoSinkBuffer: autoSinkBuffer == const Object()
            ? this.autoSinkBuffer
            : (autoSinkBuffer as bool?),
        version: version ?? this.version,
        frozenFields: frozenFields ?? this.frozenFields,
        implicit: implicit ?? this.implicit,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (enabled != null) 'enabled': enabled,
        if (logLevel != null) 'logLevel': logLevel!.name,
        if (includeFileLineInHeader != null)
          'includeFileLineInHeader': includeFileLineInHeader,
        if (stackMethodCount != null)
          'stackMethodCount': <String, int>{
            for (final entry in stackMethodCount!.entries)
              entry.key.name: entry.value,
          },
        if (timestamp != null)
          'timestamp': <String, dynamic>{
            'formatter': timestamp!.formatter.pattern,
            if (timestamp!.timezone != null)
              'timezone': timestamp!.timezone!.name,
          },
        if (stackTraceParser != null)
          'stackTraceParser': <String, dynamic>{
            'ignorePackages': stackTraceParser!.ignorePackages,
            'includeAsyncOrigin': stackTraceParser!.includeAsyncOrigin,
          },
        if (handlers != null)
          'handlers': handlers!
              .map(
                (final h) => <String, dynamic>{
                  'formatter': LoggerSerializationRegistry.serializeFormatter(
                    h.formatter,
                  ),
                  'sink': LoggerSerializationRegistry.serializeSink(h.sink),
                  'filters': h.filters
                      .map(LoggerSerializationRegistry.serializeFilter)
                      .toList(),
                  'decorators': h.decorators
                      .map(LoggerSerializationRegistry.serializeDecorator)
                      .toList(),
                  'engine':
                      LoggerSerializationRegistry.serializeEngine(h.engine),
                },
              )
              .toList(),
        if (autoSinkBuffer != null) 'autoSinkBuffer': autoSinkBuffer,
        'version': version,
        'frozenFields': frozenFields.toList(),
        'implicit': implicit,
      };
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
    if (cached != null && cached.version == config.version) {
      LoggerMetrics._cacheHits++;
      return cached;
    }

    LoggerMetrics._cacheMisses++;
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
        if (cSource.stackMethodCount != null) {
          resolvedStackMethodCount ??= {};
          for (final entry in cSource.stackMethodCount!.entries) {
            resolvedStackMethodCount.putIfAbsent(entry.key, () => entry.value);
          }
        }
        resolvedTimestamp ??= cSource.timestamp;
        resolvedStackTraceParser ??= cSource.stackTraceParser;
        resolvedHandlers ??= cSource.handlers;
        resolvedAutoSinkBuffer ??= cSource.autoSinkBuffer;
      }

      if (Logger._patternRules.isNotEmpty) {
        for (var i = Logger._patternRules.length - 1; i >= 0; i--) {
          final rule = Logger._patternRules[i];
          if (rule.regExp.hasMatch(currentName)) {
            final pSource = rule.config;
            resolvedEnabled ??= pSource.enabled;
            resolvedLogLevel ??= pSource.logLevel;
            resolvedIncludeFileLineInHeader ??= pSource.includeFileLineInHeader;
            if (pSource.stackMethodCount != null) {
              resolvedStackMethodCount ??= {};
              for (final entry in pSource.stackMethodCount!.entries) {
                resolvedStackMethodCount.putIfAbsent(
                  entry.key,
                  () => entry.value,
                );
              }
            }
            resolvedTimestamp ??= pSource.timestamp;
            resolvedStackTraceParser ??= pSource.stackTraceParser;
            resolvedHandlers ??= pSource.handlers;
            resolvedAutoSinkBuffer ??= pSource.autoSinkBuffer;
          }
        }
      }

      final parentName = Logger._getParentName(currentName);
      if (parentName == null) {
        break;
      }
      currentName = parentName;
    }

    // Merge partial stackMethodCount with default fallback values
    final defaultStackMethodCount = {
      LogLevel.trace: 0,
      LogLevel.debug: 0,
      LogLevel.info: 0,
      LogLevel.warning: 2,
      LogLevel.error: 8,
    };
    final Map<LogLevel, int> finalStackMethodCount = {};
    if (resolvedStackMethodCount != null) {
      finalStackMethodCount.addAll(resolvedStackMethodCount);
    }
    for (final entry in defaultStackMethodCount.entries) {
      finalStackMethodCount.putIfAbsent(entry.key, () => entry.value);
    }

    // Ensure resolved collections are unmodifiable
    // to prevent external mutation.
    final resolved = _ResolvedConfig(
      version: config.version,
      enabled: resolvedEnabled ?? true,
      logLevel: resolvedLogLevel ?? LogLevel.debug,
      includeFileLineInHeader: resolvedIncludeFileLineInHeader ?? false,
      stackMethodCount: Map.unmodifiable(finalStackMethodCount),
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
    if (_cache.remove(normalized) != null) {
      LoggerMetrics._cacheInvalidations++;
    }
    final descendantsList = _descendants[normalized];
    if (descendantsList != null) {
      for (final descendant in descendantsList) {
        if (_cache.remove(descendant) != null) {
          LoggerMetrics._cacheInvalidations++;
        }
      }
    }
  }

  /// Invalidates the cache for multiple loggers and all their descendants in
  /// a single pass.
  static void invalidateMultiple(final Iterable<String> loggerNames) {
    final keysToInvalidate = <String>{};
    for (final name in loggerNames) {
      final normalized = Logger._normalizeName(name);
      keysToInvalidate.add(normalized);
      final descendantsList = _descendants[normalized];
      if (descendantsList != null) {
        keysToInvalidate.addAll(descendantsList);
      }
    }
    for (final key in keysToInvalidate) {
      if (_cache.remove(key) != null) {
        LoggerMetrics._cacheInvalidations++;
      }
    }
  }

  /// Clears the entire logger cache.
  static void clear() {
    LoggerMetrics._cacheInvalidations += _cache.length;
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

/// Internal container for a pattern configuration rule.
@immutable
class _PatternRule {
  const _PatternRule({
    required this.pattern,
    required this.regExp,
    required this.config,
  });

  final String pattern;
  final RegExp regExp;
  final LoggerConfig config;
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

  /// Internal: Registered pattern configuration rules.
  static final List<_PatternRule> _patternRules = [];

  /// Callback triggered when all configured handlers fail.
  ///
  /// Defaults to printing a formatted message to standard output.
  /// Set to `null` to disable fallback logging entirely.
  static void Function(
    LogEntry entry,
    Object? error,
    StackTrace? stackTrace,
  )? fallbackHandler = _defaultFallbackHandler;

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
      _registry[name] = const LoggerConfig();
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
    configureMultiple({
      name: LoggerConfig(
        enabled: enabled,
        logLevel: logLevel,
        includeFileLineInHeader: includeFileLineInHeader,
        stackMethodCount: stackMethodCount,
        timestamp: timestamp,
        stackTraceParser: stackTraceParser,
        handlers: handlers,
        autoSinkBuffer: autoSinkBuffer,
      ),
    });
  }

  /// Configures multiple loggers at once, applying their properties in-place.
  ///
  /// This method is more efficient than calling [configure] multiple times
  /// as it performs cache invalidation in a single batched pass.
  ///
  /// Parameters:
  /// - [configurations]: A map of logger names to their desired [LoggerConfig].
  ///
  /// Throws [ArgumentError] if:
  /// - Any [stackMethodCount] value is negative.
  /// - [handlers] is an empty list.
  ///
  /// Example:
  ///   Logger.configureMultiple({
  ///     'global': const LoggerConfig(logLevel: LogLevel.warning),
  ///     'app.network': const LoggerConfig(logLevel: LogLevel.debug),
  ///   });
  static void configureMultiple(
    final Map<String, LoggerConfig> configurations,
  ) {
    if (configurations.isEmpty) {
      return;
    }

    // First validate all inputs to ensure correctness/atomicity
    for (final entry in configurations.entries) {
      final config = entry.value;
      if (config.stackMethodCount != null) {
        for (final smcEntry in config.stackMethodCount!.entries) {
          if (smcEntry.value < 0) {
            throw ArgumentError.value(
              smcEntry.value,
              'stackMethodCount[${smcEntry.key}]',
              'Stack method count cannot be negative for logger '
                  '"${entry.key}"',
            );
          }
        }
      }
      if (config.handlers != null && config.handlers!.isEmpty) {
        throw ArgumentError.value(
          config.handlers,
          'handlers',
          'Handlers list cannot be empty for logger "${entry.key}"',
        );
      }
    }

    final changedLoggers = <String>{};

    for (final entry in configurations.entries) {
      final name = entry.key;
      final newConfig = entry.value;
      final normalized = _normalizeName(name);
      _registerLogger(normalized);
      final existingConfig = _registry[normalized]!;

      bool changed = false;
      final frozenFields = Set<String>.from(existingConfig.frozenFields);

      bool? newEnabled = existingConfig.enabled;
      if (newConfig.enabled != null) {
        final removed = frozenFields.remove('enabled');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'enabled' was frozen; configure() has "
            "promoted it to explicit. Call unfreezeInheritance() first to "
            'restore dynamic resolution instead.',
          );
        }
        if (newConfig.enabled != existingConfig.enabled || removed) {
          newEnabled = newConfig.enabled;
          changed = true;
        }
      }

      LogLevel? newLogLevel = existingConfig.logLevel;
      if (newConfig.logLevel != null) {
        final removed = frozenFields.remove('logLevel');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'logLevel' was frozen; configure() has "
            "promoted it to explicit. Call unfreezeInheritance() first to "
            'restore dynamic resolution instead.',
          );
        }
        if (newConfig.logLevel != existingConfig.logLevel || removed) {
          newLogLevel = newConfig.logLevel;
          changed = true;
        }
      }

      bool? newIncludeFileLineInHeader = existingConfig.includeFileLineInHeader;
      if (newConfig.includeFileLineInHeader != null) {
        final removed = frozenFields.remove('includeFileLineInHeader');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'includeFileLineInHeader' was frozen; "
            'configure() has promoted it to explicit. Call '
            'unfreezeInheritance() first to restore dynamic '
            'resolution instead.',
          );
        }
        if (newConfig.includeFileLineInHeader !=
                existingConfig.includeFileLineInHeader ||
            removed) {
          newIncludeFileLineInHeader = newConfig.includeFileLineInHeader;
          changed = true;
        }
      }

      Map<LogLevel, int>? newStackMethodCount = existingConfig.stackMethodCount;
      if (newConfig.stackMethodCount != null) {
        final removed = frozenFields.remove('stackMethodCount');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'stackMethodCount' was frozen; configure() "
            "has promoted it to explicit. Call unfreezeInheritance() first "
            'to restore dynamic resolution instead.',
          );
        }
        if (!mapEquals(
              newConfig.stackMethodCount,
              existingConfig.stackMethodCount,
            ) ||
            removed) {
          newStackMethodCount = newConfig.stackMethodCount;
          changed = true;
        }
      }

      Timestamp? newTimestamp = existingConfig.timestamp;
      if (newConfig.timestamp != null) {
        final removed = frozenFields.remove('timestamp');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'timestamp' was frozen; configure() has "
            "promoted it to explicit. Call unfreezeInheritance() first to "
            'restore dynamic resolution instead.',
          );
        }
        if (newConfig.timestamp != existingConfig.timestamp || removed) {
          newTimestamp = newConfig.timestamp;
          changed = true;
        }
      }

      StackTraceParser? newStackTraceParser = existingConfig.stackTraceParser;
      if (newConfig.stackTraceParser != null) {
        final removed = frozenFields.remove('stackTraceParser');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'stackTraceParser' was frozen; configure() "
            "has promoted it to explicit. Call unfreezeInheritance() first "
            'to restore dynamic resolution instead.',
          );
        }
        if (newConfig.stackTraceParser != existingConfig.stackTraceParser ||
            removed) {
          newStackTraceParser = newConfig.stackTraceParser;
          changed = true;
        }
      }

      List<Handler>? newHandlers = existingConfig.handlers;
      if (newConfig.handlers != null) {
        final removed = frozenFields.remove('handlers');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'handlers' was frozen; configure() has "
            "promoted it to explicit. Call unfreezeInheritance() first to "
            'restore dynamic resolution instead.',
          );
        }
        if (!listEquals(newConfig.handlers, existingConfig.handlers) ||
            removed) {
          newHandlers = newConfig.handlers;
          changed = true;
        }
      }

      bool? newAutoSinkBuffer = existingConfig.autoSinkBuffer;
      if (newConfig.autoSinkBuffer != null) {
        final removed = frozenFields.remove('autoSinkBuffer');
        if (removed) {
          InternalLogger.log(
            LogLevel.warning,
            "'$normalized' field 'autoSinkBuffer' was frozen; configure() "
            "has promoted it to explicit. Call unfreezeInheritance() first "
            'to restore dynamic resolution instead.',
          );
        }
        if (newConfig.autoSinkBuffer != existingConfig.autoSinkBuffer ||
            removed) {
          newAutoSinkBuffer = newConfig.autoSinkBuffer;
          changed = true;
        }
      }

      if (changed) {
        _registry[normalized] = existingConfig.copyWith(
          enabled: newEnabled,
          logLevel: newLogLevel,
          includeFileLineInHeader: newIncludeFileLineInHeader,
          stackMethodCount: newStackMethodCount,
          timestamp: newTimestamp,
          stackTraceParser: newStackTraceParser,
          handlers: newHandlers,
          autoSinkBuffer: newAutoSinkBuffer,
          version: existingConfig.version + 1,
          frozenFields: frozenFields,
          implicit: false,
        );
        changedLoggers.add(normalized);
      } else {
        _registry[normalized] = existingConfig.copyWith(
          frozenFields: frozenFields,
          implicit: false,
        );
      }
    }

    if (changedLoggers.isNotEmpty) {
      LoggerCache.invalidateMultiple(changedLoggers);
    }
  }

  /// Configures loggers matching a wildcard or regular expression pattern.
  ///
  /// This allows setting behavior on loggers without having to configure each
  /// logger individually or depending on a strict dot-separated hierarchy.
  ///
  /// The pattern supports glob-style wildcards:
  /// - `*` matches zero or more characters.
  /// - `?` matches any single character.
  ///
  /// Throws [ArgumentError] if:
  /// - [pattern] is empty.
  /// - Any [stackMethodCount] value is negative.
  /// - [handlers] is an empty list.
  ///
  /// Example:
  ///   Logger.configurePattern('*.database', logLevel: LogLevel.debug);
  static void configurePattern(
    final String pattern, {
    final bool? enabled,
    final LogLevel? logLevel,
    final bool? includeFileLineInHeader,
    final Map<LogLevel, int>? stackMethodCount,
    final Timestamp? timestamp,
    final StackTraceParser? stackTraceParser,
    final List<Handler>? handlers,
    final bool? autoSinkBuffer,
  }) {
    if (pattern.isEmpty) {
      throw ArgumentError.value(pattern, 'pattern', 'Pattern cannot be empty');
    }

    final config = LoggerConfig(
      enabled: enabled,
      logLevel: logLevel,
      includeFileLineInHeader: includeFileLineInHeader,
      stackMethodCount: stackMethodCount,
      timestamp: timestamp,
      stackTraceParser: stackTraceParser,
      handlers: handlers,
      autoSinkBuffer: autoSinkBuffer,
    );

    if (config.stackMethodCount != null) {
      for (final smcEntry in config.stackMethodCount!.entries) {
        if (smcEntry.value < 0) {
          throw ArgumentError.value(
            smcEntry.value,
            'stackMethodCount[${smcEntry.key}]',
            'Stack method count cannot be negative',
          );
        }
      }
    }
    if (config.handlers != null && config.handlers!.isEmpty) {
      throw ArgumentError.value(
        config.handlers,
        'handlers',
        'Handlers list cannot be empty',
      );
    }

    final regExp = _patternToRegExp(pattern);

    _patternRules.add(
      _PatternRule(
        pattern: pattern,
        regExp: regExp,
        config: config,
      ),
    );

    LoggerCache.clear();
  }

  static RegExp _patternToRegExp(final String pattern) {
    final buffer = StringBuffer()..write('^');
    for (var i = 0; i < pattern.length; i++) {
      final char = pattern[i];
      if (char == '*') {
        buffer.write('.*');
      } else if (char == '?') {
        buffer.write('.');
      } else if (const [
        '.',
        '+',
        '^',
        '\$',
        '(',
        ')',
        '[',
        ']',
        '{',
        '}',
        '|',
        '\\',
      ].contains(char)) {
        buffer.write('\\$char');
      } else {
        buffer.write(char);
      }
    }
    buffer.write('\$');
    return RegExp(buffer.toString(), caseSensitive: false);
  }

  /// Exports the current configurations of all loggers registered.
  ///
  /// The returned object is a JSON-compatible map containing all configurations
  /// that can be sent to another isolate.
  static Map<String, dynamic> exportConfig() {
    final configsMap = <String, dynamic>{};
    for (final entry in _registry.entries) {
      configsMap[entry.key] = entry.value.toJson();
    }
    final patternRulesList = <Map<String, dynamic>>[];
    for (final rule in _patternRules) {
      patternRulesList.add({
        'pattern': rule.pattern,
        'config': rule.config.toJson(),
      });
    }
    return <String, dynamic>{
      'registry': configsMap,
      'patternRules': patternRulesList,
    };
  }

  /// Imports and applies configurations exported via [exportConfig].
  ///
  /// This registers all configurations, merging/overwriting any existing ones
  /// and invalidating cache keys.
  static void importConfig(final Map<String, dynamic> configData) {
    final registryMap = configData['registry'] as Map<dynamic, dynamic>?;
    if (registryMap != null) {
      for (final entry in registryMap.entries) {
        final name = entry.key as String;
        final configJson = entry.value as Map<dynamic, dynamic>;
        final config =
            LoggerConfig.fromJson(Map<String, dynamic>.from(configJson));
        _registry[name] = config;
      }
    }

    final patternRulesList = configData['patternRules'] as List<dynamic>?;
    if (patternRulesList != null) {
      _patternRules.clear();
      for (final ruleObj in patternRulesList) {
        final ruleMap = ruleObj as Map<dynamic, dynamic>;
        final pattern = ruleMap['pattern'] as String;
        final configJson = ruleMap['config'] as Map<dynamic, dynamic>;
        final config =
            LoggerConfig.fromJson(Map<String, dynamic>.from(configJson));
        final regExp = _patternToRegExp(pattern);
        _patternRules.add(
          _PatternRule(
            pattern: pattern,
            regExp: regExp,
            config: config,
          ),
        );
      }
    }

    LoggerCache.clear();
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
        callerConfig.implicit &&
        callerConfig.frozenFields.isEmpty) {
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
            isNull || (force && childConfig.frozenFields.contains(field));

        final nextFrozenFields = Set<String>.from(childConfig.frozenFields);
        bool? newEnabled = childConfig.enabled;
        LogLevel? newLogLevel = childConfig.logLevel;
        bool? newIncludeFileLineInHeader = childConfig.includeFileLineInHeader;
        Map<LogLevel, int>? newStackMethodCount = childConfig.stackMethodCount;
        Timestamp? newTimestamp = childConfig.timestamp;
        StackTraceParser? newStackTraceParser = childConfig.stackTraceParser;
        List<Handler>? newHandlers = childConfig.handlers;
        bool? newAutoSinkBuffer = childConfig.autoSinkBuffer;

        if (shouldWrite(
          field: 'enabled',
          isNull: childConfig.enabled == null,
        )) {
          newEnabled = enabled;
          nextFrozenFields.add('enabled');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'logLevel',
          isNull: childConfig.logLevel == null,
        )) {
          newLogLevel = logLevel;
          nextFrozenFields.add('logLevel');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'includeFileLineInHeader',
          isNull: childConfig.includeFileLineInHeader == null,
        )) {
          newIncludeFileLineInHeader = includeFileLineInHeader;
          nextFrozenFields.add('includeFileLineInHeader');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'stackMethodCount',
          isNull: childConfig.stackMethodCount == null,
        )) {
          newStackMethodCount = Map.from(stackMethodCount);
          nextFrozenFields.add('stackMethodCount');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'timestamp',
          isNull: childConfig.timestamp == null,
        )) {
          newTimestamp = timestamp;
          nextFrozenFields.add('timestamp');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'stackTraceParser',
          isNull: childConfig.stackTraceParser == null,
        )) {
          newStackTraceParser = stackTraceParser;
          nextFrozenFields.add('stackTraceParser');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'handlers',
          isNull: childConfig.handlers == null,
        )) {
          newHandlers = List.from(handlers);
          nextFrozenFields.add('handlers');
          changed = true;
          writtenCount++;
        }
        if (shouldWrite(
          field: 'autoSinkBuffer',
          isNull: childConfig.autoSinkBuffer == null,
        )) {
          newAutoSinkBuffer = autoSinkBuffer;
          nextFrozenFields.add('autoSinkBuffer');
          changed = true;
          writtenCount++;
        }
        if (changed) {
          _registry[key] = childConfig.copyWith(
            enabled: newEnabled,
            logLevel: newLogLevel,
            includeFileLineInHeader: newIncludeFileLineInHeader,
            stackMethodCount: newStackMethodCount,
            timestamp: newTimestamp,
            stackTraceParser: newStackTraceParser,
            handlers: newHandlers,
            autoSinkBuffer: newAutoSinkBuffer,
            version: childConfig.version + 1,
            frozenFields: nextFrozenFields,
          );
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
      if (childConfig.frozenFields.isNotEmpty) {
        // Determine which frozen fields to actually clear.
        final toClear = fields == null
            ? Set.of(childConfig.frozenFields)
            : childConfig.frozenFields.intersection(fields);

        final nextFrozenFields = Set<String>.from(childConfig.frozenFields);
        bool? newEnabled = childConfig.enabled;
        LogLevel? newLogLevel = childConfig.logLevel;
        bool? newIncludeFileLineInHeader = childConfig.includeFileLineInHeader;
        Map<LogLevel, int>? newStackMethodCount = childConfig.stackMethodCount;
        Timestamp? newTimestamp = childConfig.timestamp;
        StackTraceParser? newStackTraceParser = childConfig.stackTraceParser;
        List<Handler>? newHandlers = childConfig.handlers;
        bool? newAutoSinkBuffer = childConfig.autoSinkBuffer;

        for (final field in toClear) {
          switch (field) {
            case 'enabled':
              newEnabled = null;
            case 'logLevel':
              newLogLevel = null;
            case 'includeFileLineInHeader':
              newIncludeFileLineInHeader = null;
            case 'stackMethodCount':
              newStackMethodCount = null;
            case 'timestamp':
              newTimestamp = null;
            case 'stackTraceParser':
              newStackTraceParser = null;
            case 'handlers':
              newHandlers = null;
            case 'autoSinkBuffer':
              newAutoSinkBuffer = null;
          }
          nextFrozenFields.remove(field);
          changed = true;
        }

        if (changed) {
          _registry[key] = childConfig.copyWith(
            enabled: newEnabled,
            logLevel: newLogLevel,
            includeFileLineInHeader: newIncludeFileLineInHeader,
            stackMethodCount: newStackMethodCount,
            timestamp: newTimestamp,
            stackTraceParser: newStackTraceParser,
            handlers: newHandlers,
            autoSinkBuffer: newAutoSinkBuffer,
            version: childConfig.version + 1,
            frozenFields: nextFrozenFields,
          );
          LoggerCache.invalidate(key);
        }
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
    if (config.enabled != null && !config.frozenFields.contains('enabled')) {
      fields.add('enabled');
    }
    if (config.logLevel != null && !config.frozenFields.contains('logLevel')) {
      fields.add('logLevel');
    }
    if (config.includeFileLineInHeader != null &&
        !config.frozenFields.contains('includeFileLineInHeader')) {
      fields.add('includeFileLineInHeader');
    }
    if (config.stackMethodCount != null &&
        !config.frozenFields.contains('stackMethodCount')) {
      fields.add('stackMethodCount');
    }
    if (config.timestamp != null &&
        !config.frozenFields.contains('timestamp')) {
      fields.add('timestamp');
    }
    if (config.stackTraceParser != null &&
        !config.frozenFields.contains('stackTraceParser')) {
      fields.add('stackTraceParser');
    }
    if (config.handlers != null && !config.frozenFields.contains('handlers')) {
      fields.add('handlers');
    }
    if (config.autoSinkBuffer != null &&
        !config.frozenFields.contains('autoSinkBuffer')) {
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
    return Set.unmodifiable(config.frozenFields);
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
        'implicit': config.implicit,
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
      enabled ? LogBuffer._checkout(this, LogLevel.trace) : null;

  /// Returns a buffer for building multi-line debug-level logs.
  ///
  /// Intentions: Similar to traceBuffer, but for debug messages. Helps in
  /// constructing detailed debug output without interleaving.
  ///
  /// Example: logger.debugBuffer?..writeln('Debug start')..sink();
  LogBuffer? get debugBuffer =>
      enabled ? LogBuffer._checkout(this, LogLevel.debug) : null;

  /// Returns a buffer for building multi-line info-level logs.
  ///
  /// Intentions: For informational messages that may span multiple lines.
  ///
  /// Example: logger.infoBuffer?..writeln('Info start')..sink();
  LogBuffer? get infoBuffer =>
      enabled ? LogBuffer._checkout(this, LogLevel.info) : null;

  /// Returns a buffer for building multi-line warning-level logs.
  ///
  /// Intentions: For warnings that require detailed, multi-line descriptions.
  ///
  /// Example: logger.warningBuffer?..writeln('Warning start')..sink();
  LogBuffer? get warningBuffer =>
      enabled ? LogBuffer._checkout(this, LogLevel.warning) : null;

  /// Returns a buffer for building multi-line error-level logs.
  ///
  /// Intentions: For errors with stack traces or multi-line details.
  ///
  /// Example: logger.errorBuffer?..writeln('Error start')..sink();
  LogBuffer? get errorBuffer =>
      enabled ? LogBuffer._checkout(this, LogLevel.error) : null;

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
      LoggerMetrics._drops++;
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
      bool anySuccess = false;
      for (final handler in handlers) {
        try {
          await handler.log(entry);
          anySuccess = true;
        } catch (e, s) {
          LoggerMetrics._handlerFailures++;
          InternalLogger.log(
            LogLevel.error,
            'Handler failure: ${handler.runtimeType}',
            error: e,
            stackTrace: s,
          );
        }
      }
      if (!anySuccess && handlers.isNotEmpty) {
        if (fallbackHandler != null) {
          fallbackHandler!(
            entry,
            entry.error,
            entry.stackTrace,
          );
        }
      }
    } finally {
      Arena.instance.releaseLogEntry(entry);
    }
  }

  String _buildOrigin(final CallbackInfo info) {
    if (!includeFileLineInHeader) {
      return info.className.isNotEmpty
          ? '${info.className}.${info.methodName}'
          : info.methodName;
    }
    final sb = StringBuffer();
    if (info.className.isNotEmpty) {
      sb
        ..write(info.className)
        ..write('.')
        ..write(info.methodName);
    } else {
      sb.write(info.methodName);
    }
    sb
      ..write(' (')
      ..write(info.filePath)
      ..write(':')
      ..write(info.lineNumber)
      ..write(')');
    return sb.toString();
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
      _patternRules.clear();
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

  static void _defaultFallbackHandler(
    final LogEntry entry,
    final Object? error,
    final StackTrace? stackTrace,
  ) {
    final timestampStr =
        entry.timestamp.isNotEmpty ? '${entry.timestamp} ' : '';
    final levelStr = '[${entry.level.name.toUpperCase()}]';
    final nameStr = entry.loggerName.isNotEmpty ? ' [${entry.loggerName}]' : '';
    final originStr = entry.origin.isNotEmpty ? ' (${entry.origin})' : '';
    print(
      'FALLBACK: $timestampStr$levelStr$nameStr:'
      ' ${entry.message}$originStr',
    );
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace:\n$stackTrace');
    }
  }
}

/// Observability API for monitoring [Logger] performance and memory lifecycle.
///
/// All counters are **isolate-local** static integers — each Dart isolate
/// maintains an independent set of counters. Dart's single-threaded execution
/// model within an isolate makes concurrent counter mutation impossible.
///
/// ### Lifecycle
///
/// Counters are **never reset automatically**. Calling [Logger.reset] clears
/// the logger registry and cache but does **not** reset [LoggerMetrics]
/// counters. Call [LoggerMetrics.reset] explicitly when you want a fresh
/// measurement window (e.g., at the start of each benchmark or test).
///
/// ### Usage
///
/// ```dart
/// LoggerMetrics.reset(); // start clean window
/// // ... run workload ...
/// print(LoggerMetrics.toJson());
/// ```
class LoggerMetrics {
  LoggerMetrics._();

  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _cacheInvalidations = 0;
  static int _handlerFailures = 0;
  static int _bufferAllocations = 0;
  static int _bufferReleases = 0;
  static int _bufferLeaks = 0;
  static int _drops = 0;

  /// The number of cache hits in the configuration resolution cache.
  ///
  /// A cache hit means the logger's resolved configuration was retrieved
  /// from the in-memory [LoggerCache] without walking the hierarchy tree.
  static int get cacheHits => _cacheHits;

  /// The number of cache misses (slow-path resolutions) in the cache.
  ///
  /// A cache miss triggers a full hierarchy walk to produce a
  /// [_ResolvedConfig]. This happens after a new logger is first accessed
  /// or after a parent's configuration is invalidated.
  static int get cacheMisses => _cacheMisses;

  /// The number of times resolved configurations were invalidated.
  ///
  /// Incremented when [Logger.configure] changes a parent's version, which
  /// evicts all descendant entries from [LoggerCache].
  static int get cacheInvalidations => _cacheInvalidations;

  /// The number of handler invocations that threw an exception.
  ///
  /// When this counter increments, [Logger.fallbackHandler] is invoked
  /// (if non-null) so the log event is not silently lost.
  static int get handlerFailures => _handlerFailures;

  /// The total number of [LogBuffer] instances checked out from the pool
  /// or freshly constructed.
  static int get bufferAllocations => _bufferAllocations;

  /// The total number of [LogBuffer] instances returned to the LIFO pool
  /// via [LogBuffer.sink].
  static int get bufferReleases => _bufferReleases;

  /// The number of [LogBuffer] instances that were garbage-collected
  /// without calling [LogBuffer.sink] (i.e., leaked).
  ///
  /// A non-zero value indicates a usage error. Inspect [InternalLogger]
  /// output for the associated warning messages.
  static int get bufferLeaks => _bufferLeaks;

  /// The number of log calls dropped because the entry's level was below the
  /// logger's configured [Logger.logLevel], or the logger was disabled.
  ///
  /// This is the dominant counter in production-level logging where most
  /// trace/debug calls are filtered at the fast-path.
  static int get drops => _drops;

  /// Returns a JSON-compatible snapshot of all counters.
  ///
  /// The map is suitable for serialization, structured logging, or export
  /// to an external monitoring system.
  ///
  /// ```dart
  /// final snapshot = LoggerMetrics.toJson();
  /// // {'cacheHits': 412, 'cacheMisses': 5, ...}
  /// ```
  static Map<String, int> toJson() => <String, int>{
        'cacheHits': _cacheHits,
        'cacheMisses': _cacheMisses,
        'cacheInvalidations': _cacheInvalidations,
        'handlerFailures': _handlerFailures,
        'bufferAllocations': _bufferAllocations,
        'bufferReleases': _bufferReleases,
        'bufferLeaks': _bufferLeaks,
        'drops': _drops,
      };

  /// Resets all metric counters to zero.
  ///
  /// **Note**: This is independent of [Logger.reset]. Resetting the logger
  /// registry does not reset metrics, and vice versa.
  static void reset() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheInvalidations = 0;
    _handlerFailures = 0;
    _bufferAllocations = 0;
    _bufferReleases = 0;
    _bufferLeaks = 0;
    _drops = 0;
  }
}
