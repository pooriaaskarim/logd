# BoxFormatter Migration Guide

As of version 0.2.0, `BoxFormatter` is deprecated. While it remains functional for backward compatibility, it is recommended to migrate to the new composable system using `StructuredFormatter` and `BoxDecorator`.

## Why the Change?

The original `BoxFormatter` coupled two distinct responsibilities:
1. **Layout**: Organizing log metadata (timestamp, origin, etc.).
2. **Visual Framing**: Drawing ASCII borders.

By splitting these, you can now:
- Use the structured layout WITHOUT boxes (e.g., for file logs).
- Apply boxes to OTHER formatters (e.g., a simple plain formatter).
- Compose multiple decorators (e.g., Colors + Boxes + Custom tags) in a predictable way.

## Migration Examples

### Standard Boxed Logging

**Before**:
```dart
final handler = Handler(
  formatter: BoxFormatter(
    borderStyle: BorderStyle.rounded,
    lineLength: 80,
    useColors: true,
  ),
  sink: ConsoleSink(),
);
```

**After**:
```dart
final handler = Handler(
  formatter: StructuredFormatter(lineLength: 80),
  decorators: [
    BoxDecorator(
      borderStyle: BorderStyle.rounded,
      lineLength: 80,
      useColors: false, // Recommended: use AnsiColorDecorator instead
    ),
    AnsiColorDecorator(), // Handles coloring for both content and borders
  ],
  sink: ConsoleSink(),
);
```

> [!TIP]
> **Recommended Pattern**: We recommend disabling `useColors` in `BoxDecorator` and adding `AnsiColorDecorator` at the end of the `decorators` list. This ensures consistent coloring across the entire output.

### Plain Layout (No Box)

**Before**:
(Not easily possible with `BoxFormatter`)

**After**:
```dart
final handler = Handler(
  formatter: StructuredFormatter(lineLength: 80),
  sink: ConsoleSink(),
);
```

## Parameter Mapping

| Old `BoxFormatter` | New Component |
|-------------------|---------------|
| `lineLength` | `StructuredFormatter(lineLength: ...)` AND `BoxDecorator(lineLength: ...)` |
| `borderStyle` | `BoxDecorator(borderStyle: ...)` |
| `useColors` | `AnsiColorDecorator()` (Preferred) or `BoxDecorator(useColors: ...)` |

### Color Customization (New in v0.5.0)

With the new ANSI color infrastructure, you can customize colors for different use cases:

```dart
// Dark terminal theme
final darkHandler = Handler(
  formatter: StructuredFormatter(),
  decorators: [
    AnsiColorDecorator(colorScheme: AnsiColorScheme.darkScheme),
    BoxDecorator(colorScheme: AnsiColorScheme.darkScheme),
  ],
  sink: ConsoleSink(),
);

// Custom colors
final customScheme = AnsiColorScheme(
  trace: AnsiColor.cyan,
  info: AnsiColor.brightMagenta,
  error: AnsiColor.brightRed,
);

final customHandler = Handler(
  formatter: StructuredFormatter(),
  decorators: [
    AnsiColorDecorator(colorScheme: customScheme),
    BoxDecorator(colorScheme: customScheme),
  ],
  sink: ConsoleSink(),
);

// Control which elements to color
final selectiveHandler = Handler(
  formatter: StructuredFormatter(),
  decorators: [
    AnsiColorDecorator(
      config: AnsiColorConfig(
        colorHeader: true,
        colorBody: true,
        colorBorder: false,  // Skip borders
        colorStackFrame: true,
      ),
    ),
  ],
  sink: ConsoleSink(),
);
```

#### Header Background Migration

Old `AnsiColorDecorator(colorHeaderBackground: true)`:

```dart
// Old (deprecated)
AnsiColorDecorator(
  useColors: true,
  colorHeaderBackground: true,  // Removed in v0.5.0
);
```

```dart
// New
AnsiColorDecorator(
  useColors: true,
  config: AnsiColorConfig(headerBackground: true),
);
```

## Troubleshooting

### Box Alignment Issues
If your box borders look "shaggy" or misaligned, ensure that any decorator that significantly changes line length (like `AnsiColorDecorator`) is placed **AFTER** `BoxDecorator` in the list. `BoxDecorator` now handles existing ANSI codes correctly, but it's still best practice to color the final structure.
