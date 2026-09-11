import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/studio_state.dart';
import '../../../models/progression/progression_models.dart';
import '../../../utils/theory_utils.dart';
import 'timeline/timeline_chord_card.dart';
import 'timeline/timeline_key_panel.dart';
import 'timeline/timeline_analysis_panel.dart';
import 'timeline/timeline_quick_add_bar.dart';
import 'timeline/timeline_sections_bar.dart';
import 'timeline/timeline_header_toolbar.dart';

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
        Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabel = constraints.maxWidth > 300;
              final showIcon = constraints.maxWidth > 40;

              return Row(
                children: [
                  if (showIcon) ...[
                    Icon(Icons.grid_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Voicing Shape (CAGED)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(width: showLabel ? 16 : 8),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: innerConstraints.maxWidth),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final style in [
                                  'C',
                                  'C-A',
                                  'A',
                                  'A-G',
                                  'G',
                                  'G-E',
                                  'E',
                                  'E-D',
                                  'D',
                                  'D-C'
                                ])
                                  _buildCagedNode(context, studio, style),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 60) return const SizedBox.shrink();

                  int crossAxisCount = (constraints.maxWidth / 160).floor();
                  double sidePadding = 24.0;
                  double spacing = 16.0;

                  if (constraints.maxWidth < 360) {
                    crossAxisCount = 2;
                    sidePadding = 8.0;
                    spacing = 8.0;
                  }

                  if (constraints.maxWidth < 220) {
                    crossAxisCount = 1;
                    sidePadding = 4.0;
                    spacing = 4.0;
                  } else if (crossAxisCount < 2) {
                    crossAxisCount = 2;
                  }

                  if (crossAxisCount > 4) crossAxisCount = 4;

                  return GridView.builder(
                    padding:
                        EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 48),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: session.progression.length,
                    itemBuilder: (context, index) {
                      final block = session.progression[index];
                      return TimelineChordCard(
                        block: block,
                        index: index,
                        studio: studio,
                      );
                    },
                  );
                },
              ),
              _buildMoreBarsBadge(context, session),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCagedNode(
      BuildContext context, StudioState studio, String style) {
    final isMainNode = !style.contains('-');
    final isSelected = studio.timelineVoicingStyle == style;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMainNode ? 2 : 1),
      child: Tooltip(
        message: isMainNode ? '$style Form' : 'Bridge: $style',
        child: InkWell(
          onTap: () => studio.setTimelineVoicingStyle(style),
          borderRadius: BorderRadius.circular(isMainNode ? 20 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isMainNode ? 32 : 36,
            height: isMainNode ? 32 : 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: isMainNode ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isMainNode ? null : BorderRadius.circular(6),
              color: isSelected
                  ? colorScheme.primary
                  : (isMainNode
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : (isMainNode
                      ? Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2))
                      : null),
            ),
            child: Text(
              isMainNode ? style : 'BR',
              style: TextStyle(
                fontSize: isMainNode ? 12 : 9,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : (isMainNode ? FontWeight.w600 : FontWeight.w500),
                color: isSelected
                    ? colorScheme.onPrimary
                    : (isMainNode
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildMoreBarsBadge(BuildContext context, ProgressionSession session) {
    if (session.progression.length <= 4) return const SizedBox.shrink();
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.keyboard_double_arrow_down,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 6),
              Text('${session.progression.length - 4} More Bars Below',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer)),
            ]),
          ),
        ),
      ),
    );
  }
}
