part of '../handler.dart';

/// The complete semantic document of a formatted log entry.
///
/// A [LogDocument] represents the semantic content of a log entry,
/// independent of its final physical rendering (e.g., ANSI text, HTML, JSON).
@immutable
class LogDocument {
  /// Creates a [LogDocument].
  const LogDocument({
    required this.nodes,
    this.metadata = const {},
  });

  /// The sequence of logical nodes that make up the log content.
  final List<LogNode> nodes;

  /// Arbitrary semantic metadata associated with the entire structure.
  final Map<String, dynamic> metadata;

  /// Creates a copy of this [LogDocument] with optional new values.
  LogDocument copyWith({
    final List<LogNode>? nodes,
    final Map<String, dynamic>? metadata,
  }) =>
      LogDocument(
        nodes: nodes ?? this.nodes,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is LogDocument &&
          listEquals(nodes, other.nodes) &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(nodes), Object.hashAll(metadata.values));
}

/// Base class for all logical units in a [LogDocument].
@immutable
sealed class LogNode {
  /// Creates a [LogNode].
  const LogNode({this.tags = const {}});

  /// Semantic tags describing this node.
  final Set<LogTag> tags;
}
