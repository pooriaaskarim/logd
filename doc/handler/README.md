# Handler Module

The Handler module is responsible for the final stage of the logging pipeline: processing, formatting, and outputting log entries.

## Responsibilities

A `Handler` encapsulates two distinct operations:
1. **Formatting**: Transforming a structured `LogEntry` into a serialized format (String, JSON, etc.).
2. **Output**: Writing the serialized data to a destination (Console, File, Network).

## Components

### Formatters
- `StructuredFormatter`: Detailed layout (header, origin, message) without borders. **(Preferred)**
- `BoxFormatter`: Wraps logs in a visual box. **(Deprecated - use StructuredFormatter + BoxDecorator)**
- `JsonFormatter`: Serializes logs to JSON for machine parsing.
- `PlainFormatter`: Simple text output.

### Decorators
Decorators now have full access to the `LogEntry` object, including metadata like `hierarchyDepth`, `tags`, and `loggerName`, enabling more context-aware transformations.
- `BoxDecorator`: Adds ASCII borders around formatted lines.
- `ColorDecorator`: Adds level-based coloring with customizable color schemes and color application options. Includes a `headerBackground` option for bold header highlights.
- `HierarchyDepthPrefixDecorator`: Adds visual indentation (defaulting to `│ `) based on the logger's hierarchy depth, creating a clear tree-like structure in the terminal.

#### ANSI Color Customization

Both `ColorDecorator` and `BoxDecorator` support customizable color schemes:

```dart
// Use predefined color schemes
final darkHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    ColorDecorator(),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
);

// Or create custom color scheme
final customScheme = AnsiColorScheme(
  trace: AnsiColor.cyan,
  debug: AnsiColor.white,
  info: AnsiColor.brightBlue,
  warning: AnsiColor.brightYellow,
  error: AnsiColor.brightRed,
);

final customHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    ColorDecorator(),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
);
```

#### Fine-Grained Color Control

`ColorDecorator` supports granular control over which log elements to color, including options for header background highlights:

```dart
// Color only headers
const headerOnly = ColorDecorator(
  
  config: AnsiColorConfig.headerOnly,
);

// Color everything except borders
const noBorders = ColorDecorator(
  
  config: AnsiColorConfig.noBorders,
);

// Custom configuration
const custom = ColorDecorator(
  
  config: AnsiColorConfig(
    colorHeader: true,
    colorBody: true,
    colorBorder: false,  // Don't color borders
    colorStackFrame: true,
    headerBackground: true,  // Use background color for headers
  ),
);
```

#### Default Colors

The default color scheme provides good visibility in most terminals:
- **trace**: Green
- **debug**: White
- **info**: Blue
- **warning**: Yellow
- **error**: Red

For dark terminals, use `AnsiColorScheme.darkScheme` which uses brighter variants.

### Sinks
- `ConsoleSink`: Writes to standard output (`stdout`).
- `FileSink`: Writes to the local filesystem. Supports rotation strategies.
- `MultiSink`: multiplexes output to multiple sinks.

## Composition

The power of the Handler module lies in its composability. You can chain decorators to achieve complex output. The `Handler` automatically sorts decorators by type (Transform → Visual → Structural) and deduplicates them to ensure correct visual composition:

```dart
Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(borderStyle: BorderStyle.double),
    ColorDecorator(),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
)
```

For detailed rules on how decorators interact, see [Decorator Composition](decorator_composition.md).

## Edge Cases and Robustness

The Handler module is designed to handle various edge cases gracefully:

### Empty and Null Messages
- Empty strings are handled without crashing
- Whitespace-only messages are processed correctly
- Very short messages (single character) work with all decorators

### Very Long Lines
- Text wrapping preserves ANSI codes correctly
- Box decorator maintains consistent width with long content
- Very long words (no spaces) are handled appropriately

### Unicode and Special Characters
- Unicode characters (Chinese, Japanese, etc.) are supported
- Emoji characters work correctly
- Special ASCII characters are handled properly
- Mixed Unicode and ASCII content is supported

### ANSI Code Preservation
- ANSI codes are preserved during text wrapping
- Multiple ANSI codes in sequence are handled correctly
- Colors work correctly with box decorators

### Error Handling
- Formatter exceptions propagate correctly
- Decorator exceptions are handled appropriately
- Sink failures are reported properly
- Filter exceptions don't crash the pipeline

### Decorator Composition
- Duplicate decorators are automatically deduplicated
- Decorators are auto-sorted for correct composition
- Idempotency: applying decorators multiple times is safe

For comprehensive edge case tests, see `test/handler/edge_cases/`.

## Contribution
Documentation for independent Formatters and Sinks is currently being expanded. Please refer to the source code in `lib/src/handler/` for implementation details.
