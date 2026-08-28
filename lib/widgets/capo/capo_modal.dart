import 'package:flutter/material.dart';
import '../../services/capo_service.dart';

class CapoModal extends StatefulWidget {
  final List<String> originalChords;
  final Function(int selectedCapo, List<String> transposedChords)? onApply;

  const CapoModal({
    super.key,
    required this.originalChords,
    this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> chords,
    Function(int selectedCapo, List<String> transposedChords)? onApply,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CapoModal(
        originalChords: chords,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CapoModal> createState() => _CapoModalState();
}

class _CapoModalState extends State<CapoModal> {
  int _selectedFret = 0;
  late List<CapoOption> _options;
  CapoOption? _bestOption;

  @override
  void initState() {
    super.initState();
    _options = CapoService.calculateCapoOptions(widget.originalChords);
    _bestOption = CapoService.getBestCapoOption(widget.originalChords);
    if (_bestOption != null && _bestOption!.score > (_options.isNotEmpty ? _options[0].score : 0)) {
      _selectedFret = _bestOption!.fret;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOption = _options.firstWhere(
      (o) => o.fret == _selectedFret,
      orElse: () => _options.first,
    );

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 680),
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
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트 카포 계산기 (Smart Capo Transposer)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '카포를 사용해 어려운 바레 코드를 쉬운 오픈 코드로 연주하세요.',
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
            const SizedBox(height: 16),

            // Original Progression Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Text(
                    '원곡 진행:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: widget.originalChords
                          .map((c) => Chip(
                                label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: theme.colorScheme.surface,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Capo Fret Selector Bar
            Text(
              '카포 위치 선택 (Capo Fret)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  final isSelected = opt.fret == _selectedFret;
                  final isBest = _bestOption?.fret == opt.fret && opt.fret > 0;

                  return InkWell(
                    onTap: () => setState(() => _selectedFret = opt.fret),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isBest
                                ? Colors.amber.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isBest ? Colors.amber : theme.dividerColor),
                          width: isSelected || isBest ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                opt.fret == 0 ? 'No Capo' : 'Capo ${opt.fret}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isBest ? Colors.amber : theme.colorScheme.onSurface),
                                ),
                              ),
                              if (isBest) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Result Display Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFret == 0 ? '기본 연주 폼' : '카포 $_selectedFret 프렛 장착 시 연주 폼',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedOption.openChordCount == selectedOption.transposedChords.length
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '오픈 코드: ${selectedOption.openChordCount}/${selectedOption.transposedChords.length}개',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selectedOption.openChordCount == selectedOption.transposedChords.length
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transposed Chords Chips
                    Expanded(
                      child: Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: selectedOption.transposedChords.map((chord) {
                            final isOpen = CapoService.isOpenFriendly(chord);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOpen ? Colors.green : theme.dividerColor,
                                  width: isOpen ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    chord,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isOpen ? Colors.green : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOpen ? '오픈 폼 ✨' : '바레 폼',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOpen ? Colors.green : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
                if (widget.onApply != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onApply!(_selectedFret, selectedOption.transposedChords);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      _selectedFret == 0 ? '원곡 폼 유지' : '카포 $_selectedFret 폼으로 타임라인 변환',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
