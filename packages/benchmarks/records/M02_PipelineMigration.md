# Benchmark Report: Milestone 2 (Pipeline Migration)
**Goal:** Fully decouple the Pipeline using the `LogDocument` semantic IR.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **M1 Semantic** | 198.4 | 569.5 | 274.1 |
| **M2 Migration** | 147.5 | 478.7 | 268.1 |

## Analysis
- **Decoupling gains**: Moving from a brittle, combined pipeline to a decoupled `LogDocument` flow allowed for better compiler optimization.
- **Consistent results**: All formatters saw a reduction in overhead as the pipeline logic was streamlined.

## Raw Output
```text
--- Formatter Throughput ---
PlainFormatter(RunTime): 147.45 us.
StructuredFormatter(RunTime): 478.71 us.
ToonFormatter(RunTime): 294.82 us.
JsonFormatter(RunTime): 268.10 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 542.75 us.
PrefixDecorator(RunTime): 555.84 us.
```
