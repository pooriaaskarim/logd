# Logger Module

The Logger module is the core of `logd`, implementing the hierarchical logger system, configuration management, and resolution logic.

## Responsibilities

1. **Logger Instantiation**: Factory pattern via `Logger.get(name)` for retrieving loggers
2. **Hierarchical Configuration**: Dot-separated naming with parent-child inheritance
3. **Configuration Resolution**: Lazy resolution and caching of effective settings
4. **Log Dispatch**: Processing log calls and routing entries to handlers

## Core Concepts

### Hierarchy
Loggers form a tree structure where children inherit configuration from parents:
```
global
└── app
    ├── app.network
    │   └── app.network.http
    └── app.ui
```

### Sparse Configuration
Only explicitly set values are stored. `null` indicates inheritance from parent.

### Caching
Resolved configurations are cached for O(1) access. Cache invalidation uses version-based tracking.

## API Overview

- `Logger.get(name)`: Retrieve or create logger
- `Logger.configure(name, ...)`: Set configuration for a logger and its descendants
- `logger.info()`, `logger.error()`, etc.: Log methods
- `logger.freezeInheritance()`: Lock configuration for performance optimization

## Documentation

- [Design Philosophy](philosophy.md) - Core principles and rationale
- [Architecture](architecture.md) - Internal implementation details
- [Roadmap](roadmap.md) - Planned improvements and known issues
