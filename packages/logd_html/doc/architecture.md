# logd_html Architecture

`logd_html` provides browser-friendly log rendering for the `logd` ecosystem, allowing users to view structured logs, metrics, and errors in a highly readable HTML format.

## Core Concepts

### 1. `HtmlEncoder`
The `HtmlEncoder` is responsible for rendering the `LogDocument` semantic tree into valid HTML5 markup. It applies CSS classes based on `LogTag` classifications (e.g., `.logd-level-info`, `.logd-error-text`).

### 2. `HtmlFormatter`
The `HtmlFormatter` orchestrates the conversion. It relies on the core `StructuredFormatter` to break down the `LogEntry` into a `LogDocument`, and then injects the `HtmlEncoder` into the document's metadata (`AutoEncoder.encoderKey`).

This injection allows agnostic sinks like `FileSink(encoder: AutoTextEncoder())` to automatically discover and use the `HtmlEncoder` when rendering the final bytes.

### 3. `HtmlFileHandler`
A convenience wrapper combining `HtmlFormatter` and `FileSink`. It simplifies setting up an HTML log file and gracefully supports background isolate execution (`HtmlFileHandler.async`), ensuring the `HtmlEncoder` survives cross-isolate serialization seamlessly.

### 4. `HtmlStylesheet`
Injects CSS and JS during the `HtmlEncoder.preamble` phase. `DefaultHtmlStylesheet` provides a dark-mode optimized aesthetic with responsive tables and collapsible stack traces. Custom implementations can override the stylesheet to apply proprietary branding.
