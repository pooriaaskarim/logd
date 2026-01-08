# Migration Guide

The `logd` library has evolved from a simple logging utility to a high-performance, segment-based pipeline. This guide helps you migrate from legacy patterns to the modern architecture introduced in v0.4.2.

## Key Transitions

### 1. From BoxFormatter to Decorator Pipeline
As of v0.4.1, `BoxFormatter` is deprecated. Responsibilities are now split between Layout (Formatter) and Framing (Decorator).

**Legacy (BoxFormatter)**:
```dart
final handler = Handler(
  formatter: BoxFormatter(
    borderStyle: BorderStyle.rounded,
    lineLength: 80,
  ),
  sink: const ConsoleSink(),
);
```

**Modern (StructuredFormatter + BoxDecorator)**:
```dart
final handler = Handler(
  formatter: StructuredFormatter(lineLength: 80),
  decorators: [
    BoxDecorator(borderStyle: BorderStyle.rounded, lineLength: 80),
    const ColorDecorator(), // Recommended: Add color after structural decorators
  ],
  sink: const ConsoleSink(),
);
```

### 2. Segment-Based Architecture (v0.4.2+)
The single-string output pipeline has been replaced with `LogLine` and `LogSegment`. This allows decorators and sinks to understand the **semantics** of each part of a line.

- **Formatters**: Now implement `format(entry, context)` returning `Iterable<LogLine>`.
- **Decorators**: Now implement `decorate(lines, entry, context)` returning `Iterable<LogLine>`.
- **Sinks**: Now implement `output(lines, level)` taking `Iterable<LogLine>`.

### 3. Advanced Color Configuration
Coloring is no longer a simple boolean. It uses `ColorScheme` and `ColorConfig` to target specific semantic tags.

**Legacy (colorHeaderBackground)**:
```dart
ColorDecorator(colorHeaderBackground: true) // Deprecated
```

**Modern (ColorConfig)**:
```dart
ColorDecorator(
  config: ColorConfig(headerBackground: true),
  scheme: ColorScheme.darkScheme,
)
```

## Parameter Mapping

| Old Parameter | New Component / Parameter |
|---------------|---------------------------|
| `lineLength`  | `StructuredFormatter(lineLength: ...)` AND `BoxDecorator(lineLength: ...)` |
| `borderStyle` | `BoxDecorator(borderStyle: ...)` |
| `useColors`   | `ColorDecorator()` (Preferred) |

## Breaking Changes in v0.4.2
- `LogFormatter.format` return type changed from `Iterable<String>` to `Iterable<LogLine>`.
- `LogDecorator.decorate` parameter and return type changed to `Iterable<LogLine>`.
- `LogSink.output` parameter changed to `Iterable<LogLine>`.
- Internal modules moved to `lib/src/core/`. Public exports in `lib/logd.dart` remain the same.

## Recommendations
- **Order Matters**: Put `BoxDecorator` before `ColorDecorator` if you want the borders to be colored along with the content.
- **Hierarchy**: Use `HierarchyDepthPrefixDecorator` to visualize nested loggers.
- **Buffers**: Use `logger.infoBuffer` for multi-line logs to ensure they stay grouped together.
