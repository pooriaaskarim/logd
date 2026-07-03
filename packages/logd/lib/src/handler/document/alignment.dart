part of 'document.dart';

/// Horizontal text alignment options.
enum LogAlignment {
  /// Align to the left edge (default).
  left,

  /// Center content within the available width.
  center,

  /// Align to the right edge.
  right,

  /// Stretch content to fill the full width by adjusting spacing.
  justify;

  /// Returns the B-IR alignment type code.
  int get binaryType => switch (this) {
        left => 0,
        center => 1,
        right => 2,
        justify => 3,
      };
}
