import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/lick/artist_lick_model.dart';
import 'package:guitar_theory_app/services/lick/asset_lick_repository.dart';
import 'package:guitar_theory_app/providers/lick_vault_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetLickRepository repository;

  setUp(() {
    repository = AssetLickRepository();
  });

  group('AssetLickRepository & JSON Assets Verification', () {
    test('Loads 18 legendary guitar artists across 7 distinct genres', () async {
      final artists = await repository.getArtists();
      expect(artists.length, equals(18));

      final genres = await repository.getGenres();
      expect(genres.length, equals(7));
      expect(genres, contains('Blues & Blues Rock'));
      expect(genres, contains('Classic & Hard Rock'));
      expect(genres, contains('Tone & Expressive'));
      expect(genres, contains('Instrumental Rock'));
      expect(genres, contains('Shred & Neo-Classical'));
      expect(genres, contains('Jazz & Fusion'));
      expect(genres, contains('Neo-Soul & Modern'));

      // Validate artist models
      for (final artist in artists) {
        expect(artist.id, isNotEmpty);
        expect(artist.name, isNotEmpty);
        expect(artist.koreanName, isNotEmpty);
        expect(artist.era, isNotEmpty);
        expect(artist.signatureGuitar, isNotEmpty);
        expect(artist.bio, isNotEmpty);
        expect(artist.famousSongs, isNotEmpty);
      }
    });

    test('Filters artists by specific genre correctly', () async {
      final rockArtists = await repository.getArtists(genre: 'Classic & Hard Rock');
      expect(rockArtists.length, equals(3));
      final names = rockArtists.map((a) => a.name).toList();
      expect(names, containsAll(['Jimmy Page', 'Eddie Van Halen', 'Slash']));

      final shredArtists = await repository.getArtists(genre: 'Shred & Neo-Classical');
      expect(shredArtists.length, equals(2));
      expect(shredArtists.map((a) => a.name), containsAll(['Yngwie Malmsteen', 'Paul Gilbert']));

      final jazzArtists = await repository.getArtists(genre: 'Jazz & Fusion');
      expect(jazzArtists.length, equals(2));
      expect(jazzArtists.map((a) => a.name), containsAll(['Wes Montgomery', 'Joe Pass']));
    });

    test('Lazy loads licks for individual artists on demand', () async {
      // 1. Hendrix
      final hendrixLicks = await repository.getLicksByArtist('hendrix');
      expect(hendrixLicks.length, greaterThanOrEqualTo(2));
      expect(hendrixLicks.first.artist, equals('Jimi Hendrix'));

      // 2. Van Halen (Tapping technique)
      final vanHalenLicks = await repository.getLicksByArtist('van_halen');
      expect(vanHalenLicks.length, greaterThanOrEqualTo(2));
      final eruption = vanHalenLicks.firstWhere((l) => l.id == 'van_halen_eruption');
      expect(eruption.notes.any((n) => n.technique == NoteTechnique.tap), isTrue);

      // 3. Gilmour (Epic Bend)
      final gilmourLicks = await repository.getLicksByArtist('gilmour');
      expect(gilmourLicks.length, greaterThanOrEqualTo(2));
      expect(gilmourLicks.any((l) => l.title.contains('Comfortably Numb')), isTrue);

      // 4. Henson (Polyphia Trap Guitar)
      final hensonLicks = await repository.getLicksByArtist('henson');
      expect(hensonLicks.length, greaterThanOrEqualTo(2));
      expect(hensonLicks.any((l) => l.title.contains('Playing God')), isTrue);
    });

    test('getAllLicks loads all 40+ licks across entire library', () async {
      final allLicks = await repository.getAllLicks();
      expect(allLicks.length, greaterThanOrEqualTo(35));
    });

    test('searchLicks finds licks by text query and tags', () async {
      final bendResults = await repository.searchLicks(tag: 'Full Bend');
      expect(bendResults, isNotEmpty);

      final sweepResults = await repository.searchLicks(query: 'Sweep');
      expect(sweepResults.any((l) => l.artist == 'Yngwie Malmsteen'), isTrue);
    });
  });

  group('LickVaultState with Repository Integration', () {
    test('initialize loads artists and selects initial lick asynchronously', () async {
      final state = LickVaultState(repository: repository);
      expect(state.isInitialized, isFalse);

      await state.initialize();
      expect(state.isInitialized, isTrue);
      expect(state.allArtists.length, equals(18));
      expect(state.selectedArtist?.name, equals('Jimi Hendrix'));
      expect(state.selectedLick.artist, equals('Jimi Hendrix'));
    });

    test('selectGenre filters artists and dynamically loads new artist licks', () async {
      final state = LickVaultState(repository: repository);
      await state.initialize();

      await state.selectGenre('Classic & Hard Rock');
      expect(state.selectedGenre, equals('Classic & Hard Rock'));
      expect(state.filteredArtists.length, equals(3));
      expect(state.selectedArtist?.name, equals('Jimmy Page'));
      expect(state.selectedLick.artist, equals('Jimmy Page'));
    });

    test('selectArtist switches artist and loads their signature licks', () async {
      final state = LickVaultState(repository: repository);
      await state.initialize();

      final gilmour = state.allArtists.firstWhere((a) => a.id == 'gilmour');
      await state.selectArtist(gilmour);

      expect(state.selectedArtist?.id, equals('gilmour'));
      expect(state.selectedLick.artist, equals('David Gilmour'));
      expect(state.filteredLicks.every((l) => l.artist == 'David Gilmour'), isTrue);
    });
  });
}
