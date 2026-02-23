---
trigger: always_on
---

# Architectural Integrity (Logd)

To maintain the long-term stability of the `logd` handler architecture, adhere to these constraints during refactors:

## 1. Semantic vs Physical Boundary
- **Formatters** and **Decorators** must operate strictly on the **Semantic IR** (`LogDocument`, `LogNode`). They should never perform terminal width calculations or direct string rendering.
- **TerminalLayout** is the sole authority on **Physical Layout**. It handles wrapping, TAB-stops, and ANSI segment slicing.

## 2. Performance Safeguards
- **Recursion Limits**: Always check `LogNode.flatten` logic and `LogDocument` traversal for potential infinite recursion when introducing new node types.
- **Throughput Verification**: Any change to `TerminalLayout` or the core bitmask logic REQUIRES a verification run via the `benchmarks` suite to ensure no `>5%` throughput regression.

## 3. Stability
- Never modify a component's behavior without first performing a `view_code_item` on its existing implementation and adjacent tests to fully understand its invariants.
