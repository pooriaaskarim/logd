library;

import 'dart:typed_data';

import '../core/log_level.dart';
import '../core/theme/log_theme.dart';
import '../handler/engine/native_engine.dart';
import '../handler/handler.dart';
import '../handler/sink/file_sink.dart';
import '../handler/sink/isolate_sink.dart';
import 'logger.dart';

class _SerializerSpec<T> {
  const _SerializerSpec({required this.fromJson, required this.toJson});
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  bool _typeMatches(final dynamic value) => value is T;
}

/// Registry for serializing and deserializing logging pipeline components.
///
/// Used to pass configurations between isolates or serialize them to JSON.
class LoggerSerializationRegistry {
  LoggerSerializationRegistry._();

  static final Map<Type, _SerializerSpec<LogFormatter>> _formattersByType = {};
  static final Map<String, _SerializerSpec<LogFormatter>> _formattersByName =
      {};

  static final Map<Type, _SerializerSpec<LogSink>> _sinksByType = {};
  static final Map<String, _SerializerSpec<LogSink>> _sinksByName = {};

  static final Map<Type, _SerializerSpec<LogFilter>> _filtersByType = {};
  static final Map<String, _SerializerSpec<LogFilter>> _filtersByName = {};

  static final Map<Type, _SerializerSpec<LogDecorator>> _decoratorsByType = {};
  static final Map<String, _SerializerSpec<LogDecorator>> _decoratorsByName =
      {};

  static final Map<Type, _SerializerSpec<LogEngine>> _enginesByType = {};
  static final Map<String, _SerializerSpec<LogEngine>> _enginesByName = {};

  static bool _initialized = false;

