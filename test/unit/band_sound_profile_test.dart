import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/audio/band_sound_profile.dart';
import 'package:guitar_theory_app/providers/lyria_state.dart';

void main() {
  group('BandSoundProfiles Model & Catalog Tests', () {
    test('Should have exactly 4 sound profiles per instrument category (16 total)', () {
      expect(BandSoundProfiles.allDrums.length, 4);
      expect(BandSoundProfiles.allBass.length, 4);
      expect(BandSoundProfiles.allKeys.length, 4);
      expect(BandSoundProfiles.allGuitar.length, 4);

      expect(
        BandSoundProfiles.getProfilesForCategory(BandInstrumentCategory.drums).length,
        4,
      );
      expect(
        BandSoundProfiles.getProfilesForCategory(BandInstrumentCategory.bass).length,
        4,
      );
      expect(
        BandSoundProfiles.getProfilesForCategory(BandInstrumentCategory.keys).length,
        4,
      );
      expect(
        BandSoundProfiles.getProfilesForCategory(BandInstrumentCategory.guitar).length,
        4,
      );
    });

    test('Should retrieve profile by id correctly', () {
      final acousticDrums = BandSoundProfiles.getProfileById('drums_acoustic', BandInstrumentCategory.drums);
      expect(acousticDrums.id, 'drums_acoustic');
      expect(acousticDrums.name, contains('스튜디오 어쿠스틱'));

      final slapBass = BandSoundProfiles.getProfileById('bass_slap', BandInstrumentCategory.bass);
      expect(slapBass.id, 'bass_slap');
      expect(slapBass.shortName, '펑키 슬랩');

      final rhodesKeys = BandSoundProfiles.getProfileById('keys_rhodes', BandInstrumentCategory.keys);
      expect(rhodesKeys.id, 'keys_rhodes');

      final nylonGuitar = BandSoundProfiles.getProfileById('guitar_nylon', BandInstrumentCategory.guitar);
      expect(nylonGuitar.id, 'guitar_nylon');
    });

    test('Should recommend appropriate 4-band sound profiles according to style keywords', () {
      // 1. Lofi
      final lofiPresets = BandSoundProfiles.getRecommendedProfilesForStyle('Lo-Fi Chill');
      expect(lofiPresets[BandInstrumentCategory.drums]?.id, 'drums_lofi');
      expect(lofiPresets[BandInstrumentCategory.guitar]?.id, 'guitar_nylon');

      // 2. City Pop / Disco
      final cityPopPresets = BandSoundProfiles.getRecommendedProfilesForStyle('City Pop');
      expect(cityPopPresets[BandInstrumentCategory.drums]?.id, 'drums_electronic');
      expect(cityPopPresets[BandInstrumentCategory.bass]?.id, 'bass_slap');
      expect(cityPopPresets[BandInstrumentCategory.keys]?.id, 'keys_pad');
      expect(cityPopPresets[BandInstrumentCategory.guitar]?.id, 'guitar_clean');

      // 3. Acoustic / Ballad
      final acousticPresets = BandSoundProfiles.getRecommendedProfilesForStyle('Acoustic Ballad');
      expect(acousticPresets[BandInstrumentCategory.drums]?.id, 'drums_acoustic');
      expect(acousticPresets[BandInstrumentCategory.bass]?.id, 'bass_upright');
      expect(acousticPresets[BandInstrumentCategory.keys]?.id, 'keys_piano');
      expect(acousticPresets[BandInstrumentCategory.guitar]?.id, 'guitar_acoustic');

      // 4. Blues
      final bluesPresets = BandSoundProfiles.getRecommendedProfilesForStyle('Blues 12-bar');
      expect(bluesPresets[BandInstrumentCategory.drums]?.id, 'drums_brush');
      expect(bluesPresets[BandInstrumentCategory.keys]?.id, 'keys_organ');
      expect(bluesPresets[BandInstrumentCategory.guitar]?.id, 'guitar_crunch');
    });
  });

  group('LyriaState Sound Profile Integration Tests', () {
    test('Should initialize with default sound profiles', () {
      final state = LyriaState();
      expect(state.selectedDrums.id, isNotEmpty);
      expect(state.selectedBass.id, isNotEmpty);
      expect(state.selectedKeys.id, isNotEmpty);
      expect(state.selectedGuitar.id, isNotEmpty);
    });

    test('Should allow manual sound profile selection and notify listeners', () {
      final state = LyriaState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setSoundProfile(BandInstrumentCategory.guitar, BandSoundProfiles.guitarCrunch);
      expect(state.selectedGuitar.id, 'guitar_crunch');
      expect(notifyCount, 1);

      state.setSoundProfile(BandInstrumentCategory.bass, BandSoundProfiles.bassSynth);
      expect(state.selectedBass.id, 'bass_synth');
      expect(notifyCount, 2);
    });

    test('Should auto-update sound profiles when style is changed', () {
      final state = LyriaState();

      state.updateStyle('City Pop');
      expect(state.selectedDrums.id, 'drums_electronic');
      expect(state.selectedBass.id, 'bass_slap');
      expect(state.selectedKeys.id, 'keys_pad');
      expect(state.selectedGuitar.id, 'guitar_clean');

      state.updateStyle('Acoustic');
      expect(state.selectedDrums.id, 'drums_acoustic');
      expect(state.selectedBass.id, 'bass_upright');
      expect(state.selectedKeys.id, 'keys_piano');
      expect(state.selectedGuitar.id, 'guitar_acoustic');
    });
  });
}
