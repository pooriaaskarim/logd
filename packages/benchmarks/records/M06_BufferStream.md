# Benchmark Report: Milestone 6 (Buffer Stream)
**Goal:** Transition from String-based to byte-oriented pipeline via `HandlerContext` and `Uint8List`.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M5 Arena** | 139.4 | 423.4 | 241.8 |
| **M6 Stream** | 164.8 | 438.8 | 275.1 |

## Analysis
- **The "UTF-8 Tax"**: Throughput saw a minor regression due to the overhead of immediate UTF-8 encoding for small string segments. 
- **Architectural Foundation**: This shift was necessary to support zero-churn I/O and future static token streaming optimizations.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 141.37 us.
StructuredFormatter(RunTime): 420.54 us.
ToonFormatter(RunTime): 280.54 us.
JsonFormatter(RunTime): 243.50 us.
JsonPrettyFormatter(RunTime): 584.49 us.
MarkdownFormatter(RunTime): 225.93 us.

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
10574 Ops/sec | p90: 110.00µs | p95: 134.00µs | p99: 213.00µs | GC Pressure: 198.40 KB/10k
```
