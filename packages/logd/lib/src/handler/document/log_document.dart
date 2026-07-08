// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'document.dart';

/// An intermediate representation (IR) of a structured log entry.
///
/// [LogDocument] captures the semantic structure of a log (headers, body,
/// boxes,
/// indentation) as a tree of [LogNode]s, rather than a flat string.
///
/// This structure allows for:
/// - **"Format Once"**: The document is built once by a [LogFormatter].
/// - **Rich Styling**: [LogDecorator]s can traverse and wrap the tree.
/// - **Multiple Outputs**: Different [LogEncoder]s can render the same document
///   to ANSI text, JSON, or HTML without re-parsing.
///
/// On the `arena_refinement` branch, [LogDocument] is a poolable object.
/// It is NOT `@immutable`: instances are checked out from `Arena`,
/// populated by formatters, and returned via [releaseRecursive] after
/// the pipeline completes. Arena-owned documents **must not** be retained
/// across log cycles.
abstract class LogDocument {
  /// Creates a [LogDocument].
  LogDocument();

  /// The root nodes of the document tree.
  List<LogNode> get nodes;

  /// Arbitrary metadata associated with the document.
  Map<String, Object?> get metadata;

  /// Resets this document to an empty state so it can be reused.
  void reset();

  /// Recursively releases this document and all its nodes back to [factory].
  void releaseRecursive(final LogPipelineFactory factory);

  // --- Emitter API (v0.7.X) ---

  /// Appends a text segment to the document.
  void text(
    final String text, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  });

  /// Appends a styled text segment to the document.
  void styledText(final StyledText text, {final LogPipelineFactory? factory});

  /// Appends a newline to the document.
  void newline();

  /// Starts a box scope.
  void startBox({
    final BoxBorderStyle border = BoxBorderStyle.rounded,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  });

  /// Ends the current box scope.
  void endBox();

  /// Starts an indentation scope.
  void startIndent(
    final String indent, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  });

  /// Ends the current indentation scope.
  void endIndent();

  /// Appends a metadata block (Map) to the document.
  void metadataBlock(
    final Map<String, Object?> data, {
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  });

  /// Starts an alignment scope.
  void startAlignment(
    final LogAlignment alignment, {
    final LogPipelineFactory? factory,
  });

  /// Ends the current alignment scope.
  void endAlignment();

  /// Starts a table.
  void startTable({
    final List<int>? columnWidths,
    final LogPipelineFactory? factory,
  });

  /// Ends the current table.
  void endTable();

  /// Starts a table row.
  void startRow({final LogPipelineFactory? factory});

  /// Ends the current table row.
  void endRow();

  /// Starts a table cell.
  void startCell({
    final int colspan = 1,
    final int rowspan = 1,
    final LogPipelineFactory? factory,
  });

  /// Ends the current table cell.
  void endCell();

  /// Starts a decorated scope (e.g. with a leading prefix).
  void startDecorated({
    required final List<StyledText> leading,
    final int leadingWidth = 0,
    final String? leadingHint,
    final LogPipelineFactory? factory,
  });

  /// Ends the current decorated scope.
  void endDecorated();

  /// Appends a filler segment to the document.
  void filler({
    required final String char,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  });

  /// Appends an existing [LogNode] to the document.
  ///
  /// This allows mixing streaming and object-based node construction.
  void writeNode(final LogNode node);
}

/// The standard, object-based implementation of [LogDocument].
class StandardDocument extends LogDocument {
  StandardDocument({
    final List<LogNode>? nodes,
    final Map<String, Object?>? metadata,
  })  : nodes = nodes ?? [],
        metadata = metadata ?? {};

  @internal
  StandardDocument.pooled()
      : nodes = [],
        metadata = {};

  @override
  final List<LogNode> nodes;

  @override
  final Map<String, Object?> metadata;

  @override
  void reset() {
    nodes.clear();
    metadata.clear();
    while (_nodeStack.isNotEmpty) {
      InternalLogger.log(
        LogLevel.warning,
        'reset() called on document with non-empty node stack '
        '— leaked container node.',
      );
      _nodeStack.removeLast();
    }
  }

