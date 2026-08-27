import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';
import '../../../providers/studio_state.dart';
import '../../../providers/settings_state.dart';
import '../../../widgets/common/dialogs/settings_dialog.dart';

class LyriaJamPanel extends StatelessWidget {
  const LyriaJamPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();
    final studio = context.read<StudioState>();
    final settings = context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> styles = [
      "Neo-Soul",
      "Jazz Funk",
      "Lofi Chill",
      "Rock",
      "Blues",
      "City Pop",
      "Acoustic Ballad",
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lyria.isPlaying
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: lyria.isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: lyria.isPlaying
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Jam Session & Backing Band",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Lyria / Gemini Realtime Backing Track",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lyria.isPlaying
                      ? Colors.green.withValues(alpha: 0.2)
                      : (lyria.isConnecting
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lyria.isPlaying
                            ? Colors.green
                            : (lyria.isConnecting ? Colors.amber : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lyria.isPlaying
                          ? "Playing"
                          : (lyria.isConnecting ? "Connecting" : "Ready"),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: lyria.isPlaying
                            ? Colors.green
                            : (lyria.isConnecting
                                ? Colors.amber.shade800
                                : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Missing API Key Notification
          if (!settings.hasApiKey) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Gemini API Key가 없어도 가상 밴드로 연주 가능합니다. (AI 실시간 밴드는 설정에서 키 등록)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("설정 열기", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Controls Bar
          Row(
            children: [
              // Single-click Start / Stop Jam Session Button
              FilledButton.icon(
                onPressed: lyria.isConnecting
                    ? null
                    : () {
                        if (lyria.isPlaying) {
                          lyria.stopPlayback();
                        } else {
                          final session = studio.session;
                          String chords = "Key: ${session.key}\n";
                          if (session.progression.isEmpty) {
                            chords += "Progression: C - Am - F - G";
                          } else {
                            chords +=
                                "Progression: ${session.progression.map((b) => b.chordSymbol).join(" - ")}";
                          }

                          if (!settings.hasApiKey) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    "Gemini API 키가 없어 내장 가상 밴드로 반주를 시작합니다."),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: "설정 열기",
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const SettingsDialog(),
                                    );
                                  },
                                ),
                              ),
                            );
                          }

                          lyria.startJamSession(
                            chordProgression: chords,
                            blocks: session.progression,
                          );
                        }
                      },
                icon: lyria.isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        lyria.isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                label: Text(
                  lyria.isConnecting
                      ? "연결 중..."
                      : (lyria.isPlaying ? "잼 중지" : "잼 시작"),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: lyria.isPlaying
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Tempo Slider
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tempo: ${lyria.tempo.toInt()} BPM",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      child: Slider(
                        value: lyria.tempo,
                        min: 60,
                        max: 180,
                        divisions: 24,
                        onChanged: (val) => lyria.updateTempo(val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Style Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: styles.contains(lyria.style) ? lyria.style : styles.first,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: styles
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) lyria.updateStyle(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
