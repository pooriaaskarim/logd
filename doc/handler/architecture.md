# Handler Architecture: Semantic Separation

The `logd` handler module is built on a fundamental philosophical shift in logging: **Separation of Intent from Rendering**.

Unlike traditional logging systems where formatters immediately "draw" text, `logd` uses a multi-stage pipeline that treats a log entry as a **Semantic Data Structure** until the very last moment.

## The Semantic Pipeline

When `handler.log(entry)` is called, data flows through five distinct logical stages.

```mermaid
flowchart LR
    Entry --> Filter --> Format --> Dec --> Enc --> Sink --> IO
```

### 1. Filtering (Semantic Admission)
**Component**: `LogFilter`
Efficient checks run before any structure is built. If a filter fails, processing stops.

### 2. Formatting (Logical Intent)
**Component**: `LogFormatter`
**Output**: `LogStructure` (Internal Representation)

The formatter decides **WHAT** information is relevant and in what **LOGICAL** order. It does not decide how it looks. It emits a `LogStructure` composed of semantic `LogBlock`s (Sections, Containers).

### 3. Decoration (Structural Enhancement)
**Component**: `LogDecorator`
**Output**: `LogStructure` (Enhanced)

Decorators wrap or modify the logical structure. For example, a `BoxDecorator` doesn't draw a box with `-` and `|`; it wraps the existing structure in a `LogContainer` of style `box`.

### 4. Encoding (Physical Rendering)
**Component**: `LogEncoder<T>`
**Output**: `T` (Physical Format: String, HTML, JSON)

**The most critical stage.** The encoder is the only component that knows the physical constraints of the target medium. It translates the abstract `LogStructure` into a specific format.
- **Terminal Encoder**: Calculates terminal width, draws ASCII borders, performs hard line-wrapping, and applies ANSI colors.
- **HTML Encoder**: Generates a semantic `<details>` DOM tree, delegates wrapping to CSS, and applies color via classes.
- **JSON Encoder**: Preserves the structural hierarchy as nested objects for log aggregators.

### 5. Sinking (Physical Transport)
**Component**: `LogSink`
The sink receives the rendered data and performs the actual I/O side effect (writing to file, sending via HTTP).

---


## The Layout Contract: `LogContext`

While Encoders have the final say on *how* to draw, the `Handler` ensures everyone plays by the same spatial rules via `LogContext`.

- **totalWidth**: The authoritative spatial target (e.g., 80 chars, or terminal width).
- **hints**: Semantic hints for formatters (e.g., `colors: true/false`).

> **Note**: Unlike the v0.6.1 architecture where formatters had to calculate `availableWidth` and wrap text manually, v0.6.2 formatters generally **ignore** width. They emit the full content, trusting the `Encoder` to handle wrapping gracefully at the very last moment.

---

## The Components in Detail

### Stage 1: Filtering
**Component**: `LogFilter`
**Input**: `LogEntry`
**Output**: `Boolean`

Filters are deeply efficient checks run before any structure is built. If any filter returns `false`, processing stops immediately.
- *Example*: `LevelFilter` (ignore DEBUG logs), `RegexFilter` (ignore logs containing "password").

### Stage 2: Formatting (The Architect)
**Component**: `LogFormatter`
**Output**: `LogStructure`

The formatter constructs the logical building blocks of the log.

#### Standard Formatters
- **StructuredFormatter**: The default for humans. Organizes data into clear Header, Message, and Origin sections.
- **ToonFormatter**: "Token-Oriented Object Notation". A high-density format optimized for LLM consumption.
- **JsonFormatter**: Compact JSON serialization.
- **JsonPrettyFormatter**: Recursive, color-aware JSON for human debugging.
- **PlainFormatter**: Minimalist `[time] level: message`.
- **MarkdownFormatter**: Structured Markdown output.

#### Semantic Tagging (`LogTag`)
The formatter tags every `LogSegment` with semantic meaning, allowing downstream styles to be applied regardless of the formatter used.

| Tag | Purpose | Example |
|---|---|---|
| `header` | Structural metadata blocks | `[INFO]` |
| `timestamp` | Time of entry | `2023-10-10...` |
| `level` | Severity indication | `ERROR` |
| `message` | The primary content body | User message |
| `error` | Exception details | Stack traces |
| `origin` | Source location | `UserService:42` |
| `key/value` | Structured data pairs | `userId=5` |

### Stage 3: Decoration (The Interior Designer)
**Component**: `LogDecorator`
**Output**: `LogStructure` (Enhanced)

Decorators modify the logical tree, wrapping content or injecting new sections.

- **BoxDecorator**: Wraps the entire structure in a `LogContainer(style: box)`. It implies "this is a frame".
- **HierarchyDecorator**: Wraps content in a `LogContainer(style: hierarchy)`, implying indentation/nesting.
- **SuffixDecorator**: Appends a specific section to the end of the structure (e.g., `[v1.0]`).
- **StyleDecorator**: Applies `LogStyle` to segments based on their `LogTag`. This is where "Errors should be red" is defined, separate from the text.

### Stage 4: Encoding (The Renderer)
**Component**: `LogEncoder<T>`
**Output**: `T` (e.g., `String`, `List<int>`)

This is where the abstract `LogStructure` becomes concrete.

| Encoder | Philosophy | Output Example |
|---|---|---|
| **AnsiEncoder** | "Pixel Perfect" | Draws `┌─┐`, calculates `width=80`, wraps text, adds `\x1B[31m`. |
| **HtmlEncoder** | "Semantic Web" | Renders `<details class="log-box error">`. No physical border chars. |
| **JsonEncoder** | "Pure Data" | Converts the hierarchy to nested JSON objects. Preserves structure. |
| **PlainTextEncoder** | "Universal" | Renders ASCII borders but no colors. |

### Stage 5: Output (Sinking)
**Component**: `LogSink`
**Output**: Side Effect

The sink handles the physical transport.

#### Standard Sinks
- **ConsoleSink**:
  - Auto-detects terminal capabilities.
  - Defaults to `AnsiEncoder` if supported, else `PlainTextEncoder`.
- **FileSink**:
  - **Thread-Safety**: Uses internal mutexes for concurrent writes.
  - **Rotation**: Handles `SizeRotation` and `TimeRotation` safely.
  - **Durability**: Auto-flushes to disk.
- **HtmlLayoutSink**:
  - A wrapper sink! It wraps any other sink (like `FileSink`).
  - Writes the global `<html><head><style>...</head>` preamble.
  - Writes `HtmlEncoder` fragments into the `<body>`.
- **NetworkSinks (Http/Socket)**:
  - **HttpSink**: Batches logs and POSTs them with exponential backoff.
  - **SocketSink**: Streams logs over WebSockets with auto-reconnect.

---

## Data Model: `LogEntry`

The `LogEntry` is the immutable snapshot of a logging event.

> [!IMPORTANT]
> The `LogEntry` constructor is `@internal`. Users should only create logs via the `Logger` interface. This shields the internal data structure from breaking changes in user code.

### Dynamic Hierarchy
`logd` computes hierarchy depth dynamically from the logger name (`app.component.service`). This ensures that indentation in `HierarchyDecorator` is always correct, even if loggers are created ad-hoc.

---

## Threading & Safety

- **Isolate Safe**: `LogEntry` and `LogStructure` are immutable and sendable across isolates.
- **Async Boundary**: The boundary lies at `Sink.output`. Formatting, Decorating, and Encoding happen synchronously to ensure the *state* of the log (mutable objects, memory) is captured immediately. Only the I/O is async.
