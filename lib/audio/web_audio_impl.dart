import 'dart:js_interop';

@JS('playWebGuitarNote')
external void _playWebGuitarNote(JSString note, JSNumber octave);

@JS('playWebDrum')
external void _playWebDrum(JSString type, JSNumber volume);

@JS('playWebBass')
external void _playWebBass(JSString note, JSNumber octave, JSNumber volume);

@JS('playWebKeys')
external void _playWebKeys(JSString note, JSNumber octave, JSNumber volume);

@JS('scheduleWebSequence')
external void _scheduleWebSequence(JSNumber bpm, JSString progressionJson);

@JS('stopWebAudio')
external void _stopWebAudio();

@JS('setWebBPM')
external void _setWebBPM(JSNumber bpm);

@JS('setWebInstrument')
external void _setWebInstrument(JSString id);

@JS('setWebSoundProfile')
external void _setWebSoundProfile(JSString category, JSString profileId);

@JS('setWebVolume')
external void _setWebVolume(JSNumber volume);

@JS('startWebRecording')
external JSPromise<JSBoolean> _startWebRecording();

@JS('stopWebRecording')
external JSBoolean _stopWebRecording();

@JS('downloadWebRecording')
external JSBoolean _downloadWebRecording(JSString filename);

class WebAudioApi {
  static void playNote(String note, int octave) {
    _playWebGuitarNote(note.toJS, octave.toJS);
  }

  static void playDrum(String type, double volume) {
    _playWebDrum(type.toJS, volume.toJS);
  }

  static void playBass(String note, int octave, double volume) {
    _playWebBass(note.toJS, octave.toJS, volume.toJS);
  }

  static void playKeys(String note, int octave, double volume) {
    _playWebKeys(note.toJS, octave.toJS, volume.toJS);
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

  static void setSoundProfile(String category, String profileId) {
    _setWebSoundProfile(category.toJS, profileId.toJS);
  }

  static void setVolume(double volume) {
    _setWebVolume(volume.toJS);
  }


  static Future<bool> startRecording() async {
    try {
      final res = await _startWebRecording().toDart;
      return res.toDart;
    } catch (_) {
      return false;
    }
  }

  static bool stopRecording() {
    try {
      return _stopWebRecording().toDart;
    } catch (_) {
      return false;
    }
  }

  static bool downloadRecording(String filename) {
    try {
      return _downloadWebRecording(filename.toJS).toDart;
    } catch (_) {
      return false;
    }
  }
}


