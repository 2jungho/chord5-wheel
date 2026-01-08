import 'package:flutter/material.dart';

class RelatedScalesSection extends StatelessWidget {
  final String root;
  final String displayQuality;
  final List<String> relatedScales;
  final String? selectedScaleName;
  final Function(String) onScaleSelected;
  final VoidCallback onChordTonesSelected;
  final bool showHeader;
  final bool hasContainer;

  const RelatedScalesSection({
    super.key,
    required this.root,
    required this.displayQuality,
    required this.relatedScales,
    required this.selectedScaleName,
    required this.onScaleSelected,
    required this.onChordTonesSelected,
    this.showHeader = true,
    this.hasContainer = true,
  });

  // 스케일 표시 이름 매핑 (칩 레이블용)
  static const Map<String, String> _scaleDisplayNames = {
    'Phrygian Dominant': 'Phrygian Dom. (HM5)',
    'Lydian Dominant': 'Lydian Dom. (MM4)',
    'Altered': 'Altered (Super Locrian)',
  };

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text('ANALYSIS',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Text('$root $displayQuality 코드입니다. 다양한 보이싱으로 연주해보세요.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16)),
          const SizedBox(height: 24),
        ],

        // RELATED SCALES 섹션
        if (hasContainer)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor)),
            child: _buildRelatedScalesContent(context),
          )
        else
          _buildRelatedScalesContent(context),
      ],
    );

    return content;
  }

  Widget _buildRelatedScalesContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Related Scales',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 코드 톤 버튼 (리셋용)
            FilterChip(
              label: const Text('⭐ Chord Tones'),
              selected: selectedScaleName == null,
              onSelected: (_) => onChordTonesSelected(),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                  color: selectedScaleName == null
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
              side: BorderSide(
                  color: selectedScaleName == null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              showCheckmark: false,
            ),
            // 분석된 관련 스케일 칩 생성
            ...relatedScales.map((s) {
              final isSelected = s == selectedScaleName;
              // 표시 이름 적용 (없으면 원래 이름)
              final displayName = _scaleDisplayNames[s] ?? s;
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (_) => onScaleSelected(s),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10),
                side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.5)),
                showCheckmark: false,
              );
            }),
            if (relatedScales.isEmpty)
              const Text("No specific scales found.",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
