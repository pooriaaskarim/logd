# Logd Engine Stability & Performance Report

An architectural assessment and performance profiling of the three core log execution engines in `logd`: **Standard**, **Arena**, and **Native (FFI)**.

---

## 1. Engine Architecture & Memory Lifecycles

### I. Standard Engine (Managed GC)
> Focuses on simplicity and ease of debugging. Every log cycle relies on the Dart VM garbage collector.

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'textColor': '#ffffff', 'lineColor': '#4fc3f7' }}}%%
graph TD
    S_Entry["LogEntry (Input)"] --> S_Form["Formatter (Produces AST)"]
    S_Form --> S_Doc["LogDocument (Allocated on Dart Heap)"]
    S_Doc --> S_Layout["TerminalLayout (Calculates Wrapping/Borders)"]
    S_Layout --> S_Enc["AnsiEncoder (Formats String)"]
    S_Enc --> S_Sink["ConsoleSink / FileSink (I/O)"]
    S_Sink --> S_GC["Dart VM Garbage Collector (Reclaims Heap)"]

    classDef std fill:#0d47a1,stroke:#4fc3f7,stroke-width:2.5px,color:#ffffff;
    class S_Entry,S_Form,S_Doc,S_Layout,S_Enc,S_Sink,S_GC std;
```

---

### II. Arena Engine (Object Pool)
> Focuses on zero main-thread allocations. Reuses memory using an isolate-local LIFO pool.

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'textColor': '#ffffff', 'lineColor': '#81c784' }}}%%
graph TD
    A_Entry["LogEntry (Input)"] --> A_Checkout["Checkout Recycled Nodes from Arena"]
    A_Checkout --> A_Form["Formatter (Populates Recycled Nodes)"]
    A_Form --> A_Doc["Recycled LogDocument"]
    A_Doc --> A_Layout["TerminalLayout (Calculates Wrapping/Borders)"]
    A_Layout --> A_Enc["AnsiEncoder (Formats String)"]
    A_Enc --> A_Release["Reset & Recycle Tree Nodes to Arena Pool"]

    classDef arena fill:#1b5e20,stroke:#81c784,stroke-width:2.5px,color:#ffffff;
    class A_Entry,A_Checkout,A_Form,A_Doc,A_Layout,A_Enc,A_Release arena;
```

---

### III. Native Engine (FFI / Isolate Offload)
> Focuses on maximum throughput. Offloads formatting, wrapping, and I/O to background C/Isolate layers.

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'textColor': '#ffffff', 'lineColor': '#e57373' }}}%%
graph TD
    N_Entry["LogEntry (Input)"] --> N_Form["Formatter (Populates AST Nodes)"]
    N_Form --> N_Writer["BinaryIRWriter (Serializes to Binary IR)"]
    N_Writer --> N_Buf["Contiguous Native Buffer (FFI C-Heap)"]
    N_Buf --> N_Off["Background Isolate Worker"]
    N_Off --> N_Enc["BinaryAnsiEncoder (Decodes, Wraps, Colorizes)"]
    N_Enc --> N_Free["Native Memory Release (Frees C-Heap Pointer)"]

    classDef native fill:#7f1d1d,stroke:#f87171,stroke-width:2.5px,color:#ffffff;
    class N_Entry,N_Form,N_Writer,N_Buf,N_Off,N_Enc,N_Free native;
```

---

## 2. Engine Scorecard

| Metric | `StandardEngine` | `ArenaEngine` | `NativeEngine` |
| :--- | :---: | :---: | :---: |
| **Stability** | 🟢 **Excellent** | 🟢 **High / Stable** | 🟢 **High / Stable** |
| **Memory Model** | Managed VM Heap | LIFO Object Pool | Raw Native Pointers (C-Heap) |
| **Memory Safety** | 100% Guaranteed | Pool Contract Dependent | Safe (Fully Bounds-Checked) |
| **Layout Parity** | 100% (Primary Path) | 100% (Primary Path) | 🟢 **100% Parity (Verified)** |
| **GC Pressure** | High Churn | **Zero Churn** | **Zero Churn** |
| **Portability** | Universal | Universal | VM-Only (FFI) |

---

## 3. Real-Time Performance Benchmarks
*Profiled using Dart SDK 3.12.0 on Linux x64 over 10,000 iterations per scenario on a level playing field.*

### Scenario 1: Plain Text (Compact)
> High-density plain text serialization.

```
Standard  ██████████████  16,971 ops/sec (85.0µs)
Arena     ████████████████████  23,918 ops/sec (61.0µs) [FASTEST]
Native    ████████████  14,498 ops/sec (99.0µs)
```

### Scenario 2: Modern Human (Structured + Box)
> Multi-line layout styling with box borders.

```
Standard  ████████████  9,157 ops/sec (166.0µs)
Arena     █████████████  9,638 ops/sec (157.0µs)
Native    ████████████████  10,528 ops/sec (124.0µs) [FASTEST]
```

### Scenario 3: Framing Squeeze (Prefix + Box @ 40 width)
> Heavy word-wrapping and line slicing under tight width boundaries.

```
Standard  ████████  4,240 ops/sec (366.0µs)
Arena     █████████  4,815 ops/sec (266.0µs)
Native    ███████████████  6,442 ops/sec (180.0µs) [1.5x FASTEST]
```

### Scenario 4: Complex Native (TOON + Box + Nesting)
> Structured columns with decorators triggering compatibility fallback.

```
Standard  ███████████  5,248 ops/sec (231.0µs)
Arena     ████████████  5,570 ops/sec (211.0µs) [FASTEST]
Native    █████████  4,399 ops/sec (320.0µs)
```

---

## 4. Key Performance Takeaways

> [!TIP]
> **The Word-Wrapping Breakthrough (Scenario 3)**
> When terminal widths are constrained (e.g. 40 columns), word-wrapping on the Dart heap generates thousands of short-lived string allocations. By processing text wrapping and alignment at the raw byte/pointer level, `NativeEngine` runs **1.5x faster** than the Standard Engine in the main-thread serialization pipeline, and scales even higher under background isolate-offloading.

> [!WARNING]
> **The Compatibility Penalty (Scenario 4)**
> Custom serialization formats (like TOON) cannot be processed natively by `BinaryAnsiEncoder`. This forces `NativeEngine` to trigger an engine fallback, causing a double-formatting overhead that drops throughput below heap-allocation levels (4.3k ops/sec vs 5.5k ops/sec).

---

## 5. Architectural Recommendations

1. **StandardEngine is the Universal Default**:
   * Out-of-the-box compatibility across Web, Desktop, Mobile, and CLI. Fully guarantees layout parity with zero platform bindings.
2. **Opt into `ArenaEngine` for High-Throughput VM/Flutter Applications**:
   * It provides 100% layout fidelity guarantees and eliminates GC pressure on the Dart thread by using a LIFO recycler pool.
3. **Opt into `NativeEngine` for Performance-Critical VM pipelines**:
   * Fully stabilized in `v0.8.1` with 100% verified visual layout parity, `NativeEngine` can be selected as an opt-in execution strategy for native CLI and server applications. Restrict it to standard human/JSON CLI profiles to avoid double-formatting fallback rendering degradation on unsupported layouts.

