# Benchmark Report: Legacy System Baseline

**Date:** Feb 2026
**Description:** Phase 0 Baseline Research. Performance before the semantic document IR migration.

## Results

```
Running Baseline Benchmarks (Legacy System)...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 276.5 us.
StructuredFormatter(RunTime): 467.3 us.
ToonFormatter(RunTime): 319.6 us.
JsonFormatter(RunTime): 26.3 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 157.0 us.
PrefixDecorator(RunTime): 1.9 us.
StyleDecorator(RunTime): 13.0 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 930.2 us.
Complex Pipeline (Structure+Box+Style+Prefix)(RunTime): 1738.7 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 460.5 us.
MultiSink (x2)(RunTime): 484.1 us.
MultiSink (x4)(RunTime): 508.1 us.
==============================
Benchmarks Complete.
```
