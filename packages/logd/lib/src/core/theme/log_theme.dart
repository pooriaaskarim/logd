import 'package:meta/meta.dart';
import '../../../logd.dart';

/// Semantic tags describing the content of a [LogNode].
abstract class LogTag {
  /// No tags.
  static const int none = 0;

  /// General metadata like timestamp, level, or logger name.
  static const int header = 1 << 0;

  /// Information about where the log was emitted (file, line, function).
  static const int origin = 1 << 1;

  /// The primary log message body.
  static const int message = 1 << 2;

  /// Error information (exception message).
  static const int error = 1 << 3;

  /// Individual frame in a stack trace.
  static const int stackFrame = 1 << 4;

  /// Content related to the log level (e.g. the "[[INFO]]" text).
  static const int level = 1 << 5;

  /// Structural lines like box borders or dividers.
  static const int border = 1 << 6;

  /// Content related to the timestamp.
  static const int timestamp = 1 << 7;

  /// Content related to the logger name.
  static const int loggerName = 1 << 8;

  /// Tree-like hierarchy prefix.
  static const int hierarchy = 1 << 9;

  /// Content Prefix
  static const int prefix = 1 << 10;

  /// Content Suffix
  static const int suffix = 1 << 11;

  /// Semantic key (e.g. JSON key, TOON field name).
  static const int key = 1 << 12;

  /// Generic data value.
  static const int value = 1 << 13;

  /// Structural punctuation (e.g. braces, commas, delimiters).
  static const int punctuation = 1 << 14;

  /// Optimization hint: Content should not be wrapped by the layout engine.
  /// Used for machine-readable formats (JSON, TOON) where structure is
  /// critical.
  static const int noWrap = 1 << 15;

  /// Semantic hint: Content is suitable for a collapsible/expandable section
  /// (e.g., \<details\> in HTML/Markdown).
  static const int collapsible = 1 << 16;
}

/// Visual style suggestion for a log segment.
@immutable
class LogStyle {
  /// Creates a [LogStyle].
  const LogStyle({
    this.color,
    this.backgroundColor,
    this.bold,
    this.dim,
    this.italic,
    this.inverse,
    this.underline,
  });

  /// The suggested foreground color.
  final LogColor? color;

  /// The suggested background color.
  final LogColor? backgroundColor;

  /// Whether the text should be bold.
  final bool? bold;

  /// Whether the text should be dimmed (faint).
  final bool? dim;

  /// Whether the text should be italic.
  final bool? italic;

  /// Whether the text/background color should be inverted.
  final bool? inverse;

  /// Whether the text should be underlined.
  final bool? underline;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          bold == other.bold &&
          dim == other.dim &&
          italic == other.italic &&
          inverse == other.inverse &&
          underline == other.underline;

  @override
  int get hashCode => Object.hash(
        color,
        backgroundColor,
        bold,
        dim,
        italic,
        inverse,
        underline,
      );
}

/// Abstract color definitions for log rendering.
///
/// These colors are semantic and do not imply any specific rendering technology
/// (like ANSI). Sinks are free to interpret these colors as they see fit, or
/// ignore them entirely.
enum LogColor {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite;
}

/// Configuration for color schemes based on log levels.
@immutable
class LogColorScheme {
  /// Creates a color scheme.
  const LogColorScheme({
    required this.trace,
    required this.debug,
    required this.info,
    required this.warning,
    required this.error,
    this.timestampColor,
    this.loggerNameColor,
    this.levelColor,
    this.borderColor,
    this.stackFrameColor,
    this.hierarchyColor,
  });

  // Base colors per level
  final LogColor trace;
  final LogColor debug;
  final LogColor info;
  final LogColor warning;
  final LogColor error;

  // Override colors for specific tags (optional)
  /// Color for timestamp segments. If null, uses base level color.
  final LogColor? timestampColor;

  /// Color for logger name segments. If null, uses base level color.
  final LogColor? loggerNameColor;

  /// Color for level indicator segments. If null, uses base level color.
  final LogColor? levelColor;

  /// Color for border segments. If null, uses base level color.
  final LogColor? borderColor;

  /// Color for stack frame segments. If null, uses base level color.
  final LogColor? stackFrameColor;

  /// Color for hierarchy lines. If null, defaults to null (no color).
  final LogColor? hierarchyColor;

  /// Get color for a specific tag set at a given level.
  ///
  /// Priority: specific tag overrides > base level color.
  LogColor colorFor(final LogLevel level, final int tags) {
    // Check for specific tag overrides first
    if ((tags & LogTag.timestamp) != 0 && timestampColor != null) {
      return timestampColor!;
    }
    if ((tags & LogTag.loggerName) != 0 && loggerNameColor != null) {
      return loggerNameColor!;
    }
    if ((tags & LogTag.level) != 0 && levelColor != null) {
      return levelColor!;
    }
    if ((tags & LogTag.border) != 0 && borderColor != null) {
      return borderColor!;
    }
    if ((tags & LogTag.stackFrame) != 0 && stackFrameColor != null) {
      return stackFrameColor!;
    }
    if ((tags & LogTag.hierarchy) != 0 && hierarchyColor != null) {
      return hierarchyColor!;
    }

    // Fallback to base level color
    return colorForLevel(level);
  }

