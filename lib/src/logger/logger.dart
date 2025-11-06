import 'package:flutter/foundation.dart';

import '../printer/box.printer.dart';
import '../stack_trace_parser/stack_trace_parser.dart';
import '../time/timestamp_formatter.dart';

part 'log_buffer.dart';

enum LogLevel { trace, debug, info, warning, error }

class Logger {
  Logger._();
  static bool enabled = kDebugMode;
  static LogLevel minLevel = LogLevel.debug;
  static bool includeFileLineInHeader = false;
  static Map<LogLevel, int> stackMethodCount = {
    LogLevel.trace: 0,
    LogLevel.debug: 0,
    LogLevel.info: 0,
    LogLevel.warning: 2,
    LogLevel.error: 8,
  };

  static StackTraceParser parser = const StackTraceParser(
    ignorePackages: ['logger', 'flutter'],
  );

  static Timestamp? timestamp = Timestamp(
    formatter: 'yyyy/MMMM/dd\nhhhh:mm:ss.SSSS\nZZZ',
    timeZone: TimeZone.named('NY', '-05:00'),
  );

  static void t(final LogBuffer? buffer) => _log(buffer, level: LogLevel.trace);
  static void d(final LogBuffer? buffer) => _log(buffer, level: LogLevel.debug);
  static void i(final LogBuffer? buffer) => _log(buffer, level: LogLevel.info);
  static void w(final LogBuffer? buffer) =>
      _log(buffer, level: LogLevel.warning);
  static void e(final LogBuffer? buffer) => _log(buffer, level: LogLevel.error);

  static void _log(final LogBuffer? buffer, {required final LogLevel level}) {
    if (!enabled || level.index < minLevel.index || buffer == null) {
      return;
    }
    final caller =
        parser.extractCaller(stackTrace: StackTrace.current, skipFrames: 2);
    if (caller == null) {
      return;
    }
    final origin = _buildOrigin(caller);
    final innerWidth = BoxPrinter.lineLength - 4;
    final lines = <String>[
      ..._buildLogHeader(level),
      ..._buildHeader(origin, innerWidth),
      ..._buildMessage(buffer.toString(), innerWidth),
      ..._buildStackTrace(level, innerWidth),
    ];
    BoxPrinter.printBox(lines, level);
  }

  static String _buildOrigin(final CallbackInfo info) {
    var origin = info.className.isNotEmpty
        ? '${info.className}.${info.methodName}'
        : info.methodName;
    if (includeFileLineInHeader) {
      origin += ' (${info.filePath}:${info.lineNumber})';
    }
    return origin;
  }

  static List<String> _buildLogHeader(final LogLevel level) {
    final levelInfo = '[${level.name.toUpperCase()}]';
    final timestampInfo = timestamp?.getTimestamp() ?? '';
    final header =
        '$levelInfo${timestampInfo.isNotEmpty ? '\n$timestampInfo' : ''}';
    const prefix = '____';
    const prefixLen = prefix.length;
    final wrapWidth = BoxPrinter.lineLength - prefixLen;
    final raw =
        header.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    final out = <String>[];
    for (final line in raw) {
      final wrapped = BoxPrinter.wrapLine(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        out.add(prefix + wrapped[i].padRight(wrapWidth, '_').padLeft(16, '_'));
      }
    }
    return out;
  }

  static List<String> _buildHeader(final String origin, final int innerWidth) {
    const prefix = '--';
    const indent = prefix.length;
    final wrapped = BoxPrinter.wrapLine(origin, innerWidth);
    return wrapped.asMap().entries.map((final e) {
      final p = e.key == 0 ? prefix : ' ' * indent;
      return p + e.value;
    }).toList();
  }

  static List<String> _buildMessage(
    final String content,
    final int innerWidth,
  ) {
    final raw =
        content.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    const prefix = '----|';
    const prefixLen = prefix.length;
    final wrapWidth = innerWidth - prefixLen + 1;
    final out = <String>[];
    for (final line in raw) {
      final wrapped = BoxPrinter.wrapLine(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefixLen;
        out.add(p + wrapped[i]);
      }
    }
    return out;
  }

  static List<String> _buildStackTrace(
      final LogLevel level, final int innerWidth) {
    final count = stackMethodCount[level] ?? 0;
    if (count == 0) {
      return [];
    }
    final lines = <String>[];
    const prefix = '----|';
    const prefixLen = prefix.length;
    final wrapWidth = innerWidth - prefixLen + 1;
    lines.addAll(
      BoxPrinter.wrapLine('Stack Trace:', wrapWidth)
          .map((final l) => prefix + l),
    );
    final stackLines = StackTrace.current.toString().split('\n');
    int idx = stackLines.indexWhere((final l) => l.contains('Logger._log')) + 1;
    int added = 0;
    const parser = StackTraceParser();
    while (idx < stackLines.length && added < count) {
      final frame = stackLines[idx++].trim();
      if (frame.isEmpty) {
        continue;
      }
      final info = parser.parseFrame(frame);
      if (info == null) {
        continue;
      }
      final line =
          '   at ${info.fullMethod} (${info.filePath}:${info.lineNumber})';
      final wrapped = BoxPrinter.wrapLine(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefixLen;
        lines.add(p + wrapped[i]);
      }
      added++;
    }
    return lines;
  }
}