  @override
  void releaseRecursive(final LogPipelineFactory factory) {
    for (final node in nodes) {
      node.releaseRecursive(factory);
    }
    factory.release(this);
  }

  // --- Emitter Implementation ---

  final List<List<LogNode>> _nodeStack = [];

  List<LogNode> get _currentNodes =>
      _nodeStack.isEmpty ? nodes : _nodeStack.last;

  @override
  void text(
    final String text, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    if (_currentNodes.isNotEmpty) {
      final last = _currentNodes.last;
      if (last is MessageNode && last.tags == tags) {
        last.segments.add(StyledText(text, style: style ?? const LogStyle()));
        return;
      }
    }

    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutMessage()
      ..tags = tags
      ..segments.add(StyledText(text, style: style ?? const LogStyle()));
    _currentNodes.add(node);
  }

  @override
  void styledText(final StyledText text, {final LogPipelineFactory? factory}) {
    if (_currentNodes.isNotEmpty) {
      final last = _currentNodes.last;
      if (last is MessageNode && last.tags == text.tags) {
        last.segments.add(text);
        return;
      }
    }

    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutMessage()..segments.add(text);
    _currentNodes.add(node);
  }

  @override
  void newline() {
    text('\n');
  }

  @override
  void startBox({
    final BoxBorderStyle border = BoxBorderStyle.rounded,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutBox()
      ..tags = tags
      ..border = border;
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endBox() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endBox() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void startIndent(
    final String indent, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutIndentation()
      ..tags = tags
      ..indentString = indent
      ..style = style;
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endIndent() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endIndent() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void metadataBlock(
    final Map<String, Object?> data, {
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutMap()
      ..tags = tags
      ..map = data;
    _currentNodes.add(node);
  }

  @override
  void startAlignment(
    final LogAlignment alignment, {
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutAlignment()..alignment = alignment;
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endAlignment() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endAlignment() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void startTable({
    final List<int>? columnWidths,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutTable()..columnWidths = columnWidths ?? [];
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endTable() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endTable() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void startRow({final LogPipelineFactory? factory}) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutTableRow();
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endRow() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endRow() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void startCell({
    final int colspan = 1,
    final int rowspan = 1,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutTableCell()
      ..colSpan = colspan
      ..rowSpan = rowspan;
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endCell() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endCell() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void startDecorated({
    required final List<StyledText> leading,
    final int leadingWidth = 0,
    final String? leadingHint,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutDecorated()
      ..leading = leading
      ..leadingWidth = leadingWidth
      ..leadingHint = leadingHint;
    _currentNodes.add(node);
    _nodeStack.add(node.children);
  }

  @override
  void endDecorated() {
    assert(
      _nodeStack.isNotEmpty,
      'Mismatched endDecorated() — node stack is empty. Check formatter for unbalanced start/end calls.',
    );
    if (_nodeStack.isNotEmpty) {
      _nodeStack.removeLast();
    }
  }

  @override
  void filler({
    required final String char,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutFiller()
      ..char = char
      ..tags = tags;
    _currentNodes.add(node);
  }

  @override
  void writeNode(final LogNode node) {
    _currentNodes.add(node);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogDocument &&
          listEquals(nodes, other.nodes) &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodes),
        Object.hashAll(metadata.keys),
        Object.hashAll(metadata.values),
      );
}

/// The base class for all nodes in a [LogDocument] tree.
///
/// Nodes are either:
/// - **Content**: [ErrorNode], [MessageNode] (leaf nodes with text).
/// - **Layout**: [BoxNode], [IndentationNode] (container nodes with children).
///
/// On the `arena_refinement` branch, [LogNode] subclasses are mutable
/// poolable objects. They must not be `const`-constructed and must not be
/// retained across log cycles.
sealed class LogNode {
  /// Creates a [LogNode].
  LogNode({this.tags = LogTag.none});

  /// Semantic tags describing this node.
  int tags;

  /// Resets this node's fields to their defaults for pool reuse.
  void reset();

  /// Releases this node and any children back to [factory].
  void releaseRecursive(final LogPipelineFactory factory);
}
