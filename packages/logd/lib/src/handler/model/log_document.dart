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
@immutable
class LogDocument {
  /// Creates a [LogDocument].
  const LogDocument({
    required this.nodes,
    this.metadata = const {},
  });

  /// The root nodes of the document tree.
  final List<LogNode> nodes;

  /// Arbitrary metadata associated with the document.
  final Map<String, Object?> metadata;

  /// Creates a copy of this document with optional changes.
  LogDocument copyWith({
    final List<LogNode>? nodes,
    final Map<String, Object?>? metadata,
  }) =>
      LogDocument(
        nodes: nodes ?? this.nodes,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogDocument &&
          runtimeType == other.runtimeType &&
          listEquals(nodes, other.nodes) &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodes),
        Object.hashAll(
          (metadata.entries.toList()
                ..sort((final a, final b) => a.key.compareTo(b.key)))
              .map((final e) => Object.hash(e.key, e.value)),
        ),
      );
}

/// The base class for all nodes in a [LogDocument] tree.
///
/// Nodes are either:
/// - **Content**: [ErrorNode], [MessageNode] (leaf nodes with text).
/// - **Layout**: [BoxNode], [IndentationNode] (container nodes with children).
@immutable
sealed class LogNode {
  /// Creates a [LogNode].
  const LogNode({this.tags = LogTag.none});

  /// Semantic tags describing this node.
  final int tags;
}
