## 0.1.0

- **Initial Stable Release:** Promoted `logd_markdown` to a mature, standalone satellite package.
- **Serialization Safety:** Implemented `MarkdownFormatter` to inject `MarkdownEncoder` dynamically via `AutoEncoder.encoderKey` metadata. This prevents cross-isolate crashes and ensures `MarkdownFileHandler.async()` works correctly on background isolates.
- **Isolate Registry:** Added `registerLogdMarkdownSerializers()` to correctly register `MarkdownFormatter` and `MarkdownEncoder` during isolate bootstrap.
- **Documentation:** Added `architecture.md`, `benchmarks.md`, and `migration_guide.md` covering the transition from deprecated `logd` v0.9.7 core shims.
- **Examples:** Included standard examples (`example/main.dart`) alongside file rotation examples (`example/extra/file_rotation_example.dart`).
