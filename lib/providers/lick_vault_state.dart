import 'package:flutter/material.dart';
import '../models/lick/guitar_artist.dart';
import '../models/lick/artist_lick_model.dart';
import '../models/lick/artist_lick_presets.dart';
import '../models/audio/band_sound_profile.dart';
import '../models/fretboard_marker.dart';
import '../services/lick/lick_repository.dart';
import '../services/lick/asset_lick_repository.dart';
import '../services/lick_analyzer_service.dart';
import '../services/lick_audio_player.dart';
import 'studio_state.dart';

/// 아티스트 릭 보관함(Vault)의 탐색, 필터링, 화성 분석 및 오디오 재생 상태 관리
class LickVaultState extends ChangeNotifier {
  final LickRepository _repository;
  final LickAudioPlayer _player = LickAudioPlayer();

  bool _isInitialized = false;
  bool _isLoading = false;

  List<GuitarArtist> _allArtists = [];
  List<String> _genres = [];
  String? _selectedGenre;
  GuitarArtist? _selectedArtist;

  List<ArtistLick> _currentArtistLicks = [];
  String? _selectedTag;
  late ArtistLick _selectedLick;

  String _activeKey = 'G Major';
  double _playbackSpeed = 1.0;
  int _activePlayingNoteIndex = -1;

  // 기타 사운드 프로필 (통기타, 나일론, 클린, 오버드라이브, 디스토션)
  SoundProfile _selectedGuitarSound = BandSoundProfiles.guitarOverdrive;
  bool _hasUserSelectedSound = false;

