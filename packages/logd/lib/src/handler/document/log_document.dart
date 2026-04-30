// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of '../handler.dart';

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
/// It is NOT `@immutable`: instances are checked out from [Arena],
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

  StandardDocument._pooled()
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
    _nodeStack.clear();
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
    final f = factory ?? const StandardPipelineFactory();
    final node = f.checkoutMessage()
      ..tags = tags
      ..segments.add(StyledText(text, style: style ?? const LogStyle()));
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
