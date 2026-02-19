import 'package:logd/src/core/utils/utils.dart';

void main() {
  const suffix = ' | TRACE-ID: 7a93f1';
  print('String: "$suffix"');
  print('Length: ${suffix.length}');
  print('Visible Length (getVisibleLength): ${suffix.visibleLength}');

  const line = '       formatter.';
  print('Line: "$line"');
  print('Line Length: ${line.length}');
  print('Line Visible Length: ${line.visibleLength}');
}
