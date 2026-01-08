import 'package:flutter/material.dart';

class PianoChordWidget extends StatelessWidget {
  final List<String> notes;
  final double width;
  final double height;
  final bool showLabels;

  const PianoChordWidget({
    super.key,
    required this.notes,
    this.width = 100,
    this.height = 60,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _PianoChordPainter(notes: notes, showLabels: showLabels),
      ),
    );
  }
}

class _PianoChordPainter extends CustomPainter {
  final List<String> notes;
  final bool showLabels;

  // 정규화된 노트 이름 집합 (매칭 효율화)
  late final Set<String> _activeNotes;
  late final int _startOctave; // 동적으로 결정될 시작 옥타브

  String _normalizeNote(String note) {
    // 1. 공백 제거
    String clean = note.trim();

    // 2. 유니코드 변환 (특수문자 -> 가독문자)
    clean = clean.replaceAll('♯', '#');
    clean = clean.replaceAll('♭', 'b');
    // 혹시 모를 다른 특수문자들도 처리하고 싶다면 추가

    return clean;
  }

  _PianoChordPainter({required this.notes, required this.showLabels}) {
    // 1. 기본 노트 저장
    // 2. 이명동음(Enharmonic) 처리
    final extendedNotes = <String>{};

    for (final rawNote in notes) {
      final note = _normalizeNote(rawNote); // 정규화 적용
      extendedNotes.add(note);

      // 옥타브 분리 (예: F#3 -> notePart:F#, octPart:3)
      // 정규식: (노트이름)(옥타브숫자)
      final match = RegExp(r'^([A-G][#b]?)(-?\d+)$').firstMatch(note);
      if (match != null) {
        final notePart = match.group(1)!;
        final octPart = match.group(2)!;

        final enharmonic = _getEnharmonic(notePart);
        if (enharmonic != notePart) {
          extendedNotes.add('$enharmonic$octPart');
        }
      }
    }

    _activeNotes = extendedNotes;

    // 입력된 노트들에서 최소 옥타브 찾기
    int minOctave = 10;
    final octaveRegExp = RegExp(r'(-?\d+)$');

    bool foundOctave = false;
    for (final rawNote in notes) {
      final note = _normalizeNote(rawNote); // 정규화 적용
      final match = octaveRegExp.firstMatch(note);
      if (match != null) {
        final oct = int.parse(match.group(1)!);
        if (oct < minOctave) {
          minOctave = oct;
          foundOctave = true;
        }
      }
    }

    if (foundOctave) {
      _startOctave = minOctave;
    } else {
      _startOctave = 3;
    }
  }

  String _getEnharmonic(String note) {
    const map = {
      'C#': 'Db', 'Db': 'C#',
      'D#': 'Eb', 'Eb': 'D#',
      'F#': 'Gb', 'Gb': 'F#',
      'G#': 'Ab', 'Ab': 'G#',
      'A#': 'Bb', 'Bb': 'A#',
      // 필요 시 E#->F, B#->C, Fb->E, Cb->B 등 추가 가능하나
      // 현재 시스템상 C#/Db 류만 주로 사용됨.
    };
    return map[note] ?? note;
  }