  LogColor colorForLevel(final LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return trace;
      case LogLevel.debug:
        return debug;
      case LogLevel.info:
        return info;
      case LogLevel.warning:
        return warning;
      case LogLevel.error:
        return error;
    }
  }

  static const defaultScheme = LogColorScheme(
    trace: LogColor.green,
    debug: LogColor.white,
    info: LogColor.blue,
    warning: LogColor.yellow,
    error: LogColor.red,
  );

  static const darkScheme = LogColorScheme(
    trace: LogColor.brightGreen,
    debug: LogColor.brightWhite,
    info: LogColor.brightBlue,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  static const pastelScheme = LogColorScheme(
    trace: LogColor.green,
    debug: LogColor.cyan,
    info: LogColor.brightCyan,
    warning: LogColor.brightYellow,
    error: LogColor.brightRed,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogColorScheme &&
          trace == other.trace &&
          debug == other.debug &&
          info == other.info &&
          warning == other.warning &&
          error == other.error &&
          timestampColor == other.timestampColor &&
          loggerNameColor == other.loggerNameColor &&
          levelColor == other.levelColor &&
          borderColor == other.borderColor &&
          stackFrameColor == other.stackFrameColor &&
          hierarchyColor == other.hierarchyColor;

  @override
  int get hashCode => Object.hash(
        trace,
        debug,
        info,
        warning,
        error,
        timestampColor,
        loggerNameColor,
        levelColor,
        borderColor,
        stackFrameColor,
        hierarchyColor,
      );
}

/// Defines a theme for logging, mapping semantic concepts to [LogStyle]s.
@immutable
class LogTheme {
  /// Creates a [LogTheme].
  ///
  /// [colorScheme] is required and defines the base palette.
  /// Optional style parameters allow overriding specific semantic segments.
  const LogTheme({
    required this.colorScheme,
    this.timestampStyle,
    this.loggerNameStyle,
    this.levelStyle,
    this.messageStyle,
    this.borderStyle,
    this.stackFrameStyle,
    this.errorStyle,
    this.hierarchyStyle,
  });

  /// The base color scheme for log levels.
  final LogColorScheme colorScheme;

  /// Style for timestamps.
  final LogStyle? timestampStyle;

  /// Style for logger names.
  final LogStyle? loggerNameStyle;

  /// Style for level indicators.
  final LogStyle? levelStyle;

  /// Style for the main message.
  final LogStyle? messageStyle;

  /// Style for borders/dividers.
  final LogStyle? borderStyle;

  /// Style for stack trace frames.
  final LogStyle? stackFrameStyle;

  /// Style for error messages.
  final LogStyle? errorStyle;

  /// Style for hierarchy lines.
  final LogStyle? hierarchyStyle;

  /// Resolves the style for a given segment based on level and tags.
  LogStyle getStyle(final LogLevel level, final int tags) {
    // 1. Start with base color for the level
    // Exception: Hierarchy lines should NOT take level color by default.
    final baseColor = (tags & LogTag.hierarchy) != 0
        ? null
        : colorScheme.colorForLevel(level);

    var style = LogStyle(color: baseColor);

    // 2. Apply default semantic styles
    if ((tags & LogTag.level) != 0) {
      style = _merge(style, const LogStyle(bold: true));
    } else if ((tags & LogTag.timestamp) != 0 ||
        (tags & LogTag.loggerName) != 0) {
      style = _merge(style, const LogStyle(dim: true));
    } else if ((tags & LogTag.header) != 0) {
      style = _merge(style, const LogStyle(bold: true));
    }

    // 3. Apply tag-specific overrides/merges
    if ((tags & LogTag.level) != 0) {
      style = _merge(style, levelStyle);
      // Ensure level color override from scheme
      // is respected if theme style doesn't enforce one
      if (colorScheme.levelColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.levelColor));
      }
    } else if ((tags & LogTag.timestamp) != 0) {
      style = _merge(style, timestampStyle);
      if (colorScheme.timestampColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.timestampColor));
      }
    } else if ((tags & LogTag.loggerName) != 0) {
      style = _merge(style, loggerNameStyle);
      if (colorScheme.loggerNameColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.loggerNameColor));
      }
    } else if ((tags & LogTag.message) != 0) {
      style = _merge(style, messageStyle);
    } else if ((tags & LogTag.border) != 0) {
      style = _merge(style, borderStyle);
      if (colorScheme.borderColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.borderColor));
      }
    } else if ((tags & LogTag.stackFrame) != 0) {
      style = _merge(style, stackFrameStyle);
      if (colorScheme.stackFrameColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.stackFrameColor));
      }
    } else if ((tags & LogTag.error) != 0) {
      style = _merge(style, errorStyle);
    } else if ((tags & LogTag.hierarchy) != 0) {
      style = _merge(style, hierarchyStyle);
      if (colorScheme.hierarchyColor != null) {
        style = _merge(style, LogStyle(color: colorScheme.hierarchyColor));
      }
    }

    return style;
  }

  LogStyle _merge(final LogStyle base, final LogStyle? override) {
    if (override == null) {
      return base;
    }
    return LogStyle(
      color: override.color ?? base.color,
      backgroundColor: override.backgroundColor ?? base.backgroundColor,
      bold: override.bold ?? base.bold,
      dim: override.dim ?? base.dim,
      italic: override.italic ?? base.italic,
      inverse: override.inverse ?? base.inverse,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogTheme &&
          runtimeType == other.runtimeType &&
          colorScheme == other.colorScheme &&
          timestampStyle == other.timestampStyle &&
          loggerNameStyle == other.loggerNameStyle &&
          levelStyle == other.levelStyle &&
          messageStyle == other.messageStyle &&
          borderStyle == other.borderStyle &&
          stackFrameStyle == other.stackFrameStyle &&
          errorStyle == other.errorStyle &&
          hierarchyStyle == other.hierarchyStyle;

  @override
  int get hashCode => Object.hash(
        colorScheme,
        timestampStyle,
        loggerNameStyle,
        levelStyle,
        messageStyle,
        borderStyle,
        stackFrameStyle,
        errorStyle,
        hierarchyStyle,
      );
}
