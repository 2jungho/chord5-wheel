import 'package:flutter/material.dart';
import '../../../../providers/studio_state.dart';
import '../../../../models/progression/progression_models.dart';
import '../soloing_guide_panel.dart';
import '../insight_report_widget.dart';

class TimelineAnalysisPanel extends StatelessWidget {
  final StudioState studio;
  final ProgressionSession session;
  final double panelWidth;
  final bool forceFullWidth;

  const TimelineAnalysisPanel({
    super.key,
    required this.studio,
    required this.session,
    this.panelWidth = 500.0,
    this.forceFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    double safeWidth = panelWidth;
    if (forceFullWidth) {
      safeWidth = double.infinity;
    } else if (safeWidth.isNaN || safeWidth < 100 || safeWidth > 2000) {
      safeWidth = 500.0;
    }

    return Container(
      width: forceFullWidth ? double.infinity : safeWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color: forceFullWidth
                  ? Colors.transparent
                  : Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Analysis Tab Header
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.analytics_outlined, size: 16),
                    text: "기본 분석 (Basic)",
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    icon: Icon(Icons.auto_awesome, size: 16),
                    text: "AI 심층 분석 (Deep)",
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                ],
              ),
            ),
            // Tab Contents
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Voice Leading & Soloing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildVoiceLeadingAnalysis(context),
                        ),
                      ),
                      VerticalDivider(
                          width: 1,
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.5)),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: SoloingGuidePanel(),
                        ),
                      ),
                    ],
                  ),
                  // Tab 2: AI Insight Report
                  InsightReportWidget(progression: session.progression),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceLeadingAnalysis(BuildContext context) {
    if (session.progression.isEmpty) return const SizedBox.shrink();

    final currentIndex = studio.selectedBlockIndex;
    final currentBlock =
        (currentIndex >= 0 && currentIndex < session.progression.length)
            ? session.progression[currentIndex]
            : null;

    ChordBlock? nextBlock;
    bool isLoop = false;

    if (currentBlock != null && session.progression.isNotEmpty) {
      if (currentIndex < session.progression.length - 1) {
        nextBlock = session.progression[currentIndex + 1];
      } else {
        nextBlock = session.progression.first;
        isLoop = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  size: 18, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '보이스 리딩 분석 (Voice Leading)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentBlock != null && nextBlock != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildAnalysisChordTag(context, currentBlock.chordSymbol),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Icon(isLoop ? Icons.refresh : Icons.arrow_forward,
                            size: 16,
                            color: isLoop
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                        if (isLoop)
                          Text('Loop',
                              style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                  _buildAnalysisChordTag(context, nextBlock.chordSymbol),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가이드톤 연결:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentBlock.chordSymbol}의 7음이 ${nextBlock.chordSymbol}의 3음으로 부드럽게 해결됩니다.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '반음/온음 간격의 순차 진행이 감지되었습니다.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ] else if (currentBlock != null) ...[
            Text(
              '${currentBlock.chordSymbol} 다음에 오는 코드를 선택하면\n두 코드 간의 연결성을 분석합니다.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.outline),
            )
          ] else ...[
            Text(
              '타임라인에서 코드를 선택하여\n보이스 리딩 분석을 확인하세요.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.outline),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisChordTag(BuildContext context, String chordName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        chordName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
