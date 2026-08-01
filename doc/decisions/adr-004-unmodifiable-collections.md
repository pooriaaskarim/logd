# ADR-004: Unmodifiable Resolved Collections

## Status
Accepted

## Context
When resolving logger configurations (such as lists of `Handler`s or `stackMethodCount` maps), descendant loggers merge or inherit collections from their ancestors. If these inherited collections are mutable, descendants or external consumers could accidentally modify the configuration of parent loggers, leading to critical runtime side effects and broken configuration encapsulation.

## Decision
We enforce unmodifiable collections for all resolved configuration properties:
1. Resolved maps (e.g. `stackMethodCount`) are wrapped in `UnmodifiableMapView`.
2. Resolved lists (e.g. `handlers`) are wrapped in `List.unmodifiable` during the resolution walk.
3. Immutability checks are run in tests to ensure that attempting to modify resolved lists/maps throws a `UnsupportedError`.

## Consequences
- **Pros**: Complete encapsulation and runtime safety. Changes to ancestor configurations are guaranteed not to be corrupted by descendant overrides.
- **Cons**: Minor overhead of wrapping collections during slow-path cache resolution, which is mitigated since it only runs once per cache miss.
