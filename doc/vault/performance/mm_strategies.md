# Performance: Memory Management Strategies

In our state of "Strategic Elasticity," we maintain multiple strategies for managing memory pressure. These reside in our "Mechanical Reserve," ready to be engaged as the environment demands.

## Strategy A: LIFO Pooling (The Arena)
*Status: Preservation Mode (Mechanical Reserve)*

### Summary
Introduced in the `arena_refinement` branch, this strategy uses a manual stack-based allocator for `LogDocument` and `LogNode` objects. It reduces memory pressure by reusing objects across log cycles.

### Findings
- **The "UTF-8 Tax"**: Small, segmental byte writes incurred a high conversion cost, often outweighing the benefits of avoided allocations.
- **VM Pointer Interference**: Manual management can occasionally interfere with the Dart VM's optimized pointer-bumping allocator.
- **Reference**: [ADR 002: The Arena Paradox](../archive/002-the-arena-paradox.md)

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
