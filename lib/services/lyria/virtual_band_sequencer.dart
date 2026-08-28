import 'dart:async';
import '../../audio/audio_manager.dart';
import '../../audio/virtual_band_synth.dart';
import '../../models/chord_model.dart';
import '../../models/progression/progression_models.dart';
import '../../utils/theory_utils.dart';
import '../../utils/guitar_utils.dart';



typedef BandStepCallback = void Function(int blockIndex, int stepInBlock, int totalStepsInBlock);

class VirtualBandSequencer {
  Timer? _timer;
  bool _isRunning = false;

  // Configuration
  double bpm;
  String style;
  double volume;
  bool drumsEnabled;
  bool bassEnabled;
  bool keysEnabled;
  bool guitarEnabled;

  // Active progression
  List<ChordBlock> _blocks = [];
  int _currentBlockIndex = 0;
  int _currentStepInBlock = 0;

  // Step Callback for UI sync
  BandStepCallback? onStep;

  VirtualBandSequencer({
    this.bpm = 120.0,
    this.style = 'Neo-Soul',
    this.volume = 0.8,
    this.drumsEnabled = true,
    this.bassEnabled = true,
    this.keysEnabled = true,
    this.guitarEnabled = true,
    this.onStep,
  });

  bool get isRunning => _isRunning;

  void start(List<ChordBlock> blocks) {
    stop();

    if (blocks.isEmpty) {
      // Default fallback 4-chord progression: C - Am - F - G
      final defaultChords = ['C', 'Am', 'F', 'G'];
      _blocks = defaultChords.map((sym) {
        final analyzed = TheoryUtils.analyzeChord(sym);
        final voicings = GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
        return ChordBlock(
          chordSymbol: sym,
          functionTag: '',
          duration: 4,
          chordDetail: analyzed,
          voicing: voicings.isNotEmpty ? voicings.first : null,
        );
      }).toList();
    } else {
      _blocks = List<ChordBlock>.from(blocks);
    }

    _currentBlockIndex = 0;
    _currentStepInBlock = 0;
    _isRunning = true;

    _scheduleNextTick();
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _currentBlockIndex = 0;
    _currentStepInBlock = 0;
    AudioManager().stopProgression();
  }

  void updateBpm(double newBpm) {
    bpm = newBpm.clamp(50.0, 220.0);
  }

  void updateStyle(String newStyle) {
    style = newStyle;
  }

  void updateVolume(double newVolume) {
    volume = newVolume.clamp(0.0, 1.0);
  }

  void setInstruments({
    bool? drums,
    bool? bass,
    bool? keys,
    bool? guitar,
  }) {
    if (drums != null) drumsEnabled = drums;
    if (bass != null) bassEnabled = bass;
    if (keys != null) keysEnabled = keys;
    if (guitar != null) guitarEnabled = guitar;
  }

  String _normalizeStyle(String rawStyle) {
    final s = rawStyle.toLowerCase();
    if (s.contains('lofi') || s.contains('로파이') || s.contains('비 오는')) return 'Lofi Chill';
    if (s.contains('neo') || s.contains('soul') || s.contains('소울')) return 'Neo-Soul';
    if (s.contains('blue') || s.contains('블루스')) return 'Blues';
    if (s.contains('city') || s.contains('시티팝') || s.contains('disco') || s.contains('디스코')) return 'City Pop';
    if (s.contains('rock') || s.contains('록') || s.contains('락') || s.contains('펑키')) return 'Rock';
    if (s.contains('jazz') || s.contains('funk') || s.contains('재즈')) return 'Jazz Funk';
    if (s.contains('acoustic') || s.contains('어쿠스틱') || s.contains('ballad') || s.contains('감성')) return 'Acoustic Ballad';
    return rawStyle;
  }

  void _scheduleNextTick() {
    if (!_isRunning || _blocks.isEmpty) return;

    // Base 16th-note step interval in milliseconds: (60,000 / BPM / 4)
    final baseStepMs = 60000.0 / bpm / 4.0;
    final normalized = _normalizeStyle(style);

    // Natural swing factor per style (0.50 = straight, 0.56 = neo-soul/lofi, 0.62 = blues shuffle)
    double swingRatio = 0.50;
    if (normalized == 'Neo-Soul' || normalized == 'Lofi Chill') {
      swingRatio = 0.56;
    } else if (normalized == 'Blues') {
      swingRatio = 0.62;
    } else if (normalized == 'Jazz Funk') {
      swingRatio = 0.54;
    }

    // Even 16th steps (0, 2, 4, ...) get the longer swung beat, odd 16th steps (1, 3, 5, ...) get the upbeat
    final isOddStep = (_currentStepInBlock % 2) != 0;
    final stepDurationMs = isOddStep
        ? (baseStepMs * 2.0 * (1.0 - swingRatio)).round().clamp(30, 500)
        : (baseStepMs * 2.0 * swingRatio).round().clamp(30, 500);

    _timer = Timer(Duration(milliseconds: stepDurationMs), () {
      if (!_isRunning) return;
      _executeStep();
      _scheduleNextTick();
    });
  }

