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

  // --- Native Memory Pool (B-IR Dispatch) ---
  final List<_NativeBuffer> _freeNativeBuffers = [];
  final Map<int, _NativeBuffer> _inFlightNativeBuffers = {};
  late final ReceivePort _completionPort = ReceivePort()
    ..listen(_handlePacketCompletion);

  static const _defaultPacketSize = 64 * 1024; // 64KB

  _NativeBuffer? _currentBuffer;
  int _totalAllocatedBytes = 0;

  /// The maximum number of native packets allowed to be in-flight before
  /// the main thread blocks (backpressure).
  static const int maxInFlightPackets = 200;

  bool _saturationWarningFired = false;

  /// The maximum total native memory (in bytes) the arena can allocate.
  static const int maxNativeMemory = 16 * 1024 * 1024; // 16MB

  Completer<void>? _poolCapacityWaiter;

  void _handlePacketCompletion(final dynamic address) {
    if (address is int) {
      final buffer = _inFlightNativeBuffers.remove(address);
      if (buffer != null) {
        buffer.offset = 0;
        _freeNativeBuffers.add(buffer);

        // Notify waiters that capacity is available (with hysteresis)
        if (_inFlightNativeBuffers.length < (maxInFlightPackets * 0.8).toInt()) {
          _saturationWarningFired = false;
        }

        if (_poolCapacityWaiter != null && !_poolCapacityWaiter!.isCompleted) {
          _poolCapacityWaiter!.complete();
          _poolCapacityWaiter = null;
        }
      }
    }
  }

  /// Waits until the pool has capacity to accept new native packets.
  Future<void> waitForPoolCapacity() async {
    while (_inFlightNativeBuffers.length >= maxInFlightPackets) {
      _poolCapacityWaiter ??= Completer<void>();
      await _poolCapacityWaiter!.future;
    }
  }

  /// Returns the offset into the current native buffer.
  int get nativeOffset => _currentBuffer?.offset ?? 0;

  /// Returns the completion port used for cross-isolate packet recycling.
  SendPort get completionPort => _completionPort.sendPort;

  /// Resets the native buffer for a new log cycle.
  ///
  /// If [releaseToPool] is true, the buffer is marked as free.
  void resetNative({final bool releaseToPool = false}) {
    if (_currentBuffer != null) {
      if (releaseToPool) {
        _currentBuffer!.offset = 0;
        _freeNativeBuffers.add(_currentBuffer!);
        _currentBuffer = null;
      } else {
        _currentBuffer!.offset = 0;
      }
    }
  }

  /// Checks out a [NativePacket] containing the current buffer's data.
  ///
  /// The buffer is moved to the "In-Flight" state and will be recycled
  /// when the background isolate sends its address to the [completionPort].
  NativePacket checkoutNativePacket({required final int terminalWidth}) {
    final buffer = _currentBuffer;
    if (buffer == null || buffer.offset == 0) {
      throw StateError('No native data to dispatch');
    }

    _inFlightNativeBuffers[buffer.pointer.address] = buffer;
    _currentBuffer = null;

    // Log a warning if pool is saturated (blocking happens in NativeEngine)
    if (_inFlightNativeBuffers.length >= maxInFlightPackets &&
        !_saturationWarningFired) {
      _saturationWarningFired = true;
      InternalLogger.log(
        LogLevel.warning,
        'Arena saturation reached (${_inFlightNativeBuffers.length} packets). Blocking main thread.',
      );
    }

    return NativePacket(
      address: buffer.pointer.address,
      length: buffer.offset,
      terminalWidth: terminalWidth,
      completionPort: _completionPort.sendPort,
    );
  }

  /// Reclaims all in-flight buffers back to the free pool.
  ///
  /// This should be called if the background worker isolate fails or
  /// is shut down abruptly to prevent native memory leaks.
  void reclaimInFlightBuffers() {
    for (final buffer in _inFlightNativeBuffers.values) {
      buffer.offset = 0;
      _freeNativeBuffers.add(buffer);
    }
    _inFlightNativeBuffers.clear();

    // Release any blocked threads
    if (_poolCapacityWaiter != null && !_poolCapacityWaiter!.isCompleted) {
      _poolCapacityWaiter!.complete();
      _poolCapacityWaiter = null;
    }
  }

  /// Allocates [size] bytes from the native arena.
  ffi.Pointer<ffi.Uint8> allocateNative(final int size) {
    if (_currentBuffer == null ||
        _currentBuffer!.offset + size > _currentBuffer!.size) {
      _checkoutNewBuffer(max(_defaultPacketSize, size));
    }

    final ptr = _currentBuffer!.pointer + _currentBuffer!.offset;
    _currentBuffer!.offset += size;
    return ptr.cast();
  }

  void _checkoutNewBuffer(final int size) {
    // 1. Try to find a free buffer that is large enough
    for (int i = 0; i < _freeNativeBuffers.length; i++) {
      if (_freeNativeBuffers[i].size >= size) {
        _currentBuffer = _freeNativeBuffers.removeAt(i);
        return;
      }
    }

    // 2. Allocate a new one if none available
    if (_totalAllocatedBytes + size > maxNativeMemory) {
      throw const OutOfMemoryError();
    }

    final pointer = pkg_ffi.malloc.allocate<ffi.Uint8>(size);
    _totalAllocatedBytes += size;
    _currentBuffer = _NativeBuffer(pointer, size);
  }

  // ---------------------------------------------------------------------------
  // Checkout helpers — pop from pool or allocate a fresh instance.
  // ---------------------------------------------------------------------------

  /// Checks out a [LogDocument] from the pool, or allocates a fresh one.
  @override
  LogDocument checkoutDocument() =>
      _documents.isNotEmpty ? _documents.removeLast() : ArenaDocument(this);

  /// Completely clears all object pools and reclaims all native memory.
  ///
  /// This is primarily used in benchmarks to ensure a clean state between
  /// different engine configurations.
  @internal
  void clear() {
    _documents.clear();
    _headers.clear();
    _messages.clear();
    _errors.clear();
    _footers.clear();
    _metadataNodes.clear();
    _boxes.clear();
    _indents.clear();
    _groups.clear();
    _decorated.clear();
    _paragraphs.clear();
    _rows.clear();
    _sections.clear();
    _fillers.clear();
    _maps.clear();
    _lists.clear();
    _contexts.clear();
    _physicalLines.clear();
    _physicalDocuments.clear();

    reclaimInFlightBuffers();
    for (final buffer in _freeNativeBuffers) {
      pkg_ffi.malloc.free(buffer.pointer);
    }
    _freeNativeBuffers.clear();
    _currentBuffer = null;
    _totalAllocatedBytes = 0;
  }

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
    _completionPort.close();

    if (_currentBuffer != null) {
      pkg_ffi.malloc.free(_currentBuffer!.pointer);
      _currentBuffer = null;
    }

    for (final buffer in _freeNativeBuffers) {
      pkg_ffi.malloc.free(buffer.pointer);
    }
    _freeNativeBuffers.clear();

    for (final buffer in _inFlightNativeBuffers.values) {
      pkg_ffi.malloc.free(buffer.pointer);
    }
    _inFlightNativeBuffers.clear();
  }
}

