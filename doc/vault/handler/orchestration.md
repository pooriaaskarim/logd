# Handler Orchestration

The `logd` handler architecture is built for extreme efficiency by internalizing the complex "mechanical" logic of log processing. This ensures that formatters and decorators remain simple, while the core system guarantees memory safety and high throughput.

## 1. Lifecycle & Memory Strategy

The `LogEngine` is the authoritative orchestrator of the processing cycle. It manages the **LogPipelineFactory** (e.g., `Arena`) to ensure memory safety and high throughput.

- **Deterministic Pipeline**: The engine coordinates the flow from `LogFormatter` through the `DecoratorPipeline`.
- **Resource Management**: It handles the `checkout` and `release` of [LogDocument]s. The `ArenaEngine` implementation specifically ensures that the entire layout tree is returned to the pool via a recursive release, neutralizing GC pressure.

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
| **Checkout** | `LogEngine` | `factory.checkoutDocument()` | Semantic IR initialized |
| **Format** | `LogFormatter` | `format(entry, doc, factory)`| Content nodes added |
| **Decorate**| `LogDecorator` | `apply(doc, entry, factory)`| Layout/Style modified |
| **Encode** | `LogEncoder` | `encode(entry, doc, factory)`| Bytes written to buffer |
| **Sink** | `LogSink` | `output(doc, entry, factory)`| Data persisted |
| **Release** | `LogEngine` | `doc.releaseRecursive(factory)`| Tree returned to pool |
