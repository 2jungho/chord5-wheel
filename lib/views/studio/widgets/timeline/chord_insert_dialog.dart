import 'package:flutter/material.dart';
import '../../../../services/harmonic_suggestion_service.dart';
import '../../../../audio/audio_manager.dart';

class ChordInsertDialog extends StatefulWidget {
  final String targetChord;
  final String currentKey;
  final int insertIndex;
  final Function(String chordSymbol, int index) onInsert;

  const ChordInsertDialog({
    super.key,
    required this.targetChord,
    required this.currentKey,
    required this.insertIndex,
    required this.onInsert,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetChord,
    required String currentKey,
    required int insertIndex,
    required Function(String chordSymbol, int index) onInsert,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ChordInsertDialog(
        targetChord: targetChord,
        currentKey: currentKey,
        insertIndex: insertIndex,
        onInsert: onInsert,
      ),
    );
  }

  @override
  State<ChordInsertDialog> createState() => _ChordInsertDialogState();
}

class _ChordInsertDialogState extends State<ChordInsertDialog> {
  late List<HarmonicSuggestion> _suggestions;
  final TextEditingController _customChordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _suggestions = HarmonicSuggestionService.getSuggestionsForTarget(
      targetChordSymbol: widget.targetChord,
      currentKey: widget.currentKey,
    );
  }

  @override
  void dispose() {
    _customChordController.dispose();
    super.dispose();
  }

  void _previewChord(HarmonicSuggestion suggestion) {
    AudioManager().playStrum(suggestion.notes);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 540,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '화성 확장 & 경과 화음 삽입',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\'${widget.targetChord}\' 코드로 자연스럽게 연결되는 텐션/경과 화음을 추천합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Suggestions List
            Text(
              '추천 경과 화음 (Harmonic Recommendations)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        // Chord Symbol Box
                        Container(
                          width: 64,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            item.chordSymbol,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.romanNumeral,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 20),
                          tooltip: '미리듣기',
                          onPressed: () => _previewChord(item),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.onInsert(item.chordSymbol, widget.insertIndex);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('삽입'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Custom Chord Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customChordController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: '직접 코드 입력 (예: D7#9, F#m7b5, Bbmaj7)',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onInsert(val.trim(), widget.insertIndex);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final val = _customChordController.text.trim();
                      if (val.isNotEmpty) {
                        widget.onInsert(val, widget.insertIndex);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('직접 삽입'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
