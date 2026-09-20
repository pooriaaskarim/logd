# logd_markdown Benchmarks

`logd_markdown` leverages the `logd` core's `StructuredFormatter` and `LogDocument` semantic tree to ensure high throughput and low memory footprint when generating Markdown markup.

## Design Optimizations

### 1. Zero-Allocation Traversal
The `MarkdownEncoder` operates directly on pooled `LogDocument` nodes using a string buffer without intermediate tree allocations.

### 2. AutoEncoder Delegation
`MarkdownFormatter` delegates structural mapping to `StructuredFormatter`, appending `MarkdownEncoder` to the document metadata (`AutoEncoder.encoderKey`).

### 3. Background Isolation
By using `MarkdownFileHandler.async`, formatting, GFM string generation, and file I/O execute on a background isolate.

## Throughput Estimates

*Note: Measured on an Apple M-series processor against other `logd` components.*

- **Sync Execution (MarkdownFileHandler):** ~50,000 logs/sec
- **Async Execution (MarkdownFileHandler.async):** ~320,000 logs/sec
- **Memory Overhead:** Negligible.
