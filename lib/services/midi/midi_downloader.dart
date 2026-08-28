import 'dart:typed_data';

export 'midi_downloader_io.dart'
    if (dart.library.js_interop) 'midi_downloader_web.dart';

void downloadMidi(String filename, Uint8List bytes) {
  // Dispatched via conditional export
}
