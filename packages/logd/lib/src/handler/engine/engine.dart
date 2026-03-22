part of '../handler.dart';

/// The orchestration layer for the logging pipeline.
///
/// A [LogEngine] is responsible for the end-to-end execution of a [LogEntry]
/// processing cycle. It manages the lifecycle of the [LogDocument] intermediate
/// representation, including its allocation, transformation, and emission.
abstract interface class LogEngine {
  /// The factory/allocator used by this engine for pipeline resources.
  LogPipelineFactory get factory;

  /// Executes the pipeline for a single [LogEntry].
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  );
}

/// An abstraction for log resource allocation and management.
///
/// This interface decouples semantic transformation logic ([LogFormatter],
/// [LogDecorator]) from mechanical resource management. It provides a
/// unified protocol for obtaining nodes and buffers, allowing components to
/// remain agnostic of the underlying allocation strategy (e.g., heap vs. pool).
abstract interface class LogPipelineFactory {
  /// Checks out a [LogDocument] from the pool, or allocates a fresh one.
  LogDocument checkoutDocument();

  /// Checks out a [HeaderNode] from the pool, or allocates a fresh one.
  HeaderNode checkoutHeader();

  /// Checks out a [MessageNode] from the pool, or allocates a fresh one.
  MessageNode checkoutMessage();

  /// Checks out an [ErrorNode] from the pool, or allocates a fresh one.
  ErrorNode checkoutError();

  /// Checks out a [FooterNode] from the pool, or allocates a fresh one.
  FooterNode checkoutFooter();

  /// Checks out a [MetadataNode] from the pool, or allocates a fresh one.
  MetadataNode checkoutMetadata();

  /// Checks out a [BoxNode] from the pool, or allocates a fresh one.
  BoxNode checkoutBox();

  /// Checks out an [IndentationNode] from the pool, or allocates a fresh one.
  IndentationNode checkoutIndentation();

  /// Checks out a [GroupNode] from the pool, or allocates a fresh one.
  GroupNode checkoutGroup();

  /// Checks out a [DecoratedNode] from the pool, or allocates a fresh one.
  DecoratedNode checkoutDecorated();

  /// Checks out a [ParagraphNode] from the pool, or allocates a fresh one.
  ParagraphNode checkoutParagraph();

  /// Checks out a [RowNode] from the pool, or allocates a fresh one.
  RowNode checkoutRow();

  /// Checks out a [SectionNode] from the pool, or allocates a fresh one.
  SectionNode checkoutSection();

  /// Checks out a [FillerNode] from the pool, or allocates a fresh one.
  FillerNode checkoutFiller();

  /// Checks out a [MapNode] from the pool, or allocates a fresh one.
  MapNode checkoutMap();

  /// Checks out a [ListNode] from the pool, or allocates a fresh one.
  ListNode checkoutList();

  /// Checks out a [HandlerContext] from the pool, or allocates a fresh one.
  HandlerContext checkoutContext();

  /// Checks out a [PhysicalDocument] from the pool, or allocates a fresh one.
  PhysicalDocument checkoutPhysicalDocument();

  /// Checks out a [PhysicalLine] from the pool, or allocates a fresh one.
  PhysicalLine checkoutPhysicalLine();

  /// Releases [obj] back to the pool after resetting its state.
  ///
  /// This may be a no-op for non-pooling factories.
  void release(final Object obj);
}
