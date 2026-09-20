# logd_markdown Architecture

`logd_markdown` provides GitHub-Flavored Markdown (GFM) log rendering for the `logd` logging ecosystem.

## Core Concepts

### 1. `MarkdownEncoder`
The `MarkdownEncoder` transforms the `LogDocument` semantic tree into valid GFM markup:
- `HeaderNode`: Renders level emojis (`### 🐛 INFO`, `### ❌ ERROR`) and bullet-separated headers.
- `MessageNode`: Renders bold message body.
- `ErrorNode`: Renders GFM alerts (`> [!ERROR]`).
- `LogTag.stackFrame`: Renders fenced code blocks (```).

### 2. `MarkdownFormatter`
The `MarkdownFormatter` orchestrates the conversion. It delegates structural mapping to `StructuredFormatter`, then injects `MarkdownEncoder` into `document.metadata[AutoEncoder.encoderKey]`. This allows agnostic sinks like `FileSink(encoder: AutoTextEncoder())` to automatically discover and use `MarkdownEncoder`.

### 3. `MarkdownFileHandler`
A pre-wired `Handler` combining `MarkdownFormatter` and `FileSink`.
- `MarkdownFileHandler(path: ...)`: Synchronous log writing.
- `MarkdownFileHandler.async(path: ...)`: Background isolate log writing.
