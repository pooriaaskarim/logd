## 0.1.0

- **Initial Stable Release:** Promoted `logd_markdown` to a mature, standalone satellite package.
- **Core Components:** Introduced `MarkdownFormatter`, `MarkdownEncoder`, and `MarkdownFileHandler` for GitHub-Flavored Markdown (GFM) log rendering.
- **Async Isolate Execution (`MarkdownFileHandler.async`)**: Added `MarkdownFileHandler.async()` for non-blocking disk persistence on a background isolate, leveraging direct `@immutable` formatter/decorator transfer in Dart 3.7+.
- **Exhaustive Semantic IR Support:** Encodes all core semantic IR node types (`TableNode`, `CodeBlockNode`, `ListNode`, `BlockquoteNode`, `MapNode`, and `KeyValueNode`) into valid GFM syntax.
- **Encoder Auto-Injection:** Implemented `MarkdownFormatter` to inject `MarkdownEncoder` dynamically via `AutoEncoder.encoderKey` metadata, maintaining clean separation between semantic formatting and physical string layout.
- **Isolate Registry:** Added `registerLogdMarkdownSerializers()` to register `MarkdownFormatter` and `MarkdownEncoder` with `LoggerSerializationRegistry` for configuration import/export.
- **Testing & Regression Safeguards:** Established a golden test harness validating GFM output against baseline files across standard and error payloads.
- **Documentation & Examples:** Added `architecture.md`, `benchmarks.md`, `migration_guide.md`, standard examples (`example/main.dart`), and file rotation patterns (`example/extra/`).
