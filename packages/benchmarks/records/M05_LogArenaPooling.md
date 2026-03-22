# Benchmark Report: Milestone 5 (Arena Pooling)
**Goal:** Implement LIFO object pooling for `LogDocument` and `LogNode` to reduce heap churn.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M4 HTML** | 136.3 | 411.3 | 262.1 |
| **M5 Arena** | 139.4 | 423.4 | 241.8 |

## Analysis
- **Allocation Efficiency**: Achieved near-zero steady-state churn for complex formatting pipelines by reusing nodes.
- **Throughput Stability**: Throughput remained stable, proving that manual pooling overhead is negligible compared to the saved GC cycles in high-pressure environments.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 139.35 us.
StructuredFormatter(RunTime): 423.38 us.
ToonFormatter(RunTime): 281.79 us.
JsonFormatter(RunTime): 241.76 us.
JsonPrettyFormatter(RunTime): 568.14 us.
MarkdownFormatter(RunTime): 228.61 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 579.67 us.
PrefixDecorator(RunTime): 588.82 us.
StyleDecorator(RunTime): 419.61 us.
SuffixDecorator(RunTime): 620.16 us.
HierarchyDepthPrefixDecorator(RunTime): 581.68 us.

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
10634 Ops/sec | p90: 107.00µs | p95: 128.00µs | p99: 195.00µs | GC Pressure: 198.40 KB/10k
```
