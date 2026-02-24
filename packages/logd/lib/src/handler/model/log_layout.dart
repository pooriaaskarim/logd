// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of '../handler.dart';

/// A container node that defines the visual structure or layout.
///
/// [LayoutNode]s wrap other nodes (children) to apply structural effects like:
/// - **Boxing**: [BoxNode] draws a border around its children.
/// - **Indentation**: [IndentationNode] shifts content to the right.
/// - **Decoration**: [DecoratedNode] adds prefixes or suffixes.
///
/// On the `arena_refinement` branch, [LayoutNode] and all subclasses are
/// poolable mutable objects. Use [LogArena] to check out and release them.
sealed class LayoutNode extends LogNode {
  /// Creates a [LayoutNode].
  LayoutNode({
    required this.children,
    this.title,
    super.tags,
  });

  /// The child nodes contained within this layout structure.
  List<LogNode> children;

  /// Optional title or label for this structural block (e.g., box title).
  StyledText? title;

  /// Creates a copy of this node with optional changes.
  LayoutNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
  });

  @override
  void reset() {
    children.clear();
    title = null;
    tags = LogTag.none;
  }

  @override
  void releaseRecursive(final LogArena arena) {
    for (final child in children) {
      child.releaseRecursive(arena);
    }
    arena.release(this);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LayoutNode &&
          runtimeType == other.runtimeType &&
          listEquals(children, other.children) &&
          title == other.title &&
          tags == other.tags;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        Object.hashAll(children),
        title,
        tags,
      );
}

/// A framed container (box).
final class BoxNode extends LayoutNode {
  /// Creates a [BoxNode].
  BoxNode({
    required super.children,
    super.title,
    this.border = BoxBorderStyle.rounded,
    this.style,
    super.tags,
  });

  /// Named constructor for arena pool allocation.
  BoxNode._pooled()
      : border = BoxBorderStyle.rounded,
        style = null,
        super(children: []);

  /// The visual style of the box borders.
  BoxBorderStyle border;

  /// Optional visual style for the box borders/title.
  LogStyle? style;

  @override
  void reset() {
    super.reset();
    border = BoxBorderStyle.rounded;
    style = null;
  }

  @override
  BoxNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
    final BoxBorderStyle? border,
    final LogStyle? style,
  }) =>
      BoxNode(
        children: children ?? List<LogNode>.from(this.children),
        title: title ?? this.title,
        tags: tags ?? this.tags,
        border: border ?? this.border,
        style: style ?? this.style,
      );

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
  IndentationNode({
    required super.children,
    super.title,
    this.indentString = '│ ',
    this.style,
    super.tags,
  });

  /// Named constructor for arena pool allocation.
  IndentationNode._pooled()
      : indentString = '│ ',
        style = null,
        super(children: []);

  /// The indentation string.
  String indentString;

  /// Optional visual style for the indentation line.
  LogStyle? style;

  @override
  void reset() {
    super.reset();
    indentString = '│ ';
    style = null;
  }

  @override
  IndentationNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
    final String? indentString,
    final LogStyle? style,
  }) =>
      IndentationNode(
        children: children ?? List<LogNode>.from(this.children),
        title: title ?? this.title,
        tags: tags ?? this.tags,
        indentString: indentString ?? this.indentString,
        style: style ?? this.style,
      );

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
  /// Creates a [GroupNode].
  GroupNode({required super.children, super.title, super.tags});

  /// Named constructor for arena pool allocation.
  GroupNode._pooled() : super(children: []);

  @override
  GroupNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
  }) =>
      GroupNode(
        children: children ?? List<LogNode>.from(this.children),
        title: title ?? this.title,
        tags: tags ?? this.tags,
      );
}

/// A node that applies decoration (prefix/suffix) to its content.
final class DecoratedNode extends LayoutNode {
  /// Creates a [DecoratedNode] container.
  DecoratedNode({
    required super.children,
    super.title,
    this.leadingWidth = 0,
    this.trailingWidth = 0,
    this.leadingHint,
    this.trailingHint,
    this.leading,
    this.trailing,
    this.repeatLeading = false,
    this.repeatTrailing = false,
    this.alignTrailing = true,
    this.style,
    super.tags,
  });

