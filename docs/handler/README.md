# Handler Module

The Handler module is responsible for the final stage of the logging pipeline: processing, formatting, and outputting log entries.

## Responsibilities

A `Handler` encapsulates two distinct operations:
1. **Formatting**: Transforming a structured `LogEntry` into a serialized format (String, JSON, etc.).
2. **Output**: Writing the serialized data to a destination (Console, File, Network).

## Components

### Formatters
- `StructuredFormatter`: Detailed layout (header, origin, message) without borders. **(New)**
- `BoxFormatter`: Wraps logs in a visual box. **(Deprecated - use StructuredFormatter + BoxDecorator)**
- `JsonFormatter`: Serializes logs to JSON for machine parsing.
- `PlainFormatter`: Simple text output.

### Decorators
- `BoxDecorator`: Adds ASCII borders around formatted lines. **(New)**
- `AnsiColorDecorator`: Adds level-based coloring.

### Sinks
- `ConsoleSink`: Writes to standard output (`stdout`).
- `FileSink`: Writes to the local filesystem. Supports rotation strategies.
- `MultiSink`: multiplexes output to multiple sinks.

## Composition

The power of the Handler module lies in its composability. You can chain decorators to achieve complex output:

```dart
Handler(
  formatter: StructuredFormatter(),
  decorators: [
    BoxDecorator(borderStyle: BorderStyle.double),
    AnsiColorDecorator(),
  ],
  sink: ConsoleSink(),
)
```

For detailed rules on how decorators interact, see [Decorator Composition](decorator_composition.md).

## Contribution
Documentation for independent Formatters and Sinks is currently being expanded. Please refer to the source code in `lib/src/handler/` for implementation details.
