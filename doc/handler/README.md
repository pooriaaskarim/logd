# Handler Module

The Handler module is responsible for the final stage of the logging pipeline: processing, formatting, and outputting log entries.

## Responsibilities

A `Handler` encapsulates two distinct operations:
1. **Formatting**: Transforming a structured `LogEntry` into a serialized format (String, JSON, etc.).
2. **Output**: Writing the serialized data to a destination (Console, File, Network).

## Components

### Formatters
- `StructuredFormatter`: Detailed layout (header, origin, message) without borders. **(Preferred for humans)**
- `ToonFormatter`: Token-Oriented Object Notation. Designed for LLM token efficiency. **(Preferred for AI)**
- `JsonFormatter`: Serializes logs to JSON. Supports field selection.
- `JsonPrettyFormatter`: Human-readable JSON with semantic styling.
- `PlainFormatter`: Simple text output.

### Decorators
Decorators now have full access to the `LogEntry` object, including metadata like `hierarchyDepth`, `tags`, and `loggerName`, enabling more context-aware transformations.
- `BoxDecorator`: Adds ASCII borders around formatted lines.
- `StyleDecorator`: Applies semantic styles (colors, bold, dim, etc.) to log segments using a `LogTheme`. It is the central engine for platform-agnostic visual presentation.
- `HierarchyDepthPrefixDecorator`: Adds visual indentation based on the logger's hierarchy depth, creating a clear tree-like structure.

#### Style Customization

`StyleDecorator` leverages the `LogTheme` system to map semantic tags to visual styles:

```dart
// Use predefined schemes
final darkHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
  ],
  sink: const ConsoleSink(),
);

// Or create a custom theme with specific segment overrides
final customTheme = LogTheme(
  colorScheme: LogColorScheme.defaultScheme,
  levelStyle: const LogStyle(bold: true, inverse: true), // Bold & Inverted levels
  timestampStyle: const LogStyle(dim: true, italic: true), // Dim & Italic timestamps
  borderStyle: const LogStyle(color: LogColor.white), // Always white borders
);

final customHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: [
    StyleDecorator(theme: customTheme),
  ],
  sink: const ConsoleSink(),
);
```

#### Fine-Grained Segment Styling

`LogTheme` allows you to override styles for specific semantic segments (`LogTag`). Every segment starts with the base level color (info=blue, error=red) and merges with your overrides:

```dart
// Highlight only the message
final messageHighlight = LogTheme(
  colorScheme: LogColorScheme.defaultScheme,
  messageStyle: const LogStyle(bold: true, backgroundColor: LogColor.blue),
);

// Dim everything except headers
final minimalTheme = LogTheme(
  colorScheme: LogColorScheme.defaultScheme,
  messageStyle: const LogStyle(dim: true),
  borderStyle: const LogStyle(dim: true),
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

#### Semantic Styling
Even complex formats like JSON or TOON use semantic tags (`LogTag.timestamp`, `LogTag.level`, `LogTag.header`, etc.) rather than implementation-specific tags. This ensures your color scheme remains consistent across different formatters. For instance, `StyleDecorator` will dim the timestamp in both a `StructuredFormatter` and a `JsonPrettyFormatter` automatically if `timestampStyle` is set.

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
    StyleDecorator(),
  ],
  sink: const ConsoleSink(),
  lineLength: 80,
)
```

For detailed rules on how decorators interact, see [Decorator Composition](decorator_compositions.md).

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

## Layout Resolution

A handler's output width is determined by a strict priority chain:
1. **Explicit `lineLength`**: If you pass `lineLength` to the `Handler` constructor, it is used as the absolute limit.
2. **Sink `preferredWidth`**: If `lineLength` is null, the handler queries the sink.
   - `ConsoleSink`: Dynamically detects terminal width (e.g., 80 or 120).
   - `FileSink`: Default to 80 (configurable).
3. **Fallback**: Default to 80 if neither can provide a value.

All formatters and decorators receive this calculated width via `LogContext.availableWidth`. 

> [!NOTE]
> Structural decorators like `BoxDecorator` use `availableWidth` as a minimum target. If content exceeds this width, the box will expand to fit the content, potentially exceeding the `lineLength`. Most formatters automatically wrap to `availableWidth` to prevent this.

---

## Common Patterns (Recipes)

### 1. Production Rotating JSON
Optimized for ELK/Splunk consumption with daily rotation and compression.

```dart
final prodHandler = Handler(
  formatter: const JsonFormatter(
    fields: [LogField.timestamp, LogField.level, LogField.message, LogField.error],
  ),
  sink: FileSink(
    'logs/app.log',
    fileRotation: TimeRotation(
      interval: Duration(days: 1),
      compress: true,
    ),
  ),
);
```

### 2. Developer's Dashboard
High-visual-fidelity output with hierarchy tracking and refined styling.

```dart
final devHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: [
    const HierarchyDepthPrefixDecorator(),
    const BoxDecorator(borderStyle: BorderStyle.rounded),
    StyleDecorator(
      theme: LogTheme(
        colorScheme: LogColorScheme.darkScheme,
        levelStyle: const LogStyle(bold: true, inverse: true),
      ),
    ),
  ],
  sink: const ConsoleSink(),
);
```

### 3. LLM-Native Agent Stream
Minimal tokens, maximum structure for AI agent consumption.

```dart
final aiHandler = Handler(
  formatter: const ToonFormatter(
    arrayName: 'context',
    keys: [LogField.timestamp, LogField.level, LogField.message],
  ),
  sink: FileSink('logs/agent.toon'),
);
```

### 4. Hybrid (Multi-Sink)
Log to console and file simultaneously with the same formatting.

```dart
final hybridHandler = Handler(
  formatter: const PlainFormatter(),
  sink: MultiSink(sinks: [
    const ConsoleSink(),
    FileSink('logs/backup.log'),
  ]),
);
```

---

## Contribution
Documentation for independent Formatters and Sinks is currently being expanded. Please refer to the source code in `lib/src/handler/` for implementation details.
