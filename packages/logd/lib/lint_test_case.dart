import 'logd.dart';

void main() {
  final logger = Logger.get('test');

  // Case 1: Variable leak (Error)
  final buf1 = logger.infoBuffer!; // LINT
  buf1.writeln('leaking');

  // Case 2: Chain leak (Error)
  logger.infoBuffer!.writeln('anonymous leak'); // LINT

  // Case 3: Proper variable usage (Safe)
  final buf2 = logger.infoBuffer!;
  try {
    buf2.writeln('safe');
  } finally {
    buf2.sink();
  }

  // Case 4: Proper chain usage (Safe)
  logger.infoBuffer!.sink();

  // Case 5: Proper cascade usage (Safe)
  logger.infoBuffer!
    ..writeln('cascade')
    ..sink();

  // Case 6: Cascade leak (Error)
  logger.infoBuffer!.writeln('cascade leak'); // LINT

  // Case 7: Variable sinked but NOT in finally (Warning)
  final buf3 = logger.infoBuffer!; // LINT
  buf3.writeln('unsafe');
  buf3.sink();
  // Case 8: Fix Verification (Apply Quick Fix Here)
  // Expected:
  // final bufFix = logger.infoBuffer!;
  // try {
  //   bufFix.writeln('fix me');
  // } finally {
  //   bufFix.sink();
  // }
  final bufFix = logger.infoBuffer!; // LINT
  bufFix.writeln('fix me');

  // Case 9: Safe Cascade (repro fix)
  logger.infoBuffer!
    ..writeln('safe cascade')
    ..sink();

  // Case 9: Safe Return
  LogBuffer getBuffer() {
    final b = logger.infoBuffer!;
    return b;
  }

  getBuffer().sink();

  // Case 10: Safe Argument Passing
  void consume(final LogBuffer b) {
    b.sink();
  }

  final buf4 = logger.infoBuffer!;
  consume(buf4);

  // Case 11: Conditional Sinking (Warning)
  final buf5 = logger.infoBuffer!; // LINT
  if (2 > 1) {
    buf5.sink();
  }
}
