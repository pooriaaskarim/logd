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
/// It is NOT `@immutable`: instances are checked out from [LogArena],
/// populated by formatters, and returned via [releaseRecursive] after
/// the pipeline completes. Arena-owned documents **must not** be retained
/// across log cycles.
class LogDocument {
  /// Creates a [LogDocument] with the given [nodes] and [metadata].
  LogDocument({
    final List<LogNode>? nodes,
    final Map<String, Object?>? metadata,
  })  : nodes = nodes ?? [],
        metadata = metadata ?? {};

  /// Named constructor for arena pool allocation.
  /// Creates an empty, uninitialized instance for recycling.
  LogDocument._pooled()
      : nodes = [],
        metadata = {};

  /// The root nodes of the document tree.
  List<LogNode> nodes;

  /// Arbitrary metadata associated with the document.
  Map<String, Object?> metadata;

  /// Resets this document to an empty state so it can be reused.
  ///
  /// **Warning**: This does NOT recursively release child nodes.
  /// Call [releaseRecursive] to return the entire tree to the pool.
  void reset() {
    nodes.clear();
    metadata.clear();
  }

  /// Recursively releases this document and all its nodes back to [arena].
  ///
  /// After calling this method, neither this document nor any of its nodes
  /// may be used again until checked out from the arena.
  void releaseRecursive(final LogArena arena) {
    for (final node in nodes) {
      node.releaseRecursive(arena);
    }
    arena.release(this);
  }

  /// Creates a copy of this document with optional changes.
  ///
  /// Note: Returns a fresh heap-allocated document, not an arena checkout.
  /// Use within the same pipeline cycle only.
  LogDocument copyWith({
    final List<LogNode>? nodes,
    final Map<String, Object?>? metadata,
  }) =>
      LogDocument(
        nodes: nodes ?? List<LogNode>.from(this.nodes),
        metadata: metadata ?? Map<String, Object?>.from(this.metadata),
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

  /// Releases this node and any children back to [arena].
  void releaseRecursive(final LogArena arena);
}