  /// Ensures all default serialization specifications are registered.
  static void ensureInitialized() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    // --- Formatters ---
    registerFormatter<PlainFormatter>(
      type: 'PlainFormatter',
      fromJson: (final json) => const PlainFormatter(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerFormatter<JsonFormatter>(
      type: 'JsonFormatter',
      fromJson: (final json) => const JsonFormatter(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerFormatter<StructuredFormatter>(
      type: 'StructuredFormatter',
      fromJson: (final json) => const StructuredFormatter(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerFormatter<ToonFormatter>(
      type: 'ToonFormatter',
      fromJson: (final json) => const ToonFormatter(),
      toJson: (final val) => <String, dynamic>{},
    );

    // --- Sinks ---
    registerSink<ConsoleSink>(
      type: 'ConsoleSink',
      fromJson: (final json) => const ConsoleSink(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerSink<PrintSink>(
      type: 'PrintSink',
      fromJson: (final json) => const PrintSink(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerSink<FileSink>(
      type: 'FileSink',
      fromJson: (final json) {
        FileRotation? rotation;
        final rotJson = json['fileRotation'] as Map?;
        if (rotJson != null) {
          final rotType = rotJson['type'] as String;
          if (rotType == 'SizeRotation') {
            rotation = SizeRotation(
              maxSize: '${rotJson['maxBytes']} B',
              compress: rotJson['compress'] as bool? ?? false,
              backupCount: rotJson['backupCount'] as int? ?? 5,
            );
          } else if (rotType == 'TimeRotation') {
            rotation = TimeRotation(
              interval: Duration(milliseconds: rotJson['interval'] as int),
              compress: rotJson['compress'] as bool? ?? false,
              backupCount: rotJson['backupCount'] as int? ?? 5,
            );
          }
        }
        return FileSink(
          json['basePath'] as String,
          fileRotation: rotation,
        );
      },
      toJson: (final val) {
        Map<String, dynamic>? rotJson;
        final rot = val.fileRotation;
        if (rot is SizeRotation) {
          rotJson = <String, dynamic>{
            'type': 'SizeRotation',
            'maxBytes': rot.maxBytes,
            'compress': rot.compress,
            'backupCount': rot.backupCount,
          };
        } else if (rot is TimeRotation) {
          rotJson = <String, dynamic>{
            'type': 'TimeRotation',
            'interval': rot.interval.inMilliseconds,
            'compress': rot.compress,
            'backupCount': rot.backupCount,
          };
        }
        return <String, dynamic>{
          'basePath': val.basePath,
          if (rotJson != null) 'fileRotation': rotJson,
        };
      },
    );
    registerSink<IsolateSink>(
      type: 'IsolateSink',
      fromJson: (final json) => IsolateSink(
        deserializeSink(Map<String, dynamic>.from(json['target'] as Map))
            as LogSink<Uint8List>,
      ),
      toJson: (final val) => <String, dynamic>{
        'target': serializeSink(val.target),
      },
    );
    registerSink<MultiSink>(
      type: 'MultiSink',
      fromJson: (final json) => MultiSink(
        (json['sinks'] as List)
            .map(
              (final s) => deserializeSink(Map<String, dynamic>.from(s as Map))
                  as LogSink<LogDocument>,
            )
            .toList(),
      ),
      toJson: (final val) => <String, dynamic>{
        'sinks': val.sinks.map(serializeSink).toList(),
      },
    );

    // --- Filters ---
    registerFilter<LevelFilter>(
      type: 'LevelFilter',
      fromJson: (final json) => LevelFilter(
        LogLevel.values.byName(json['minimumLevel'] as String),
      ),
      toJson: (final val) => <String, dynamic>{
        'minimumLevel': val.minimumLevel.name,
      },
    );
    registerFilter<RegexFilter>(
      type: 'RegexFilter',
      fromJson: (final json) => RegexFilter(
        RegExp(
          json['pattern'] as String,
          caseSensitive: json['caseSensitive'] as bool? ?? true,
          multiLine: json['multiLine'] as bool? ?? false,
          unicode: json['unicode'] as bool? ?? false,
          dotAll: json['dotAll'] as bool? ?? false,
        ),
        invert: json['invert'] as bool? ?? false,
      ),
      toJson: (final val) => <String, dynamic>{
        'pattern': val.regex.pattern,
        'caseSensitive': val.regex.isCaseSensitive,
        'multiLine': val.regex.isMultiLine,
        'unicode': val.regex.isUnicode,
        'dotAll': val.regex.isDotAll,
        'invert': val.invert,
      },
    );
    registerFilter<ContextFilter>(
      type: 'ContextFilter',
      fromJson: (final json) => ContextFilter(
        json['key'] as String,
        value: json['value'],
        exclude: json['exclude'] as bool? ?? false,
      ),
      toJson: (final val) => <String, dynamic>{
        'key': val.key,
        'value': val.value,
        'exclude': val.exclude,
      },
    );

    // --- Decorators ---
    registerDecorator<BoxDecorator>(
      type: 'BoxDecorator',
      fromJson: (final json) => BoxDecorator(
        borderStyle: json['borderStyle'] != null
            ? BoxBorderStyle.values.byName(json['borderStyle'] as String)
            : BoxBorderStyle.rounded,
      ),
      toJson: (final val) => <String, dynamic>{
        'borderStyle': val.borderStyle.name,
      },
    );
    registerDecorator<StyleDecorator>(
      type: 'StyleDecorator',
      fromJson: (final json) => StyleDecorator(
        theme: json['theme'] != null
            ? _deserializeTheme(Map<String, dynamic>.from(json['theme'] as Map))
            : const LogTheme(colorScheme: LogColorScheme.defaultScheme),
      ),
      toJson: (final val) => <String, dynamic>{
        'theme': _serializeTheme(val.theme),
      },
    );
    registerDecorator<PrefixDecorator>(
      type: 'PrefixDecorator',
      fromJson: (final json) => PrefixDecorator(
        json['prefix'] as String,
        style: json['style'] != null
            ? _deserializeStyle(Map<String, dynamic>.from(json['style'] as Map))
            : null,
      ),
      toJson: (final val) => <String, dynamic>{
        'prefix': val.prefix,
        if (val.style != null) 'style': _serializeStyle(val.style!),
      },
    );
    registerDecorator<SuffixDecorator>(
      type: 'SuffixDecorator',
      fromJson: (final json) => SuffixDecorator(
        json['suffix'] as String,
        aligned: json['aligned'] as bool? ?? true,
        style: json['style'] != null
            ? _deserializeStyle(Map<String, dynamic>.from(json['style'] as Map))
            : null,
      ),
      toJson: (final val) => <String, dynamic>{
        'suffix': val.suffix,
        'aligned': val.aligned,
        if (val.style != null) 'style': _serializeStyle(val.style!),
      },
    );
    registerDecorator<HierarchyDepthPrefixDecorator>(
      type: 'HierarchyDepthPrefixDecorator',
      fromJson: (final json) => HierarchyDepthPrefixDecorator(
        indent: json['indent'] as String? ?? '│ ',
        style: json['style'] != null
            ? _deserializeStyle(Map<String, dynamic>.from(json['style'] as Map))
            : null,
      ),
      toJson: (final val) => <String, dynamic>{
        'indent': val.indent,
        if (val.style != null) 'style': _serializeStyle(val.style!),
      },
    );

    // --- Engines ---
    registerEngine<StandardEngine>(
      type: 'StandardEngine',
      fromJson: (final json) => const StandardEngine(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerEngine<ArenaEngine>(
      type: 'ArenaEngine',
      fromJson: (final json) => const ArenaEngine(),
      toJson: (final val) => <String, dynamic>{},
    );
    registerEngine<NativeEngine>(
      type: 'NativeEngine',
      fromJson: (final json) => NativeEngine(),
      toJson: (final val) => <String, dynamic>{},
    );
  }

  // --- Registration APIs ---

  static void registerFormatter<T extends LogFormatter>({
    required final String type,
    required final T Function(Map<String, dynamic> json) fromJson,
    required final Map<String, dynamic> Function(T value) toJson,
  }) {
    final spec = _SerializerSpec<LogFormatter>(
      fromJson: (final json) => fromJson(json),
      toJson: (final val) => toJson(val as T),
    );
    _formattersByName[type] = spec;
    _formattersByType[T] = spec;
  }

  static void registerSink<T extends LogSink>({
    required final String type,
    required final T Function(Map<String, dynamic> json) fromJson,
    required final Map<String, dynamic> Function(T value) toJson,
  }) {
    final spec = _SerializerSpec<LogSink>(
      fromJson: (final json) => fromJson(json),
      toJson: (final val) => toJson(val as T),
    );
    _sinksByName[type] = spec;
    _sinksByType[T] = spec;
  }

  static void registerFilter<T extends LogFilter>({
    required final String type,
    required final T Function(Map<String, dynamic> json) fromJson,
    required final Map<String, dynamic> Function(T value) toJson,
  }) {
    final spec = _SerializerSpec<LogFilter>(
      fromJson: (final json) => fromJson(json),
      toJson: (final val) => toJson(val as T),
    );
    _filtersByName[type] = spec;
    _filtersByType[T] = spec;
  }

  static void registerDecorator<T extends LogDecorator>({
    required final String type,
    required final T Function(Map<String, dynamic> json) fromJson,
    required final Map<String, dynamic> Function(T value) toJson,
  }) {
    final spec = _SerializerSpec<LogDecorator>(
      fromJson: (final json) => fromJson(json),
      toJson: (final val) => toJson(val as T),
    );
    _decoratorsByName[type] = spec;
    _decoratorsByType[T] = spec;
  }

  static void registerEngine<T extends LogEngine>({
    required final String type,
    required final T Function(Map<String, dynamic> json) fromJson,
    required final Map<String, dynamic> Function(T value) toJson,
  }) {
    final spec = _SerializerSpec<LogEngine>(
      fromJson: (final json) => fromJson(json),
      toJson: (final val) => toJson(val as T),
    );
    _enginesByName[type] = spec;
    _enginesByType[T] = spec;
  }

  // --- Serialization APIs ---

  static Map<String, dynamic> serializeFormatter(final LogFormatter val) {
    ensureInitialized();
    final spec = _lookupSpec(_formattersByType, val);
    final type = _lookupName(_formattersByName, spec);
    return <String, dynamic>{
      'type': type,
      'config': spec.toJson(val),
    };
  }

  static LogFormatter deserializeFormatter(final Map<String, dynamic> json) {
    ensureInitialized();
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map);
    final spec = _formattersByName[type];
    if (spec == null) {
      throw ArgumentError('Formatter type "$type" not registered.');
    }
    return spec.fromJson(config);
  }

  static Map<String, dynamic> serializeSink(final LogSink val) {
    ensureInitialized();
    final spec = _lookupSpec(_sinksByType, val);
    final type = _lookupName(_sinksByName, spec);
    return <String, dynamic>{
      'type': type,
      'config': spec.toJson(val),
    };
  }

  static LogSink deserializeSink(final Map<String, dynamic> json) {
    ensureInitialized();
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map);
    final spec = _sinksByName[type];
    if (spec == null) {
      throw ArgumentError('Sink type "$type" not registered.');
    }
    return spec.fromJson(config);
  }

  static Map<String, dynamic> serializeFilter(final LogFilter val) {
    ensureInitialized();
    final spec = _lookupSpec(_filtersByType, val);
    final type = _lookupName(_filtersByName, spec);
    return <String, dynamic>{
      'type': type,
      'config': spec.toJson(val),
    };
  }

  static LogFilter deserializeFilter(final Map<String, dynamic> json) {
    ensureInitialized();
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map);
    final spec = _filtersByName[type];
    if (spec == null) {
      throw ArgumentError('Filter type "$type" not registered.');
    }
    return spec.fromJson(config);
  }

  static Map<String, dynamic> serializeDecorator(final LogDecorator val) {
    ensureInitialized();
    final spec = _lookupSpec(_decoratorsByType, val);
    final type = _lookupName(_decoratorsByName, spec);
    return <String, dynamic>{
      'type': type,
      'config': spec.toJson(val),
    };
  }

  static LogDecorator deserializeDecorator(final Map<String, dynamic> json) {
    ensureInitialized();
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map);
    final spec = _decoratorsByName[type];
    if (spec == null) {
      throw ArgumentError('Decorator type "$type" not registered.');
    }
    return spec.fromJson(config);
  }

  static Map<String, dynamic> serializeEngine(final LogEngine val) {
    ensureInitialized();
    final spec = _lookupSpec(_enginesByType, val);
    final type = _lookupName(_enginesByName, spec);
    return <String, dynamic>{
      'type': type,
      'config': spec.toJson(val),
    };
  }

  static LogEngine deserializeEngine(final Map<String, dynamic> json) {
    ensureInitialized();
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map);
    final spec = _enginesByName[type];
    if (spec == null) {
      throw ArgumentError('Engine type "$type" not registered.');
    }
    return spec.fromJson(config);
  }

  // --- Internal helpers ---

  static _SerializerSpec<V> _lookupSpec<V>(
    final Map<Type, _SerializerSpec<V>> typeMap,
    final V val,
  ) {
    final exact = typeMap[val.runtimeType];
    if (exact != null) {
      return exact;
    }

    for (final spec in typeMap.values) {
      if (spec._typeMatches(val)) {
        return spec;
      }
    }
    throw ArgumentError('Type "${val.runtimeType}" is not registered.');
  }

  static String _lookupName<V>(
    final Map<String, _SerializerSpec<V>> nameMap,
    final _SerializerSpec<V> spec,
  ) {
    for (final entry in nameMap.entries) {
      if (entry.value == spec) {
        return entry.key;
      }
    }
    throw ArgumentError('Specification not found in name map.');
  }

  static Map<String, dynamic> _serializeStyle(final LogStyle style) =>
      <String, dynamic>{
        if (style.color != null) 'color': style.color!.name,
        if (style.backgroundColor != null)
          'backgroundColor': style.backgroundColor!.name,
        if (style.bold != null) 'bold': style.bold,
        if (style.dim != null) 'dim': style.dim,
        if (style.italic != null) 'italic': style.italic,
        if (style.inverse != null) 'inverse': style.inverse,
        if (style.underline != null) 'underline': style.underline,
      };

  static LogStyle? _deserializeStyle(final Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    return LogStyle(
      color: json['color'] != null
          ? LogColor.values.byName(json['color'] as String)
          : null,
      backgroundColor: json['backgroundColor'] != null
          ? LogColor.values.byName(json['backgroundColor'] as String)
          : null,
      bold: json['bold'] as bool?,
      dim: json['dim'] as bool?,
      italic: json['italic'] as bool?,
      inverse: json['inverse'] as bool?,
      underline: json['underline'] as bool?,
    );
  }

  static Map<String, dynamic> _serializeColorScheme(
    final LogColorScheme scheme,
  ) =>
      <String, dynamic>{
        'trace': scheme.trace.name,
        'debug': scheme.debug.name,
        'info': scheme.info.name,
        'warning': scheme.warning.name,
        'error': scheme.error.name,
        if (scheme.timestampColor != null)
          'timestampColor': scheme.timestampColor!.name,
        if (scheme.loggerNameColor != null)
          'loggerNameColor': scheme.loggerNameColor!.name,
        if (scheme.levelColor != null) 'levelColor': scheme.levelColor!.name,
        if (scheme.borderColor != null) 'borderColor': scheme.borderColor!.name,
        if (scheme.stackFrameColor != null)
          'stackFrameColor': scheme.stackFrameColor!.name,
        if (scheme.hierarchyColor != null)
          'hierarchyColor': scheme.hierarchyColor!.name,
      };

  static LogColorScheme _deserializeColorScheme(
    final Map<String, dynamic> json,
  ) =>
      LogColorScheme(
        trace: LogColor.values.byName(json['trace'] as String),
        debug: LogColor.values.byName(json['debug'] as String),
        info: LogColor.values.byName(json['info'] as String),
        warning: LogColor.values.byName(json['warning'] as String),
        error: LogColor.values.byName(json['error'] as String),
        timestampColor: json['timestampColor'] != null
            ? LogColor.values.byName(json['timestampColor'] as String)
            : null,
        loggerNameColor: json['loggerNameColor'] != null
            ? LogColor.values.byName(json['loggerNameColor'] as String)
            : null,
        levelColor: json['levelColor'] != null
            ? LogColor.values.byName(json['levelColor'] as String)
            : null,
        borderColor: json['borderColor'] != null
            ? LogColor.values.byName(json['borderColor'] as String)
            : null,
        stackFrameColor: json['stackFrameColor'] != null
            ? LogColor.values.byName(json['stackFrameColor'] as String)
            : null,
        hierarchyColor: json['hierarchyColor'] != null
            ? LogColor.values.byName(json['hierarchyColor'] as String)
            : null,
      );

  static Map<String, dynamic> _serializeTheme(final LogTheme theme) =>
      <String, dynamic>{
        'colorScheme': _serializeColorScheme(theme.colorScheme),
        if (theme.timestampStyle != null)
          'timestampStyle': _serializeStyle(theme.timestampStyle!),
        if (theme.loggerNameStyle != null)
          'loggerNameStyle': _serializeStyle(theme.loggerNameStyle!),
        if (theme.levelStyle != null)
          'levelStyle': _serializeStyle(theme.levelStyle!),
        if (theme.messageStyle != null)
          'messageStyle': _serializeStyle(theme.messageStyle!),
        if (theme.borderStyle != null)
          'borderStyle': _serializeStyle(theme.borderStyle!),
        if (theme.stackFrameStyle != null)
          'stackFrameStyle': _serializeStyle(theme.stackFrameStyle!),
        if (theme.errorStyle != null)
          'errorStyle': _serializeStyle(theme.errorStyle!),
        if (theme.hierarchyStyle != null)
          'hierarchyStyle': _serializeStyle(theme.hierarchyStyle!),
      };

  static LogTheme _deserializeTheme(final Map<String, dynamic> json) =>
      LogTheme(
        colorScheme: _deserializeColorScheme(
          Map<String, dynamic>.from(json['colorScheme'] as Map),
        ),
        timestampStyle: json['timestampStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['timestampStyle'] as Map),
              )
            : null,
        loggerNameStyle: json['loggerNameStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['loggerNameStyle'] as Map),
              )
            : null,
        levelStyle: json['levelStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['levelStyle'] as Map),
              )
            : null,
        messageStyle: json['messageStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['messageStyle'] as Map),
              )
            : null,
        borderStyle: json['borderStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['borderStyle'] as Map),
              )
            : null,
        stackFrameStyle: json['stackFrameStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['stackFrameStyle'] as Map),
              )
            : null,
        errorStyle: json['errorStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['errorStyle'] as Map),
              )
            : null,
        hierarchyStyle: json['hierarchyStyle'] != null
            ? _deserializeStyle(
                Map<String, dynamic>.from(json['hierarchyStyle'] as Map),
              )
            : null,
      );
}
