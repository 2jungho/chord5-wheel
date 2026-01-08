import 'package:flutter/material.dart';

class PianoKeysWidget extends StatelessWidget {
  final Set<String>
      highlightedNotes; // Notes to highlight (e.g., {"C", "E", "G"})
  final String? rootNote;
  final int startOctave;
  final int endOctave;

  const PianoKeysWidget({
    super.key,
    this.highlightedNotes = const {},
    this.rootNote,
    this.startOctave = 3, // C3
    this.endOctave = 5, // B5
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate key width based on available width and number of white keys
        // If width is too small, use a minimum width and enable scrolling.
        final int octaveCount = endOctave - startOctave + 1;
        final int whiteKeyCount = octaveCount * 7;

        // 각 건반마다 right margin 1px가 있으므로(아래 _buildWhiteKey 참조)
        // 전체 가용 너비에서 갭을 뺀 나머지로 키 너비를 계산해야 함.
        const double keyGap = 1.0;
        final double totalGapWidth = keyGap * whiteKeyCount;
        final double availableWidth = constraints.maxWidth - totalGapWidth;

        // 최소 건반 너비 설정 (너무 좁아지면 클릭이나 시인성이 떨어짐)
        const double minKeyWidth = 20.0;

        // 가용 너비 기준으로 키 너비 계산
        double calculatedWidth = availableWidth / whiteKeyCount;

        // [수정] 건반이 너무 비대해지지 않도록 최대 너비 제한
        // 1920x1080 해상도 기준(사이드바 제외 가용폭 약 1470px) / 49키 ≈ 30px
        double whiteKeyWidth = calculatedWidth;
        if (whiteKeyWidth > 32.0) {
          whiteKeyWidth = 32.0;
        }

        if (whiteKeyWidth < minKeyWidth) {
          whiteKeyWidth = minKeyWidth;
        }

        // 전체 너비 재계산 (키 너비 + 갭)
        final double totalWidth = (whiteKeyWidth + keyGap) * whiteKeyCount;

        // 중앙 정렬을 위해 Container로 감쌈 (SingleChildScrollView는 오버플로우 시에만 동작)
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: 120, // 높이 소폭 증가 (비율 고려)
              child: Stack(
                children: [
                  // ... (draw keys)
                  // 1. Draw White Keys
                  Row(
                    children: List.generate(whiteKeyCount, (index) {
                      final noteIndex = index % 7; // 0=C, 1=D, ...
                      final noteName = _getWhiteKeyName(noteIndex);

                      final isHighlighted = highlightedNotes
                          .map((n) => n.replaceAll(RegExp(r'[0-9]'), ''))
                          .contains(noteName); // Simple matching for now
                      final isRoot = rootNote == noteName;

                      return _buildWhiteKey(context, whiteKeyWidth, noteName,
                          isHighlighted, isRoot);
                    }),
                  ),
                  // 2. Draw Black Keys (overlay)
                  ..._buildBlackKeys(
                      context, whiteKeyWidth, startOctave, octaveCount),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getWhiteKeyName(int index) {
    const names = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    return names[index];
  }

  Widget _buildWhiteKey(BuildContext context, double width, String noteName,
      bool isHighlighted, bool isRoot) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 1), // Tiny gap
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isRoot ? Colors.red[300] : Colors.blue[200])
            : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(noteName,
            style: TextStyle(
                fontSize: 10,
                color: isHighlighted ? Colors.black87 : Colors.grey.shade600)),
      ),
    );
  }

  List<Widget> _buildBlackKeys(BuildContext context, double whiteKeyWidth,
      int startOctave, int octaveCount) {
    final List<Widget> blackKeys = [];
    // Black key pattern relative to white keys in an octave:
    // C(0) - C# - D(1) - D# - E(2) - F(3) - F# - G(4) - G# - A(5) - A# - B(6)
    // Black keys are after C, D, but not E. After F, G, A, but not B.
    // Offsets: C#=0.7, D#=1.7, F#=3.7, G#=4.7, A#=5.7 (approximate visual offset)

    // We iterate through octaves and add black keys
    for (int oct = 0; oct < octaveCount; oct++) {
      final double octaveOffset = oct * 7 * whiteKeyWidth;

      final blackKeyIndices = [
        0,
        1,
        3,
        4,
        5
      ]; // After 0th(C), 1st(D), 3rd(F), 4th(G), 5th(A) white key
      final blackKeyNames = ['C#', 'D#', 'F#', 'G#', 'A#'];

      for (int i = 0; i < blackKeyIndices.length; i++) {
        final wkIndex = blackKeyIndices[i];
        final noteName = blackKeyNames[i];

        final isHighlighted = highlightedNotes
            .map((n) => n.replaceAll(RegExp(r'[0-9]'), ''))
            .contains(noteName);
        final isRoot = rootNote == noteName;

        // Position: Start of target white key + width - (blackKeyWidth / 2)
        // Actually usually strictly between keys.
        // Let's settle on: whiteKey.right - (blackWidth/2)
        final left = octaveOffset +
            (wkIndex + 1) * whiteKeyWidth -
            (whiteKeyWidth * 0.35);

        blackKeys.add(Positioned(
          left: left,
          top: 0,
          width: whiteKeyWidth * 0.7, // Black keys are thinner
          height: 70, // And shorter
          child: Container(
            decoration: BoxDecoration(
              color: isHighlighted
                  ? (isRoot ? Colors.red[700] : Colors.blue[400])
                  : Colors.black,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(3)),
              border: Border.all(color: Colors.black),
            ),
          ),
        ));
      }
    }
    return blackKeys;
  }
}
