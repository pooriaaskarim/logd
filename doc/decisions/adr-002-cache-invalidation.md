# ADR-002: Version-Based Cache Invalidation via Descendants Index

## Status
Accepted

## Context
Resolving configuration overrides dynamically up the parent chain has a lookup complexity of $O(d)$ where $d$ is hierarchy depth. In high-frequency logging loops, repeating this walk for every log entry introduces unacceptable latency. While caching resolved configurations solves the lookup overhead, updating any logger config in the hierarchy requires invalidating the caches of all affected descendants. A linear scan of the cache during invalidation scales poorly to large numbers of loggers.

## Decision
We implement a version-based cache invalidation system backed by an in-memory descendants index:
1. Every resolved configuration is cached in `LoggerCache._cache`.
2. When a logger is accessed, its ancestry is scanned, and it is registered in `LoggerCache._descendants` as a descendant of each ancestor.
3. Cache invalidations map the modified logger namespace to all its cached descendants in $O(m)$ time (where $m$ is the number of descendants) rather than scanning the entire cache.
4. We support single-pass bulk invalidations (`LoggerCache.invalidateMultiple`) to avoid redundant walk cycles on multi-logger configurations.

## Consequences
- **Pros**: Resolved configuration lookup is a fast $O(1)$ cache hit. Cache invalidation latency is minimized, avoiding regressions during bulk configurations.
- **Cons**: Minor memory overhead to store the reverse-index list/set of descendant logger names.
