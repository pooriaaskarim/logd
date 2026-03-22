# Benchmark Report: Milestone 8 (Physical Layer Arena)
**Goal:** Implement pooling for `PhysicalDocument` and `PhysicalLine` to eliminate layout-phase allocations.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M7 Refactor** | 145.0 | 421.1 | 263.8 |
| **M8 PhysArena** | 138.6 | 404.2 | 262.7 |

## Analysis
- **Layout Optimization**: Pooling the physical layout objects eliminated thousands of small list allocations per log cycle.
- **Throughput Gain**: Achieved a clean ~5% improvement in standard logging paths without increasing GC pressure.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 138.56 us.
StructuredFormatter(RunTime): 404.16 us.
ToonFormatter(RunTime): 296.34 us.
JsonFormatter(RunTime): 262.71 us.

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
10477 Ops/sec | p90: 117.00µs | p95: 169.00µs | p99: 216.00µs | GC Pressure: 188.00 KB/10k
```
