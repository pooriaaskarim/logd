part of '../handler.dart';

/// Pre-calculated UTF-8 tokens for common log structural elements.
///
/// Reusing these tokens avoids expensive `convert.utf8.encode()` calls
/// on every log line for static characters like brackets, spaces, and borders.
@internal
abstract final class RenderTokens {
  const RenderTokens._();

  /// '['
  static final Uint8List openBracket = Uint8List.fromList([0x5B]);

  /// ']'
  static final Uint8List closeBracket = Uint8List.fromList([0x5D]);

  /// ' '
  static final Uint8List space = Uint8List.fromList([0x20]);

  /// ':'
  static final Uint8List colon = Uint8List.fromList([0x3A]);

  /// '\n'
  static final Uint8List newline = Uint8List.fromList([0x0A]);

  /// '|'
  static final Uint8List pipe = Uint8List.fromList([0x7C]);

  // ANSI Structural
  /// ESC [ 0 m (Reset)
  static final Uint8List ansiReset = FastStringWriter.utf8Bytes('\x1B[0m');

  // Box Borders (Standard Rounded)
  static final Uint8List borderTopLeft = FastStringWriter.utf8Bytes('╭');
  static final Uint8List borderTopRight = FastStringWriter.utf8Bytes('╮');
  static final Uint8List borderBottomLeft = FastStringWriter.utf8Bytes('╰');
  static final Uint8List borderBottomRight = FastStringWriter.utf8Bytes('╯');
  static final Uint8List borderHorizontal = FastStringWriter.utf8Bytes('─');
  static final Uint8List borderVertical = FastStringWriter.utf8Bytes('│');
  static final Uint8List borderMiddle = FastStringWriter.utf8Bytes('├');

  // Box Borders (Sharp)
  static final Uint8List borderSharpTopLeft = FastStringWriter.utf8Bytes('┌');
  static final Uint8List borderSharpTopRight = FastStringWriter.utf8Bytes('┐');
  static final Uint8List borderSharpBottomLeft =
      FastStringWriter.utf8Bytes('└');
  static final Uint8List borderSharpBottomRight =
      FastStringWriter.utf8Bytes('┘');

  // Box Borders (Double)
  static final Uint8List borderDoubleTopLeft = FastStringWriter.utf8Bytes('╔');
  static final Uint8List borderDoubleTopRight = FastStringWriter.utf8Bytes('╗');
  static final Uint8List borderDoubleBottomLeft =
      FastStringWriter.utf8Bytes('╚');
  static final Uint8List borderDoubleBottomRight =
      FastStringWriter.utf8Bytes('╝');
  static final Uint8List borderDoubleHorizontal =
      FastStringWriter.utf8Bytes('═');
  static final Uint8List borderDoubleVertical = FastStringWriter.utf8Bytes('║');
  static final Uint8List borderDoubleMiddle = FastStringWriter.utf8Bytes('╠');

  /// `----|` (LogTag.header)
  static const StyledText styledMessagePrefix =
      StyledText('----|', tags: LogTag.header);

  /// `____` (LogTag.header)
  static const StyledText styledHeaderPrefix =
      StyledText('____', tags: LogTag.header);

  // --- Level Tokens (Full) ---

  /// Returns the pre-encoded level token for [level].
  static StyledText getLevelToken(final LogLevel level) => switch (level) {
        LogLevel.trace => styledLevelTrace,
        LogLevel.debug => styledLevelDebug,
        LogLevel.info => styledLevelInfo,
        LogLevel.warning => styledLevelWarning,
        LogLevel.error => styledLevelError,
      };

  /// `[TRACE]`
  static const StyledText styledLevelTrace =
      StyledText('[TRACE]', tags: LogTag.level | LogTag.header);

  /// `[DEBUG]`
  static const StyledText styledLevelDebug =
      StyledText('[DEBUG]', tags: LogTag.level | LogTag.header);

  /// `[INFO]`
  static const StyledText styledLevelInfo =
      StyledText('[INFO]', tags: LogTag.level | LogTag.header);

  /// `[WARNING]`
  static const StyledText styledLevelWarning =
      StyledText('[WARNING]', tags: LogTag.level | LogTag.header);

  /// `[ERROR]`
  static const StyledText styledLevelError =
      StyledText('[ERROR]', tags: LogTag.level | LogTag.header);

  // --- Structural Fragments (StyledText) ---

  /// `[` (LogTag.header)
  static const StyledText styledOpenBracket =
      StyledText('[', tags: LogTag.header);

  /// `]` (LogTag.header)
  static const StyledText styledCloseBracket =
      StyledText(']', tags: LogTag.header);

  /// ` ` (LogTag.header)
  static const StyledText styledSpace = StyledText(' ', tags: LogTag.header);

  /// `:` (LogTag.header)
  static const StyledText styledColon = StyledText(':', tags: LogTag.header);
}
