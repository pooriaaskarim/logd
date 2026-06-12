# Phase 2: LogEntry Pooling Optimization
**Commit:** 0d14f22 feat(engine): complete Phase 1 - zero-latency native offload
**Branch:** feat/ffi-binary-ir
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

```text
The Dart VM service is listening on http://127.0.0.1:8181/0xHpuAmcZJg=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/0xHpuAmcZJg=/devtools/?uri=ws://127.0.0.1:8181/0xHpuAmcZJg=/ws
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 171.30807715094463 us.
StructuredFormatter(RunTime): 355.5109243697479 us.
ToonFormatter(RunTime): 260.91572961096034 us.
JsonFormatter(RunTime): 319.6934576434657 us.
JsonPrettyFormatter(RunTime): 647.6775 us.
MarkdownEncoder(RunTime): 103.93580605420627 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 578.44675 us.
PrefixDecorator(RunTime): 684.419 us.
StyleDecorator(RunTime): 12.170026234881943 us.
SuffixDecorator(RunTime): 619.91475 us.
HierarchyDepthPrefixDecorator(RunTime): 561.6856330014225 us.

--- Pipeline Throughput ---
FullPipeline(RunTime): 55.409761936427714 us.
ArenaFullPipeline(RunTime): 62.312736498108016 us.
ManualPipeline(RunTime): 576.6974576271186 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 13.765695788673161 us.
MultiSink (x2)(RunTime): 13.65210025042356 us.
MultiSink (x4)(RunTime): 14.238191189948456 us.

--- Phase 1: Native Offload Scaling (10k iterations) ---
[logd-internal] [WARNING]: Arena saturation reached (200 packets). Blocking main thread.
NativeEngineOffload (Phase 1): 44.22 us/op

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
Profiling: Raw Machine ...
14543 Ops/sec | p90: 88.00µs | p95: 101.00µs | p99: 132.00µs | GC Pressure: 0.00 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
Profiling: Modern Human ...
7324 Ops/sec | p90: 160.00µs | p95: 193.00µs | p99: 252.00µs | GC Pressure: 36020.80 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
Profiling: Framing Squeeze ...
2707 Ops/sec | p90: 455.00µs | p95: 554.00µs | p99: 841.00µs | GC Pressure: 41858.40 KB/10k


--- Structural Efficiency Report ---
Warming up Arena (2,000 entries)...
Resetting VM Service allocation accumulators...
Logging 10,000 entries (Arena Active)...

Final Arena Pool Size: 2091021

Class Allocations during 10,000 logs:
-------------------------------------
HeaderNode     : 306001 objects |  9792032 bytes
MessageNode    : 102000 objects |  3264000 bytes
FillerNode     : 306000 objects | 14688000 bytes
MapNode        :  51000 objects |  1632000 bytes
BoxNode        : 102000 objects |  4896000 bytes
IndentationNode: 255000 objects | 12240000 bytes
DecoratedNode  : 408000 objects | 45696000 bytes
ParagraphNode  : 102000 objects |  3264000 bytes
RowNode        : 306000 objects |  9792000 bytes
StyledText     : 445036 objects | 14241152 bytes
-------------------------------------
⚠️ WARNING: Identified leak of 105264032 bytes (105264032 total bytes) in Arena-managed classes.
This might be due to cold-start pool expansion or VM-internal allocations.
Bytes Allocated per log event (Structural): 10526.4032 bytes/log
==============================
Benchmarks Complete.
