part of '../handler.dart';

/// A layout-bearing node, providing structure.
@immutable
sealed class LayoutNode extends LogNode {
  /// Creates a [LayoutNode].
  const LayoutNode({
    required this.children,
    this.title,
    super.tags,
  });

  /// The nested logical nodes.
  final List<LogNode> children;

  /// Optional title for the container.
  final String? title;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LayoutNode &&
          runtimeType == other.runtimeType &&
          listEquals(children, other.children) &&
          setEquals(tags, other.tags) &&
          title == other.title;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        Object.hashAll(children),
        title,
        Object.hashAll(tags),
      );
}

/// A framed container (box).
final class BoxNode extends LayoutNode {
  /// Creates a [BoxNode].
  const BoxNode({
    required super.children,
    super.title,
    this.border = BoxBorderStyle.rounded,
    this.style,
    super.tags,
  });

  /// The visual style of the box borders.
  final BoxBorderStyle border;

  /// Optional visual style for the box borders/title.
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      super == other &&
          other is BoxNode &&
          border == other.border &&
          style == other.style;

  @override
  int get hashCode => Object.hash(super.hashCode, border, style);
}

/// Defines the visual style of a container's border.
enum BoxBorderStyle {
  /// No vertical or horizontal borders.
  none,

  /// A border with rounded corners.
  rounded,

  /// A border with sharp (square) corners.
  sharp,

  /// A double-line border.
  double;

  /// Returns the character for the given border position.
  String getChar(final BoxBorderPosition pos) {
    if (this == none) {
      return '';
    }
    return switch (this) {
      BoxBorderStyle.rounded || BoxBorderStyle.sharp => switch (pos) {
          BoxBorderPosition.horizontal => '─',
          BoxBorderPosition.vertical => '│',
          BoxBorderPosition.middle => '├',
          _ => '',
        },
      BoxBorderStyle.double => switch (pos) {
          BoxBorderPosition.horizontal => '═',
          BoxBorderPosition.vertical => '║',
          BoxBorderPosition.middle => '╠',
          _ => '',
        },
      _ => '',
    };
  }

  /// Returns the character for a box corner.
  String getCorner(final BoxBorderPosition pos, final BoxBorderCorner corner) {
    if (this == none) {
      return '';
    }
    return switch (this) {
      BoxBorderStyle.rounded => switch (pos) {
          BoxBorderPosition.top => corner == BoxBorderCorner.left ? '╭' : '╮',
          BoxBorderPosition.bottom =>
            corner == BoxBorderCorner.left ? '╰' : '╯',
          BoxBorderPosition.middle =>
            corner == BoxBorderCorner.left ? '├' : '┤',
          _ => '',
        },
      BoxBorderStyle.sharp => switch (pos) {
          BoxBorderPosition.top => corner == BoxBorderCorner.left ? '┌' : '┐',
          BoxBorderPosition.bottom =>
            corner == BoxBorderCorner.left ? '└' : '┘',
          BoxBorderPosition.middle =>
            corner == BoxBorderCorner.left ? '├' : '┤',
          _ => '',
        },
      BoxBorderStyle.double => switch (pos) {
          BoxBorderPosition.top => corner == BoxBorderCorner.left ? '╔' : '╗',
          BoxBorderPosition.bottom =>
            corner == BoxBorderCorner.left ? '╚' : '╝',
          BoxBorderPosition.middle =>
            corner == BoxBorderCorner.left ? '╠' : '╣',
          _ => '',
        },
      _ => '',
    };
  }
}

/// Logical positions for box border segments.
enum BoxBorderPosition {
  /// Top border line.
  top,

  /// A separator line between title and content.
  middle,

  /// Bottom border line.
  bottom,

  /// Horizontal line character.
  horizontal,

  /// Vertical line character.
  vertical;
}

/// Horizontal corners of a box.
enum BoxBorderCorner {
  /// Left corner.
  left,

  /// Right corner.
  right;
}

/// A nested/indented container.
final class IndentationNode extends LayoutNode {
  /// Creates an [IndentationNode].
  const IndentationNode({
    required super.children,
    super.title,
    this.indentString = '│ ',
    this.style,
    super.tags,
  });

  /// The indentation string.
  final String indentString;

  /// Optional visual style for the indentation line.
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      super == other &&
          other is IndentationNode &&
          indentString == other.indentString &&
          style == other.style;

  @override
  int get hashCode => Object.hash(super.hashCode, indentString, style);
}

/// A simple logical grouping of blocks with no visual styling.
final class GroupNode extends LayoutNode {
  const GroupNode({required super.children, super.title, super.tags});
}

@immutable
final class DecoratedNode extends LayoutNode {
  /// Creates a [DecoratedNode] container.
  const DecoratedNode({
    required super.children,
    super.title,
    this.leadingWidth = 0,
    this.trailingWidth = 0,
    this.leadingHint,
    this.trailingHint,
    this.leading,
    this.trailing,
    this.alignTrailing = true,
    this.style,
    super.tags,
  });

  /// Width reserved for leading decoration.
  ///
  /// If [leading] is provided, this width should usually match the visible
  /// length of the decoration.
  final int leadingWidth;

  /// Width reserved for trailing decoration.
  final int trailingWidth;

  /// Optional semantic hint about the leading decoration type.
  final String? leadingHint;

  /// Optional semantic hint about the trailing decoration type.
  final String? trailingHint;

  /// Explicit segments for leading decoration.
  final List<StyledText>? leading;

  /// Explicit segments for trailing decoration.
  final List<StyledText>? trailing;

  /// Whether to align the trailing decoration to the right edge.
  final bool alignTrailing;

  /// Optional visual style for the decoration characters (applies if hints are
  /// used).
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      super == other &&
          other is DecoratedNode &&
          leadingWidth == other.leadingWidth &&
          trailingWidth == other.trailingWidth &&
          leadingHint == other.leadingHint &&
          trailingHint == other.trailingHint &&
          listEquals(leading, other.leading) &&
          listEquals(trailing, other.trailing) &&
          alignTrailing == other.alignTrailing &&
          style == other.style;

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        leadingWidth,
        trailingWidth,
        leadingHint,
        trailingHint,
        Object.hashAll(leading ?? []),
        Object.hashAll(trailing ?? []),
        alignTrailing,
        style,
      );
}
