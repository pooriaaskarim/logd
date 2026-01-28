# Migration Guide

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
