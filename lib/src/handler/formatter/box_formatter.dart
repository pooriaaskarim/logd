part of '../handler.dart';

/// A [LogFormatter] that wraps log entries in an ASCII box.
///
/// This formatter provides a highly visual output by enclosing the log message
/// and its metadata (timestamp, level, origin) within a styled border. It
/// supports auto-wrapping, ANSI colors, and multiple border styles.
@Deprecated(
  'Use StructuredFormatter with BoxDecorator instead. '
  'Example: Handler(formatter: StructuredFormatter(),'
  ' decorators: [BoxDecorator(),],)',
)
class BoxFormatter implements LogFormatter {
  BoxFormatter({
    this.useColors,
    this.borderStyle = BorderStyle.rounded,
  });

  /// Explicit control over ANSI color usage.
  ///
  /// If `null`, colors are enabled only if the stdout supports ANSI escapes.
  final bool? useColors;

  /// The visual style of the box borders.
  final BorderStyle borderStyle;

  static const _ansiReset = '\x1B[0m';
  static final _levelColors = {
    LogLevel.trace: '\x1B[90m', // Grey
    LogLevel.debug: '\x1B[37m', // White
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
  };

  @override
  Iterable<LogLine> format(final LogEntry entry, final LogContext context) {
    final effectiveLength = context.availableWidth;
    final effectiveUseColors = useColors ?? false;

    final innerWidth = effectiveLength - 4;
    final content = <String>[
      ..._buildHeader(entry, effectiveLength),
      ..._buildOrigin(entry.origin, innerWidth),
      ..._buildMessage(entry.message, innerWidth),
      if (entry.error != null) ..._buildError(entry.error!, innerWidth),
      if (entry.stackFrames != null)
        ..._buildStackTrace(entry.stackFrames!, innerWidth),
    ];
    return _box(content, entry.level, effectiveLength, effectiveUseColors)
        .map((final s) => LogLine([LogSegment(s)]));
  }

  List<String> _buildHeader(final LogEntry entry, final int lineLength) {
    final logger = '[${entry.loggerName}]';
    final level = '[${entry.level.name.toUpperCase()}]';
    final ts = entry.timestamp;
    final header = '$logger$level\n$ts';
    const prefix = '____';
    final wrapWidth = lineLength - prefix.length;
    final raw =
        header.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    final out = <String>[];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        out.add(prefix + wrapped[i].padRight(wrapWidth, '_').padLeft(16, '_'));
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

  List<String> _box(
    final List<String> content,
    final LogLevel level,
    final int lineLength,
    final bool useColors,
  ) {
    final color = useColors ? _levelColors[level] ?? '' : '';
    String topLeft, topRight, bottomLeft, bottomRight, horizontal, vertical;
    switch (borderStyle) {
      case BorderStyle.rounded:
        topLeft = '╭';
        topRight = '╮';
        bottomLeft = '╰';
        bottomRight = '╯';
        horizontal = '─';
        vertical = '│';
        break;
      case BorderStyle.sharp:
        topLeft = '┌';
        topRight = '┐';
        bottomLeft = '└';
        bottomRight = '┘';
        horizontal = '─';
        vertical = '│';
        break;
      case BorderStyle.double:
        topLeft = '╔';
        topRight = '╗';
        bottomLeft = '╚';
        bottomRight = '╝';
        horizontal = '═';
        vertical = '║';
        break;
    }
    final top = '$color$topLeft${horizontal * lineLength}$topRight$_ansiReset';
    final bottom =
        '$color$bottomLeft${horizontal * lineLength}$bottomRight$_ansiReset';
    final boxed = <String>[top];
    for (final line in content) {
      final padded = line.padRight(lineLength);
      boxed.add('$color$vertical$_ansiReset$padded$color$vertical$_ansiReset');
    }
    boxed.add(bottom);
    return boxed;
  }

  List<String> _wrap(final String text, final int maxWidth) {
    final lines = <String>[];
    var remaining = text;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxWidth) {
        lines.add(remaining);
        break;
      }
      var breakPoint = maxWidth;
      while (breakPoint > 0 && remaining[breakPoint] != ' ') {
        breakPoint--;
      }
      if (breakPoint == 0) {
        breakPoint = maxWidth;
      }
      lines.add(remaining.substring(0, breakPoint).trimRight());
      remaining = remaining.substring(breakPoint).trimLeft();
    }
    return lines;
  }
}
