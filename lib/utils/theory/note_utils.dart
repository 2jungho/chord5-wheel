import '../../models/music_constants.dart';

class NoteUtils {
  static final Map<String, int> _noteIndexMap = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5,
    'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10,
    'B': 11,
    'Am': 9, 'Em': 4, 'Bm': 11, 'F#m': 6, 'C#m': 1, 'G#m': 8,
    'Ebm': 3, 'Bbm': 10, 'Fm': 5, 'Cm': 0, 'Gm': 7, 'Dm': 2,
  };

  static String normalizeNoteName(String name) {
    return name.replaceAll('m', '');
  }

  static int getNoteIndex(String noteName) {
    final norm = normalizeNoteName(noteName);
    return _noteIndexMap[norm] ?? 0;
  }

  static String getNoteName(int chromaticIndex, bool useSharp) {
    final idx = (chromaticIndex % 12 + 12) % 12;
    final scale = useSharp
        ? MusicConstants.CHROMATIC_SHARP
        : MusicConstants.CHROMATIC_SCALE;
    return scale[idx];
  }

  static String transposeNote(String note, int semitones) {
    if (note.isEmpty) return note;
    final idx = getNoteIndex(note);
    final newIdx = (idx + semitones + 12) % 12;
    bool useSharp = !note.contains('b');
    return getNoteName(newIdx, useSharp);
  }

  static int intervalToSemitone(String iv) {
    switch (iv) {
      case '1':
      case '1P':
      case 'P1':
        return 0;
      case 'b2':
      case 'm2':
        return 1;
      case '2':
      case 'M2':
        return 2;
      case 'b3':
      case 'm3':
      case '#2':
        return 3;
      case '3':
      case 'M3':
        return 4;
      case '4':
      case 'P4':
        return 5;
      case 'b5':
      case 'd5':
      case '#4':
      case 'A4':
        return 6;
      case '5':
      case 'P5':
        return 7;
      case '#5':
      case 'A5':
      case 'b6':
      case 'm6':
        return 8;
      case '6':
      case 'M6':
      case 'bb7':
      case 'd7':
        return 9;
      case 'b7':
      case 'm7':
        return 10;
      case '7':
      case 'M7':
      case '7M':
        return 11;
      default:
        return 0;
    }
  }

  static String getIntervalName(int st) {
    const map = {
      0: '1P',
      1: 'm2',
      2: 'M2',
      3: 'm3',
      4: 'M3',
      5: 'P4',
      6: 'd5',
      7: 'P5',
      8: 'm6',
      9: 'M6',
      10: 'm7',
      11: 'M7'
    };
    return map[st] ?? '?';
  }

  /// 임의의 인터벌 표기(재즈/클래식)를 표준 클래식 키('1P', 'm3', 'P5' 등)로 정규화합니다.
  static String normalizeInterval(String iv) {
    switch (iv) {
      case '1':
      case '1P':
      case 'P1':
        return '1P';
      case 'b2':
      case 'm2':
        return 'm2';
      case '2':
      case 'M2':
        return 'M2';
      case 'b3':
      case 'm3':
      case '#2':
        return 'm3';
      case '3':
      case 'M3':
        return 'M3';
      case '4':
      case 'P4':
        return 'P4';
      case 'b5':
      case 'd5':
        return 'd5';
      case '#4':
      case 'A4':
        return '#4';
      case '5':
      case 'P5':
        return 'P5';
      case '#5':
      case 'A5':
      case 'b6':
      case 'm6':
        return 'm6';
      case '6':
      case 'M6':
      case 'bb7':
      case 'd7':
        return 'M6';
      case 'b7':
      case 'm7':
        return 'm7';
      case '7':
      case 'M7':
      case '7M':
        return 'M7';
      default:
        return iv;
    }
  }

  /// 인터벌의 동의어 집합을 반환하여 UI 필터 토글 시 연관된 모든 표기가 동기화되도록 지원합니다.
  static Set<String> getIntervalSynonyms(String iv) {
    final norm = normalizeInterval(iv);
    switch (norm) {
      case '1P':
        return {'1P', '1', 'P1'};
      case 'm2':
        return {'m2', 'b2'};
      case 'M2':
        return {'M2', '2'};
      case 'm3':
        return {'m3', 'b3', '#2'};
      case 'M3':
        return {'M3', '3'};
      case 'P4':
        return {'P4', '4'};
      case 'd5':
        return {'d5', 'b5', '#4', 'A4'};
      case '#4':
        return {'#4', 'A4', 'd5', 'b5'};
      case 'P5':
        return {'P5', '5'};
      case 'm6':
        return {'m6', 'b6', '#5', 'A5'};
      case 'M6':
        return {'M6', '6', 'bb7', 'd7'};
      case 'm7':
        return {'m7', 'b7'};
      case 'M7':
        return {'M7', '7', '7M'};
      default:
        return {iv};
    }
  }

  /// Normalizes any CAGED form string (e.g. "Em Form", "E Form", "Em", "E")
  /// to its single-letter uppercase base form ("E", "D", "C", "A", "G").
  static String normalizeCagedForm(String? form) {
    if (form == null || form.isEmpty) return '';
    final token = form.trim().split(RegExp(r'\s+'))[0];
    final base = token.replaceAll(RegExp(r'm$', caseSensitive: false), '').toUpperCase();
    if (const {'C', 'A', 'G', 'E', 'D'}.contains(base)) {
      return base;
    }
    return token;
  }
}
