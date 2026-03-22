# Performance: Memory Management Strategies

In our state of "Strategic Elasticity," we maintain multiple strategies for managing memory pressure. These reside in our "Mechanical Reserve," ready to be engaged as the environment demands.

## Strategy A: LIFO Pooling (The Arena)
*Status: Active (Integrated)*

### Summary
Introduced in the `arena_refinement` branch and refined through Milestone 8, this strategy uses a manual stack-based allocator for `LogDocument`, `LogNode`, `PhysicalDocument`, and `PhysicalLine` objects. It drastically reduces heap churn by reusing the entire layout tree across log cycles.

### Findings
- **Milestone 8 Success**: By pooling the physical layer, we eliminated intermediate list and line allocations, achieving a ~5% throughput gain in standard logging paths.
- **Isolate Safety**: The arena is strictly isolate-local, ensuring zero-contention pooling.
- **Reference**: [M08: Physical Layer Arena](../../packages/benchmarks/records/M08_PhysicalArena.md)

## Strategy B: Off-Heap Autonomy (FFI/C)
*Status: Research Frontier*

### Summary
Proposed research into using `dart:ffi` for absolute memory isolation. By allocating buffers and nodes in C-land, we bypass the Dart GC entirely.

### Objective
This strategy is reserved for extreme high-pressure bursts where even a generational scavenger might induce frame drops. It represents the ultimate level of memory determinism.

## The Default: Organic GC
*Status: Active (Default Path)*

### Summary
The Dart VM's native garbage collector remains our primary engine. We align with the environment, prioritizing code simplicity and "Creation Comfort" until pressure thresholds are crossed.
- **Reference**: [ADR 003: Strategic Simplification](../archive/003-strategic-simplification.md)
