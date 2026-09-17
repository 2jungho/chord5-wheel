import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/lick/artist_lick_model.dart';
import 'package:guitar_theory_app/providers/lick_vault_state.dart';
import 'package:guitar_theory_app/services/ai_lick_generator_service.dart';
import 'package:guitar_theory_app/services/prompt_templates.dart';

void main() {
  group('AILickGeneratorService Tests', () {
    test('PromptTemplates produces valid prompts with playability constraints', () {
      final sysPrompt = PromptTemplates.getLickGeneratorSystemPrompt('기타 마스터');
      expect(sysPrompt, contains('Playability'));
      expect(sysPrompt, contains('cagedForm'));
      expect(sysPrompt, contains('technique'));

      final userPrompt = PromptTemplates.getLickGeneratorUserPrompt(
        prompt: '블루스 벤딩 릭',
        currentKey: 'E Minor',
        targetChord: 'Em7',
        artistStyle: 'SRV Style',
      );
      expect(userPrompt, contains('E Minor'));
      expect(userPrompt, contains('Em7'));
      expect(userPrompt, contains('SRV Style'));
      expect(userPrompt, contains('Response Format (JSON Object):'));
    });

    test('sanitizeAndBuildLick converts raw AI JSON into valid ArtistLick', () {
      final sampleJson = {
        'id': 'ai_test_lick_1',
        'artistId': 'custom_ai',
        'artist': 'AI Guitar Master',
        'genre': 'Blues',
        'title': 'Soulful E Minor Bend',
        'difficulty': 'Intermediate',
        'defaultKey': 'E Minor',
        'targetChord': 'Em',
        'applicableDegrees': ['i', 'iv'],
        'scaleUsed': 'E Minor Pentatonic',
        'cagedForm': 'E Form',
        'pentatonicBox': 1,
        'description': '애절한 벤딩 중심의 블루스 릭입니다.',
        'theoryTips': '1번줄 15프렛 Full 벤딩 후 단3도에서 근음으로 해결합니다.',
        'tags': ['Full Bend', 'Vibrato'],
        'notes': [
          {
            'string': 3,
            'fret': 12,
            'duration': 0.5,
            'interval': 'R',
            'noteName': 'G',
            'technique': 'none',
            'isTargetNote': false,
          },
          {
            'string': 2,
            'fret': 15,
            'duration': 0.5,
            'interval': 'b7',
            'noteName': 'D',
            'technique': 'bendFull',
            'isTargetNote': false,
          },
          {
            'string': 1,
            'fret': 12,
            'duration': 1.0,
            'interval': 'R',
            'noteName': 'E',
            'technique': 'vibrato',
            'isTargetNote': true,
          }
        ]
      };

      final lick = AILickGeneratorService.sanitizeAndBuildLick(
        sampleJson,
        fallbackKey: 'E Minor',
        fallbackTargetChord: 'Em',
        userPrompt: 'Soulful Blues',
      );

      expect(lick.id, equals('ai_test_lick_1'));
      expect(lick.title, equals('Soulful E Minor Bend'));
      expect(lick.pentatonicBox, equals(1));
      expect(lick.cagedForm, equals('E Form'));
      expect(lick.tags, contains('AI Generated'));
      expect(lick.tags, contains('Full Bend'));
      expect(lick.notes.length, equals(3));
      expect(lick.notes[1].technique, equals(NoteTechnique.bendFull));
      expect(lick.notes[2].isTargetNote, isTrue);
    });

    test('sanitizeAndBuildLick clamps out-of-bounds strings and frets safely', () {
      final noisyJson = {
        'title': 'Extreme Lick',
        'notes': [
          {
            'string': 8, // out of range, should clamp to 6
            'fret': 35, // out of range, should clamp to 24
            'technique': 'unknown_technique', // fallback to none
          }
        ]
      };

      final lick = AILickGeneratorService.sanitizeAndBuildLick(
        noisyJson,
        fallbackKey: 'A Minor',
        fallbackTargetChord: 'Am',
      );

      expect(lick.notes.first.string, equals(6));
      expect(lick.notes.first.fret, equals(24));
      expect(lick.notes.first.technique, equals(NoteTechnique.none));
      expect(lick.tags, contains('AI Generated'));
    });

    test('formatLickAsJson produces valid, indented JSON string ready for file storage', () {
      final note = const LickNote(
        string: 1,
        fret: 12,
        duration: 0.5,
        interval: 'R',
        noteName: 'E',
        technique: NoteTechnique.vibrato,
        isTargetNote: true,
      );
      final lick = ArtistLick(
        id: 'json_export_test',
        artist: 'Export Master',
        title: 'Export Lick',
        defaultKey: 'E Minor',
        targetChord: 'Em',
        applicableDegrees: const ['i'],
        scaleUsed: 'Pentatonic',
        cagedForm: 'E Form',
        pentatonicBox: 1,
        description: 'Test export',
        theoryTips: 'Tips',
        tags: const ['AI Generated'],
        notes: [note],
      );

      final jsonStr = AILickGeneratorService.formatLickAsJson(lick);
      expect(jsonStr, contains('"id": "json_export_test"'));
      expect(jsonStr, contains('"technique": "vibrato"'));

      // Validate decode
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final reconstructed = ArtistLick.fromJson(decoded);
      expect(reconstructed.id, equals(lick.id));
      expect(reconstructed.notes.first.technique, equals(NoteTechnique.vibrato));
    });

    test('LickVaultState addCustomLick prepends lick and sets as selected', () {
      final vault = LickVaultState();
      final customLick = const ArtistLick(
        id: 'custom_runtime_lick',
        artist: 'Custom AI Hero',
        title: 'My Custom Lick',
        defaultKey: 'C Major',
        targetChord: 'C',
        applicableDegrees: ['I'],
        scaleUsed: 'Major Pentatonic',
        cagedForm: 'C Form',
        pentatonicBox: 3,
        description: 'Dynamically added',
        theoryTips: 'Tips',
        tags: ['AI Generated'],
        notes: [
          LickNote(
            string: 2,
            fret: 5,
            duration: 0.5,
            interval: '3',
            noteName: 'E',
            technique: NoteTechnique.none,
            isTargetNote: true,
          ),
        ],
      );

      vault.addCustomLick(customLick);

      expect(vault.selectedLick.id, equals('custom_runtime_lick'));
      expect(vault.selectedBox, equals(3));
      expect(vault.filteredLicks.first.id, equals('custom_runtime_lick'));
    });
  });
}
