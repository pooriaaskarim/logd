# Handler Orchestration

The `logd` handler architecture is built for extreme efficiency by internalizing the complex "mechanical" logic of log processing. This ensures that formatters and decorators remain simple, while the core system guarantees memory safety and high throughput.

## 1. Lifecycle & Memory Safety

The `Handler` is the sole manager of the `LogArena` lifecycle. This centralized control prevents memory leaks and ensures that all components operate within the same pooled context.

- **Deterministic Release**: `Handler.log` uses a `try-finally` pattern to ensure that the `LogDocument` IR is always returned to the arena, even if a formatter or sink fails.
- **Node Recycling**: By managing the arena at the handler level, we ensure that specialized nodes (`BoxNode`, `FillerNode`) are reused across millions of log cycles without triggering GC.

## 2. In-place Mutation (Semantic Boundary)

The semantic pipeline operates via **directed mutation** rather than conversion. 

- **Formatter**: Populates the `LogDocument` with semantic structures (Rows, Paragraphs, Heads).
- **Decorators**: Modify the existing IR in-place (e.g., adding a `BoxNode` wrapper or a `PrefixNode`).

This in-place approach eliminates the need for returning new document objects, keeping the stack shallow and the heap clean.

## 3. Byte-Oriented Emission (Physical Boundary)

The final stage of the pipeline translates the semantic IR into physical bytes via a `LogEncoder`.

- **HandlerContext**: A byte-level abstraction that avoids `String` concatenation. Encoders write UTF-8 bytes directly into this context.
- **Standardized Delimiting**: The `EncodingSink` (base class for Console/File/Network) handles the final record-level separator (`\n`). This ensures that encoders remain "content-only" and that concurrency-safe sinks like `FileSink` can write atomic, properly-delimited records.

## Summary

| Phase | Component | Action | Result |
|---|---|---|---|
| **Checkout** | `Handler` | `arena.checkoutDocument()` | Semantic IR initialized |
| **Format** | `LogFormatter` | `format(entry, doc)` | Content nodes added |
| **Decorate**| `LogDecorator` | `decorate(doc)` | Layout/Style modified |
| **Encode** | `LogEncoder` | `encode(entry, doc, ctx)`| Bytes written to buffer |
| **Sink** | `EncodingSink` | `output(bytes + "\n")` | Data persisted |
| **Release** | `Handler` | `doc.releaseRecursive()` | Tree returned to pool |
