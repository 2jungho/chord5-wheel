import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_state.dart';
import '../../../utils/theory_utils.dart';
import 'piano_chord_widget.dart';
import '../../../audio/audio_manager.dart';

class PianoInversionList extends StatefulWidget {
  const PianoInversionList({super.key});

  @override
  State<PianoInversionList> createState() => _PianoInversionListState();
}

class _PianoInversionListState extends State<PianoInversionList> {
  // 현재 선택된 인버전 인덱스 (기본값 0: Root Position)
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MusicState>();
    final chord = state.selectedChord;
    final root = chord.root;
    final quality = chord.quality; // ex. "Maj7"

    // 만약 root가 비어있으면(초기화 전) 표시 안함
    if (root.isEmpty) return const SizedBox.shrink();

    // 전위 데이터 생성
    // 매번 계산하는 비용이 걱정되면 캐싱할 수 있으나, 리스트 길이가 짧아 괜찮음.
    final inversions = TheoryUtils.getChordInversionsWithOctave(root, quality);

    return Container(
      height: 170, // 조금 더 여유있게 (선택 효과 등)
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.piano, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Piano Inversions : $root$quality',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: inversions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final inv = inversions[index];
                final name = inv['name'] as String;
                final notes = inv['notes'] as List<String>;
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // Audio Playback
                    // 노트 이름 그대로 전달 (예: "C3", "E3"...)
                    // AudioManager가 파싱 가능한 포맷인지 확인 필요하지만
                    // 보통 "C3" 형식을 지원함.
                    AudioManager().playStrum(notes);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        PianoChordWidget(
                          notes: notes,
                          width: 100, // 살짝 키움
                          height: 60,
                          showLabels: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
