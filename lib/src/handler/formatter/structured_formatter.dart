part of '../handler.dart';

/// A [LogFormatter] that formats log entries in a structured layout.
///
/// This formatter provides detailed output by organizing the log message
/// and its metadata (timestamp, level, origin) in a structured format with
/// clear visual separators. It supports auto-wrapping for long content.
///
@immutable
final class StructuredFormatter implements LogFormatter {
  /// Creates a [StructuredFormatter] with customizable constraints.
  ///
  /// - [lineLength]: The maximum width for content wrapping.
  /// If `null`, attempts to detect terminal width or defaults to 80.
  StructuredFormatter({
    this.lineLength,
  });

  /// The maximum line length for wrapping.
  ///
  /// If `null`, it will attempt to detect the terminal width at runtime.
  final int? lineLength;

  late final int _lineLength = lineLength ??
      (io.stdout.hasTerminal ? io.stdout.terminalColumns - 4 : 80);

  @override
  Iterable<String> format(final LogEntry entry) {
    final innerWidth = _lineLength - 4;
    return <String>[
      ..._buildHeader(entry),
      ..._buildOrigin(entry.origin, innerWidth),
      ..._buildMessage(entry.message, innerWidth),
      if (entry.error != null) ..._buildError(entry.error!, innerWidth),
      if (entry.stackFrames != null)
        ..._buildStackTrace(entry.stackFrames!, innerWidth),
    ];
  }

  List<String> _buildHeader(final LogEntry entry) {
    final logger = '[${entry.loggerName}]';
    final level = '[${entry.level.name.toUpperCase()}]';
    final ts = entry.timestamp;
    final header = '$logger$level\n$ts';
    const prefix = '____';
    final wrapWidth = _lineLength - prefix.length;
    final raw =
        header.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    final out = <String>[];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        out.add(
          prefix + wrapped[i].padVisible(wrapWidth, '_').padLeft(16, '_'),
        );
      }
    }
    return out;
  }

  List<String> _buildOrigin(final String origin, final int innerWidth) {
    const prefix = '--';
    final wrapped = _wrap(origin, innerWidth);
    return wrapped.asMap().entries.map((final e) {
      final p = e.key == 0 ? prefix : ' ' * prefix.length;
      return p + e.value;
    }).toList();
  }

  List<String> _buildMessage(final String content, final int innerWidth) {
    final raw =
        content.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    const prefix = '----|';
    final wrapWidth = innerWidth - prefix.length + 1;
    final out = <String>[];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        out.add(p + wrapped[i]);
      }
    }
    return out;
  }

  List<String> _buildError(
    final Object error,
    final int innerWidth,
  ) {
    final raw = error
        .toString()
        .split('\n')
        .where((final l) => l.trim().isNotEmpty)
        .toList();
    const prefix = '----|';
    final wrapWidth = innerWidth - prefix.length + 1;
    final lines = <String>[
      ..._wrap('Error:', wrapWidth).map((final l) => prefix + l),
    ];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);

      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(p + wrapped[i]);
      }
    }
    return lines;
  }

  List<String> _buildStackTrace(
    final List<CallbackInfo> frames,
    final int innerWidth,
  ) {
    const prefix = '----|';
    final wrapWidth = innerWidth - prefix.length + 1;
    final lines = <String>[
      ..._wrap('Stack Trace:', wrapWidth).map((final l) => prefix + l),
    ];
    for (final frame in frames) {
      final line =
          ' at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(p + wrapped[i]);
      }
    }
    return lines;
  }

  List<String> _wrap(final String text, final int maxWidth) =>
      text.wrapVisible(maxWidth).toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StructuredFormatter &&
          runtimeType == other.runtimeType &&
          lineLength == other.lineLength;

  @override
  int get hashCode => lineLength.hashCode;
}