  bool _checkActive(String targetNoteName, int targetOctave) {
    // targetNoteName은 이미 내부적으로 표준 포맷(C#, F# 등)이므로 정규화 불필요

    // 1. Direct Set Lookup (Fast path)
    final key1 = '$targetNoteName$targetOctave';
    if (_activeNotes.contains(key1)) return true;

    // 2. Enharmonic Lookup
    final enharmonic = _getEnharmonic(targetNoteName);
    final key2 = '$enharmonic$targetOctave';
    if (_activeNotes.contains(key2)) return true;

    // 3. Fuzzy Scan
    // _activeNotes에 들어있는 원본(혹은 extended) 문자열들을 직접 파싱하여 비교
    // 공백, 특수문자 이슈 등을 우회
    for (final active in _activeNotes) {
      // active는 이미 생성자에서 _normalizeNote 됨.

      // 숫자 앞부분을 노트, 뒷부분을 옥타브로 분리
      // 정규식을 좀 더 유연하게: [^\d-]+ (숫자나 마이너스가 아닌 것)
      final match = RegExp(r'^([^\d-]+)(-?\d+)$').firstMatch(active);
      if (match != null) {
        final n = match.group(1)!; // 이미 trim 됨
        final o = int.parse(match.group(2)!);

        if (o == targetOctave) {
          // 이름 비교 (F# == Gb 등)
          if (n == targetNoteName || n == enharmonic) return true;
          if (_getEnharmonic(n) == targetNoteName) return true;
        }
      } else {
        // 옥타브 정보가 없는 노트 (예: "C", "C#")
        // 이 경우, 현재 targetOctave가 _startOctave와 같을 때만 활성화
        // (중복 표시 방지 및 기본 위치 표시)
        if (targetOctave == _startOctave) {
          if (active == targetNoteName || active == enharmonic) return true;
          if (_getEnharmonic(active) == targetNoteName) return true;
        }
      }
    }

    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 동적으로 결정된 startOctave 사용
    final int startOctave = _startOctave;
    const int octaveCount = 2; // 2옥타브 표시 (대부분의 코드 보이싱 커버 가능)
    const int whiteKeyCount = octaveCount * 7;

    final double whiteKeyWidth = size.width / whiteKeyCount;
    final double blackKeyWidth = whiteKeyWidth * 0.65;
    final double blackKeyHeight = size.height * 0.6;

    final Paint whiteKeyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint whiteKeyBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final Paint blackKeyPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Highlight colors
    final Paint activeWhitePaint = Paint()..color = Colors.blue.shade300;
    final Paint activeBlackPaint = Paint()..color = Colors.blue.shade400;

    // White Keys: C, D, E, F, G, A, B
    final whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

    // 1. Draw White Keys
    for (int oct = 0; oct < octaveCount; oct++) {
      final currentOctave = startOctave + oct;
      for (int i = 0; i < 7; i++) {
        final globalIndex = oct * 7 + i;
        final x = globalIndex * whiteKeyWidth;
        final noteName = whiteNotes[i];

        final isActive = _checkActive(noteName, currentOctave);

        final rect = Rect.fromLTWH(x, 0, whiteKeyWidth, size.height);

        // Draw key
        canvas.drawRect(rect, isActive ? activeWhitePaint : whiteKeyPaint);
        canvas.drawRect(rect, whiteKeyBorderPaint);

        // Label
        if ((showLabels || isActive) && isActive) {
          _drawLabel(
              canvas, noteName, x + whiteKeyWidth / 2, size.height - 10, true);
        }
      }
    }

    // 2. Draw Black Keys
    // C# is after C(0), D# after D(1), F# after F(3), G# after G(4), A# after A(5)
    // Indices relative to local octave: 0, 1, 3, 4, 5 associated with C, D, F, G, A
    final blackNoteNames = ['C#', 'D#', 'F#', 'G#', 'A#'];
    final blackKeyRelIndices = [
      0,
      1,
      3,
      4,
      5
    ]; // White key index after which black key comes

    for (int oct = 0; oct < octaveCount; oct++) {
      final currentOctave = startOctave + oct;
      for (int i = 0; i < blackKeyRelIndices.length; i++) {
        final wkIndexLocal = blackKeyRelIndices[i];
        final wkIndexGlobal = oct * 7 + wkIndexLocal;

        // Black key is effectively centered on the border between wkIndex and wkIndex+1
        // x = (wkIndex + 1) * whiteWidth - (blackWidth / 2)
        final x = (wkIndexGlobal + 1) * whiteKeyWidth - (blackKeyWidth / 2);

        final noteName = blackNoteNames[i];

        final isActive = _checkActive(noteName, currentOctave);

        final rect = Rect.fromLTWH(x, 0, blackKeyWidth, blackKeyHeight);

        canvas.drawRect(rect, isActive ? activeBlackPaint : blackKeyPaint);
      }
    }
  }

  void _drawLabel(
      Canvas canvas, String text, double x, double y, bool isWhiteKey) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: isWhiteKey ? Colors.black87 : Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _PianoChordPainter oldDelegate) {
    // 깊은 비교가 아니므로 리스트 레퍼런스가 다르면 리페인트.
    // 내용 비교가 더 정확하지만 성능상 단순 비교.
    return oldDelegate.notes.toString() != notes.toString();
  }
}
