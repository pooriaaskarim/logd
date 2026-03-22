# Benchmark Report: Milestone 4 (HTML Pipeline)
**Goal:** Implement the high-performance HTML log pipeline and finalize the geometric engine.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M3 Bitmasks** | 138.3 | 405.3 | 241.9 |
| **M4 HTML** | 136.3 | 411.3 | 262.1 |

## Analysis
- **Parity Achievement**: Successfully reached performance parity with the legacy system while offering vastly superior semantic capabilities.
- **HTML Overhead**: The introduction of the HTML pipeline had a negligible impact on standard text output performance.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 136.28 us.
StructuredFormatter(RunTime): 411.25 us.
ToonFormatter(RunTime): 311.43 us.
JsonFormatter(RunTime): 262.07 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 597.96 us.
PrefixDecorator(RunTime): 614.46 us.
StyleDecorator(RunTime): 444.97 us.

--- Stress Test & Profiling (10k iterations) ---
1. Raw Machine (JSON -> FileSink):
   31347 Ops/sec | p90: 38.00µs | p95: 44.00µs | p99: 67.00µs | GC Pressure: 332.00 KB/10k

2. Modern Human (Structured -> Box -> ConsoleSink):
   14224 Ops/sec | p90: 77.00µs | p95: 91.00µs | p99: 134.00µs | GC Pressure: 0.00 KB/10k

3. Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width):
   5197 Ops/sec | p90: 214.00µs | p95: 243.00µs | p99: 350.00µs | GC Pressure: 236.00 KB/10k
```
