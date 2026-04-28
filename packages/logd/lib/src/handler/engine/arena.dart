part of '../handler.dart';

/// An isolate-local resource pool for deterministic object reuse.
///
/// [Arena] provides a LIFO-based pooling mechanism to eliminate allocation
/// overhead and garbage collection (GC) churn during steady-state logging.
///
/// **Lifecycle contract**:
/// 1. **Checkout**: Obtain a recycled or fresh instance via `checkout*()`.
/// 2. **Population**: Initialize the object's state using the provided data.
/// 3. **Execution**: Process the document through the configured pipeline.
/// 4. **Release**: Invoke `document.releaseRecursive(arena)` to return the
///    entire object graph to the pool for subsequent reuse.
///
/// **Safety invariants**:
/// - Arena-owned documents and nodes **must never** be retained across log
///   cycles (no caching, no storing in long-lived state).
/// - Only the [Handler] orchestrates checkout/release; formatters and
///   decorators receive the arena only to create new nodes.
/// - This class is **not** thread-safe. Isolate isolation is the safety
///   boundary.
class Arena implements LogPipelineFactory {
  // Private constructor; use [instance] for isolate-local access.
  Arena._();

  /// The isolate-local singleton arena.
  static final Arena instance = Arena._();

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
  final List<SectionNode> _sections = [];
  final List<FillerNode> _fillers = [];
  final List<MapNode> _maps = [];
  final List<ListNode> _lists = [];
  final List<HandlerContext> _contexts = [];
  final List<PhysicalLine> _physicalLines = [];
  final List<PhysicalDocument> _physicalDocuments = [];

  // --- Native Memory (B-IR) ---
  ffi.Pointer<ffi.Uint8> _nativeBuffer = ffi.Pointer.fromAddress(0);
  int _nativeBufferSize = 0;
  int _nativeBufferOffset = 0;

  /// Returns the offset into the current native buffer.
  int get nativeOffset => _nativeBufferOffset;

  /// Resets the native buffer for a new log cycle.
  void resetNative() {
    _nativeBufferOffset = 0;
  }

  /// Allocates [size] bytes from the native arena.
  ffi.Pointer<ffi.Uint8> allocateNative(final int size) {
    if (_nativeBuffer == ffi.Pointer.fromAddress(0) ||
        _nativeBufferOffset + size > _nativeBufferSize) {
      _reallocateNative(max(_nativeBufferSize * 2, size + 1024));
    }

    final ptr = _nativeBuffer.elementAt(_nativeBufferOffset);
    _nativeBufferOffset += size;
    return ptr.cast();
  }

  void _reallocateNative(final int newSize) {
    if (_nativeBuffer != ffi.Pointer.fromAddress(0)) {
      pkg_ffi.malloc.free(_nativeBuffer);
    }
    _nativeBuffer = pkg_ffi.malloc.allocate<ffi.Uint8>(newSize);
    _nativeBufferSize = newSize;
    _nativeBufferOffset = 0;
  }

  // ---------------------------------------------------------------------------
  // Checkout helpers — pop from pool or allocate a fresh instance.
  // ---------------------------------------------------------------------------

  /// Checks out a [LogDocument] from the pool, or allocates a fresh one.
  @override
  LogDocument checkoutDocument() =>
      _documents.isNotEmpty ? _documents.removeLast() : LogDocument._pooled();

  /// Checks out a [HeaderNode] from the pool, or allocates a fresh one.
  @override
  HeaderNode checkoutHeader() =>
      _headers.isNotEmpty ? _headers.removeLast() : HeaderNode._pooled();

  /// Checks out a [MessageNode] from the pool, or allocates a fresh one.
  @override
  MessageNode checkoutMessage() =>
      _messages.isNotEmpty ? _messages.removeLast() : MessageNode._pooled();

  /// Checks out an [ErrorNode] from the pool, or allocates a fresh one.
  @override
  ErrorNode checkoutError() =>
      _errors.isNotEmpty ? _errors.removeLast() : ErrorNode._pooled();

  /// Checks out a [FooterNode] from the pool, or allocates a fresh one.
  @override
  FooterNode checkoutFooter() =>
      _footers.isNotEmpty ? _footers.removeLast() : FooterNode._pooled();

  /// Checks out a [MetadataNode] from the pool, or allocates a fresh one.
  @override
  MetadataNode checkoutMetadata() => _metadataNodes.isNotEmpty
      ? _metadataNodes.removeLast()
      : MetadataNode._pooled();

