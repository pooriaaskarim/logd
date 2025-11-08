# Changelog

## 0.1.2: Minor API Changes

## 0.1.1: Dynamic Logger Tree Hierarchy Inheritance
- ### Dynamic Inheritance
  - Logger tree is now dynamically propagated, rooting at 'global' logger
  - freezeInheritance() is introduced to bake configs into a logger (and it's descendant branch, if any).
  - global getter ditched in favor of uniformity: access global logger using get() or get('global').

## 0.1.0: Dot-separated Logger Tree Hierarchy + Handlers
- ### New Api
  - Logger has new Api surface.
  - Introduced Dot-separated Logger Tree Hierarchy.
  - Introduced functionalities to attach to Flutter/Dart Error and Unhandled Exceptions
- ### Logger Tree Hierarchy
  - Loggers are named, now with a Dot-separated mechanism to inherit from their parent if not explicitly set. (Under Development)
  - global Logger (still) available.
  - Child propagation. (Under Development)
- ### Handlers
  - Introduce Handlers:
    This Replaces Printers in V 0.0.2, no backward compatibility here!
  - Introduced LogFormatters:
    Separated formatting LogEntries from outputting.
  - Introduced LogSinks:
    Separated outputting LogEntries from formatting.
  - Introduce LogFilters
    A way to filter out specific log entries.
- ### Better Structure and Documentation

## 0.0.2: Modularity + Printers
- ### Introduced Modular Loggers
- ### Introduced LogEvents
- ### Introduced Printers
  - Printers are a way of outputting data. (Soon to be replaced with Handlers: Formatters and Sinks)

## 0.0.1: Initial version
- ### Logger Daemon
  - Uses LogBuffer to collect  and output data.
- ### Simple BoxPrinter
  - Formats output in a simple box.
- ### StackTraceParser
- ### TimeStampFormatter and TimeZone
