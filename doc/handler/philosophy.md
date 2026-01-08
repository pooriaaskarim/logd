# Handler Design Philosophy

## Composition Over Inheritance

The Handler module uses composition rather than class hierarchies to combine processing stages.

**Implementation**: A `Handler` is a container that orchestrates independent components:
- Filters (decision logic)
- Formatter (serialization)
- Decorators (transformation)
- Sink (output destination)

**Benefit**: Developers can combine behaviors without creating subclasses. For example, `Handler(formatter: JsonFormatter(), sink: FileSink(...))` creates a JSON-to-file handler without defining a `JsonFileHandler` class.

## Separation of Concerns

Each pipeline stage has a single responsibility:

| Component | Responsibility | Input | Output |
|-----------|---------------|-------|--------|
| Filter | Accept/reject decision | LogEntry | boolean |
| Formatter | Structure serialization | LogEntry | Iterable<String> |
| Decorator | Line transformation | Iterable<String> | Iterable<String> |
| Sink | I/O operation | Iterable<String> | Future<void> |

This separation ensures components remain reusable and testable in isolation.

## Atomic Processing

Handlers process log entries as complete units rather than streaming characters. The `Iterable<String>` output from formatters represents complete lines, ensuring multi-line logs (stack traces, boxed messages) remain grouped during concurrent logging.
