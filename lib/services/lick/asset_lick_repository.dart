import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/lick/guitar_artist.dart';
import '../../models/lick/artist_lick_model.dart';
import 'lick_repository.dart';

/// Flutter 번들 JSON 에셋 기반 지연 로딩(Lazy-loading) Repository 구현체
class AssetLickRepository implements LickRepository {
  static const String _artistsAssetPath = 'assets/data/artists/artists.json';

  static const Map<String, String> _genreToFileMap = {
    'Blues & Blues Rock': 'assets/data/licks/licks_blues.json',
    'Classic & Hard Rock': 'assets/data/licks/licks_rock.json',
    'Tone & Expressive': 'assets/data/licks/licks_tone.json',
    'Instrumental Rock': 'assets/data/licks/licks_instrumental.json',
    'Shred & Neo-Classical': 'assets/data/licks/licks_shred.json',
    'Jazz & Fusion': 'assets/data/licks/licks_jazz.json',
    'Neo-Soul & Modern': 'assets/data/licks/licks_neosoul.json',
  };

  List<GuitarArtist>? _artistCache;
  final Map<String, List<ArtistLick>> _lickCacheByArtist = {};
  final Set<String> _loadedGenreAssets = {};
  final List<ArtistLick> _allLoadedLicks = [];

  @override
  Future<List<GuitarArtist>> getArtists({String? genre}) async {
    if (_artistCache == null) {
      final jsonString = await rootBundle.loadString(_artistsAssetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;
      _artistCache = list.map((e) => GuitarArtist.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (genre == null || genre.isEmpty || genre == 'All' || genre == '전체') {
      return List.unmodifiable(_artistCache!);
    }

    return _artistCache!.where((a) => a.genre == genre).toList();
  }

  @override
  Future<List<String>> getGenres() async {
    final artists = await getArtists();
    final genres = artists.map((a) => a.genre).toSet().toList();
    return genres;
  }

  @override
  Future<List<ArtistLick>> getLicksByArtist(String artistId) async {
    // 1. 이미 메모리에 캐시되어 있다면 즉시 반환
    if (_lickCacheByArtist.containsKey(artistId)) {
      return List.unmodifiable(_lickCacheByArtist[artistId]!);
    }

    // 2. 해당 아티스트의 장르 파악
    final artists = await getArtists();
    final artist = artists.firstWhere(
      (a) => a.id == artistId,
      orElse: () => throw ArgumentError('Artist with id $artistId not found'),
    );

    // 3. 해당 장르의 JSON 파일만 지연 로딩(Lazy load)
    await _loadGenreAssetIfNeeded(artist.genre);

    final licks = _allLoadedLicks.where((l) => l.artistId == artistId).toList();
    _lickCacheByArtist[artistId] = licks;
    return List.unmodifiable(licks);
  }

  @override
  Future<List<ArtistLick>> getLicksByGenre(String genre) async {
    await _loadGenreAssetIfNeeded(genre);
    return _allLoadedLicks.where((l) => l.genre == genre).toList();
  }

  @override
  Future<List<ArtistLick>> getAllLicks() async {
    // 모든 장르 파일 로드
    for (final genre in _genreToFileMap.keys) {
      await _loadGenreAssetIfNeeded(genre);
    }
    return List.unmodifiable(_allLoadedLicks);
  }

  @override
  Future<List<ArtistLick>> searchLicks({String? query, String? tag}) async {
    final all = await getAllLicks();
    return all.where((lick) {
      if (tag != null && !lick.tags.contains(tag)) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        return lick.title.toLowerCase().contains(q) ||
            lick.artist.toLowerCase().contains(q) ||
            lick.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _loadGenreAssetIfNeeded(String genre) async {
    final assetPath = _genreToFileMap[genre];
    if (assetPath == null || _loadedGenreAssets.contains(assetPath)) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;
      final licks = list.map((e) => ArtistLick.fromJson(e as Map<String, dynamic>)).toList();

      for (final lick in licks) {
        if (!_allLoadedLicks.any((l) => l.id == lick.id)) {
          _allLoadedLicks.add(lick);
        }
        if (!_lickCacheByArtist.containsKey(lick.artistId)) {
          _lickCacheByArtist[lick.artistId] = [];
        }
        if (!_lickCacheByArtist[lick.artistId]!.any((l) => l.id == lick.id)) {
          _lickCacheByArtist[lick.artistId]!.add(lick);
        }
      }

      _loadedGenreAssets.add(assetPath);
    } catch (e) {
      // 에셋 로딩 예외 안전 처리
      // ignore: avoid_print
      print('Warning: Failed to load lick asset for $genre ($assetPath): $e');
    }
  }
}
