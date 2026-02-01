# Handler Architecture

This document details the internal processing pipeline of the `Handler` module.

## The Pipeline

The `Handler` class acts as an orchestrator. When `handler.log(entry)` is called, data flows through four distinct stages.

```mermaid
flowchart LR
    Entry --> Filter --> Format --> Wrap --> Dec --> Sink --> IO
```

### The Life of a Log entry (Sequence)

```mermaid
sequenceDiagram
    participant L as Logger
    participant H as Handler
    participant F as Formatter
    participant D as Decorator
    participant S as Sink

    L->>H: log(LogEntry)
    H->>H: Filter Check
    alt Should remain?
        H->>F: format(entry, context)
        F-->>H: Iterable<LogLine>
        H->>H: wrap(availableWidth)
        loop Each Decorator
            H->>D: decorate(lines, entry, context)
            D-->>H: Iterable<LogLine>
        end
        H->>S: output(lines, level)
        S-->>H: Future<void>
    end
```

The `Handler` initializes a `LogContext` for every entry, ensuring **Unified Layout Sovereignty**:
- **totalWidth**: The authoritative spatial limit (from sink or user).
- **paddingWidth**: Calculated as the sum of all structural decorator footprints.
- **availableWidth**: The remaining slot for initial content (`totalWidth - paddingWidth`).
- **contentLimit**: The boundary for aligned metadata (e.g. suffixes).

Formatters wrap content to `availableWidth` *before* decorators run, eliminating layout conflicts.

### Stage 1: Filtering
**Component**: `LogFilter`
**Input**: `LogEntry`
**Output**: `Boolean`

Filters are deeply efficient checks run before any string manipulation occurs. If any filter returns `false`, processing stops immediately to save CPU cycles.
- *Example*: `LevelFilter` (ignore DEBUG logs), `RegexFilter` (ignore logs containing "password").

### Stage 2: Formatting
**Component**: `LogFormatter`
**Data Interface**: `LogField`
**Input**: `LogEntry`, `LogContext`
**Output**: `Iterable<LogLine>`
 
The formatter transforms the structured log entry into a list of semantic lines (`LogLine`). To ensure consistency, all formatters use the `LogField` system for field-safe data extraction from `LogEntry`.

- **Layout Alignment**: Formatters strictly rely on `context.availableWidth` provided by the handler to perform internal wrapping and alignment.
- **StructuredFormatter**: Detailed layout (header, origin, message) with fine-grained semantic tagging. **(Preferred for human reading)**
- **ToonFormatter**: Token-Oriented Object Notation. Highly efficient for LLM consumption. **(Preferred for AI agents)**
- **JsonFormatter**: Compact JSON serialization. Supports field customization via `LogField`.
- **JsonPrettyFormatter**: Pretty-printed JSON with semantic tagging.
- **MarkdownFormatter**: Generates structured Markdown output.
- **HTMLFormatter**: Produces semantic HTML segments.
- **PlainFormatter**: Standard `[timestamp] level: message` format.

### Semantic Tagging (`LogTag`)

The bridge between Stage 2 (Formatting) and Stage 3 (Decoration) is the `LogTag`. Formatters do not emit raw strings; they emit `LogSegment`s tagged with semantic metadata.

| Tag | Purpose | Example Component                     |
|---|---|---------------------------------------|
| `header` | General structural metadata | `ToonFormatter` fields                |
| `timestamp` | Time of entry | `StructuredFormatter`                 |
| `level` | Log severity (e.g. `[INFO]`) | `StructuredFormatter`                 |
| `message` | The primary content | `JsonFormatter`                       |
| `border` | Visual framing characters | `BoxDecorator`, `JsonPrettyFormatter` |
| `origin` | File/Line source info | `StructuredFormatter`                 |
| `error` | Exception details | `LogField.error` extraction           |
| `hierarchy` | Tree prefixes | `HierarchyDepthPrefixDecorator`       |
| `suffix` | Trailing metadata | `SuffixDecorator`                     |

**Why this matters**: A decorator can selectively target segments. For example, `StyleDecorator` might make `border` segments dim while making `level` segments bold and colored. This decoupling allows you to swap formatters without losing your high-fidelity terminal styling.

### Stage 3: Decoration
**Component**: `LogDecorator`
**Input**: `Iterable<LogLine>`
**Output**: `Iterable<LogLine>`

