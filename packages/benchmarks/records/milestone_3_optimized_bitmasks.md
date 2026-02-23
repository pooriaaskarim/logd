# Benchmark Report: Milestone 3 (Optimized Bitmasks)

**Commit:** 788b9bb
**Date:** 2026-02-24
**Description:** First implementation of `LogTag` as an `int` bitmask to reduce object allocation and Set overhead.

## Results

```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 138.31 us.
StructuredFormatter(RunTime): 405.31 us.
ToonFormatter(RunTime): 286.08 us.
JsonFormatter(RunTime): 241.86 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 568.47 us.
PrefixDecorator(RunTime): 582.98 us.
StyleDecorator(RunTime): 411.40 us.

--- Stress Test & Profiling ---
1. Raw Machine (JSON -> FileSink):
   30654 Ops/sec | p90: 38.00µs | p95: 44.00µs | p99: 68.00µs | GC Pressure: 328.00 KB/10k

2. Modern Human (Structured -> Box -> ConsoleSink):
   14074 Ops/sec | p90: 77.00µs | p95: 86.00µs | p99: 137.00µs | GC Pressure: 0.00 KB/10k

3. Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width):
   4843 Ops/sec | p90: 236.00µs | p95: 360.00µs | p99: 389.00µs | GC Pressure: 240.00 KB/10k
```