  /// Named constructor for arena pool allocation.
  DecoratedNode._pooled()
      : leadingWidth = 0,
        trailingWidth = 0,
        leadingHint = null,
        trailingHint = null,
        leading = null,
        trailing = null,
        repeatLeading = false,
        repeatTrailing = false,
        alignTrailing = true,
        style = null,
        super(children: []);

  /// Width reserved for leading decoration.
  int leadingWidth;

  /// Width reserved for trailing decoration.
  int trailingWidth;

  /// Optional semantic hint about the leading decoration type.
  String? leadingHint;

  /// Optional semantic hint about the trailing decoration type.
  String? trailingHint;

  /// Explicit segments for leading decoration.
  List<StyledText>? leading;

  /// Explicit segments for trailing decoration.
  List<StyledText>? trailing;

  /// Whether the leading decoration should be repeated on all lines.
  bool repeatLeading;

  /// Whether the trailing decoration should be repeated on all lines.
  bool repeatTrailing;

  /// Whether to align the trailing decoration to the right edge.
  bool alignTrailing;

  /// Optional visual style for the decoration characters.
  LogStyle? style;

  @override
  void reset() {
    super.reset();
    leadingWidth = 0;
    trailingWidth = 0;
    leadingHint = null;
    trailingHint = null;
    leading = null;
    trailing = null;
    repeatLeading = false;
    repeatTrailing = false;
    alignTrailing = true;
    style = null;
  }

  @override
  DecoratedNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
    final int? leadingWidth,
    final int? trailingWidth,
    final String? leadingHint,
    final String? trailingHint,
    final List<StyledText>? leading,
    final List<StyledText>? trailing,
    final bool? repeatLeading,
    final bool? repeatTrailing,
    final bool? alignTrailing,
    final LogStyle? style,
  }) =>
      DecoratedNode(
        children: children ?? List<LogNode>.from(this.children),
        title: title ?? this.title,
        tags: tags ?? this.tags,
        leadingWidth: leadingWidth ?? this.leadingWidth,
        trailingWidth: trailingWidth ?? this.trailingWidth,
        leadingHint: leadingHint ?? this.leadingHint,
        trailingHint: trailingHint ?? this.trailingHint,
        leading: leading ?? this.leading,
        trailing: trailing ?? this.trailing,
        repeatLeading: repeatLeading ?? this.repeatLeading,
        repeatTrailing: repeatTrailing ?? this.repeatTrailing,
        alignTrailing: alignTrailing ?? this.alignTrailing,
        style: style ?? this.style,
      );

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
          repeatLeading == other.repeatLeading &&
          repeatTrailing == other.repeatTrailing &&
          alignTrailing == other.alignTrailing &&
          style == other.style;

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        leadingWidth,
        trailingWidth,
        leadingHint,
        trailingHint,
        leading != null ? Object.hashAll(leading!) : null,
        trailing != null ? Object.hashAll(trailing!) : null,
        repeatLeading,
        repeatTrailing,
        alignTrailing,
        style,
      );
}

/// A node that forces its children to be flowed and wrapped as a paragraph.
final class ParagraphNode extends LayoutNode {
  /// Creates a [ParagraphNode].
  ParagraphNode({required super.children, super.tags});

  /// Named constructor for arena pool allocation.
  ParagraphNode._pooled() : super(children: []);

  @override
  ParagraphNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
  }) =>
      ParagraphNode(
        children: children ?? List<LogNode>.from(this.children),
        tags: tags ?? this.tags,
      );
}

/// A node that lays out its children horizontally on a single physical line.
final class RowNode extends LayoutNode {
  /// Creates a [RowNode].
  RowNode({required super.children, super.tags});

  /// Named constructor for arena pool allocation.
  RowNode._pooled() : super(children: []);

  @override
  RowNode copyWith({
    final List<LogNode>? children,
    final StyledText? title,
    final int? tags,
  }) =>
      RowNode(
        children: children ?? List<LogNode>.from(this.children),
        tags: tags ?? this.tags,
      );
}
