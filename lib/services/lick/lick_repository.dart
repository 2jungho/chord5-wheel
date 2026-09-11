import '../../models/lick/guitar_artist.dart';
import '../../models/lick/artist_lick_model.dart';

/// 아티스트 및 시그니처 릭 데이터 접근 추상 인터페이스
abstract class LickRepository {
  /// 모든 아티스트 또는 특정 장르의 아티스트 목록을 반환합니다.
  Future<List<GuitarArtist>> getArtists({String? genre});

  /// 사용 가능한 모든 장르 목록을 반환합니다.
  Future<List<String>> getGenres();

  /// 특정 아티스트의 시그니처 릭 목록을 반환합니다 (지연 로딩).
  Future<List<ArtistLick>> getLicksByArtist(String artistId);

  /// 특정 장르의 모든 시그니처 릭 목록을 반환합니다.
  Future<List<ArtistLick>> getLicksByGenre(String genre);

  /// 전체 릭 목록을 반환합니다.
  Future<List<ArtistLick>> getAllLicks();

  /// 검색어 또는 태그로 릭을 검색합니다.
  Future<List<ArtistLick>> searchLicks({String? query, String? tag});
}