class _NativeBuffer {
  _NativeBuffer(this.pointer, this.size);
  final ffi.Pointer<ffi.Uint8> pointer;
  final int size;
  int offset = 0;
}

/// A specialized [LogDocument] for use within an [Arena].
///
/// [ArenaDocument] supports a **Hybrid Execution Mode**:
/// 1. **Streaming Mode**: Writes directly to the native Binary IR buffer.
///    This mode provides maximum performance (20x boost) but bypasses
///    structural decorators that rely on tree traversal.
/// 2. **Object Mode**: Behaves like a [StandardDocument], creating poolable
///    nodes. This mode is used when decorators are present.
class ArenaDocument extends StandardDocument {
  ArenaDocument(this.arena) : super._pooled();

  /// The arena that owns this document.
  final Arena arena;

  /// The writer used for streaming Binary IR.
  late final BinaryIRWriter writer = BinaryIRWriter(arena);

  bool _isStreaming = false;

  /// Returns whether this document is currently in streaming mode.
  bool get isStreaming => _isStreaming;

  /// Enables high-performance streaming mode.
  void enableStreaming() {
    _isStreaming = true;
    writer
      ..start()
      ..writeDocumentMetadata(metadata);
  }

  @override
  void reset() {
    super.reset();
    _isStreaming = false;
  }

  @override
  void text(
    final String text, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    if (_isStreaming) {
      writer.writeText(text, style: style, tags: tags);
    } else {
      super.text(text, style: style, tags: tags, factory: factory ?? arena);
    }
  }

  @override
  void startBox({
    final BoxBorderStyle border = BoxBorderStyle.rounded,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    if (_isStreaming) {
      writer.writeBoxStart(border: border, tags: tags);
    } else {
      super.startBox(border: border, tags: tags, factory: factory ?? arena);
    }
  }

  @override
  void endBox() {
    if (_isStreaming) {
      writer.writeBoxEnd();
    } else {
      super.endBox();
    }
  }

  @override
  void startIndent(
    final String indent, {
    final LogStyle? style,
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    if (_isStreaming) {
      writer.writeIndentStart(indent, style: style, tags: tags);
    } else {
      super.startIndent(
        indent,
        style: style,
        tags: tags,
        factory: factory ?? arena,
      );
    }
  }

  @override
  void endIndent() {
    if (_isStreaming) {
      writer.writeIndentEnd();
    } else {
      super.endIndent();
    }
  }

  @override
  void metadataBlock(
    final Map<String, Object?> data, {
    final int tags = LogTag.none,
    final LogPipelineFactory? factory,
  }) {
    if (_isStreaming) {
      writer.writeMap(data, tags: tags);
    } else {
      super.metadataBlock(data, tags: tags, factory: factory ?? arena);
    }
  }

  @override
  void writeNode(final LogNode node) {
    if (_isStreaming) {
      writer.writeNode(node);
    } else {
      super.writeNode(node);
    }
  }
}
