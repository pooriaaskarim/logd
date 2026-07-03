import 'file_system.dart';

class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  File file(final String path) =>
      throw UnsupportedError('FileSystem is not supported on web.');

  @override
  Directory directory(final String path) =>
      throw UnsupportedError('FileSystem is not supported on web.');
}
