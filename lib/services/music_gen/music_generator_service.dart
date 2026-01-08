import 'dart:io';

abstract class MusicGeneratorService {
  /// Generates music based on the prompt.
  ///
  /// [prompt]: Description of the music to generate.
  /// [duration]: Target duration in seconds (note: free API might ignore this).
  /// [onStatusChanged]: Callback to notify UI of progress/errors.
  ///
  /// Returns the generated [File] path, or null if failed.
  Future<File?> generateMusic({
    required String prompt,
    int duration = 10,
    void Function(String message)? onStatusChanged,
  });
}
