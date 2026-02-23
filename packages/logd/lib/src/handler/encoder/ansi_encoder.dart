part of '../handler.dart';

/// An encoder that produces colorized ANSI output for terminals.
///
/// This encoder uses [TerminalLayout] to calculate the physical geometry of the
/// log and then applies [LogStyle]s resolved via its [theme] using ANSI escape
/// sequences.
class AnsiEncoder implements LogEncoder<String> {
  /// Creates an [AnsiEncoder].
  ///
  /// - [theme]: The theme used to resolve semantic styles.
  ///            Defaults to [LogColorScheme.defaultScheme].
  const AnsiEncoder({
    this.theme = const LogTheme(colorScheme: LogColorScheme.defaultScheme),
  });

  /// The theme used to resolve semantic styles.
  final LogTheme theme;

  @override
  String? preamble(final LogLevel level, {final LogDocument? document}) => null;

  @override
  String? postamble(final LogLevel level) => null;

  @override
  String encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level, {
    final int? width,
  }) {
    if (document.nodes.isEmpty) {
      return '';
    }

    // 1. Calculate physical layout
    final totalWidth = width ?? 80;
    final layoutEngine = TerminalLayout(width: totalWidth);
    final physicalDoc = layoutEngine.layout(document, level);

    // 2. Encode with styles
    final buffer = StringBuffer();
    for (final line in physicalDoc.lines) {
      buffer.writeln(_encodeLine(line, level));
    }

    return buffer.toString().trimRight();
  }

  String _encodeLine(final PhysicalLine line, final LogLevel level) {
    final buffer = StringBuffer();
    for (final segment in line.segments) {
      final style = segment.style ?? theme.getStyle(level, segment.tags);
      buffer.write(_applyStyle(segment.text, style));
    }
    return buffer.toString();
  }

  String _applyStyle(final String text, final LogStyle style) {
    if (text.isEmpty) {
      return text;
    }

    final codes = <int>[];

    if (style.bold == true) {
      codes.add(1);
    }
    if (style.dim == true) {
      codes.add(2);
    }
    if (style.italic == true) {
      codes.add(3);
    }
    if (style.inverse == true) {
      codes.add(7);
    }
    if (style.underline == true) {
      codes.add(4);
    }

    if (style.color != null) {
      codes.add(_getColorCode(style.color!, background: false));
    }
    if (style.backgroundColor != null) {
      codes.add(_getColorCode(style.backgroundColor!, background: true));
    }

    if (codes.isEmpty) {
      return text;
    }

    final codeString = codes.join(';');
    return '\x1B[${codeString}m$text\x1B[0m';
  }

  int _getColorCode(final LogColor color, {required final bool background}) {
    final base = background ? 40 : 30;
    return switch (color) {
      LogColor.black => base + 0,
      LogColor.red => base + 1,
      LogColor.green => base + 2,
      LogColor.yellow => base + 3,
      LogColor.blue => base + 4,
      LogColor.magenta => base + 5,
      LogColor.cyan => base + 6,
      LogColor.white => base + 7,
      LogColor.brightBlack => base + 60,
      LogColor.brightRed => base + 61,
      LogColor.brightGreen => base + 62,
      LogColor.brightYellow => base + 63,
      LogColor.brightBlue => base + 64,
      LogColor.brightMagenta => base + 65,
      LogColor.brightCyan => base + 66,
      LogColor.brightWhite => base + 67,
    };
  }
}
