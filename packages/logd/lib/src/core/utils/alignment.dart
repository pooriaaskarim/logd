part of '../../handler/handler.dart';

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
        left => BinaryIR.alignLeft,
        center => BinaryIR.alignCenter,
        right => BinaryIR.alignRight,
        justify => BinaryIR.alignJustify,
      };
}