Decorators apply post-formatting transformations, often leveraging `LogContext.availableWidth` for dynamic adjustments. They are composable and execute in the order they appear in the `decorators` list (auto-sorted by type).
- **BoxDecorator**: Adds ASCII borders around the lines. It is now decoupled from the layout logic.
- **StyleDecorator**: The primary engine for visual transformations. Unlike simple colorizers, it:
    - Resolves semantic **LogStyles** from a **LogTheme** using both the `LogLevel` and the segment's `LogTag`s.
    - Supports bold, dim, italic, inverse, and both foreground/background colors.
    - **Merges styles**: It respects styles already applied by formatters while applying theme defaults.
    - Replaces the legacy **ColorDecorator** (now a deprecated alias).

For a deep dive into how decorators interact, see [Decorator Composition](decorator_compositions.md).

### Stage 4: Output (Sinking)
**Component**: `LogSink`
**Input**: `Iterable<LogLine>`, `LogLevel`
**Output**: `Future<void>` (I/O Side Effect)
 
The sink handles the physical write operation. Sinks are designed to be robust and isolated from the main application flow.

- **Preferred Width**: Each sink reports its `preferredWidth` (e.g., terminal width or default 80). The `Handler` uses this to initialize `LogContext.availableWidth` if a manual `lineLength` is not provided.
- **Fail-Safe Processing**: Sinks are wrapped in internal error handlers. If a `FileSink` fails (e.g., Disk Full), the error is routed to `InternalLogger` and does not crash the calling thread.
- **Concurrency**: Most sinks (except simple console wrappers) utilize an internal task queue (mutex) to serialize writes, preventing race conditions during rapid logging.

## Class Diagram

## The Data Model: LogEntry

The `LogEntry` is the immutable data snapshot passed through the pipeline.

### API Protection
> [!IMPORTANT]
> The `LogEntry` constructor and `Handler.log` method are marked as **`@internal`**. 
> Developers should always interface with the logging system via the `Logger` API (e.g., `logger.info()`). This preserves the integrity of the data model and allows for future pipeline optimizations without breaking user code.

### Dynamic Hierarchy
To ensure performance and consistency, `LogEntry` does not store a manual depth value. Instead, `hierarchyDepth` is computed dynamically from the `loggerName`:
- `global` -> 0
- `app` -> 1
- `app.services.db` -> 3

This ensures that indentation always perfectly mirrors the actual logger hierarchy, regardless of how the entry was created.

## Standard Implementations

### Sinks
- **ConsoleSink**: 
  - Dynamic width detection via `stdout.terminalColumns`.
  - Platform-aware ANSI support detection.
  - Efficiently translates `LogStyle` metadata into ANSI escape codes.
- **FileSink**: 
  - **Thread-Safety**: Uses a `_writeLock` (Completer-based mutex) to ensure sequential file access across asynchronous calls.
  - **Rotation**: Supports `SizeRotation` and `TimeRotation`. Handles file shifts, compression (GZip), and cleanup of old backups.
  - **Durability**: Employs `flush: true` on every write to minimize data loss during crashes.
  - **Auto-Provisioning**: Automatically creates parent directories if they don't exist.
- **HTMLSink**: 
  - Self-contained documents with embedded CSS for high-fidelity viewing in browsers.
  - Session-managed: Safely coordinates multiple sink instances writing to the same file path.
  - Dark mode support built-in.
- **MultiSink**: 
  - **Broadcast Engine**: Dispatches logs to child sinks in parallel using `Future.wait`.
  - **Error Isolation**: Failure in one child sink (e.g., a network timeout) does not prevent other sinks from completing.
- **HttpSink**:
  - **Batching**: Buffers logs and ships them in configurable batch sizes to reduce network overhead.
  - **Resilience**: Implements exponential backoff retries on failure (up to `maxRetries` attempts).
  - **Memory Safety**: Uses `DropPolicy` (`discardOldest`, `discardNewest`) to manage buffer overflow.
  - **Final Drain**: `dispose()` flushes all pending logs before cleanup.
- **SocketSink**:
  - **Real-Time Streaming**: Sends logs immediately over a WebSocket connection.
  - **Connection Awareness**: Buffers logs during disconnection and automatically drains the buffer upon reconnection.
  - **Auto-Reconnect**: Schedules reconnection attempts after configurable intervals.

> [!NOTE]
> **Formatter Flexibility**: Network sinks are formatter-agnostic. While `JsonFormatter` is recommended for structured log aggregation, any formatter works. The sink converts `LogLine` output to strings via `.toString()` and joins multi-line output with newlines. Ensure your receiving endpoint expects the format your chosen formatter produces.

### Threading & Safety
- **Isolate Awareness**: `logd` is designed to be safe across multiple isolates, though most sinks (like `FileSink`) perform their own synchronization to prevent file locking conflicts.
- **Async Boundary**: While formatting and decoration are synchronous for deterministic snapshotting of data, the `Sink.output` call is the async boundary. This allows the application to continue while the I/O system persists the logs.
