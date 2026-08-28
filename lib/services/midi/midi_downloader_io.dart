import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

void downloadFileCrossPlatform(String filename, Uint8List bytes) async {
  try {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
  } catch (_) {}
}
