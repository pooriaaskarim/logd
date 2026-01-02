# Documentation Index

This directory contains detailed documentation regarding the design, architecture, and roadmap of the `logd` library.

## Logger Core
The core module handles logger instantiation, the inheritance hierarchy, and configuration resolution.

- [**Overview**](logger/README.md): Module responsibilities and API overview
- [**Philosophy**](logger/philosophy.md): Explains the design principles (Inheritance, Sparse Configuration, Lazy Resolution).
- [**Architecture**](logger/architecture.md): Technical overview of the internal registry, caching mechanisms, and data structures.
- [**Roadmap**](logger/roadmap.md): Active tracking of features, technical debt, and future plans.

## Modules

### Handler
Responsible for the processing pipeline of log entries.
- [Overview](handler/README.md)
- [Design Philosophy](handler/philosophy.md)
- [Architecture](handler/architecture.md)
- [Roadmap](handler/roadmap.md)
- [Roadmap](handler/roadmap.md)

### Time
Handles timestamp generation and timezone management.
- [Overview](time/README.md)
- [Design Philosophy](time/philosophy.md)
- [Architecture](time/architecture.md)
- [Roadmap](time/roadmap.md)

### Stack Trace
Parses and sanitizes stack traces to provide meaningful caller information.
- [Overview](stack_trace/README.md)
- [Design Philosophy](stack_trace/philosophy.md)
- [Architecture](stack_trace/architecture.md)
- [Roadmap](stack_trace/roadmap.md)

## Meta
- [**Contributing to Documentation**](CONTRIBUTING_DOCS.md): Guidelines for documentation contributions.
- [**Contributing**](../CONTRIBUTING.md): Guidelines for project contributors.
