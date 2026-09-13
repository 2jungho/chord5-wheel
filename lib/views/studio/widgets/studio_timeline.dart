import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/studio_state.dart';
import '../../../models/progression/progression_models.dart';
import '../../../utils/theory_utils.dart';
import 'timeline/timeline_key_panel.dart';
import 'timeline/timeline_analysis_panel.dart';
import 'timeline/timeline_quick_add_bar.dart';
import 'timeline/timeline_sections_bar.dart';
import 'timeline/timeline_header_toolbar.dart';
import 'timeline/timeline_caged_bar.dart';
import 'timeline/timeline_cards_grid.dart';

class StudioTimeline extends StatefulWidget {
  const StudioTimeline({super.key});

  @override
  State<StudioTimeline> createState() => _StudioTimelineState();
}

class _StudioTimelineState extends State<StudioTimeline> {
  final TextEditingController _quickAddController = TextEditingController();
  double _analysisPanelWidth = 500.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final studio = context.read<StudioState>();
        if (_quickAddController.text.isEmpty &&
            studio.session.progression.isNotEmpty) {
          _quickAddController.text =
              studio.session.progression.map((c) => c.chordSymbol).join(' - ');
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioState>();
    final session = studio.session;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;

      if (isMobile) {
        // Mobile Layout: Tabbed Interface
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: "Key"),
                    Tab(text: "Timeline"),
                    Tab(text: "Analysis"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: Key
                    TimelineKeyPanel(
                      studio: studio,
                      session: session,
                      isMobile: true,
                    ),
                    // Tab 2: Timeline
                    Column(
                      children: [
                        TimelineHeaderToolbar(
                          studio: studio,
                          session: session,
                          isMobile: true,
                          quickAddWidget: TimelineQuickAddBar(
                            controller: _quickAddController,
                            studio: studio,
                          ),
                          chordTypeToggleWidget:
                              TimelineChordTypeToggle(studio: studio),
                          progressionBadgeWidget:
                              _buildProgressionBadge(context, session, studio),
                        ),
                        const Divider(height: 1),
                        Expanded(
                            child: _buildTimelineGrid(context, studio, session)),
                      ],
                    ),
                    // Tab 3: Analysis
                    TimelineAnalysisPanel(
                      studio: studio,
                      session: session,
                      forceFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Desktop Layout: Side-by-Side
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Panel: Key Selector
            Container(
              width: 380,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: TimelineKeyPanel(
                studio: studio,
                session: session,
              ),
            ),
            // Right Panel: Timeline & Controls
            Expanded(
              child: Column(
                children: [
                  TimelineHeaderToolbar(
                    studio: studio,
                    session: session,
                    quickAddWidget: TimelineQuickAddBar(
                      controller: _quickAddController,
                      studio: studio,
                    ),
                    chordTypeToggleWidget:
                        TimelineChordTypeToggle(studio: studio),
                    progressionBadgeWidget:
                        _buildProgressionBadge(context, session, studio),
                  ),
                  const Divider(height: 1),
                  // Main Content: Timeline + Analysis
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grid Tracks
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                  child: _buildTimelineGrid(
                                      context, studio, session)),
                            ],
                          ),
                        ),
                        // Resize Handle
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _analysisPanelWidth =
                                    (_analysisPanelWidth - details.delta.dx)
                                        .clamp(250.0, 800.0);
                              });
                            },
                            child: Container(
                              width: 12,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right Side Analysis Panel
                        TimelineAnalysisPanel(
                          studio: studio,
                          session: session,
                          panelWidth: _analysisPanelWidth,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimelineGrid(
      BuildContext context, StudioState studio, ProgressionSession session) {
    return Column(
      children: [
        // Song Sections Toolbar (Intro, Verse, Chorus, Bridge, Outro)
        TimelineSectionsBar(studio: studio, session: session),

        // CAGED Voicing Selector Toolbar
        TimelineCagedBar(studio: studio),

        // Timeline Chord Cards Grid
        Expanded(
          child: TimelineCardsGrid(studio: studio, session: session),
        ),
      ],
    );
  }

  Widget _buildProgressionBadge(
      BuildContext context, ProgressionSession session, StudioState studio) {
    final matchedPreset =
        TheoryUtils.matchProgressionToPreset(session.progression);

    if (matchedPreset == null) return const SizedBox.shrink();

    return Tooltip(
      message:
          '${matchedPreset.description}\nTags: ${matchedPreset.tags.join(", ")}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final newTitle = studio.regenerateSimilarProgression();
            if (newTitle != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('\'$newTitle\'(으)로 재생성되었습니다.'),
                  duration: const Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('교체할 유사한 프리셋이 없습니다.'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .tertiaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh,
                    size: 14, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  matchedPreset.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                if (matchedPreset.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${matchedPreset.tags.first}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
