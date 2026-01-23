# Decorator Composition

This document defines the rules and behavior for composing multiple `LogDecorator`s in a `Handler`. Composition allows you to separate visual styling from structural framing and content transformation.

## Execution Order (Auto-Sorting)

To prevent visual artifacts (like uncolored borders or wrapped ANSI codes), the `Handler` automatically sorts all attached decorators by their technical role.

**Execution Priority (Lower runs first):**

1.  **TransformDecorator (0)**: Mutates the semantic content (e.g., masking secrets, truncating long messages).
2.  **StructuralDecorator (1-3)**: Changes the layout or adds structural segments.
    *   **BoxDecorator (1)**: Wraps the lines in an ASCII box.
    *   **HierarchyDepthPrefixDecorator (2)**: Adds indentation prefixes *outside* the box.
    *   **Other (3)**: Custom structural components.
3.  **VisualDecorator (4)**: Applies final presentation styles (e.g. `StyleDecorator` using ANSI codes or CSS).
4.  **Unknown types (5)**: Processed last.

> [!IMPORTANT]
> **VisualDecorator** runs AFTER **StructuralDecorator**. This ensures that borders added by the `BoxDecorator` receive the correct level-based colors.

> [!IMPORTANT]
> Current implementation might change drastically, in favor of extensibility in the future.

## Data Model: Semantic Segments

Unlike legacy systems that pass raw strings, the `logd` pipeline passes `Iterable<LogLine>`.

-   **LogLine**: A collection of `LogSegment`s representing one horizontal row of output.
-   **LogSegment**: A typed piece of text with semantic `LogTag`s (e.g., `LogTag.border`, `LogTag.timestamp`).

Decorators are stateless. They receive the lines, the original `LogEntry` (for context), and the `LogContext` (for layout limits).

```dart
abstract class LogDecorator {
  Iterable<LogLine> decorate(
    Iterable<LogLine> lines,
    LogEntry entry,
    LogContext context,
  );
}
```

## Platform-Agnostic Styling

One of the primary benefits of this composition model is **Platform Independence**. Because `StyleDecorator` emits `LogStyle` metadata rather than raw ANSI codes, the same pipeline can:

1.  **Terminal**: Use an ANSI adapter to render colors.
2.  **Web**: Use an HTML sink to render CSS classes (e.g., `<span class="log-level-info">`).
3.  **Cloud**: Emit structured JSON with style metadata for remote dashboards.

## Common Chaining Patterns

### 1. Boxed and Styled (Standard Developer)
**Configuration**: `[BoxDecorator(), StyleDecorator()]`
-   **Step 1**: `BoxDecorator` adds `LogSegment`s with the `LogTag.border` tag.
-   **Step 2**: `StyleDecorator` sees the borders and the content, applies the `LogTheme`, and colors both according to the `LogLevel`.
-   **Result**: A fully colored box where borders and text share a cohesive visual identity.

### 2. Hierarchical Indentation
**Configuration**: `[BoxDecorator(), HierarchyDepthPrefixDecorator()]`
-   **Step 1**: `BoxDecorator` creates the frame.
-   **Step 2**: `HierarchyDepthPrefixDecorator` adds markers (`│ `) to the start of every line.
-   **Result**: The box is pushed right, visually representing its position in the logger tree without breaking the box layout.

## Best Practices

-   **Rely on Auto-Sorting**: Don't worry about the order in the `decorators: [...]` list; the `Handler` will re-sequence them for technical correctness.
-   **Deduplication**: Adding the same decorator instance twice is safe; the `Handler` deduplicates the set before processing.
-   **Statelessness**: Custom decorators should avoid keeping internal state between `decorate()` calls to remain thread-safe and predictable.