  void _executeStep() {
    if (_blocks.isEmpty) return;

    final block = _blocks[_currentBlockIndex % _blocks.length];
    final detail = block.chordDetail ?? TheoryUtils.analyzeChord(block.chordSymbol);
    final totalStepsInBlock = (block.duration * 4).clamp(4, 32); // 4 steps per beat
    final stepInBar = _currentStepInBlock % 16; // 16 steps in a 4/4 bar
    final normalized = _normalizeStyle(style);

    // Notify UI
    onStep?.call(_currentBlockIndex, _currentStepInBlock, totalStepsInBlock);

    final vol = volume;

    // 1. DRUMS SEQUENCING
    if (drumsEnabled && vol > 0.01) {
      _playDrums(normalized, stepInBar, vol);
    }

    // 2. BASS SEQUENCING
    if (bassEnabled && vol > 0.01) {
      _playBass(normalized, stepInBar, detail, vol);
    }

    // 3. KEYBOARD / ELECTRIC PIANO SEQUENCING
    if (keysEnabled && vol > 0.01) {
      _playKeys(normalized, stepInBar, detail, vol);
    }

    // 4. GUITAR SEQUENCING
    if (guitarEnabled && vol > 0.01) {
      _playGuitar(normalized, stepInBar, block, detail, vol);
    }

    // Advance step pointer
    _currentStepInBlock++;
    if (_currentStepInBlock >= totalStepsInBlock) {
      _currentStepInBlock = 0;
      _currentBlockIndex = (_currentBlockIndex + 1) % _blocks.length;
    }
  }

