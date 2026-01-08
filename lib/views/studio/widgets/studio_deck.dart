import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/studio_state.dart';
import 'insight_report_widget.dart';
import 'rhythm_sequencer.dart';

class StudioDeck extends StatefulWidget {
  const StudioDeck({super.key});

  @override
  State<StudioDeck> createState() => _StudioDeckState();
}

class _StudioDeckState extends State<StudioDeck>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.reorder, size: 20),
                text: 'Rhythm Studio',
              ),
              Tab(
                icon: Icon(Icons.play_circle_outline, size: 20),
                text: 'YouTube Media',
              ),
              Tab(
                icon: Icon(Icons.analytics_outlined, size: 20),
                text: 'AI 화성학 분석',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRhythmTab(context),
                _buildMediaTab(context),
                _buildAITab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmTab(BuildContext context) {
    return const RhythmSequencer();
  }

  Widget _buildMediaTab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library,
            size: 48,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
        const SizedBox(height: 16),
        const Text('YouTube & Backing Track',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Phase 3에서 구현될 유튜브 연동 및 반주 재생 기능입니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAITab(BuildContext context) {
    // Access session via StudioState
    final session = context.watch<StudioState>().session;
    return InsightReportWidget(progression: session.progression);
  }
}
