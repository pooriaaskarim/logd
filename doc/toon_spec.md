# Token-Oriented Object Notation (TOON) Specification
> Version: 1.0  
> Status: Living Specification  

---

## 1. Overview

**Token-Oriented Object Notation (TOON)** is a compact, token-efficient text format designed specifically for streaming structured logs into machine parsers, query engines, and Large Language Models (LLMs).

Unlike JSON—which repeats field key names for every single object in an array—TOON defines the column schema **once in a header preamble**, followed by uniform, tab-delimited rows. This yields a **30–50% reduction in token count** while preserving strict machine readability.

---

## 2. Session & Stream Structure

A TOON stream consists of a single **Preamble Header** followed by one or more **Data Rows**.

```text
<Preamble Header>\n
<Row 1>\n
<Row 2>\n
...
```

### 2.1 Preamble Header Variants

TOON supports two preamble variants:

#### Compact Schema (Default)
Defines array name and column order in a single line.

```text
logs[]{timestamp,logger,origin,level,message,error,stackTrace,context}:
```

#### Explicit Type Schema (`explicitSchema: true`)
Includes semantic type hints for LLM parsers or static schema generators.

```text
logs[]{
  timestamp  : iso8601;
  logger     : string;
  origin     : string;
  level      : enum(TRACE,DEBUG,INFO,WARNING,ERROR,FATAL);
  message    : markdown;
  error      : string;
  stackTrace : stacktrace;
  context    : string;
}:
```

---

## 3. Data Row Format

Each data row is a single physical line containing field values separated by the configured delimiter (default: Tab `\t`).

### 3.1 Column Invariance
Every row in a TOON stream contains the **exact same number of columns** in the exact order declared by the preamble header. Absent or optional fields (such as `context` or `error`) emit as an empty string `""` (resulting in adjacent delimiters `\t\t`) or as `\N` in `strict` dialect mode. Column positions **never shift** between rows.

---

## 4. Escaping & Encoding Rules

To preserve line and column boundaries, values containing special characters are escaped as follows:

| Field Content | Output Format | Example Original | Example Escaped |
|---|---|---|---|
| Plain text | Unquoted | `hello` | `hello` |
| Contains delimiter (`\t`) | Double-quoted | `foo\tbar` | `"foo\tbar"` |
| Contains quote (`"`) | Double-quoted, backslash-escaped | `say "hi"` | `"say \"hi\""` |
| Contains newline (`\n` or `\r`) | Double-quoted, literal `\n` | `line 1\nline 2` | `"line 1\nline 2"` |
| Contains `{`, `}`, `[`, `]`, `:`, `,` | Double-quoted | `status: ok` | `"status: ok"` |
| Null / Absent (Compact) | Empty string | `null` | `\t\t` |
| Null / Absent (`strict` mode) | Explicit null token | `null` | `\N` |
| Nested Map | Braced, comma-separated key:value | `{'a': 1, 'b': 2}` | `{a:1,b:2}` |
| Nested List | Bracketed, comma-separated values | `[1, 2, 3]` | `[1,2,3]` |

---

## 5. Dialects

### 5.1 `ToonDialect.compact` (Default)
Optimized for minimum byte footprint and LLM context injection.
- Preamble header on line 1
- Empty string for absent fields (`\t\t`)

### 5.2 `ToonDialect.strict` (Pipeline Ingestion)
Optimized for automated log processors (DuckDB, awk, Loki, Vector).
- Includes protocol version header comment: `-- TOON/1.0 <arrayName>`
- Includes parser configuration comment: `-- DELIMITER:\t QUOTE:" NULL:\N`
- Emits explicit `\N` tokens for absent/null fields

```text
-- TOON/1.0 logs
-- DELIMITER:\t QUOTE:" NULL:\N
logs[]{timestamp,logger,origin,level,message,error,stackTrace,context}:
2025-01-01 12:00:00	App	app.dart:10	INFO	Server started	\N	\N	\N
```

---

## 6. Reading & Ingestion Patterns

### 6.1 DuckDB Ingestion
```sql
SELECT timestamp, logger, level, message
FROM read_csv('logs/app.toon',
  comment='--',
  delim='\t',
  quote='"',
  nullstr='\N',
  header=false,
  skip=1, -- skip schema header line
  columns={
    'timestamp': 'TIMESTAMP',
    'logger': 'VARCHAR',
    'origin': 'VARCHAR',
    'level': 'VARCHAR',
    'message': 'VARCHAR',
    'error': 'VARCHAR',
    'stackTrace': 'VARCHAR',
    'context': 'VARCHAR'
  }
)
WHERE level = 'ERROR';
```

### 6.2 LLM Sliding Window Context Slicing
When slicing a TOON log file to inject a 50-line window into an LLM prompt, the consumer should extract and prepend the header preamble:

```dart
final bytes = await File('logs/app.toon').readAsBytes();
final schema = ToonEncoder.extractPreamble(bytes) ?? '';
final windowLines = sliceRecentLines(file, count: 50);

final promptContext = '$schema\n${windowLines.join('\n')}';
```
