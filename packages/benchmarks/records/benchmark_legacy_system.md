# Comprehensive Benchmark State
**Branch:** feat/handler_refinements

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 153.33274336283185 us.
StructuredFormatter(RunTime): 452.09679543459174 us.
ToonFormatter(RunTime): 293.9665093621556 us.
JsonFormatter(RunTime): 258.5836887682564 us.
JsonPrettyFormatter(RunTime): 617.5512367491166 us.
MarkdownFormatter(RunTime): 244.62863534675614 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 625.35975 us.
PrefixDecorator(RunTime): 803.771 us.
StyleDecorator(RunTime): 530.567 us.
SuffixDecorator(RunTime): 653.75425 us.
HierarchyDepthPrefixDecorator(RunTime): 622.35475 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 9.560222785255693 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 60.56769517223035 us.
JsonPretty Pipeline(RunTime): 130.6782765737874 us.
Markdown Pipeline(RunTime): 5.7952975 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 7.286255854344753 us.
MultiSink (x2)(RunTime): 7.202182045090399 us.
MultiSink (x4)(RunTime): 7.261359673300408 us.
==============================
Benchmarks Complete.
```
