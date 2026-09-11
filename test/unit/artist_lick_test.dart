import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/lick/artist_lick_model.dart';
import 'package:guitar_theory_app/models/lick/artist_lick_presets.dart';
import 'package:guitar_theory_app/models/lick/guitar_artist.dart';
import 'package:guitar_theory_app/models/audio/band_sound_profile.dart';
import 'package:guitar_theory_app/services/lick_analyzer_service.dart';
import 'package:guitar_theory_app/services/lick_audio_player.dart';
import 'package:guitar_theory_app/providers/lick_vault_state.dart';

void main() {
  group('Artist Lick Presets Verification', () {
    test('Should contain 12 signature licks across 4 guitar legends', () {
      final licks = kArtistLickPresets;
      expect(licks.length, equals(12));

      final hendrixLicks = licks.where((l) => l.artist == 'Jimi Hendrix').toList();
      final claptonLicks = licks.where((l) => l.artist == 'Eric Clapton').toList();
      final srvLicks = licks.where((l) => l.artist == 'Stevie Ray Vaughan').toList();
      final mooreLicks = licks.where((l) => l.artist == 'Gary Moore').toList();

      expect(hendrixLicks.length, equals(3));
      expect(claptonLicks.length, equals(3));
      expect(srvLicks.length, equals(3));
      expect(mooreLicks.length, equals(3));
    });

    test('All licks should have valid metadata, notes, and theory tips', () {
      for (final lick in kArtistLickPresets) {
        expect(lick.id, isNotEmpty);
        expect(lick.title, isNotEmpty);
        expect(lick.artist, isNotEmpty);
        expect(lick.defaultKey, isNotEmpty);
        expect(lick.notes, isNotEmpty);
        expect(lick.theoryTips, isNotEmpty);

        for (final note in lick.notes) {
          expect(note.string, inInclusiveRange(1, 6));
          expect(note.fret, inInclusiveRange(0, 24));
          expect(note.duration, greaterThan(0));
          expect(note.noteName, isNotEmpty);
        }
      }
    });
  });

  group('LickAnalyzerService - Transposition & Pitch Engine', () {
    test('Transposing to same key preserves exact fret positions', () {
      final originalLick = kArtistLickPresets.firstWhere((l) => l.id == 'hendrix_little_wing');
      final transposed = LickAnalyzerService.transposeLick(originalLick, toKey: originalLick.defaultKey);

      expect(transposed.notes.length, equals(originalLick.notes.length));
      for (int i = 0; i < originalLick.notes.length; i++) {
        expect(transposed.notes[i].string, equals(originalLick.notes[i].string));
        expect(transposed.notes[i].fret, equals(originalLick.notes[i].fret));
        expect(transposed.notes[i].noteName, equals(originalLick.notes[i].noteName));
      }
    });

    test('Transposition by semitones correctly recalculates pitch and note names', () {
      // Clapton Crossroads is in A Minor (fret 5/7)
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.id == 'clapton_crossroads');
      expect(claptonLick.defaultKey, contains('A'));

      // Transpose from A to C (+3 semitones)
      final cLick = LickAnalyzerService.transposeLick(claptonLick, toKey: 'C Major');
      expect(cLick.notes.length, equals(claptonLick.notes.length));

      for (int i = 0; i < claptonLick.notes.length; i++) {
        final orig = claptonLick.notes[i];
        final trans = cLick.notes[i];

        final origSemitone = LickAnalyzerService.calculateAbsolutePitch(orig.string, orig.fret);
        final transSemitone = LickAnalyzerService.calculateAbsolutePitch(trans.string, trans.fret);

        expect((transSemitone - origSemitone) % 12, equals(3));
      }
    });
  });

  group('LickAnalyzerService - Harmonic Context Analysis', () {
    test('Correctly identifies chord tones and harmonic role summary against backing chord', () {
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.id == 'clapton_crossroads');
      final analysis = LickAnalyzerService.analyzeHarmonicContext(claptonLick, 'A7');

      expect(analysis.noteAnalyses.length, equals(claptonLick.notes.length));
      expect(analysis.summary, contains('A7'));
      // Clapton Crossroads notes contain Root or chord tones
      final hasChordToneOrRoot = analysis.noteAnalyses.any(
        (str) => str.contains('Root') || str.contains('코드톤'),
      );
      expect(hasChordToneOrRoot, isTrue);
    });

    test('Detects Blue Note (b5) in Hendrix Voodoo Child Lick', () {
      // Hendrix Voodoo contains Bb (b5) over E7
      final hendrixLick = kArtistLickPresets.firstWhere((l) => l.id == 'hendrix_voodoo');
      final analysis = LickAnalyzerService.analyzeHarmonicContext(hendrixLick, 'E7');

      expect(analysis.summary, contains('b5 블루노트'));
      final hasBlueNoteAnalysis = analysis.noteAnalyses.any((str) => str.contains('블루노트 b5'));
      expect(hasBlueNoteAnalysis, isTrue);
    });
  });

  group('LickAnalyzerService - Fretboard Visual Mapping', () {
    test('mapLickToHighlightMap correctly inverts string index for FretboardMapWidget', () {
      final hendrixLick = kArtistLickPresets.firstWhere((l) => l.id == 'hendrix_little_wing');
      final highlightMap = LickAnalyzerService.mapLickToHighlightMap(hendrixLick);

      // FretboardMapWidget uses string 0 for 6th string (low E), string 5 for 1st string (high E)
      for (final note in hendrixLick.notes) {
        final expectedMapString = (6 - note.string).clamp(0, 5);
        expect(highlightMap.containsKey(expectedMapString), isTrue);
        final markers = highlightMap[expectedMapString]!;
        expect(markers.any((m) => m.fret == note.fret), isTrue);
      }
    });

    test('generateLickFlowLines produces valid VoiceLeadingLines', () {
      final srvLick = kArtistLickPresets.firstWhere((l) => l.id == 'srv_pride_and_joy');
      final lines = LickAnalyzerService.generateLickFlowLines(srvLick);

      expect(lines.length, equals(srvLick.notes.length - 1));
      for (final line in lines) {
        expect(line.fromFret, inInclusiveRange(0, 24));
        expect(line.toFret, inInclusiveRange(0, 24));
        expect(line.fromStr, inInclusiveRange(0, 5));
        expect(line.toStr, inInclusiveRange(0, 5));
      }
    });
  });

  group('LickVaultState Basic Provider Operations', () {
    test('Playback speed cycles and updates appropriately', () {
      final state = LickVaultState();
      expect(state.playbackSpeed, equals(1.0));

      state.setPlaybackSpeed(0.5);
      expect(state.playbackSpeed, equals(0.5));

      state.setPlaybackSpeed(0.75);
      expect(state.playbackSpeed, equals(0.75));
    });

    test('Key sync updates selected lick and generates transposed version', () {
      final state = LickVaultState();
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.artist == 'Eric Clapton');
      state.selectLick(claptonLick);

      expect(state.selectedLick.defaultKey, isNotEmpty);

      state.syncKey('G Major');
      expect(state.activeKey, equals('G Major'));
      expect(state.currentTransposedLick.defaultKey, equals('G Major'));
      // Transposed to G
      final noteNames = state.currentTransposedLick.notes.map((n) => n.noteName).toList();
      expect(noteNames, isNotEmpty);
    });

    test('Guitar sound profile selection updates correctly', () {
      final state = LickVaultState();
      expect(state.availableGuitarSounds.length, equals(5));

      // 기본값 확인
      expect(state.selectedGuitarSound, isNotNull);

      // 통기타 선택
      state.selectGuitarSound(BandSoundProfiles.guitarAcoustic);
      expect(state.selectedGuitarSound.id, equals('guitar_acoustic'));
      expect(state.selectedGuitarSound.shortName, equals('스틸 통기타'));

      // 나일론기타 선택
      state.selectGuitarSound(BandSoundProfiles.guitarNylon);
      expect(state.selectedGuitarSound.id, equals('guitar_nylon'));
      expect(state.selectedGuitarSound.shortName, equals('나일론 기타'));

      // 오버드라이브 일렉 선택
      state.selectGuitarSound(BandSoundProfiles.guitarOverdrive);
      expect(state.selectedGuitarSound.id, equals('guitar_overdrive'));
      expect(state.selectedGuitarSound.shortName, equals('오버드라이브'));

      // 디스토션 일렉 선택
      state.selectGuitarSound(BandSoundProfiles.guitarDistortion);
      expect(state.selectedGuitarSound.id, equals('guitar_distortion'));
      expect(state.selectedGuitarSound.shortName, equals('디스토션'));

      // 클린 일렉 선택
      state.selectGuitarSound(BandSoundProfiles.guitarClean);
      expect(state.selectedGuitarSound.id, equals('guitar_clean'));
      expect(state.selectedGuitarSound.shortName, equals('클린 일렉'));
    });

    test('getRecommendedSound recommends matching guitar sound per genre/tags', () {
      // 1. Acoustic
      final acousticSound = LickVaultState.getRecommendedSound(
        const GuitarArtist(
          id: 'tommy',
          name: 'Tommy Emmanuel',
          koreanName: '토미 임마누엘',
          genre: 'Acoustic Fingerstyle',
          era: 'Modern',
          signatureGuitar: 'Maton Acoustic',
          bio: '핑거스타일 어쿠스틱의 거장',
          famousSongs: [],
        ),
        null,
      );
      expect(acousticSound.id, equals('guitar_acoustic'));

      // 2. Nylon / Flamenco
      final nylonSound = LickVaultState.getRecommendedSound(
        const GuitarArtist(
          id: 'paco',
          name: 'Paco de Lucia',
          koreanName: '파코 데 루시아',
          genre: 'Flamenco',
          era: '1970s',
          signatureGuitar: 'Conde Hermanos Flamenco Nylon',
          bio: '플라멩코 나일론 기타',
          famousSongs: [],
        ),
        null,
      );
      expect(nylonSound.id, equals('guitar_nylon'));

      // 3. Distortion / Metal
      final distortionSound = LickVaultState.getRecommendedSound(
        const GuitarArtist(
          id: 'vanhalen',
          name: 'Eddie Van Halen',
          koreanName: '에디 반 헤일런',
          genre: 'Hard Rock / Heavy Metal',
          era: '1980s',
          signatureGuitar: 'Frankenstrat',
          bio: '태핑과 앰프 하이게인',
          famousSongs: [],
        ),
        null,
      );
      expect(distortionSound.id, equals('guitar_distortion'));
    });

    test('CAGED 5 Box definitions contain 5 valid boxes', () {
      final boxes = LickAnalyzerService.cagedBoxDefinitions;
      expect(boxes.length, equals(5));
      expect(boxes[0].boxNumber, equals(1));
      expect(boxes[0].cagedForm, equals('E Form'));
      expect(boxes[1].boxNumber, equals(2));
      expect(boxes[1].cagedForm, equals('D Form'));
      expect(boxes[2].boxNumber, equals(3));
      expect(boxes[2].cagedForm, equals('C Form'));
      expect(boxes[3].boxNumber, equals(4));
      expect(boxes[3].cagedForm, equals('A Form'));
      expect(boxes[4].boxNumber, equals(5));
      expect(boxes[4].cagedForm, equals('G Form'));
    });

    test('mapLickToBox returns original lick when targetBox == pentatonicBox', () {
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.id == 'clapton_crossroads');
      final mapped = LickAnalyzerService.mapLickToBox(claptonLick, claptonLick.pentatonicBox);
      expect(mapped, equals(claptonLick));
    });

    test('mapLickToBox preserves note pitch class and maps to target box frets', () {
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.id == 'clapton_crossroads');
      // Clapton Crossroads is in Box 1
      expect(claptonLick.pentatonicBox, equals(1));

      // Map to Box 2, 3, 4, 5
      for (int box = 2; box <= 5; box++) {
        final mapped = LickAnalyzerService.mapLickToBox(claptonLick, box);
        expect(mapped.notes.length, equals(claptonLick.notes.length));

        for (int i = 0; i < claptonLick.notes.length; i++) {
          final origNote = claptonLick.notes[i];
          final mappedNote = mapped.notes[i];

          final origPitch = LickAnalyzerService.calculateAbsolutePitch(origNote.string, origNote.fret);
          final mappedPitch = LickAnalyzerService.calculateAbsolutePitch(mappedNote.string, mappedNote.fret);

          // The pitch class (note identity mod 12) must match
          expect(mappedPitch % 12, equals(origPitch % 12),
              reason: 'Note $i pitch class must match for Box $box');
          expect(mappedNote.fret, inInclusiveRange(0, 24));
          expect(mappedNote.string, inInclusiveRange(1, 6));
        }
      }
    });

    test('LickVaultState handles Box 1~5 selection and all-boxes mode', () {
      final state = LickVaultState();
      final claptonLick = kArtistLickPresets.firstWhere((l) => l.id == 'clapton_crossroads');
      state.selectLick(claptonLick);

      expect(state.selectedBox, equals(claptonLick.pentatonicBox));
      expect(state.isAllBoxesMode, isFalse);

      // Select Box 3
      state.selectBox(3);
      expect(state.selectedBox, equals(3));
      expect(state.currentTransposedLick.notes.isNotEmpty, isTrue);

      // Toggle all boxes mode
      state.toggleAllBoxesMode();
      expect(state.isAllBoxesMode, isTrue);

      // getLickForBox returns lick mapped to that box
      for (int b = 1; b <= 5; b++) {
        final boxLick = state.getLickForBox(b);
        expect(boxLick.notes.length, equals(claptonLick.notes.length));
      }
    });
  });

  group('Lick Recommendation Engine Tests', () {
    test('findLicksForChord recommends matching licks for Dominant 7th chord (A7)', () {
      final licks = LickAnalyzerService.findLicksForChord(
        chordRoot: 'A',
        chordQuality: '7',
      );

      expect(licks.isNotEmpty, isTrue);
      // First lick should be Clapton Crossroads (A7) or blues dominant lick
      final hasDominantOrBlues = licks.any((l) =>
          l.targetChord.contains('7') || l.genre.toLowerCase().contains('blues'));
      expect(hasDominantOrBlues, isTrue);
    });

    test('findLicksForChord recommends and transposes for Minor chord (Am)', () {
      final licks = LickAnalyzerService.findLicksForChord(
        chordRoot: 'A',
        chordQuality: 'm',
      );

      expect(licks.isNotEmpty, isTrue);
      for (final lick in licks) {
        expect(lick.defaultKey, contains('A'));
      }
    });

    test('findLicksForProgression recommends licks for 12-bar blues progression', () {
      final licks = LickAnalyzerService.findLicksForProgression(
        progressionChords: ['A7', 'D7', 'E7'],
        selectedChord: 'A7',
        key: 'A Major',
      );

      expect(licks.isNotEmpty, isTrue);
      expect(licks.first.defaultKey, contains('A'));
    });
  });

  group('Guitar Technique Audio Engine Tests', () {
    test('LickAudioPlayer executes playback and emits onTechniqueStep', () async {
      final player = LickAudioPlayer();
      final hendrixLick = kArtistLickPresets.firstWhere((l) => l.id == 'hendrix_voodoo');

      final techniquesReported = <NoteTechnique>[];
      int notesReported = 0;

      await player.playLick(
        hendrixLick,
        speed: 10.0, // High speed for test
        onNoteStep: (idx) {
          if (idx >= 0) notesReported++;
        },
        onTechniqueStep: (idx, tech) {
          if (idx >= 0) techniquesReported.add(tech);
        },
      );

      expect(notesReported, equals(hendrixLick.notes.length));
      expect(techniquesReported.length, equals(hendrixLick.notes.length));
      // Hendrix Voodoo contains bends or slides
      final hasTechnique = techniquesReported.any((t) => t != NoteTechnique.none);
      expect(hasTechnique, isTrue);
    });

    test('previewNote runs without throwing for technique notes', () {
      final player = LickAudioPlayer();
      const bendNote = LickNote(
        string: 2,
        fret: 15,
        interval: 'b7',
        noteName: 'D',
        technique: NoteTechnique.bendFull,
      );
      const slideNote = LickNote(
        string: 3,
        fret: 14,
        interval: '5',
        noteName: 'B',
        technique: NoteTechnique.slide,
      );

      expect(() => player.previewNote(bendNote), returnsNormally);
      expect(() => player.previewNote(slideNote), returnsNormally);
    });
  });
}