  // --- Drum Grooves by Style ---
  void _playDrums(String style, int step, double vol) {
    switch (style) {
      case 'Rock':
        // Driving Rock: Punchy downbeat Kick (0, 8, 10); Crack Snare on 4, 12; Ghost on 15; 8th Hats
        if (step == 0 || step == 8 || step == 10) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.95);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.90);
        } else if (step == 15) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.35); // Ghost note
        }
        if (step % 2 == 0) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed, volume: (step % 4 == 0 ? vol * 0.70 : vol * 0.50));
          }
        }
        break;

      case 'Neo-Soul':
        // Dilla-style syncopated pocket: Kick on 0, 6, 11; Snappy Rimshot on 4, 12 + ghost 15; Dynamic 16th hats
        if (step == 0) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.85);
        } else if (step == 6 || step == 11) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.75);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.85);
        } else if (step == 7 || step == 15) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.30); // Subtle ghost rim
        }
        if (step % 2 == 0 || step == 3 || step == 7) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.55);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed, volume: (step % 4 == 2 ? vol * 0.60 : vol * 0.40));
          }
        }
        break;

      case 'Jazz Funk':
        // Tight 16th funk pocket: Kick on 0, 3, 6, 10; Snare backbeat on 4, 12 + ghost 7, 13, 15
        if (step == 0 || step == 10) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.90);
        } else if (step == 3 || step == 6) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.75);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.85);
        } else if (step == 7 || step == 13 || step == 15) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.35); // Funk ghost notes
        }
        if (step == 14) {
          AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
        } else {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: (step % 2 == 0 ? vol * 0.60 : vol * 0.40));
        }
        break;

      case 'Lofi Chill':
        // Warm boom-bap: Low warm kick on 0, 7; Vintage wood snare on 4, 12; Soft 8th hats
        if (step == 0) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.80);
        } else if (step == 7) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.70);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.75);
        }
        if (step % 2 == 0) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.45);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed, volume: (step % 4 == 0 ? vol * 0.45 : vol * 0.30));
          }
        }
        break;

      case 'Blues':
        // 12/8 Triplet shuffle: Kick on 0, 8; Snare on 4, 12; Swung hats on triplet grid
        if (step == 0 || step == 8) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.85);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.80);
        }
        if (step == 0 || step == 3 || step == 4 || step == 7 || step == 8 || step == 11 || step == 12 || step == 15) {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: (step % 4 == 0 ? vol * 0.60 : vol * 0.40));
        }
        break;

      case 'City Pop':
        // Disco 4-on-the-floor Kick (0, 4, 8, 12); Snare on 4, 12; Shimmering open hats on offbeats (2, 6, 10, 14)
        if (step == 0 || step == 4 || step == 8 || step == 12) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.90);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.85);
        }
        if (step == 2 || step == 6 || step == 10 || step == 14) {
          AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
        } else {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: vol * 0.45);
        }
        break;

      case 'Acoustic Ballad':
      default:
        // Gentle soft kick on 0, 8; Warm rimshot on 4, 12; Whisper hats on quarter notes
        if (step == 0 || step == 8) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.70);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.65);
        }
        if (step % 4 == 0) {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: vol * 0.35);
        }
        break;
    }
  }

  // --- Bass Lines by Style ---
  void _playBass(String style, int step, Chord detail, double vol) {
    final root = detail.root;
    final notes = detail.notes;
    final fifth = notes.length >= 3 ? notes[2] : root;
    final third = notes.length >= 2 ? notes[1] : root;

    switch (style) {
      case 'Rock':
        // Driving 8th notes on Root with 5th accent on 12
        if (step % 2 == 0) {
          if (step == 12) {
            AudioManager().playBassNote(fifth, 2, volume: vol * 0.80);
          } else {
            AudioManager().playBassNote(root, 2, volume: vol * 0.85);
          }
        }
        break;

      case 'Neo-Soul':
        // Melodic walking bassline: Deep Root on 0, 5th on 6, Upper Octave on 11
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 6) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.75);
        } else if (step == 11) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.70);
        }
        break;

      case 'Jazz Funk':
        // Syncopated funk bass: Root on 0, 3; Octave on 6; 5th on 10; Leading note on 14
        if (step == 0 || step == 3) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 6) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.80);
        } else if (step == 10) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.75);
        } else if (step == 14) {
          AudioManager().playBassNote(third, 2, volume: vol * 0.70);
        }
        break;

      case 'Blues':
        // Walking Blues Bass: Beat 1 (0) Root -> Beat 2 (4) 3rd -> Beat 3 (8) 5th -> Beat 4 (12) 6th
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 4) {
          AudioManager().playBassNote(third, 2, volume: vol * 0.80);
        } else if (step == 8) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.80);
        } else if (step == 12) {
          final sixthNote = TheoryUtils.transposeNote(root, 9);
          AudioManager().playBassNote(sixthNote, 2, volume: vol * 0.75);
        }
        break;

      case 'City Pop':
        // Disco Octave Slap Bass: Low Root on 0, 4, 8, 12; High Octave on 2, 6, 10, 14
        if (step == 0 || step == 4 || step == 8 || step == 12) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 2 || step == 6 || step == 10 || step == 14) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.75);
        }
        break;

      case 'Lofi Chill':
      case 'Acoustic Ballad':
      default:
        // Deep Warm Sustained Root on Beat 1 (0), 5th on Beat 3 (8)
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.80);
        } else if (step == 8) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.70);
        }
        break;
    }
  }

  // --- Keyboard / Electric Piano Chords by Style ---
  void _playKeys(String style, int step, Chord detail, double vol) {
    final chordNotes = detail.notes.isNotEmpty ? detail.notes : [detail.root];

    switch (style) {
      case 'Neo-Soul':
      case 'Lofi Chill':
        // Lush Rhodes comping on offbeat steps 2, 6, 10 + Sustained pad on step 0
        if (step == 0) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.70);
        } else if (step == 6 || step == 10) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.60);
        }
        break;

      case 'Jazz Funk':
        // Crisp rhythmic Rhodes stabs on steps 2, 6, 11
        if (step == 2 || step == 6 || step == 11) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.65);
        }
        break;

      case 'City Pop':
        // Bright syncopated 80s EP stabs on 0, 6, 12
        if (step == 0 || step == 6 || step == 12) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.70);
        }
        break;

      case 'Rock':
        // Heavy sustained chords on 0 & 8
        if (step == 0 || step == 8) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.65);
        }
        break;

      case 'Blues':
        // Blues comping on 4 & 12 (Beat 2 & 4)
        if (step == 4 || step == 12) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.65);
        }
        break;

      case 'Acoustic Ballad':
      default:
        // Lush sustained chord on beat 1 with high melody note on beat 3
        if (step == 0) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.65);
        } else if (step == 8 && chordNotes.length >= 2) {
          AudioManager().playKeyboardNote(chordNotes[1], 4, volume: vol * 0.50);
        }
        break;
    }
  }

  // --- Guitar Accompaniment by Style ---
  void _playGuitar(String style, int step, ChordBlock block, Chord detail, double vol) {
    if (block.voicing != null) {
      if (step == 0) {
        AudioManager().playVoicing(block.voicing!, root: block.chordSymbol);
      } else if (step == 8 && (style == 'Rock' || style == 'Neo-Soul' || style == 'City Pop')) {
        AudioManager().playVoicing(block.voicing!, root: block.chordSymbol);
      }
    } else if (detail.notes.isNotEmpty) {
      if (step == 0) {
        AudioManager().playStrum(detail.notes);
      } else if (step == 8 && (style == 'Rock' || style == 'Neo-Soul' || style == 'City Pop')) {
        AudioManager().playStrum(detail.notes);
      }
    }
  }
}

