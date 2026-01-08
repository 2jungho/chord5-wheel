import 'package:js/js.dart';

@JS('window.playWebGuitarNote')
external void playWebGuitarNote(String note, int octave);

@JS('window.scheduleWebSequence')
external void scheduleWebSequence(int bpm, String progressionJson);

@JS('window.stopWebAudio')
external void stopWebAudio();

@JS('window.setWebBPM')
external void setWebBPM(int bpm);

@JS('window.setWebInstrument')
external void setWebInstrument(String id);

class WebAudioApi {
  static void playNote(String note, int octave) {
    playWebGuitarNote(note, octave);
  }

  static void scheduleSequence(int bpm, String progressionJson) {
    scheduleWebSequence(bpm, progressionJson);
  }

  static void stop() {
    stopWebAudio();
  }

  static void setBpm(int bpm) {
    setWebBPM(bpm);
  }

  static void setInstrument(String id) {
    setWebInstrument(id);
  }
}
