# Migration Guide

The `logd` library has evolved from a simple logging utility into a high-performance, segment-based pipeline. This guide details the technical "why" behind major architectural shifts and provides a roadmap for modernizing legacy implementations.

---

## 🏗 Architectural Evolution

### 1. Decentralization: From "God Components" to Pipelines
**Problem**: In early versions, `BoxFormatter` handled both layout (fields, wrapping) and framing (ASCII borders). This violated the **Single Responsibility Principle (SRP)**, leading to "Prop Explosion" (dozens of configuration flags) and making it impossible to compose behaviors.

**Modern Fix**: Handlers now utilize a 4-stage pipeline (Filter → Formatter → Decorator → Sink). Responsibilities are strictly decoupled:
- **Layout** is handled by the **Formatter** (e.g., `StructuredFormatter`).
- **Framing** is handled by **Structural Decorators** (e.g., `BoxDecorator`).

**Legacy Pattern (v0.4.x)**:
```dart
final handler = Handler(
  formatter: BoxFormatter(borderStyle: BorderStyle.rounded, lineLength: 80),
  sink: const ConsoleSink(),
);
```

**Modern Pattern (v0.6.0+)**:
```dart
final handler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(borderStyle: BorderStyle.rounded),
    StyleDecorator(), // Recommended: Apply visual styles last
  ],
  sink: const ConsoleSink(),
  lineLength: 80, // Centralized layout control
);
```

### 2. Semantic Data vs. Monolithic Strings
**Problem**: Passing raw strings through the pipeline forced decorators to use fragile, expensive Regex to identify headers or timestamps for styling. This was slow and prone to breaking when formatters changed.

**Modern Fix**: The pipeline now communicates via `Iterable<LogLine>`. Every line contains multiple `LogSegment`s tagged with **semantic metadata** (`LogTag`).
- **Precision**: Decorators can target `LogTag.timestamp` or `LogTag.level` with 100% accuracy.
- **Zero Overhead**: No string parsing is required during decoration.

---

## 🎨 Visual System Shift

### Platform-Agnostic Styling
**Problem**: `ColorDecorator` was hardcoded to emit ANSI terminal codes, making logs unusable in web dashboards or structured JSON files.

**Modern Fix**: `StyleDecorator` (and its underlying `LogTheme`) emits platform-independent `LogStyle` metadata.
- **Visual Instructions**: Styles are treated as "instructions" (Bold, Dim) rather than "visuals" (Terminal Code).
- **Sink Responsibility**: The **Sink** (e.g., `ConsoleSink` or `HTMLSink`) determines how to render these instructions based on its target platform.

> [!IMPORTANT]
> `ColorDecorator` is now a deprecated alias for `StyleDecorator`. While it still works for backward compatibility, you should upgrade to leverage `LogTheme` and `LogColorScheme`.

---

## 🛠 API & Configuration Refining

### 1. Unified Field Selection (`LogField`)
To combat "Prop Explosion," individual boolean flags in formatters (e.g., `showLevel`, `includeTime`) have been replaced by the `LogField` enum.

```dart
// v0.6.0+
const JsonFormatter(
  fields: [LogField.timestamp, LogField.level, LogField.message],
)
```

### 2. Deterministic Cache Invalidation
The `Logger.configure` system now performs **Deep Equality** checks.
- **Efficiency**: If the new configuration matches the existing one, the library skips the O(N) tree-walk for cache invalidation.
- **Requirement**: Custom formatters, filters, or sinks **must** implement `operator ==` and `hashCode` to benefit from this optimization.

---

## ⚠️ Common Pitfalls

### Isolate Serialization
While formatters and decorators are stateless, **Sinks** are not. 
- If you use `FileSink` across multiple isolates, ensure they reference the same physical path through a coordinated file system. `logd` handles internal mutexing, but standard file-system locks still apply.

---

## 🗺 Breaking Changes Map

| Version | Feature | Impact |
|---|---|---|
| **v0.5.0** | Centralized Layout | `lineLength` moved from components to the `Handler` constructor. |
| **v0.5.0** | Pipeline Type-Safety | `format()` and `decorate()` signatures changed to `Iterable<LogLine>`. |
| **v0.6.0** | Semantic System | Formatting flags replaced by `LogField` enums. |
| **v0.6.0** | Style Refactor | `AnsiColorConfig` replaced by `LogTheme` and `LogColorScheme`. |
