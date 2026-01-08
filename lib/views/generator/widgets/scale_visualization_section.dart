import 'package:flutter/material.dart';

import '../../../utils/theory_utils.dart';

class ScaleVisualizationSection extends StatelessWidget {
  final String root;
  final String? selectedScaleName;
  final String? baseScaleName;
  final bool isMinor;
  final List<String>? chordNotes;
  final List<String>? chordIntervals;
  final VoidCallback onPlayScale;
  final VoidCallback onPlayChord;
  final bool hasContainer;

  const ScaleVisualizationSection({
    super.key,
    required this.root,
    required this.selectedScaleName,
    this.baseScaleName,
    required this.isMinor,
    this.chordNotes,
    this.chordIntervals,
    required this.onPlayScale,
    required this.onPlayChord,
    this.hasContainer = true,
  });

  // 스케일 상세 설명 생성 (동적 계산)
  String _getScaleDescription(String? scaleName, String rootNote) {
    if (rootNote.isEmpty) return '';
    if (scaleName == null) {
      return '$rootNote 코드의 핵심 구성음(Chord Tones)입니다.';
    }

    switch (scaleName) {
      case 'Ionian':
        return 'Major Scale (1st Mode). 밝고 안정적인 사운드입니다.';
      case 'Dorian':
        return 'Minor Scale (2nd Mode). 펑키하고 세련된 마이너 사운드 (Carlos Santana 등).';
      case 'Phrygian':
        return 'Minor Scale (3rd Mode). 스페인/플라멩코 느낌의 어두운 사운드.';
      case 'Lydian':
        return 'Major Scale (4th Mode). 신비롭고 몽환적인 사운드 (영화음악 등).';
      case 'Mixolydian':
        return 'Major Scale (5th Mode). 블루지하고 락(Rock)적인 도미넌트 사운드.';
      case 'Aeolian':
        return 'Natural Minor Scale (6th Mode). 슬프고 감성적인 기본 마이너 사운드.';
      case 'Locrian':
        return 'Diminished Scale (7th Mode). 불안정하고 긴장감 있는 사운드 (m7b5 코드에 사용).';
      case 'Phrygian Dominant':
        return 'Harmonic Minor 5th Mode. 중동/스패니쉬 느낌의 강렬한 사운드.';
      case 'Lydian Dominant':
        return 'Melodic Minor 4th Mode. Lydian의 신비함 + Dominant의 힘 (Fusion Jazz).';
      case 'Altered':
        return 'Super Locrian. 도미넌트 코드에서 가장 긴장감 있는 사운드 (Alt chord).';
      case 'Diminished (H-W)':
        return 'Half-Whole Diminished. 도미넌트 코드 위에서 대칭적인 긴장감을 만듭니다.';
      case 'Whole Tone':
        return '온음음계. 꿈꾸는 듯한 모호한 사운드 (Augmented 코드에 사용).';
      case 'Major Pentatonic':
        return '메이저 스케일에서 4, 7음을 뺀 5음계. 밝고 깔끔한 컨트리/락 사운드.';
      case 'Minor Pentatonic':
        return '마이너 스케일에서 2, 6음을 뺀 5음계. 블루스/락의 기본이 되는 사운드.';
      case 'Blues Scale':
        return '마이너 펜타토닉에 b5(Blue Note)를 더해 블루지한 느낌을 강조.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasContainer) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: _buildMainContent(context));
    } else {
      return _buildMainContent(context);
    }
  }

  Widget _buildMainContent(BuildContext context) {
    final isChordTones = selectedScaleName == null;
    final displayName = selectedScaleName ?? 'Chord Tones';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayName,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.volume_up,
                color: Theme.of(context).colorScheme.primary),
            onPressed: isChordTones ? onPlayChord : onPlayScale,
            tooltip: isChordTones ? "Play Chord" : "Play Scale",
          )
        ],
      ),
      // 상세 설명 표시 (있을 경우)
      if (_getScaleDescription(selectedScaleName, root).isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          _getScaleDescription(selectedScaleName, root),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
      ] else ...[
        const SizedBox(height: 8),
      ],
      Text(isChordTones ? 'Tone Visualization' : 'Scale Visualization',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 10)),
      const SizedBox(height: 8),
      // 구성음 및 인터벌 시각화
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: () {
            final targetScaleName = isChordTones
                ? (baseScaleName ?? (isMinor ? 'Aeolian' : 'Ionian'))
                : selectedScaleName!;

            final sNotes =
                TheoryUtils.calculateScaleNotes(root, targetScaleName);
            final sIntervals = TheoryUtils.getScaleIntervals(targetScaleName);

            // 펜타토닉 기준 결정 (3도 인터벌 확인)
            Set<int> pentatonicIndices = {};
            if (sNotes.length >= 3) {
              final rootIdx = TheoryUtils.getNoteIndex(root);
              final thirdIdx = TheoryUtils.getNoteIndex(sNotes[2]); // 3번째 음

              int semitones = (thirdIdx - rootIdx + 12) % 12;

              List<String> pNotes = [];
              if (semitones == 3) {
                pNotes =
                    TheoryUtils.calculateScaleNotes(root, 'Minor Pentatonic');
              } else if (semitones == 4) {
                pNotes =
                    TheoryUtils.calculateScaleNotes(root, 'Major Pentatonic');
              }

              pentatonicIndices =
                  pNotes.map((pn) => TheoryUtils.getNoteIndex(pn)).toSet();
            }

            return List.generate(sNotes.length, (i) {
              final n = sNotes[i];
              final intv = i < sIntervals.length ? sIntervals[i] : '';

              final noteIdx = TheoryUtils.getNoteIndex(n);
              final isPentatonic = pentatonicIndices.contains(noteIdx);
              final isChordTone = chordNotes
                      ?.any((cn) => TheoryUtils.getNoteIndex(cn) == noteIdx) ??
                  false;
              final isRoot = noteIdx == TheoryUtils.getNoteIndex(root);

              // 강조 조건:
              // 1. Chord Tones 모드: 코드 구성음이면 강조
              // 2. Scale 모드: 루트이거나 펜타토닉이 아닌 경우(특성음) 강조
              final bool shouldHighlight =
                  isChordTones ? isChordTone : (isRoot || !isPentatonic);

              // 강조 색상 설정
              final bgColor = shouldHighlight
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest;
              final textColor = shouldHighlight
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface;
              final subTextColor = shouldHighlight
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7);

              return Container(
                  width: 38,
                  height: 48,
                  decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        if (shouldHighlight)
                          BoxShadow(
                            color: bgColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                      ],
                      border: Border.all(
                          color: shouldHighlight
                              ? bgColor
                              : Theme.of(context).dividerColor,
                          width: 1.2)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(n,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 1),
                        Text(intv,
                            style: TextStyle(
                                color: subTextColor,
                                fontSize: 9,
                                fontWeight: !isPentatonic
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ]));
            });
          }())
    ]);
  }
}
