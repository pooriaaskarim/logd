# Logger Module

The Logger module is the core of `logd`, implementing the hierarchical logger system, configuration management, and resolution logic.

## Responsibilities

- **Hierarchy Management**: Factory pattern via `Logger.get(name)` with dot-separated inheritance.
- **Lazy Resolution**: Sparse configuration storage with version-based cache invalidation (O(1) access).
- **Log Dispatch**: Implicit `LogEntry` generation and routing to the `Handler` pipeline.

## Core Concepts

### Sparse Hierarchy
Only explicit overrides are stored. `null` values signal inheritance from the nearest configured ancestor, terminating at the `"global"` root.

### Data Model Protection
The construction of `LogEntry` objects is an automated internal concern. The `LogEntry` constructor is marked **`@internal`** to preserve pipeline integrity and allow for future backend optimizations.

## API Overview

- `Logger.get(name)`: Retrieve or create logger
- `Logger.configure(name, ...)`: Set configuration for a logger and its descendants
- `logger.info()`, `logger.error()`, etc.: Primary logging interface
- `logger.freezeInheritance()`: Optimized for high-performance static configurations

> [!IMPORTANT]
> **Data Model Protection**: The construction of `LogEntry` objects is an automated internal process. The `LogEntry` constructor is marked as **`@internal`** to preserve the integrity of the logging pipeline and allow for future backend optimizations without affecting user code.

## Documentation

- [Design Philosophy](philosophy.md) - Core principles and rationale
- [Architecture](architecture.md) - Internal implementation details
- [Roadmap](roadmap.md) - Planned improvements and known issues
