# Benchmark Report: Milestone 7 (In-Place Refinements)
**Goal:** Finalize the handler refinements and resolve redundant newlines and buffer copies.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M6 Stream** | 164.8 | 438.8 | 275.1 |
| **M7 Refactor** | 145.0 | 421.1 | 263.8 |

## Analysis
- **Refinement Recovery**: Reclaimed most of the performance lost in M6 by streamlining the `EncodingSink` and removing redundant `BytesBuilder` copies.
- **Benchmark Consistency**: Standardized the delimiter logic, ensuring benchmark results accurately reflect production I/O behavior.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 145.04 us.
StructuredFormatter(RunTime): 421.14 us.
ToonFormatter(RunTime): 306.15 us.
JsonFormatter(RunTime): 263.76 us.

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
10005 Ops/sec | p90: 127.00µs | p95: 174.00µs | p99: 218.00µs | GC Pressure: 187.20 KB/10k
```
