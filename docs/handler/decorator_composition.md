# Decorator Composition

This document defines the rules and behavior for composing multiple `LogDecorator`s in a `Handler`.

## Execution Order

Decorators are applied sequentially in the order they are defined in the `Handler`'s `decorators` list.

```dart
Handler(
  decorators: [
    DecoratorA(), // Applied first
    DecoratorB(), // Applied second
  ],
)
```

The output of the first decorator is passed as the input to the second decorator.

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

### 1. Color + Box
**Order**: `[BoxDecorator(), AnsiColorDecorator()]`
- `BoxDecorator` adds borders.
- `AnsiColorDecorator` colors the entire output (borders + content).
- **Result**: A colored box.

**Order**: `[AnsiColorDecorator(), BoxDecorator()]`
- `AnsiColorDecorator` colors the content lines.
- `BoxDecorator` adds uncolored borders around colored content.
- **Result**: A plain box with colored text inside.

### 2. Prefix + Box
**Order**: `[BoxDecorator(), PrefixDecorator()]`
- Adds a prefix to every line of the box (including borders).
- **Result**: Box is shifted or tagged.

### 3. Truncate + Box
**Order**: `[TruncateDecorator(), BoxDecorator()]`
- Content is truncated *before* being boxed.
- **Result**: The box fits the truncated content perfectly.

**Order**: `[BoxDecorator(), TruncateDecorator()]`
- The box borders themselves might be truncated, breaking the visual integrity.
- **Caution**: Generally avoid this unless the truncation width is much larger than the box width.

## Input/Output Contract

1. **Line Count**: Decorators are allowed to change the number of lines (e.g., `BoxDecorator` adds top/bottom lines).
2. **Encapsulation**: Decorators should avoid assuming the content of lines unless they are designed to work with a specific formatter.
3. **ANSI Transparency**: Decorators that calculate text width **should** account for non-printing characters (ANSI escape sequences).

## The ANSI Length Problem

A major source of conflict in decorator composition is the difference between a string's `.length` and its **visible width**.

```dart
final colorLine = "\x1B[32mHello\x1B[0m";
print(colorLine.length); // 14
// Visible width is only 5!
```

**Risk**: If `AnsiColorDecorator` is applied before `BoxDecorator`, the box will be significantly wider than the content because it uses `.padRight(width)` based on the technical length (14) rather than the visible width (5).

**Current Solution**: Always place `AnsiColorDecorator` **last** in the decorators list.

## Best Practices

- **Length-sensitive first**: Use decorators that calculate widths (Box, Wrap, Truncate) before decorators that add ANSI colors.
- **Composition over complexity**: Prefer multiple simple decorators over one "god" decorator.
- **Isolate side effects**: ensure decorators don't rely on external state that might change during the pipeline execution.
