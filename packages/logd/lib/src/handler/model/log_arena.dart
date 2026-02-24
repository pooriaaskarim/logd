part of '../handler.dart';

/// An isolate-local LIFO object pool for the log pipeline.
///
/// [LogArena] eliminates heap churn during steady-state logging by
/// reusing [LogDocument] and [LogNode] instances across log cycles.
///
/// **Lifecycle contract**:
/// 1. **Checkout**: Call `checkout*()` to obtain a recycled (or fresh) object.
/// 2. **Populate**: Set the object's fields as needed.
/// 3. **Process**: Pass the document through the full pipeline
///    (formatter → decorators → sink).
/// 4. **Release**: Call `document.releaseRecursive(arena)` after the sink
///    completes. This recursively returns the entire tree to the pool.
///
/// **Safety invariants**:
/// - Arena-owned documents and nodes **must never** be retained across log
///   cycles (no caching, no storing in long-lived state).
/// - Only the [Handler] orchestrates checkout/release; formatters and
///   decorators receive the arena only to create new nodes.
/// - This class is **not** thread-safe. Isolate isolation is the safety
///   boundary.
class LogArena {
  // Private constructor; use [instance] for isolate-local access.
  LogArena._();

  /// The isolate-local singleton arena.
  static final LogArena instance = LogArena._();

  // ---------------------------------------------------------------------------
  // LIFO pools — one list per concrete node type.
  // ---------------------------------------------------------------------------
  final List<LogDocument> _documents = [];
  final List<HeaderNode> _headers = [];
  final List<MessageNode> _messages = [];
  final List<ErrorNode> _errors = [];
  final List<FooterNode> _footers = [];
  final List<MetadataNode> _metadataNodes = [];
  final List<BoxNode> _boxes = [];
  final List<IndentationNode> _indents = [];
  final List<GroupNode> _groups = [];
  final List<DecoratedNode> _decorated = [];
  final List<ParagraphNode> _paragraphs = [];
  final List<RowNode> _rows = [];
  final List<FillerNode> _fillers = [];
  final List<MapNode> _maps = [];
  final List<ListNode> _lists = [];

  // ---------------------------------------------------------------------------
  // Checkout helpers — pop from pool or allocate a fresh instance.
  // ---------------------------------------------------------------------------

  /// Checks out a [LogDocument] from the pool, or allocates a fresh one.
  LogDocument checkoutDocument() =>
      _documents.isNotEmpty ? _documents.removeLast() : LogDocument._pooled();

  /// Checks out a [HeaderNode] from the pool, or allocates a fresh one.
  HeaderNode checkoutHeader() =>
      _headers.isNotEmpty ? _headers.removeLast() : HeaderNode._pooled();

  /// Checks out a [MessageNode] from the pool, or allocates a fresh one.
  MessageNode checkoutMessage() =>
      _messages.isNotEmpty ? _messages.removeLast() : MessageNode._pooled();

  /// Checks out an [ErrorNode] from the pool, or allocates a fresh one.
  ErrorNode checkoutError() =>
      _errors.isNotEmpty ? _errors.removeLast() : ErrorNode._pooled();

  /// Checks out a [FooterNode] from the pool, or allocates a fresh one.
  FooterNode checkoutFooter() =>
      _footers.isNotEmpty ? _footers.removeLast() : FooterNode._pooled();

  /// Checks out a [MetadataNode] from the pool, or allocates a fresh one.
  MetadataNode checkoutMetadata() => _metadataNodes.isNotEmpty
      ? _metadataNodes.removeLast()
      : MetadataNode._pooled();

  /// Checks out a [BoxNode] from the pool, or allocates a fresh one.
  BoxNode checkoutBox() =>
      _boxes.isNotEmpty ? _boxes.removeLast() : BoxNode._pooled();

  /// Checks out an [IndentationNode] from the pool, or allocates a fresh one.
  IndentationNode checkoutIndentation() =>
      _indents.isNotEmpty ? _indents.removeLast() : IndentationNode._pooled();

  /// Checks out a [GroupNode] from the pool, or allocates a fresh one.
  GroupNode checkoutGroup() =>
      _groups.isNotEmpty ? _groups.removeLast() : GroupNode._pooled();

  /// Checks out a [DecoratedNode] from the pool, or allocates a fresh one.
  DecoratedNode checkoutDecorated() =>
      _decorated.isNotEmpty ? _decorated.removeLast() : DecoratedNode._pooled();

  /// Checks out a [ParagraphNode] from the pool, or allocates a fresh one.
  ParagraphNode checkoutParagraph() => _paragraphs.isNotEmpty
      ? _paragraphs.removeLast()
      : ParagraphNode._pooled();

  /// Checks out a [RowNode] from the pool, or allocates a fresh one.
  RowNode checkoutRow() =>
      _rows.isNotEmpty ? _rows.removeLast() : RowNode._pooled();

  /// Checks out a [FillerNode] from the pool, or allocates a fresh one.
  FillerNode checkoutFiller() =>
      _fillers.isNotEmpty ? _fillers.removeLast() : FillerNode._pooled();

  /// Checks out a [MapNode] from the pool, or allocates a fresh one.
  MapNode checkoutMap() =>
      _maps.isNotEmpty ? _maps.removeLast() : MapNode._pooled();

  /// Checks out a [ListNode] from the pool, or allocates a fresh one.
  ListNode checkoutList() =>
      _lists.isNotEmpty ? _lists.removeLast() : ListNode._pooled();

  // ---------------------------------------------------------------------------
  // Release — reset and push back onto the pool.
  // ---------------------------------------------------------------------------

  /// Releases [obj] back to the pool after resetting its state.
  ///
  /// [obj] may be a [LogDocument] or any [LogNode] subclass.
  /// Prefer calling [LogDocument.releaseRecursive] to release an entire tree
  /// rather than releasing individual nodes manually.
  void release(final Object obj) {
    switch (obj) {
      case final LogDocument d:
        d.reset();
        _documents.add(d);
      case final HeaderNode n:
        n.reset();
        _headers.add(n);
      case final MessageNode n:
        n.reset();
        _messages.add(n);
      case final ErrorNode n:
        n.reset();
        _errors.add(n);
      case final FooterNode n:
        n.reset();
        _footers.add(n);
      case final MetadataNode n:
        n.reset();
        _metadataNodes.add(n);
      case final BoxNode n:
        n.reset();
        _boxes.add(n);
      case final IndentationNode n:
        n.reset();
        _indents.add(n);
      case final GroupNode n:
        n.reset();
        _groups.add(n);
      case final DecoratedNode n:
        n.reset();
        _decorated.add(n);
      case final ParagraphNode n:
        n.reset();
        _paragraphs.add(n);
      case final RowNode n:
        n.reset();
        _rows.add(n);
      case final FillerNode n:
        n.reset();
        _fillers.add(n);
      case final MapNode n:
        n.reset();
        _maps.add(n);
      case final ListNode n:
        n.reset();
        _lists.add(n);
    }
  }

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  /// Returns the total number of objects currently cached across all pools.
  int get poolSize =>
      _documents.length +
      _headers.length +
      _messages.length +
      _errors.length +
      _footers.length +
      _metadataNodes.length +
      _boxes.length +
      _indents.length +
      _groups.length +
      _decorated.length +
      _paragraphs.length +
      _rows.length +
      _fillers.length +
      _maps.length +
      _lists.length;
}
