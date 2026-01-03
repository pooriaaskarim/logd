# Decorator Composition

This document defines the rules and behavior for composing multiple `LogDecorator`s in a `Handler`.

## Execution Order

Decorators are automatically sorted by type to ensure correct visual composition:

```dart
Handler(
  decorators: [
    DecoratorB(), // May be applied first depending on type
    DecoratorA(), // May be applied second depending on type
  ],
)
```

**Auto-sort Priority:**
1. **TransformDecorator** (0) - Content mutation
2. **VisualDecorator** (1) - Content styling (e.g., ANSI colors)  
3. **StructuralDecorator** (2-4) - Layout and wrapping
   - BoxDecorator (2)
   - HierarchyDepthPrefixDecorator (3)
   - Other structural (4)
4. **Unknown types** (5) - Processed last

The output of each decorator is passed as input to the next in the sorted sequence.

## Transformation Flow

Each decorator receives an `Iterable<String>` (the lines to decorate) and produces a new `Iterable<String>`.

1. **Input**: Lines produced by the `LogFormatter` (or the previous decorator).
2. **Action**: The decorator applies transformations (e.g., adding ANSI codes, wrapping in boxes, adding prefixes).
3. **Output**: The transformed lines.

## Multi-line Handling

Decorators must be prepared to handle `Iterable<String>` containing multiple lines. 

- **Line-by-line decorators** (e.g., `AnsiColorDecorator`): Usually iterate over each line and apply a transformation to each.
- **Structural decorators** (e.g., `BoxDecorator`): Collect all lines first to determine dimensions, then wrap them in a collective structure (adding new lines for the border).

## Common Chaining Patterns
### 1. Colored Content in Colored Box
**Order**: `[AnsiColorDecorator(), BoxDecorator()]`
- `AnsiColorDecorator` colors the **content** (because it runs first).
- `BoxDecorator` wraps the content and colors the **border** (using its own `useColors: true`).
- **Result**: Perfectly distinct content and border colors without bleeding.

### 2. Hierarchical Indentation
**Order**: `[BoxDecorator(), HierarchyDepthPrefixDecorator()]`
- `BoxDecorator` creates the frame.
- `HierarchyDepthPrefixDecorator` adds indentation **outside** the box.
- **Result**: The box is shifted right, maintaining its integrity.

## Best Practices

- **Type-Based Ordering**: Rely on auto-sorting rather than manual ordering. The `Handler` automatically sequences decorators by type for optimal composition.
- **Deduplication**: Duplicate decorators are automatically removed, preventing redundant processing.
- **Content First**: `TransformDecorator` and `VisualDecorator` process content before structural wrapping.
- **Structure Second**: `StructuralDecorator` wraps and positions content after it's been styled.
- **Automatic Control**: The `Handler` manages the execution order based on decorator types, not definition order.
