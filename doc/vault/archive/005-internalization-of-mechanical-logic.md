# ADR 005: Internalization of Mechanical Logic

## Context
As the `logd` handler architecture evolved into a byte-oriented pipeline, coordinating the physical and semantic boundaries became increasingly fragmented. 

1. **Fragmented Lifecycle**: Components were inconsistently managing `LogDocument` checkout and release.
2. **Allocation Overhead**: Formatters and Decorators were often returning new `LogDocument` objects, causing allocation churn.
3. **Delimiter Ambiguity**: Responsibility for the final record-level newline (`\n`) was split between Encoders and Sinks, leading to "doubled entry" regressions in concurrent file writes.

## Decision
We have internalized the mechanical orchestration of the logging pipeline into the `Handler` and `EncodingSink` layers:

1. **Centralized Lifecycle**: `Handler.log` now independently manages the `LogArena` checkout/release cycle. It ensures that every `LogDocument` is deterministically returned to the pool via `try-finally` blocks.
2. **In-place IR Mutation**: All `LogFormatter` and `LogDecorator` implementations have been migrated to the `void` API. They now modify the `LogDocument` IR in-place, eliminating object return overhead.
3. **Standardized Record Delimiting**: Responsibility for the final `\n` has been moved to the `EncodingSink.output` method. 

## Rationale
- **Resilience**: Centralizing the lifecycle prevents memory leaks and ensures that no third-party formatter or decorator can accidentally "leak" a document from the arena.
- **Zero-Churn**: By avoiding string concatenations and using strictly in-place byte-buffered writing (`HandlerContext`), we achieve a zero-allocation pipeline from formatting to transport.
- **Consistent Output**: Placing the record-level delimiter in the sink ensures that whether outputting to Console, File, or Network, the resulting byte stream is perfectly partitioned.

## Consequences
- **Positive**: 100% test consistency (sink_safety); significantly reduced GC pressure; cleaner, more predictable handler API.
- **Negative**: Unit tests that invoke encoders directly (e.g., `LogSnap`) must now manually account for the absence of the trailing record delimiter in the raw encoder output.

---
*Status: Accepted*
*Date: 2026-02-26*
*Supersedes: [ADR 004](004-newline-consistency.md)*
