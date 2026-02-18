import '../../../logd.dart';

/// ANSI escape codes for basic 16-color terminal support.
///
/// Used by sinks (like [ConsoleSink]) to translate [LogColor] into terminal
/// escape sequences.
enum AnsiColorCode {
  black(30),
  red(31),
  green(32),
  yellow(33),
  blue(34),
  magenta(35),
  cyan(36),
  white(37),
  brightBlack(90),
  brightRed(91),
  brightGreen(92),
  brightYellow(93),
  brightBlue(94),
  brightMagenta(95),
  brightCyan(96),
  brightWhite(97);

  const AnsiColorCode(this.code);
  final int code;

  /// ANSI escape sequence for this color (foreground).
  String get foreground => '\x1B[${code}m';

  /// ANSI escape sequence for this color (background, code + 10).
  String get background => '\x1B[${code + 10}m';

  static AnsiColorCode fromLogColor(final LogColor color) {
    switch (color) {
      case LogColor.black:
        return black;
      case LogColor.red:
        return red;
      case LogColor.green:
        return green;
      case LogColor.yellow:
        return yellow;
      case LogColor.blue:
        return blue;
      case LogColor.magenta:
        return magenta;
      case LogColor.cyan:
        return cyan;
      case LogColor.white:
        return white;
      case LogColor.brightBlack:
        return brightBlack;
      case LogColor.brightRed:
        return brightRed;
      case LogColor.brightGreen:
        return brightGreen;
      case LogColor.brightYellow:
        return brightYellow;
      case LogColor.brightBlue:
        return brightBlue;
      case LogColor.brightMagenta:
        return brightMagenta;
      case LogColor.brightCyan:
        return brightCyan;
      case LogColor.brightWhite:
        return brightWhite;
    }
  }
}

/// ANSI style modifiers.
enum AnsiStyle {
  reset(0),
  bold(1),
  dim(2),
  italic(3),
  underline(4),
  blink(5),
  reverse(7),
  hidden(8),
  strikethrough(9);

  const AnsiStyle(this.code);

  final int code;

  /// ANSI escape sequence for this style.
  String get sequence => '\x1B[${code}m';
}
