# Handler Architecture

This document details the internal processing pipeline of the `Handler` module.

## The Pipeline

The `Handler` class acts as an orchestrator. When `handler.log(entry)` is called, data flows through four distinct stages.

```mermaid
flowchart LR
    Entry[LogEntry] --> Filter{Filter?}
    Filter -- No --> Drop[Stop]
    Filter -- Yes --> Format[Formatter]
    Format --> Dec[Decorator]
    Dec --> Sink[Sink]
    Sink --> IO[Output]
    
    classDef inputStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef processStyle fill:#f5f5f5,stroke:#616161,stroke-width:2px,color:#000
    classDef outputStyle fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#000
    classDef stopStyle fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    
    class Entry inputStyle
    class Format,Dec,Sink processStyle
    class IO outputStyle
    class Drop stopStyle
```

### Stage 1: Filtering
**Component**: `LogFilter`
**Input**: `LogEntry`
**Output**: `Boolean`

Filters are deeply efficient checks run before any string manipulation occurs. If any filter returns `false`, processing stops immediately to save CPU cycles.
- *Example*: `LevelFilter` (ignore DEBUG logs), `RegexFilter` (ignore logs containing "password").

### Stage 2: Formatting
**Component**: `LogFormatter`
**Input**: `LogEntry`
**Output**: `Iterable<String>`

The formatter transforms the structured log entry into a list of strings.
- **BoxFormatter**: Draws ASCII borders around the message.
- **JsonFormatter**: precise JSON serialization.
- **PlainFormatter**: Standard `[timestamp] level: message` format.

### Stage 3: Decoration
**Component**: `LogDecorator`
**Input**: `Iterable<String>`
**Output**: `Iterable<String>`

Decorators apply post-formatting transformations. This is commonly used for terminal coloring, where ANSI codes are injected around specific lines based on the log level.

### Stage 4: Output (Sinking)
**Component**: `LogSink`
**Input**: `Iterable<String>`
**Output**: `Future<void>` (I/O Side Effect)

The sink handles the physical write operation. Sinks are designed to be non-blocking where possible.
- **ConsoleSink**: Wraps `print` / `stdout`.
- **FileSink**: Manages file streams, locking, and rotation.

## Class Diagram

```mermaid
classDiagram
    class Handler {
        +Formatter formatter
        +Sink sink
        +List~Filter~ filters
        +List~Decorator~ decorators
        +log(LogEntry)
    }
    
    class LogFilter {
        <<interface>>
        +shouldLog(LogEntry): bool
    }
    
    class LogFormatter {
        <<interface>>
        +format(LogEntry): Iterable~String~
    }
    
    class LogDecorator {
        <<interface>>
        +decorate(lines): Iterable~String~
    }
    
    class LogSink {
        <<abstract>>
        +output(lines)
    }

    Handler --> LogFilter
    Handler --> LogFormatter
    Handler --> LogDecorator
    Handler --> LogSink
    
    style Handler fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style LogFilter fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style LogFormatter fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style LogDecorator fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    style LogSink fill:#fce4ec,stroke:#c2185b,stroke-width:2px
```

## Standard Implementations

### Sinks
- **FileSink**: Supports `SizeRotation` (rotate after 10MB) and `TimeRotation` (rotate daily). Uses platform-specific file locking.
- **MultiSink**: A composite sink that broadcasts to multiple children (e.g., Write to File AND Console concurrently).

### Threading & Safety
Handlers operate synchronously for Formatting and Decoration to ensure data consistency, but Sinks are typically asynchronous (`Future<void>`) to perform I/O without blocking the UI isolate.
