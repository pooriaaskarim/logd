# Benchmark Report: Milestone 2 (Pipeline Migration)

**Commit:** 7ed89d8
**Date:** 2026-02-24
**Description:** Fully decoupled Pipeline using the `LogDocument` semantic IR. Metrics captured prior to bitmask optimization.

## Results

```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 147.45 us.
StructuredFormatter(RunTime): 478.71 us.
ToonFormatter(RunTime): 294.82 us.
JsonFormatter(RunTime): 268.10 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 542.75 us.
PrefixDecorator(RunTime): 555.84 us.
```

> [!NOTE]
> This record was recovered from the `benchmark_pre_bitmask.md` baseline captured during the migration phase. It represents the architectural state before bitwise optimizations.
