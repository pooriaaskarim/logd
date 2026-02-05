part of '../handler.dart';

/// Shared context passed through the logging pipeline.
///
/// The [LogContext] acts as the authoritative source of truth for layout and
/// presentation constraints (e.g., [availableWidth]) during the formatting
/// and decoration stages.
@immutable
class LogContext {
  /// Creates a [LogContext].
  const LogContext({
    required this.availableWidth,
    final int? totalWidth,
    final int? contentLimit,
    this.arbitraryData = const {},
  })  : totalWidth = totalWidth ?? availableWidth,
        contentLimit = contentLimit ?? (totalWidth ?? availableWidth);

  /// The width available for the initial formatting of the content.
  final int availableWidth;

  /// The total terminal/configured width for the log entry.
  final int totalWidth;

  /// The layout width limit derived from [totalWidth] minus structural
  /// overheads
  /// (e.g. Box borders).
  ///
  /// Decorators that align content (like Suffix) or wrap structure (like Box)
  /// should respect this limit to ensure the final composition fits the
  /// display.
  final int contentLimit;

  /// Additional arbitrary data for extensibility.
  final Map<String, Object?> arbitraryData;

  /// Creates a copy of this [LogContext] with updated fields.
  LogContext copyWith({
    final int? availableWidth,
    final int? totalWidth,
    final int? contentLimit,
    final Map<String, Object?>? arbitraryData,
  }) =>
      LogContext(
        availableWidth: availableWidth ?? this.availableWidth,
        totalWidth: totalWidth ?? this.totalWidth,
        contentLimit: contentLimit ?? this.contentLimit,
        arbitraryData: arbitraryData ?? this.arbitraryData,
      );
}
