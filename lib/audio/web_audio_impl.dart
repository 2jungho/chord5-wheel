import 'dart:js_interop';

@JS('playWebGuitarNote')
external void _playWebGuitarNote(JSString note, JSNumber octave);

@JS('scheduleWebSequence')
external void _scheduleWebSequence(JSNumber bpm, JSString progressionJson);

@JS('stopWebAudio')
external void _stopWebAudio();

@JS('setWebBPM')
external void _setWebBPM(JSNumber bpm);

@JS('setWebInstrument')
external void _setWebInstrument(JSString id);

@JS('setWebVolume')
external void _setWebVolume(JSNumber volume);

class WebAudioApi {
  static void playNote(String note, int octave) {
    _playWebGuitarNote(note.toJS, octave.toJS);
  }

  static void scheduleSequence(int bpm, String progressionJson) {
    _scheduleWebSequence(bpm.toJS, progressionJson.toJS);
  }

  static void stop() {
    _stopWebAudio();
  }

  static void setBpm(int bpm) {
    _setWebBPM(bpm.toJS);
  }

  static void setInstrument(String id) {
    _setWebInstrument(id.toJS);
  }

  static void setVolume(double volume) {
    _setWebVolume(volume.toJS);
  }
}

