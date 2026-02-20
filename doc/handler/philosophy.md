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
| Formatter | Semantic serialization | LogEntry | LogDocument |
| Decorator | Document transformation | LogDocument | LogDocument |
| Encoder | Physical serialization | LogDocument | T (String/Map/etc) |
| Sink | I/O operation | T | Future<void> |

This separation ensures components remain reusable and testable in isolation.

## Token-Efficient Communication (AI Agents)

One of our core goals is to bridge the gap between human developers and AI agents (LLMs). 
- **TOON (Token-Oriented Object Notation)**: By providing specialized formatters like `ToonFormatter`, we minimize the token cost of streaming logs into LLMs while maintaining structural integrity. Unlike JSON, which repeats keys for every entry, TOON emits a header once and thereafter only tiny rows of data.

## The Zero-Bypass Principle (Performance)

A common issue in logging libraries is the hidden cost of "doing nothing"—the overhead of a disabled `debug()` call. `logd` addresses this through two primary mechanisms:

1. **Early Filtering**: Filters are the first stage of the `Handler` pipeline. If a level is disabled, the execution stops before any string interpolation, formatting, or object allocation occurs in the handler.
2. **Inheritance Freezing**: By calling `logger.freezeInheritance()`, you "bake" the current resolved configuration into a logger instance. This eliminates the O(N) cost of walking up the hierarchy tree on every log call, reducing it to a single O(1) cache lookup.

## Semantic Decoupling (Intent vs. Presentation)

Traditional logging libraries often bake styling or transport-encoding directly into the formatter (e.g., `JsonWithColors()`). This leads to "styling leakage" and architecture bloat: your JSON logic now knows about ANSI escape codes or HTTP batching rules.

**Our Approach**: We separate **Intent**, **Presentation**, and **Encoding**.
- **Intent (LogFormatter)**: Emits a `LogDocument` containing semantic nodes (e.g., `MapNode`).
- **Standard Vocabulary (LogTag)**: A shared "language" that all components speak.
- **Presentation (StyleDecorator)**: Injects platform-agnostic styles into nodes.
- **Encoding (LogEncoder)**: Performs the final conversion to physical bits (ANSI, JSON, TOON).

This ensures that your formatting logic remains pure and your presentation logic remains flexible. Switching from a `StructuredFormatter` to a `ToonFormatter` won't break your visual cues because both use the same semantic tags. Furthermore, the same `ToonFormatter` output can be shipped as an ANSI-colored stream to a console or as a raw TOON row to a network socket, simply by swapping the **Encoder**.

## Medium-Centric Sinks

Sinks are designed around the **Medium** (Console, File, Socket, HTTP), not the format. This means a single `HttpSink` can send JSON to an ELK stack or TOON to a real-time monitor by simply being paired with the appropriate `LogEncoder`.

This inversion of control removes code duplication and makes the entire pipeline protocol-agnostic.

## Unified Layout Sovereignty

Log layout is notoriously fragile, especially when mixing structural framing (like ASCII boxes) with content-aware styling (like ANSI escape codes). To guarantee visual stability, `logd` adheres to **Unified Layout Sovereignty**.

**The Principle**: The orchestration layer (the `Handler`) owns the authoritative layout constraints.

- **The Problem with Decentralized Wrapping**: If formatters or decorators wrap content independently, they lack global context. This inevitably leads to line-length overflows, corrupted borders, and inconsistent indentation.
- **The Solution**: Layout is deferred to the final **Encoding** stage. The `LogEncoder` (via `TerminalLayout`) calculates the exact spatial capacity once per entry, performing high-fidelity wrapping only when the final physical protocol (ANSI, HTML, etc.) is known.

By centralizing strictly defined constraints (`availableWidth`, `contentLimit`), we ensure that whether you are logging a simple string or a deeply nested JSON object, the output remains structurally sound and visually aligned across all terminal environments.

## Atomic Processing

Handlers process log entries as complete units rather than streaming characters. The `Iterable<LogLine>` output from formatters represents complete lines, ensuring multi-line logs (stack traces, boxed messages) remain grouped during concurrent logging. This prevents "log interleaving" where lines from different loggers mix together in the output sink.
