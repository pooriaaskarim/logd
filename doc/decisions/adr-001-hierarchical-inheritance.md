# ADR-001: Hierarchical Configuration Inheritance

## Status
Accepted

## Context
Loggers in large applications are organized into hierarchical namespaces separated by dots (e.g., `app.services.database`). Developers need a way to configure logging behavior (like log level, stack trace limits, and handlers) globally or for specific sub-trees without configuring every single logger instance manually.

## Decision
We implement a hierarchical configuration inheritance system where:
1. Every logger inherits its settings from the nearest ancestor in the namespace hierarchy that has an explicit configuration.
2. The root of the tree is the `global` logger, which acts as the ultimate fallback.
3. Configuration resolution is evaluated lazily on demand.
4. Loggers can be "frozen" in inheritance, meaning their configuration is copy-instantiated from their parents at that point in time, and subsequent parent updates do not dynamically propagate down to them. They can also be "unfrozen" to resume dynamic updates.

## Consequences
- **Pros**: Minimal configuration boilerplate; flexible runtime overrides for targeted namespace debugging (e.g. enabling verbose logging only on `app.services.database`).
- **Cons**: Resolving parameters through parent chains dynamically has lookup overhead. This is mitigated via caching (see [ADR-002](adr-002-cache-invalidation.md)).