  /// Checks out a [BoxNode] from the pool, or allocates a fresh one.
  @override
  BoxNode checkoutBox() =>
      _boxes.isNotEmpty ? _boxes.removeLast() : BoxNode._pooled();

  /// Checks out an [IndentationNode] from the pool, or allocates a fresh one.
  @override
  IndentationNode checkoutIndentation() =>
      _indents.isNotEmpty ? _indents.removeLast() : IndentationNode._pooled();

  /// Checks out a [GroupNode] from the pool, or allocates a fresh one.
  @override
  GroupNode checkoutGroup() =>
      _groups.isNotEmpty ? _groups.removeLast() : GroupNode._pooled();

  /// Checks out a [DecoratedNode] from the pool, or allocates a fresh one.
  @override
  DecoratedNode checkoutDecorated() =>
      _decorated.isNotEmpty ? _decorated.removeLast() : DecoratedNode._pooled();

  /// Checks out a [ParagraphNode] from the pool, or allocates a fresh one.
  @override
  ParagraphNode checkoutParagraph() => _paragraphs.isNotEmpty
      ? _paragraphs.removeLast()
      : ParagraphNode._pooled();

  /// Checks out a [RowNode] from the pool, or allocates a fresh one.
  @override
  RowNode checkoutRow() =>
      _rows.isNotEmpty ? _rows.removeLast() : RowNode._pooled();

  /// Checks out a [SectionNode] from the pool, or allocates a fresh one.
  @override
  SectionNode checkoutSection() =>
      _sections.isNotEmpty ? _sections.removeLast() : SectionNode._pooled();

  /// Checks out a [FillerNode] from the pool, or allocates a fresh one.
  @override
  FillerNode checkoutFiller() =>
      _fillers.isNotEmpty ? _fillers.removeLast() : FillerNode._pooled();

  /// Checks out a [MapNode] from the pool, or allocates a fresh one.
  @override
  MapNode checkoutMap() =>
      _maps.isNotEmpty ? _maps.removeLast() : MapNode._pooled();

  /// Checks out a [ListNode] from the pool, or allocates a fresh one.
  @override
  ListNode checkoutList() =>
      _lists.isNotEmpty ? _lists.removeLast() : ListNode._pooled();

  /// Checks out a [HandlerContext] from the pool, or allocates a fresh one.
  @override
  HandlerContext checkoutContext() =>
      _contexts.isNotEmpty ? _contexts.removeLast() : HandlerContext._pooled();

  /// Checks out a [PhysicalLine] from the pool, or allocates a fresh one.
  @override
  PhysicalLine checkoutPhysicalLine() => _physicalLines.isNotEmpty
      ? _physicalLines.removeLast()
      : PhysicalLine._pooled();

  /// Checks out a [PhysicalDocument] from the pool, or allocates a fresh one.
  @override
  PhysicalDocument checkoutPhysicalDocument() => _physicalDocuments.isNotEmpty
      ? _physicalDocuments.removeLast()
      : PhysicalDocument._pooled();

  // ---------------------------------------------------------------------------
  // Release — reset and push back onto the pool.
  // ---------------------------------------------------------------------------

  /// Releases [obj] back to the pool after resetting its state.
  ///
  /// [obj] may be a [LogDocument] or any [LogNode] subclass.
  /// Prefer calling [LogDocument.releaseRecursive] to release an entire tree
  /// rather than releasing individual nodes manually.
  @override
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
      case final SectionNode n:
        n.reset();
        _sections.add(n);
      case final FillerNode n:
        n.reset();
        _fillers.add(n);
      case final MapNode n:
        n.reset();
        _maps.add(n);
      case final ListNode n:
        n.reset();
        _lists.add(n);
      case final HandlerContext c:
        c.reset();
        _contexts.add(c);
      case final PhysicalLine l:
        l.reset();
        _physicalLines.add(l);
      case final PhysicalDocument d:
        d.reset();
        _physicalDocuments.add(d);
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
      _sections.length +
      _fillers.length +
      _maps.length +
      _lists.length +
      _contexts.length +
      _physicalLines.length +
      _physicalDocuments.length;

  /// Frees all native memory. Should only be called on isolate shutdown.
  void disposeNative() {
    if (_nativeBuffer != ffi.Pointer.fromAddress(0)) {
      pkg_ffi.malloc.free(_nativeBuffer);
      _nativeBuffer = ffi.Pointer.fromAddress(0);
      _nativeBufferSize = 0;
    }
  }
}
