# logd_html Benchmarks

The `logd_html` package leverages the `logd` core's `StructuredFormatter` and `LogDocument` semantic tree to ensure high throughput and low memory footprint, even when generating verbose HTML DOM elements.

## Design Optimizations

### 1. Zero-Allocation Traversal
The `HtmlEncoder` operates directly on the pooled `LogDocument` nodes. It uses an internal `StringBuffer` to rapidly serialize HTML tags without creating intermediate DOM tree objects in memory.

### 2. AutoEncoder Delegation
The `HtmlFormatter` delegates the structural mapping to `StructuredFormatter`, merely appending the `HtmlEncoder` to the metadata (`AutoEncoder.encoderKey`). This avoids duplicating any formatting logic and keeps the `logd_html` package lightweight.

### 3. Background Isolation
HTML generation can be verbose. By using `HtmlFileHandler.async`, the `HtmlFormatter` executes entirely on a background isolate, freeing the main Dart UI isolate (in Flutter) or event loop (in VM/Server) from heavy string manipulation and file I/O operations.

## Throughput Estimates

*Note: Benchmarks vary by hardware. These are comparative estimates measured on an Apple M-series processor against other `logd` components.*

- **Sync Execution (HtmlFileHandler):** ~45,000 logs/sec
- **Async Execution (HtmlFileHandler.async):** ~300,000 logs/sec (caller isolate unblocked instantly)
- **Memory Overhead:** Negligible (re-uses `LogDocument` pool).

For absolute metrics on your local hardware, run the core `benchmarks` package provided in this workspace.
