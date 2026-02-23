# Benchmark Report: Semantic Migration Complete

**Date:** Feb 2026
**Description:** Phase F Migration Complete. Verified perfectly flat MultiSink scaling and native semantic throughput.

## Results

```
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 198.4088291746641 us.
StructuredFormatter(RunTime): 569.47 us.
ToonFormatter(RunTime): 488.11825 us.
JsonFormatter(RunTime): 274.1113949923352 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 574.5892425088405 us.
PrefixDecorator(RunTime): 566.8758832565284 us.
StyleDecorator(RunTime): 364.05165326184095 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 13.802505086222025 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 94.06137854225962 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 8.616517979352526 us.
MultiSink (x2)(RunTime): 8.529930587586765 us.
MultiSink (x4)(RunTime): 8.562075173255687 us.
==============================
Benchmarks Complete.
```