  LickVaultState({LickRepository? repository})
      : _repository = repository ?? AssetLickRepository() {
    // 안전한 초기값 (로딩 전 기본 프리셋)
    _selectedLick = kArtistLickPresets.first;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<GuitarArtist> get allArtists => _allArtists;
  List<String> get genres => _genres;
  String? get selectedGenre => _selectedGenre;
  GuitarArtist? get selectedArtist => _selectedArtist;
  String? get selectedTag => _selectedTag;
  ArtistLick get selectedLick => _selectedLick;
  String get activeKey => _activeKey;
  double get playbackSpeed => _playbackSpeed;
  int get activePlayingNoteIndex => _activePlayingNoteIndex;
  bool get isPlaying => _player.isPlaying;
  SoundProfile get selectedGuitarSound => _selectedGuitarSound;
  List<SoundProfile> get availableGuitarSounds => BandSoundProfiles.allGuitar;

  /// 기타 사운드 프로필 직접 선택 (통기타, 나일론, 클린, 오버드라이브, 디스토션)
  void selectGuitarSound(SoundProfile profile) {
    _selectedGuitarSound = profile;
    _hasUserSelectedSound = true;
    _player.setSoundProfile(profile.id);
    notifyListeners();
  }

  /// 아티스트 및 릭 정보에 기반한 추천 기타 사운드 결정
  static SoundProfile getRecommendedSound(GuitarArtist? artist, ArtistLick? lick) {
    final text = '${artist?.name ?? ''} ${artist?.genre ?? ''} ${artist?.signatureGuitar ?? ''} ${artist?.bio ?? ''} ${lick?.tags.join(' ') ?? ''}'.toLowerCase();
    if (text.contains('acoustic') || text.contains('통기타') || text.contains('folk') || text.contains('emmanuel')) {
      return BandSoundProfiles.guitarAcoustic;
    }
    if (text.contains('nylon') || text.contains('flamenco') || text.contains('classical') || text.contains('lucia') || text.contains('bossa')) {
      return BandSoundProfiles.guitarNylon;
    }
    if (text.contains('shred') || text.contains('metal') || text.contains('moore') || text.contains('van halen') || text.contains('slash') || text.contains('rhoads') || text.contains('malmsteen') || text.contains('petrucci') || text.contains('heavy')) {
      return BandSoundProfiles.guitarDistortion;
    }
    if (text.contains('clean') || text.contains('wong') || text.contains('funk') || text.contains('jazz') || text.contains('benson') || text.contains('montgomery') || text.contains('neo-soul')) {
      return BandSoundProfiles.guitarClean;
    }
    return BandSoundProfiles.guitarOverdrive;
  }

  /// 현재 선택된 장르에 따라 필터링된 아티스트 목록
  List<GuitarArtist> get filteredArtists {
    if (_selectedGenre == null || _selectedGenre == 'All' || _selectedGenre == '전체') {
      return _allArtists;
    }
    return _allArtists.where((a) => a.genre == _selectedGenre).toList();
  }

  /// 현재 선택된 아티스트의 릭 중 태그 필터가 적용된 릭 목록
  List<ArtistLick> get filteredLicks {
    if (_currentArtistLicks.isEmpty) {
      return [_selectedLick];
    }
    if (_selectedTag == null) {
      return _currentArtistLicks;
    }
    return _currentArtistLicks.where((l) => l.tags.contains(_selectedTag)).toList();
  }

  /// 현재 활성 릭 목록에서 사용 가능한 모든 태그
  List<String> get availableTags {
    final tags = <String>{};
    for (final lick in _currentArtistLicks) {
      tags.addAll(lick.tags);
    }
    return tags.toList();
  }

  /// 현재 활성 키(_activeKey)에 맞춰 조옮김된 릭
  ArtistLick get currentTransposedLick {
    return LickAnalyzerService.transposeLick(
      _selectedLick,
      toKey: _activeKey,
    );
  }

  /// 현재 타겟 코드에 대한 화성학 분석 결과
  ({String summary, List<String> noteAnalyses}) get harmonicAnalysis {
    final transposed = currentTransposedLick;
    return LickAnalyzerService.analyzeHarmonicContext(
      transposed,
      transposed.targetChord,
    );
  }

  /// 프렛보드 맵 표시용 Highlight Map
  Map<int, List<FretboardMarker>> get fretboardHighlightMap {
    return LickAnalyzerService.mapLickToHighlightMap(currentTransposedLick);
  }

  /// 프렛보드 맵 표시용 보이스 라인 흐름선
  List<VoiceLeadingLine> get lickFlowLines {
    return LickAnalyzerService.generateLickFlowLines(currentTransposedLick);
  }

  /// 비동기 초기 데이터 로드 (앱 구동 또는 모달 진입 시 자동 호출)
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _allArtists = await _repository.getArtists();
      _genres = await _repository.getGenres();

      if (_allArtists.isNotEmpty) {
        _selectedArtist = _allArtists.first;
        _currentArtistLicks = await _repository.getLicksByArtist(_selectedArtist!.id);
        if (_currentArtistLicks.isNotEmpty) {
          _selectedLick = _currentArtistLicks.first;
        }
        if (!_hasUserSelectedSound) {
          _selectedGuitarSound = getRecommendedSound(_selectedArtist, _selectedLick);
          _player.setSoundProfile(_selectedGuitarSound.id);
        }
      }
      _isInitialized = true;
    } catch (e) {
      // fallback 유지
      // ignore: avoid_print
      print('Warning: LickVaultState initialization fallback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 장르 탭 필터 선택
  Future<void> selectGenre(String? genre) async {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    _selectedTag = null;

    final candidates = filteredArtists;
    if (candidates.isNotEmpty) {
      await selectArtist(candidates.first);
    } else {
      _currentArtistLicks = [];
      notifyListeners();
    }
  }

  /// 아티스트 선택
  Future<void> selectArtist(GuitarArtist? artist) async {
    if (artist == null || _selectedArtist?.id == artist.id) return;
    _selectedArtist = artist;
    _selectedTag = null;
    _isLoading = true;
    _stopAndResetPlayer();
    notifyListeners();

    try {
      _currentArtistLicks = await _repository.getLicksByArtist(artist.id);
      if (_currentArtistLicks.isNotEmpty) {
        _selectedLick = _currentArtistLicks.first;
      }
      if (!_hasUserSelectedSound) {
        _selectedGuitarSound = getRecommendedSound(artist, _selectedLick);
        _player.setSoundProfile(_selectedGuitarSound.id);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Failed to load licks for artist ${artist.name}: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 태그 필터 토글
  void selectTag(String? tag) {
    if (_selectedTag == tag) {
      _selectedTag = null;
    } else {
      _selectedTag = tag;
    }

    final candidates = filteredLicks;
    if (candidates.isNotEmpty && !candidates.contains(_selectedLick)) {
      _selectedLick = candidates.first;
    }
    _stopAndResetPlayer();
    notifyListeners();
  }

  /// 릭 선택
  void selectLick(ArtistLick lick) {
    if (_selectedLick.id == lick.id) return;
    _selectedLick = lick;
    _stopAndResetPlayer();
    notifyListeners();
  }

  /// 스튜디오 세션 키 동기화
  void syncKey(String key) {
    if (_activeKey == key) return;
    _activeKey = key;
    _stopAndResetPlayer();
    notifyListeners();
  }

  /// 재생 속도 변경 (0.5x, 0.75x, 1.0x)
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  /// 릭 오디오 재생 및 정지
  Future<void> togglePlay() async {
    if (_player.isPlaying) {
      _player.stop();
      _activePlayingNoteIndex = -1;
      notifyListeners();
    } else {
      notifyListeners();
      await _player.playLick(
        currentTransposedLick,
        speed: _playbackSpeed,
        soundProfileId: _selectedGuitarSound.id,
        onNoteStep: (index) {
          _activePlayingNoteIndex = index;
          notifyListeners();
        },
        onComplete: () {
          _activePlayingNoteIndex = -1;
          notifyListeners();
        },
      );
    }
  }

  /// 단일 음표 미리듣기 (TAB 클릭 시)
  void previewNote(LickNote note) {
    _player.previewNote(note, soundProfileId: _selectedGuitarSound.id);
  }

  void _stopAndResetPlayer() {
    _player.stop();
    _activePlayingNoteIndex = -1;
  }

  /// 현재 릭의 타겟 코드를 스튜디오 진행에 추가합니다.
  void insertLickChordIntoStudio(StudioState studio) {
    final transposed = currentTransposedLick;
    studio.addProgressionFromText(transposed.targetChord);
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }
}
