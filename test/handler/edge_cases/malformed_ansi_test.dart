// Tests for handling malformed ANSI codes.
library;

import 'package:logd/src/core/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Malformed ANSI Code Handling', () {
    test('handles incomplete ANSI escape sequences', () {
      // Incomplete escape sequence
      const incomplete = '\x1B[3';
      final result = incomplete.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
    });

    test('handles ANSI codes in middle of text', () {
      // ANSI code in middle, not at start
      const middleAnsi = 'Hello \x1B[34mWorld\x1B[0m';
      final result = middleAnsi.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
      // Should not crash
    });

    test('handles multiple reset codes', () {
      const multipleReset = '\x1B[34mText\x1B[0m\x1B[0m\x1B[0m';
      final result = multipleReset.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
    });

    test('handles ANSI codes without reset', () {
      const noReset = '\x1B[34mText without reset';
      final result = noReset.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
      // Last line should have reset added
      expect(result.last, endsWith('\x1B[0m'));
    });

    test('handles empty ANSI codes', () {
      const emptyAnsi = '\x1B[mText';
      final result = emptyAnsi.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
    });

    test('handles very long ANSI sequences', () {
      // Some terminals use very long sequences
      const longSequence = '\x1B[38;2;255;255;255;48;2;0;0;0mText\x1B[0m';
      final result = longSequence.wrapVisiblePreserveAnsi(10).toList();
      expect(result, isNotEmpty);
    });
  });
}
