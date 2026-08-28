class WebAudioApi {
  static void playNote(String note, int octave) {}
  static void playDrum(String type, double volume) {}
  static void playBass(String note, int octave, double volume) {}
  static void playKeys(String note, int octave, double volume) {}
  static void scheduleSequence(int bpm, String progressionJson) {}
  static void stop() {}
  static void setBpm(int bpm) {}
  static void setInstrument(String id) {}
  static void setSoundProfile(String category, String profileId) {}
  static void setVolume(double volume) {}

  static Future<bool> startRecording() async => false;
  static bool stopRecording() => false;
  static bool downloadRecording(String filename) => false;
}

