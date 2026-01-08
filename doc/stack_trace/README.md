# Stack Trace Module

The Stack Trace module provides utilities for parsing, filtering, and refining stack trace information during logging events.

## capabilities

1. **Caller Extraction**: Identifying the precise class, method, and line number where a log event originated.
2. **Frame Filtering**: Removing irrelevant frames (e.g., internal library calls from `logd` or `flutter`) to expose the relevant user code.
3. **Serialization**: Converting stack traces into structured formats for processing.

## Configuration

The behavior of this module is primarily controlled via the `StackTraceParser` configuration object, which can be applied to Loggers via `Logger.configure()`.
