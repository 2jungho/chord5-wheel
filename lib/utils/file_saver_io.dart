import 'dart:io';
import 'dart:typed_data';

/// Native (IO) implementation
Future<void> saveFileImpl(Uint8List bytes, String fileName) async {
  String? dir;
  if (Platform.isWindows) {
    dir = Platform.environment['USERPROFILE'];
    if (dir != null) {
      dir = '$dir\\Downloads';
    }
  }
  // Fallback
  dir ??= Directory.current.path;

  final String fullPath = '$dir\\$fileName';
  final File imgFile = File(fullPath);
  await imgFile.writeAsBytes(bytes);

  // Note: Caller might want to know the path, but interface returns void for simplicity with Web.
  // In a real app, we might return a Result object.
  print('Saved to $fullPath');
}
