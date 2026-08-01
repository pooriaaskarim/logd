part of 'document.dart';

/// Controls the preamble header and null-encoding behavior of TOON output.
enum ToonDialect {
  /// Default compact mode. Preamble header on line 1, empty string for nulls.
  compact,

  /// Strict mode for automated log ingestion (DuckDB, Loki, awk).
  ///
  /// Includes protocol version comment (`-- TOON/1.0 <arrayName>`) and parser
  /// configuration comment (`-- DELIMITER:\t QUOTE:" NULL:\N`). Emits `\N` for
  /// null/absent values.
  strict,
}
