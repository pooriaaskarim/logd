part of '../handler.dart';

/// A [LogDecorator] that applies semantic colors to log lines based on tags.
///
/// Colors are applied based on the [LogLevel] severity and semantic [LogTag]s.
/// This decorator is sink-agnostic; sinks interpret [LogColor] as appropriate
/// for their output format (ANSI, HTML, etc.).
///
/// Example with fine-grained color control:
/// ```dart
/// ColorDecorator(
///   colorScheme: ColorScheme(
///     info: LogColor.blue,
///     error: LogColor.red,
///     // Override specific tags
///     timestampColor: LogColor.brightBlack,
///     levelColor: LogColor.brightBlue,
///   ),
///   config: ColorConfig(
///     colorTimestamp: true,
///     colorLevel: true,
///     colorMessage: false, // Don't color message body
///   ),
/// )
/// ```
@immutable
final class ColorDecorator extends VisualDecorator {
  /// Creates a [ColorDecorator].
  ///
  /// If [useColors] is `null`, decoration proceeds (sinks decide rendering).
  /// Set to `false` to explicitly skip color decoration.
  ///
  /// [colorScheme] maps log levels and tags to semantic colors.
  /// Defaults to [ColorScheme.defaultScheme].
  ///
  /// [config] controls which semantic parts get colored.
  /// Defaults to [ColorConfig.all] (color everything).
  const ColorDecorator({
    this.useColors,
    this.colorScheme = ColorScheme.defaultScheme,
    this.config = ColorConfig.all,
  });

  /// Explicit override for enabling or disabling colors.
  final bool? useColors;

  /// Color scheme mapping log levels and tags to semantic colors.
  final ColorScheme colorScheme;

  /// Configuration for color application.
  final ColorConfig config;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    if (useColors == false) {
      yield* lines;
      return;
    }

    final level = entry.level;

    for (final line in lines) {
      final newSegments = <LogSegment>[];
      for (final segment in line.segments) {
        final tags = segment.tags;

        // Check if we should color this segment
        if (!config.shouldColor(tags)) {
          newSegments.add(segment);
          continue;
        }

        // Get color for this specific tag combination
        final color = colorScheme.colorFor(level, tags);

        // Handle style merging
        if (segment.style != null) {
          // Merge color into existing style
          final mergedStyle = TextStyle(
            color: color,
            bold: segment.style!.bold,
            dim: segment.style!.dim,
            italic: segment.style!.italic,
            inverse: segment.style!.inverse,
          );
          newSegments
              .add(LogSegment(segment.text, tags: tags, style: mergedStyle));
        } else {
          // Apply new style with color and semantic styling
          TextStyle? style;

          // Stack frames: special bright-black color
          if (tags.contains(LogTag.stackFrame)) {
            style = const TextStyle(color: LogColor.brightBlack);
          }
          // Borders: dimmed
          else if (tags.contains(LogTag.border)) {
            style = TextStyle(color: color, dim: true);
          }
          // Headers with fine-grained control
          else if (tags.contains(LogTag.header)) {
            if (tags.contains(LogTag.level)) {
              // Level indicators: bold
              style = TextStyle(
                color: color,
                bold: true,
                inverse: config.headerBackground,
              );
            } else if (tags.contains(LogTag.timestamp) ||
                tags.contains(LogTag.loggerName)) {
              // Timestamps/Logger names: dimmed
              style = TextStyle(
                color: color,
                dim: true,
                inverse: config.headerBackground,
              );
            } else {
              // Generic header: bold
              style = TextStyle(
                color: color,
                bold: true,
                inverse: config.headerBackground,
              );
            }
          }
          // Body/Message: standard color
          else {
            style = TextStyle(color: color);
          }

          newSegments.add(LogSegment(segment.text, tags: tags, style: style));
        }
      }
      yield LogLine(newSegments);
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorDecorator &&
          runtimeType == other.runtimeType &&
          useColors == other.useColors &&
          colorScheme == other.colorScheme &&
          config == other.config;

  @override
  int get hashCode =>
      useColors.hashCode ^ colorScheme.hashCode ^ config.hashCode;
}
