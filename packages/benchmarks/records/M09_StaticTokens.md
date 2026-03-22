# Benchmark Report (Milestone 9)
**Goal:** Static Token Streaming & Fast Paths
**Status:** Completed

## Results Summary
| Scenario | Baseline (M8) | M9 | Change |
| :--- | :--- | :--- | :--- |
| **Modern Human** (Ops/sec) | 10477 | 14114 | **+34.71%** |
| **Raw Machine** (Ops/sec) | 25980 | 27596 | **+6.22%** |
| **GC Pressure** (Modern) | 188.00 KB | 188.00 KB | 0.00% |

## Analysis
- **Modern Human Breakthrough**: The 35% gain is massive. It validates the impact of bypassing the word-wrapping engine for standard messages and reusing constant `StyledText` tokens via `RenderTokens`.
- **Raw Machine**: Recovered from the slight M8 dip and gained another 6%, likely due to `addToken` reducing encoding overhead.
- **GC Pressure**: Remaining flat despite throughput gains confirms that we've isolated the remaining churn to message-specific strings, effectively "pooling" the structural overhead.
- **Stability**: Verified with full regression suite. Golden test gaps were resolved by restoring coherent level tokens.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 135.6843138496612 us.
StructuredFormatter(RunTime): 305.81793842034807 us.
ToonFormatter(RunTime): 280.1310219994431 us.
JsonFormatter(RunTime): 242.1135865595325 us.
JsonPrettyFormatter(RunTime): 548.137 us.
MarkdownFormatter(RunTime): 128.43356932153392 us.

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
14114 Ops/sec | p90: 77.00µs | p95: 90.00µs | p99: 131.00µs | GC Pressure: 188.00 KB/10k
```
