import 'dart:io' as io;

String getCurrentDirectory() => io.Directory.current.path;
String getPathSeparator() => io.Platform.pathSeparator;
