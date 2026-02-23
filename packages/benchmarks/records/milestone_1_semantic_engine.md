# Benchmark Report: Milestone 1 (Core Semantic Engine)

**Commit:** cc3f7ad
**Date:** 2026-02-24
**Description:** Initial introduction of `LogDocument` semantic IR and `TerminalLayout` geometric engine.

## Results

```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 198.40 us.
StructuredFormatter(RunTime): 569.47 us.
ToonFormatter(RunTime): 488.11 us.
JsonFormatter(RunTime): 274.11 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 574.58 us.
PrefixDecorator(RunTime): 566.87 us.
```

> [!NOTE]
> This record represents the first stable state of the semantic migration. Throughput is lower than the legacy system in some areas (like JSON) due to the new geometric metadata tracking, but higher in others (like Plain) due to the optimized layout engine.
