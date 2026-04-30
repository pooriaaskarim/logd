# Migration Guide

## v0.7.1 to v0.8.0 (The High-Performance Engine Milestone)

### 1. `LogDocument` Abstraction (Breaking Change)
**Change**: `LogDocument` has transitioned from a concrete class to an **abstract interface**.
- **Impact**: You can no longer instantiate `LogDocument()` directly.
- **Migration**: 
  - For standard heap-allocated documents, use **`StandardDocument()`**.
  - For pooled documents (recommended), use **`factory.checkoutDocument()`**.
  - **Why?**: This allows the `NativeEngine` and `ArenaEngine` to swap in specialized, high-performance document types (like `ArenaDocument`) without changing your formatting logic.

### 2. `NativeEngine` is now the Default
**Change**: `Handler` now defaults to **`NativeEngine`** (on native platforms).
- **Impact**: Logs are now standardized into a **Binary IR (B-IR)** stream for high-speed delivery.
- **Benefit**: Up to 13x higher throughput out-of-the-box.
- **Note**: The engine automatically falls back to `StandardEngine` if a custom `LogSink` is used that does not support binary streaming.

### 3. Custom `LogNode` Implementation
**Change**: All `LogNode` subclasses must now implement a **`reset()`** method.
- **Impact**: If you have implemented custom node types for specialized renderers, you must add a `reset()` method to support `Arena` object pooling.
- **Reference**: See [content_nodes.dart](../../packages/logd/lib/src/handler/document/content_nodes.dart) for reference implementations.

---

## v0.6.4 to v0.7.0 (Structural Overhaul & Engine API)

### 1. Engine-Driven Orchestration
**Change**: The `Handler` now delegates all execution and lifecycle management to a matching `LogEngine`.
- **Impact**: Users can now explicitly choose their performance strategy (`StandardEngine` vs `ArenaEngine`) in the `Handler` constructor.

### 2. Unified Resource Management
**Change**: Allocation of [LogDocument]s and [LogNode]s is now managed through the `LogPipelineFactory` interface.
- **Benefit**: Decouples semantic generation (formatting) from physical memory management (heap vs pool).

### 3. File Relocation
**Change**: The internal directory structure of the `handler` module has been reorganized for architectural clarity:
- **`document/`**: Semantic Intermediate Representation (IR).
- **`layout/`**: Physical representation and rendering logic.
- **`engine/`**: Orchestration and resource pooling.
- **`decorator/`**: Transformation logic (absorbed the `pipeline/` directory).

---

## v0.6.0 to v0.6.1 (Layout Stability)

### 1. Unified Formatter Configuration
**Breaking**: `LogField` is replaced by `LogMetadata`. All modern formatters now use a unified constructor API.
- **Migration**: Pass `Set<LogMetadata>` (e.g., `{LogMetadata.timestamp}`) to your formatter. Core fields like `level` and `message` are now automatic.

### 2. Implicit Layout Management
**Change**: The `Handler` framework now owns the wrapping logic (Unified Layout Sovereignty).
- **Benefit**: Decorators no longer implement wrapping. They receive lines pre-cut to the available content slot.
- **New API**: Custom structural decorators must implement `paddingWidth` to declare their footprint.

### 3. API Protection
**Breaking**: `Handler.log` and the `LogEntry` constructor are now **`@internal`**.
- **Migration**: Always interface with the system via the `Logger` API (e.g., `logger.info()`).

---

## v0.5.0 to v0.6.0 (Semantic Data)

### 1. Platform-Agnostic Styling
**Change**: `ColorDecorator` is deprecated in favor of `StyleDecorator` and the `LogTheme` system. Styles are now instructions (Bold, Dim) rather than hardcoded ANSI codes.

### 2. Semantic Pipeline
**Change**: The pipeline now passes `Iterable<LogLine>` containing tagged `LogSegment`s.
- **Benefit**: 100% accurate styling of timestamps, levels, and borders without Regex.

---

## 🗺 Breaking Changes Map

| Version | Feature | Technical Impact |
|---|---|---|
| **v0.5.0** | Centralized Layout | `lineLength` moved from formatters to `Handler`. |
| **v0.6.0** | Metadata System | `LogField` → `LogMetadata`. |
| **v0.6.1** | Internal Guards | `Handler.log` and `LogEntry` marked as `@internal`. |
| **v0.6.1** | Unified Layout | Explicit wrapping phase moved to `Handler`. |
| **v0.6.1** | Deprecation | `BoxFormatter` removed; `ColorDecorator` deprecated. |
| **v0.7.0** | Engine API | `LogEngine` and `LogPipelineFactory` become public. `StandardEngine` default. |
| **v0.7.0** | Structural Overhaul| Files moved to `document/`, `layout/`, `engine/`, and `decorator/`. |
