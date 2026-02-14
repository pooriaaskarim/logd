# Handler Module

The Handler module orchestrates the final stage of the logging pipeline: processing, formatting, and outputting log entries with precision and flexibility.

## Responsibilities

A `Handler` encapsulates two core operations:
1. **Formatting**: Transforming a structured `LogEntry` into a serialized format (String, JSON, TOON, etc.).
2. **Output**: Writing the serialized data to a destination (Console, File, Network).

## Components

### Formatters
- `StructuredFormatter`: Modern flow-based layout with semantic tagging.
- `JsonPrettyFormatter`: High-fidelity, recursive JSON inspection for nested payloads.
- `MarkdownFormatter`: Readability-first layout with collapsible stack traces.
- `ToonFormatter`: Token-efficient header-first format optimized for AI agents.
- `PlainFormatter`: Minimal, flow-aware text output.

#### Unified Metadata Configuration
All modern formatters accept a `Set<LogMetadata>` (`timestamp`, `logger`, `origin`), providing a consistent API for selecting contextual data.

### Decorators
- `BoxDecorator`: ASCII borders for structural clarity.
- `PrefixDecorator` / `SuffixDecorator`: Prepends/Appends semantic strings (supports alignment and styles).
- `StyleDecorator`: Platform-agnostic visual presentation via `LogTheme`.
- `HierarchyDepthPrefixDecorator`: Visual indentation based on computed logger depth.

#### Style Customization

`StyleDecorator` uses the `LogTheme` system to map semantic tags to visual styles, decoupling intent from platform representation:

```dart
// Use predefined color schemes
final darkHandler = Handler(
  formatter: const StructuredFormatter(),
  decorators: const [
    BoxDecorator(),
    StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
  ],
  sink: const ConsoleSink(),
);

// Create custom themes with segment-specific overrides
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

`LogTheme` enables overrides for specific semantic segments (`LogTag`). Segments inherit base level colors (info=blue, error=red) and merge with custom styles:

```dart
// Highlight messages exclusively
final messageHighlight = LogTheme(
  colorScheme: LogColorScheme.defaultScheme,
  messageStyle: const LogStyle(bold: true, backgroundColor: LogColor.blue),
);

