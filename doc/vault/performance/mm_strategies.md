# Performance: Memory Management Strategies

In our state of "Strategic Elasticity," we maintain multiple strategies for managing memory pressure. These reside in our "Mechanical Reserve," ready to be engaged as the environment demands.

## Strategy A: LIFO Pooling (`ArenaEngine`)
*Status: Production Ready*

### Summary
The `ArenaEngine` utilizes an isolate-local `Arena` for deterministic object reuse. By checking out resources (documents, nodes, physical layout objects) from a pool and releasing the entire tree recursively at the end of the log cycle, it eliminates heap churn during steady-state logging.

### Performance Profile
- **Zero GC Churn**: By recycling the entire object graph, it neutralizes the pressure typically placed on the Dart generational scavenger.
- **Throughput Optimization**: Refined in Milestone 8 to include the physical layer, achieving a ~5% throughput gain in standard paths.
- **Reference**: [M08: Physical Layer Arena](../../packages/benchmarks/records/M08_PhysicalArena.md)

## Strategy B: Off-Heap Autonomy (FFI/C)
*Status: Research Frontier*

### Summary
Proposed research into using `dart:ffi` for absolute memory isolation. By allocating buffers and nodes in C-land, we bypass the Dart GC entirely.

### Objective
This strategy is reserved for extreme high-pressure bursts where even a generational scavenger might induce frame drops. It represents the ultimate level of memory determinism.

## The Default: Heap Allocation (`StandardEngine`)
*Status: Active (Default)*

### Summary
The `StandardEngine` relies on the Dart VM's native garbage collector for lifecycle management. It prioritizes implementation simplicity and "Creation Comfort," providing a robust default that aligns with the VM's inherent memory management physics.
- **Reference**: [ADR 003: Strategic Simplification](../archive/003-strategic-simplification.md)
