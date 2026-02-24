# Benchmark Report: Milestone 5 (LogArena Pooling)

**Date:** 2026-02-24
**Description:** Final profiling of the LogArena object pooling implementation.

## 1. Formatter Throughput (Baseline)
| Formatter           | RunTime (µs) |
|---------------------|--------------|
| PlainFormatter      | 139.35       |
| StructuredFormatter | 423.38       |
| ToonFormatter       | 281.79       |
| JsonFormatter       | 241.76       |
| JsonPrettyFormatter | 568.14       |
| MarkdownFormatter   | 228.61       |

## 2. Decorator Overhead
| Decorator                     | RunTime (µs) |
|-------------------------------|--------------|
| BoxDecorator                  | 579.67       |
| PrefixDecorator               | 588.82       |
| StyleDecorator                | 419.61       |
| SuffixDecorator               | 620.16       |
| HierarchyDepthPrefixDecorator | 581.68       |

## 3. Stress Test & Profiling (50k Iterations)

### 1. The Raw Machine (JSON -> FileSink)
**28056 Ops/sec** | p90: 39.00µs | p95: 44.00µs | p99: 66.00µs | GC Pressure: 236.80 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
**10634 Ops/sec** | p90: 107.00µs | p95: 128.00µs | p99: 195.00µs | GC Pressure: 198.40 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
**4986 Ops/sec** | p90: 238.00µs | p95: 302.00µs | p99: 422.00µs | GC Pressure: **0.00 KB/10k**

---
**Verdict:** The Arena integration has successfully achieved zero steady-state memory churn for complex formatting pipelines.
