import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/instrument_model.dart';
import 'package:guitar_theory_app/models/progression/progression_models.dart';
import 'package:guitar_theory_app/providers/studio_state.dart';
import 'package:guitar_theory_app/utils/guitar_utils.dart';

void main() {
  group('1. Custom & Drop Tunings Engine Tests', () {
    test('Tuning presets have correct note definitions', () {
      expect(TuningPreset.standard.notes, equals(['E', 'A', 'D', 'G', 'B', 'E']));
      expect(TuningPreset.dropD.notes, equals(['D', 'A', 'D', 'G', 'B', 'E']));
      expect(TuningPreset.halfStepDown.notes, equals(['Eb', 'Ab', 'Db', 'Gb', 'Bb', 'Eb']));
      expect(TuningPreset.dadgad.notes, equals(['D', 'A', 'D', 'G', 'A', 'D']));
      expect(TuningPreset.openD.notes, equals(['D', 'A', 'D', 'F#', 'A', 'D']));
      expect(TuningPreset.openG.notes, equals(['D', 'G', 'D', 'G', 'B', 'D']));
    });

    test('generateFretboardMap reflects custom tuning (Drop D 6th string D note at fret 0)', () {
      final mapStandard = GuitarUtils.generateFretboardMap(
        root: 'D',
        notes: ['D'],
        tuning: TuningPreset.standard.notes,
      );
      // Standard tuning: 6th string (index 0) D note is at fret 10
      expect(mapStandard[0]?.any((m) => m.fret == 10), isTrue);

      final mapDropD = GuitarUtils.generateFretboardMap(
        root: 'D',
        notes: ['D'],
        tuning: TuningPreset.dropD.notes,
      );
      // Drop D tuning: 6th string (index 0) D note is at open string fret 0 and 12
      expect(mapDropD[0]?.any((m) => m.fret == 0), isTrue);
      expect(mapDropD[0]?.any((m) => m.fret == 12), isTrue);
    });
  });

  group('2. Strum & TAB Visualizer Tests', () {
    test('RhythmPattern default steps correctly instantiate', () {
      final pattern = RhythmPattern.presets.first;
      expect(pattern.steps.isNotEmpty, isTrue);
      expect(pattern.steps.first.action, equals(RhythmActionType.down));
    });
  });

  group('3. Song Structure Arranger Tests', () {
    test('StudioState manages SongSections (Intro, Verse, Chorus)', () {
      final studio = StudioState();
      expect(studio.session.sections.isEmpty || studio.session.sections.length == 1, isTrue);

      // Add Chorus
      studio.addSection('Chorus');
      expect(studio.session.sections.any((s) => s.name == 'Chorus'), isTrue);
      expect(studio.session.activeSectionIndex, equals(studio.session.sections.length - 1));

      // Add Bridge
      studio.addSection('Bridge');
      expect(studio.session.sections.any((s) => s.name == 'Bridge'), isTrue);

      // Select Verse
      studio.selectSection(0);
      expect(studio.session.activeSectionIndex, equals(0));

      // Rename Section
      studio.renameSection(0, 'Intro');
      expect(studio.session.sections[0].name, equals('Intro'));
    });
  });
}
