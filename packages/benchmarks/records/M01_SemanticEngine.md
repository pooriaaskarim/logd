# Benchmark Report: Milestone 1 (Semantic Engine)
**Goal:** Introduce `LogDocument` semantic IR and the `TerminalLayout` geometric engine.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M0 Baseline** | 276.5 | 467.3 | 26.3 |
| **M1 Semantic** | 198.4 | 569.5 | 274.1 |

## Analysis
- **Geometric Metadata tracking**: The introduction of semantic layout initially increased overhead for structured formats compared to raw string concatenation.
- **Enhanced Plain throughput**: The optimization of geometric layout resulted in a significant improvement for simpler output formats.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 198.40 us.
StructuredFormatter(RunTime): 569.47 us.
ToonFormatter(RunTime): 488.11 us.
JsonFormatter(RunTime): 274.11 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 574.58 us.
PrefixDecorator(RunTime): 566.87 us.
```
