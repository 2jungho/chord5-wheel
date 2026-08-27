import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Web implementation
Future<void> saveFileImpl(Uint8List bytes, String fileName) async {
  final jsArray = [bytes.toJS].toJS;
  final blob = web.Blob(jsArray);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  web.URL.revokeObjectURL(url);
}

