# ADR-003: Sparse Configuration Storage

## Status
Accepted

## Context
In a large application with thousands of loggers, storing complete configurations for every instantiated logger consumes unnecessary memory. In most cases, only a few sub-trees need specific overrides (e.g., lower level for a database module), while everything else follows the global defaults.

## Decision
We implement a sparse storage model for logger configurations:
1. `Logger` instances hold only a reference to their name and resolve settings on-the-fly via a centralized registry.
2. The config registry (`Logger._registry`) stores configurations only for loggers that have been explicitly configured via `Logger.configure`.
3. Unconfigured loggers do not occupy entries in the explicit configuration registry and dynamically resolve properties up their ancestor chain.
4. Materialized configurations (resolved from parent inheritance) are stored inside `LoggerCache._cache` only when actually accessed, allowing cold paths to remain allocation-free.

## Consequences
- **Pros**: Minimal memory footprint for unconfigured/unused logger namespaces. Clean separation of configuration storage and logger access.
- **Cons**: Configuration resolution becomes a lookup operation rather than direct property reading, which is mitigated via caching.
