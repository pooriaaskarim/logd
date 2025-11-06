import 'package:flutter/foundation.dart';
import '../printer/box_printer.dart';
import '../printer/printer.dart';
import '../stack_trace_parser/stack_trace_parser.dart';
import '../time/timestamp.dart';
part 'log_buffer.dart';
part 'log_level.dart';
part 'log_entry.dart';

/// The main logger class — now instance-based with full control.
///
/// Create one per module:
/// ```dart
/// final auth = Logger.module('Auth', minLevel: LogLevel.warning);
/// final db = Logger.module('DB', printers: [JsonPrinter()]);
/// ```
class Logger {
  /// Creates a fully configured logger instance.
  Logger({
    this.name = 'Logger',
    this.enabled = kDebugMode,
    final LogLevel? minLevel,
    this.includeFileLineInHeader = false,
    final Map<LogLevel, int>? stackMethodCount,
    final Timestamp? timestampFormatter,
    final StackTraceParser? stackParser,
    final List<Printer> printers = const [],
  })  : minLevel = minLevel ?? LogLevel.debug,
        stackMethodCount = stackMethodCount ??
            {
              LogLevel.trace: 0,
              LogLevel.debug: 0,
              LogLevel.info: 0,
              LogLevel.warning: 2,
              LogLevel.error: 8,
            },
        timestampFormatter = timestampFormatter ??
            Timestamp(
              formatter: 'yyyy.MMM.dd\nZZ HH:mm:ss.SSSS',
              timeZone: TimeZone('NY', '-05:00'),
            ),
        stackParser = stackParser ??
            const StackTraceParser(ignorePackages: ['logd', 'flutter']) {
    _printers.addAll(printers);
    if (_printers.isEmpty) {
      _printers.add(BoxPrinter());
    }
  }

  /// Factory for module-specific loggers.
  factory Logger.module(
    final String moduleName, {
    final bool? enabled,
    final LogLevel? minLevel,
    final List<Printer> printers = const [],
  }) =>
      Logger(
        name: moduleName,
        enabled: enabled ?? kDebugMode,
        minLevel: minLevel,
        printers: printers.isNotEmpty ? printers : [BoxPrinter()],
      );
  // ── Instance Configuration ─────────────────────────────────────
  final String name;
  final bool enabled;
  final LogLevel minLevel;
  final bool includeFileLineInHeader;
  final Map<LogLevel, int> stackMethodCount;
  final Timestamp timestampFormatter;
  final StackTraceParser stackParser;

  final List<Printer> _printers = [];

  // ── Static Global (100% backward compatible) ───────────────────
  static final Logger global = Logger();
  static Logger get log => global;

  // ── Buffers (zero-cost when disabled) ─────────────────────────
  LogBuffer? get t => enabled ? LogBuffer._(this, LogLevel.trace) : null;
  LogBuffer? get d => enabled ? LogBuffer._(this, LogLevel.debug) : null;
  LogBuffer? get i => enabled ? LogBuffer._(this, LogLevel.info) : null;
  LogBuffer? get w => enabled ? LogBuffer._(this, LogLevel.warning) : null;
  LogBuffer? get e => enabled ? LogBuffer._(this, LogLevel.error) : null;

  // ── Direct logging ────────────────────────────────────────────
  void trace(
    final Object? message, [
    final Object? error,
    final StackTrace? stack,
  ]) =>
      _log(LogLevel.trace, message, error, stack);
  void debug(
    final Object? message, [
    final Object? error,
    final StackTrace? stack,
  ]) =>
      _log(LogLevel.debug, message, error, stack);
  void info(
    final Object? message, [
    final Object? error,
    final StackTrace? stack,
  ]) =>
      _log(LogLevel.info, message, error, stack);
  void warning(
    final Object? message, [
    final Object? error,
    final StackTrace? stack,
  ]) =>
      _log(LogLevel.warning, message, error, stack);
  void error(
    final Object? message, [
    final Object? error,
    final StackTrace? stack,
  ]) =>
      _log(LogLevel.error, message, error, stack);

  // ── Core logging ──────────────────────────────────────────────
  void _log(
    final LogLevel level,
    final Object? message,
    final Object? error,
    final StackTrace? stackTrace,
  ) {
    if (!enabled || level.index < minLevel.index) {
      return;
    }

    final caller = stackParser.extractCaller(
      stackTrace: stackTrace ?? StackTrace.current,
      skipFrames: 2,
    );
    if (caller == null) {
      return;
    }

    final entry = LogEntry(
      logger: name,
      level: level,
      message: message?.toString() ?? 'null',
      timestamp: timestampFormatter.getTimestamp() ?? '',
      origin: _buildOrigin(caller),
      stackFrames: _extractStackFrames(level, stackTrace ?? StackTrace.current),
      error: error,
      stackTrace: stackTrace,
    );

    for (final printer in _printers) {
      printer.log(entry);
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
    int idx = lines.indexWhere((final l) => l.contains('Logger._log')) + 1;
    final frames = <CallbackInfo>[];
    const parser = StackTraceParser();
    int added = 0;

    while (idx < lines.length && added < count) {
      final frame = lines[idx++].trim();
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
}
