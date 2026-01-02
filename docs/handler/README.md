# Handler Module

The Handler module is responsible for the final stage of the logging pipeline: processing, formatting, and outputting log entries.

## Responsibilities

A `Handler` encapsulates two distinct operations:
1. **Formatting**: Transforming a structured `LogEntry` into a serialized format (String, JSON, etc.).
2. **Output**: Writing the serialized data to a destination (Console, File, Network).

## Components

### Formatters
- `BoxFormatter`: Wraps logs in a visual box for readability (default).
- `JsonFormatter`: Serializes logs to JSON for machine parsing.
- `PlainFormatter`: Simple text output.

### Sinks
- `ConsoleSink`: Writes to standard output (`stdout`).
- `FileSink`: Writes to the local filesystem. Supports rotation strategies.
- `MultiSink`: multiplexes output to multiple sinks.

## Contribution
Documentation for independent Formatters and Sinks is currently being expanded. Please refer to the source code in `lib/src/handler/` for implementation details.