// Dim content while preserving headers
final minimalTheme = LogTheme(
  colorScheme: LogColorScheme.defaultScheme,
  messageStyle: const LogStyle(dim: true),
  borderStyle: const LogStyle(dim: true),
);
```

#### Default Colors

The default color scheme ensures optimal visibility across terminals:
- **trace**: Green
- **debug**: White
- **info**: Blue
- **warning**: Yellow
- **error**: Red

For dark terminals, use `LogColorScheme.darkScheme` with brighter variants.

#### Semantic Styling
Complex formats like JSON and TOON use semantic tags (`LogTag.timestamp`, `LogTag.level`, `LogTag.header`, etc.) for consistency. This allows `StyleDecorator` to apply uniform styling across formatters - e.g., dimming timestamps in both `StructuredFormatter` and `JsonPrettyFormatter` when `timestampStyle` is configured.

### Sinks
- `ConsoleSink`: Outputs to standard output (`stdout`), dynamically detecting terminal width.
- `FileSink`: Writes to the local filesystem with support for advanced rotation strategies (size-based, time-based) and compression.
- `HttpSink`: Ships logs to remote HTTP endpoints with batching, exponential backoff retries, and memory-safe buffering via `DropPolicy`.
- `SocketSink`: Streams logs in real-time over WebSocket connections with automatic reconnection and buffer draining on recovery.
- `MultiSink`: Distributes output to multiple sinks concurrently, ensuring resilient logging.

> [!TIP]
> **Network Sink Formatter Choice**: While `JsonFormatter` is recommended for `HttpSink` (produces structured JSON arrays), network sinks accept any formatter. Use `ToonFormatter` for efficient real-time streaming or `PlainFormatter` for simple text ingestion. Ensure your receiving endpoint matches the expected format.

## Composition

The Handler module's strength is its composability. Chain decorators for sophisticated output; `Handler` automatically sorts them by type (Transform → Visual → Structural) and deduplicates for precise visual composition:

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

For in-depth rules on decorator interactions, refer to [Decorator Composition](decorator_compositions.md).

## Edge Cases and Robustness

The Handler module handles edge cases robustly, ensuring reliable operation under diverse conditions:

### Empty and Null Messages
- Empty strings process without failure
- Whitespace-only messages handled correctly
- Single-character messages compatible with all decorators

### Very Long Lines
- Text wrapping preserves ANSI codes intact
- BoxDecorator maintains width consistency with extended content
- Long unbroken words managed effectively

### Tab Normalization
- `BoxDecorator` automatically expands tabs to spaces (default 8 cells).
- Ensures border integrity across different shell environments and tab-stop interpretations.

### ANSI Code Preservation
- ANSI codes maintained during wrapping.
- Sequential ANSI codes handled accurately.
- Colors integrate correctly with box decorators.

### Error Handling
- Formatter exceptions propagate as expected
- Decorator exceptions managed appropriately
- Sink failures logged via InternalLogger
- Filter exceptions prevent pipeline crashes

### Decorator Composition
- Duplicate decorators automatically deduplicated
- Auto-sorting ensures correct composition order
- Idempotent: multiple applications are safe

Comprehensive edge case validation available in `test/handler/edge_cases/`.

## Layout Resolution

Handler output width follows a strict priority hierarchy:
1. **Explicit `lineLength`**: Overrides all when provided to `Handler` constructor.
2. **Sink `preferredWidth`**: Queried when `lineLength` is null.
    - `ConsoleSink`: Dynamically detects terminal width (e.g., 80 or 120).
    - `FileSink`: Defaults to 80 (configurable).
3. **Fallback**: 80 characters if no value available.

Formatters and decorators access this width via `LogContext.availableWidth`.

> [!NOTE]
> Structural decorators like `BoxDecorator` treat `availableWidth` as a minimum. Content exceeding this expands the box, potentially surpassing `lineLength`. Formatters typically wrap to `availableWidth` to mitigate this.

---

## Common Patterns (Recipes)

### 1. Production Rotating JSON
Optimized for high-volume logs with automated rotation and compression.

```dart
final logger = Logger.get('app.api');
logger.configure(
  handlers: [
    Handler(
      formatter: const JsonFormatter(
        metadata: [LogMetadata.timestamp, LogMetadata.origin],
      ),
      sink: FileSink(
        'logs/production.log',
        fileRotation: TimeRotation(
          interval: Duration(days: 1),
          compress: true,
        ),
      ),
    ),
  ],
);
```

### 2. The DevOps Dashboard
High-fidelity console output with semantic prefix/suffix signaling and hierarchy visualization.

```dart
final logger = Logger.get('infra.k8s.pod');
logger.configure(
  handlers: [
    Handler(
      formatter: const StructuredFormatter(),
      decorators: [
        const PrefixDecorator('📦', tags: {LogTag.header}),
        const SuffixDecorator('[ONLINE]', style: LogStyle(color: LogColor.green)),
        const HierarchyDepthPrefixDecorator(),
        const BoxDecorator(borderStyle: BorderStyle.rounded),
        StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
      ],
      sink: const ConsoleSink(),
    ),
  ],
);
```

### 3. Recursive JSON Inspection
Deep-data visibility for highly structured logs containing nested JSON strings.

```dart
final logger = Logger.get('app.service');
logger.configure(
  handlers: [
    Handler(
      formatter: const JsonPrettyFormatter(
        // Automatically detects and expands nested JSON strings
        recursive: true, 
      ),
      sink: const ConsoleSink(),
    ),
  ],
);
```

### 4. Centralized Network Logging
Ship logs to a central aggregation service with resilient delivery.

```dart
final logger = Logger.get('app.production');
logger.configure(
  handlers: [
    Handler(
      formatter: const JsonFormatter(),
      sink: const HttpSink(
        url: 'https://logs.example.com/ingest',
        batchSize: 50,
        flushInterval: Duration(seconds: 10),
        maxRetries: 5,
        dropPolicy: DropPolicy.discardOldest,
      ),
    ),
  ],
);
```

### 5. Real-Time Monitoring Dashboard
Stream logs to a live monitoring WebSocket server.

```dart
final logger = Logger.get('app.monitor');
logger.configure(
  handlers: [
    Handler(
      formatter: const ToonFormatter(), // Efficient for streaming
      sink: const SocketSink(
        url: 'wss://monitor.example.com/logs',
        reconnectInterval: Duration(seconds: 5),
      ),
    ),
  ],
);
```

---

## Contribution
Documentation for individual Formatters and Sinks continues to expand. Refer to source code in `lib/src/handler/` for implementation details.
