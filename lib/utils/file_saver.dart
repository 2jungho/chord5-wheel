import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';

/// 파일 저장 기능을 제공하는 크로스 플랫폼 유틸리티
Future<void> saveFile(Uint8List bytes, String fileName) =>
    saveFileImpl(bytes, fileName);
