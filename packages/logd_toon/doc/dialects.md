# TOON Dialects

TOON supports multiple dialects to cater to different use cases, balancing strict machine-parsability with human-centric terminal readability.

## 1. Compact Dialect (`ToonDialect.compact`)

The `compact` dialect is designed for terminal output and human readability. It strips away unnecessary structural markers to provide a clean, uncluttered view of the log data.

**Key Characteristics:**
* **Unquoted Keys:** Keys are printed without quotes unless they contain spaces or special characters.
* **Implicit Structures:** Uses indentation and newlines to represent object boundaries instead of explicit `{}` braces.
* **Inline Primitives:** Simple key-value pairs are kept on a single line where possible.

**Use Case:** Local development, terminal debugging, and any scenario where a human is the primary consumer of the log.

## 2. Strict Dialect (`ToonDialect.strict`)

The `strict` dialect is designed for machine ingestion, log aggregators (e.g., ELK stack, Datadog), and file persistence. It prioritizes unambiguous parsing over visual aesthetics.

**Key Characteristics:**
* **Explicit Boundaries:** Uses strict structural markers (`{`, `}`, `[`, `]`) for all objects and lists.
* **Quoted Strings:** All string values are explicitly quoted.
* **Type Annotations:** Includes explicit type tags for complex types (e.g., `<DateTime>2023-10-26T14:30:00Z`) to ensure the parser reconstructs the exact type.

**Use Case:** Production logging, file outputs, structured metric collection, and scenarios where logs are consumed by automated systems.

## Selecting a Dialect

You select the dialect when instantiating the `ToonEncoder` or `ToonHandler`:

```dart
import 'package:logd_toon/logd_toon.dart';

final strictHandler = ToonHandler(dialect: ToonDialect.strict);
final compactHandler = ToonHandler(dialect: ToonDialect.compact);
```
