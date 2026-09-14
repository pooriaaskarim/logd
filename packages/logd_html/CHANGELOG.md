## 0.1.0

- **Initial Stable Release:** Promoted `logd_html` to a mature, standalone satellite package.
- **Serialization Safety:** Implemented `HtmlFormatter` to inject `HtmlEncoder` dynamically via `AutoEncoder.encoderKey` metadata. This prevents cross-isolate crashes and ensures `HtmlFileHandler.async()` works correctly on background isolates.
- **Isolate Registry:** Added `registerLogdHtmlSerializers()` to correctly register `HtmlFormatter` during isolate bootstrap.
- **Documentation:** Added `architecture.md`, `benchmarks.md`, and `migration_guide.md` covering the transition from the deprecated `logd` v0.9.7 core shims.
- **Examples:** Included standard examples (`example/main.dart`) alongside advanced patterns (`example/extra/`) for custom stylesheets and file rotation.
