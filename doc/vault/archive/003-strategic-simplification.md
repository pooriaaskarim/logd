# ADR 003: Strategic Simplification

## Context
Following the exploration into LIFO object pooling (the `arena_refinement` branch), we observed that manual memory management introduced significant complexity and several subtle performance "taxes" (e.g., the UTF-8 tax on segmental writes). This was previously documented in [ADR 002](file:///home/ono/Projects/logd/doc/vault/archive/002-the-arena-paradox.md).

## Decision
We have decided to **revert the core logging pipeline to the Dart VM's Native Garbage Collector**.

## Rationale
This is an act of **Strategic Simplification**. 
- **Reclaiming Spaciousness**: By removing the mandatory Arena boundary for all logs, we restore "Creation Comfort." Developers can add features, new node types, and complex metadata without managing life-cycles manually.
- **Strategic Reserve**: We do not discard the LIFO pooling research. Instead, we preserve it as a "Mechanical Reserve." It is an exoskeleton that remains dormant, ready to be engaged only when specific "Pressure Thresholds" are crossed.
- **Environmental Alignment**: For most use cases, the Dart VM GC is the most efficient and quietest path. We align with the environment rather than fighting it.

## Consequences
- **Positive**: Improved developer velocity; more idiomatic Dart code; lower maintenance overhead.
- **Negative**: Temporary loss of absolute memory determinism in high-pressure bursts (until the Mechanical Reserve is triggered).

---
*Status: Accepted*
*Date: 2026-02-25*
