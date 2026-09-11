import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/studio_state.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../providers/settings_state.dart';
import '../../dialogs/ai_arrange_dialog.dart';
import '../../dialogs/ai_song_search_dialog.dart';
import '../../../../widgets/capo/capo_modal.dart';
import '../../../../services/midi/midi_export_service.dart';
import '../../../../widgets/lick/artist_lick_vault_sheet.dart';

class TimelineHeaderToolbar extends StatelessWidget {
  final StudioState studio;
  final ProgressionSession session;
  final bool isMobile;
  final Widget quickAddWidget;
  final Widget chordTypeToggleWidget;
  final Widget progressionBadgeWidget;

  const TimelineHeaderToolbar({
    super.key,
    required this.studio,
    required this.session,
    this.isMobile = false,
    required this.quickAddWidget,
    required this.chordTypeToggleWidget,
    required this.progressionBadgeWidget,
  });

  Widget _buildSessionInfoBadge(
      BuildContext context, IconData icon, String text, Color bgColor) {
    final containerColor = Theme.of(context).colorScheme.primaryContainer;
    final onContainerColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: containerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onContainerColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onContainerColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = context.watch<SettingsState>().currentApiKey.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> aiButtons = hasApiKey
        ? [
            OutlinedButton.icon(
              onPressed: () {
                if (session.progression.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('편곡할 코드가 없습니다.')),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (ctx) => AIArrangeDialog(
                    currentProgression: session.progression,
                    onApply: (newProgression, style) {
                      studio.setProgression(newProgression,
                          arrangementStyle: style);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('\'$style\' 스타일로 편곡이 적용되었습니다.')),
                      );
                    },
                  ),
                );
              },
              icon: Icon(Icons.auto_fix_high,
                  size: 16, color: isDark ? Colors.white : null),
              label: Text('AI 편곡',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : null,
                      fontWeight: isDark ? FontWeight.bold : null)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : null,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                backgroundColor:
                    isDark ? Colors.white.withValues(alpha: 0.05) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AISongSearchDialog(
                    onApply: (blocks, key, title) {
                      studio.setProgression(blocks,
                          key: key, title: title, clearArrangement: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('타임라인에 곡 진행이 적용되었습니다.')),
                      );
                    },
                  ),
                );
              },
              icon: Icon(Icons.search,
                  size: 16, color: isDark ? Colors.white : null),
              label: Text('AI 곡 검색',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : null,
                      fontWeight: isDark ? FontWeight.bold : null)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : null,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                backgroundColor:
                    isDark ? Colors.white.withValues(alpha: 0.05) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ]
        : [];

    final toolButtons = [
      chordTypeToggleWidget,
      const SizedBox(width: 8),
      OutlinedButton.icon(
        onPressed: () {
          ArtistLickVaultSheet.show(context);
        },
        icon: const Icon(Icons.electric_bolt, size: 15, color: Colors.amber),
        label: const Text('아티스트 릭', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: Colors.amber.withValues(alpha: 0.6),
          ),
          backgroundColor: Colors.amber.withValues(alpha: 0.08),
        ),
      ),
      const SizedBox(width: 6),
      OutlinedButton.icon(
        onPressed: () {
          final chords =
              session.progression.map((b) => b.chordSymbol).toList();
          if (chords.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('카포를 계산할 코드 진행이 없습니다.')),
            );
            return;
          }
          CapoModal.show(
            context,
            chords: chords,
            onApply: (capoFret, transposedChords) {
              studio.applyTransposedChords(transposedChords);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Capo $capoFret 폼으로 변환되었습니다.'),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.music_note, size: 15),
        label: const Text('카포 계산기', style: TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
        ),
      ),
      const SizedBox(width: 6),
      OutlinedButton.icon(
        onPressed: () {
          if (session.progression.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('내보낼 코드 진행이 없습니다.')),
            );
            return;
          }
          final filename = MidiExportService.downloadSessionAsMidi(session);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('4인조 밴드 MIDI 파일($filename)이 다운로드되었습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.download, size: 15),
        label: const Text('MIDI 내보내기', style: TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_timeline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('코드진행',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const Spacer(),
                    progressionBadgeWidget,
                  ],
                ),
                if ((session.title.isNotEmpty &&
                        session.title != 'Untitled Progression') ||
                    session.arrangementStyle != null) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (session.title.isNotEmpty &&
                            session.title != 'Untitled Progression')
                          _buildSessionInfoBadge(
                            context,
                            Icons.music_note,
                            session.title,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        if (session.arrangementStyle != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.grey),
                          const SizedBox(width: 8),
                          _buildSessionInfoBadge(
                            context,
                            Icons.auto_fix_high,
                            session.arrangementStyle!,
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...toolButtons,
                      const SizedBox(width: 8),
                      ...aiButtons,
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: quickAddWidget),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            )
          : Row(
              children: [
                Icon(Icons.view_timeline,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('코드진행',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.title.isNotEmpty &&
                            session.title != 'Untitled Progression') ...[
                          _buildSessionInfoBadge(
                            context,
                            Icons.music_note,
                            session.title,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        ],
                        if (session.arrangementStyle != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.grey),
                          const SizedBox(width: 8),
                          _buildSessionInfoBadge(
                            context,
                            Icons.auto_fix_high,
                            session.arrangementStyle!,
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...toolButtons,
                const SizedBox(width: 6),
                ...aiButtons,
                if (hasApiKey) const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: quickAddWidget,
                ),
              ],
            ),
    );
  }
}
