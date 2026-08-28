import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';
import '../../../providers/studio_state.dart';
import '../../../providers/settings_state.dart';
import '../../../widgets/common/dialogs/settings_dialog.dart';

import '../../../audio/audio_recorder_service.dart';

class LyriaJamPanel extends StatefulWidget {
  const LyriaJamPanel({super.key});

  @override
  State<LyriaJamPanel> createState() => _LyriaJamPanelState();
}

class _LyriaJamPanelState extends State<LyriaJamPanel> {
  bool _isRecording = false;
  bool _hasRecorded = false;

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
                    "Full 4-Piece Band: Drums • Bass • Keys • Guitar",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      "내장 가상 밴드(드럼/베이스/건반/기타)로 즉시 연주됩니다. (AI 실시간 생성은 설정에서 키 등록)",
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

          // Controls Bar (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final startButton = FilledButton.icon(
                onPressed: lyria.isConnecting
                    ? null
                    : () {
                        if (lyria.isPlaying) {
                          lyria.stopPlayback();
                          if (_isRecording) {
                            AudioRecorderService.stopRecording();
                            setState(() {
                              _isRecording = false;
                              _hasRecorded = true;
                            });
                          }
                        } else {
                          final session = studio.session;
                          String chords = "Key: ${session.key}\n";
                          if (session.progression.isEmpty) {
                            chords += "Progression: C - Am - F - G";
                          } else {
                            chords +=
                                "Progression: ${session.progression.map((b) => b.chordSymbol).join(" - ")}";
                          }

                          lyria.startJamSession(
                            chordProgression: chords,
                            blocks: session.progression,
                            key: session.key.isNotEmpty ? session.key : 'C Major',
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
              );

              final recordButton = OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (_isRecording) {
                    AudioRecorderService.stopRecording();
                    setState(() {
                      _isRecording = false;
                      _hasRecorded = true;
                    });
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('마이크 녹음이 완료되었습니다. [다운로드] 버튼을 눌러 저장하세요.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    final success = await AudioRecorderService.startRecording();
                    if (!mounted) return;
                    if (success) {
                      setState(() {
                        _isRecording = true;
                      });
                      if (!lyria.isPlaying) {
                        // 녹음 시작 시 가상 밴드도 함께 자동 재생
                        final session = studio.session;
                        String chords = "Key: ${session.key}\n";
                        if (session.progression.isEmpty) {
                          chords += "Progression: C - Am - F - G";
                        } else {
                          chords +=
                              "Progression: ${session.progression.map((b) => b.chordSymbol).join(" - ")}";
                        }
                        lyria.startJamSession(
                          chordProgression: chords,
                          blocks: session.progression,
                          key: session.key.isNotEmpty ? session.key : 'C Major',
                        );
                      }
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('마이크 권한을 확인해주세요.'),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                  size: 15,
                  color: _isRecording ? Colors.redAccent : Colors.red,
                ),
                label: Text(
                  _isRecording ? "녹음 중지" : "REC",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.redAccent : null,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: _isRecording
                        ? Colors.redAccent
                        : Theme.of(context).dividerColor,
                  ),
                ),
              );

              final downloadRecordButton = _hasRecorded
                  ? IconButton(
                      tooltip: '녹음 파일 다운로드 (.webm)',
                      icon: const Icon(Icons.download, size: 18, color: Colors.cyan),
                      onPressed: () {
                        AudioRecorderService.downloadRecording();
                      },
                    )
                  : const SizedBox.shrink();

              final tempoSlider = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tempo: ${lyria.tempo.toInt()} BPM",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
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
              );

              final volumeSlider = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => lyria.toggleMute(),
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(
                          lyria.isMuted
                              ? Icons.volume_off_rounded
                              : (lyria.volume < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded),
                          size: 14,
                          color: lyria.isMuted
                              ? Colors.redAccent
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Vol: ${(lyria.volume * 100).round()}%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 24,
                    child: Slider(
                      value: lyria.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: lyria.isMuted
                          ? Colors.grey
                          : Theme.of(context).colorScheme.secondary,
                      onChanged: (val) => lyria.updateVolume(val),
                    ),
                  ),
                ],
              );

              final styleDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: styles.contains(lyria.style)
                      ? lyria.style
                      : styles.first,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: styles
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) lyria.updateStyle(val);
                  },
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        startButton,
                        const SizedBox(width: 8),
                        recordButton,
                        if (_hasRecorded) ...[
                          const SizedBox(width: 4),
                          downloadRecordButton,
                        ],
                        const Spacer(),
                        styleDropdown,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: tempoSlider),
                        const SizedBox(width: 12),
                        Expanded(child: volumeSlider),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  startButton,
                  const SizedBox(width: 8),
                  recordButton,
                  if (_hasRecorded) ...[
                    const SizedBox(width: 4),
                    downloadRecordButton,
                  ],
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: tempoSlider),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: volumeSlider),
                  const SizedBox(width: 16),
                  styleDropdown,
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Instrument Mixer & Beat Visualizer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "Band Mixer:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),

                // 4 Instrument Toggle Chips
                _buildInstrumentChip(
                  context: context,
                  label: "Drums",
                  icon: Icons.album_outlined,
                  isActive: lyria.drumsEnabled,
                  onTap: () => lyria.toggleInstrument("drums"),
                ),
                const SizedBox(width: 6),
                _buildInstrumentChip(
                  context: context,
                  label: "Bass",
                  icon: Icons.graphic_eq,
                  isActive: lyria.bassEnabled,
                  onTap: () => lyria.toggleInstrument("bass"),
                ),
                const SizedBox(width: 6),
                _buildInstrumentChip(
                  context: context,
                  label: "Keys",
                  icon: Icons.piano,
                  isActive: lyria.keysEnabled,
                  onTap: () => lyria.toggleInstrument("keys"),
                ),
                const SizedBox(width: 6),
                _buildInstrumentChip(
                  context: context,
                  label: "Guitar",
                  icon: Icons.music_note,
                  isActive: lyria.guitarEnabled,
                  onTap: () => lyria.toggleInstrument("guitar"),
                ),

                const Spacer(),

                // Beat Metronome / Pulse Indicator
                if (lyria.isPlaying) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (index) {
                      final isCurrentBeat = lyria.activeBeat == (index + 1);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isCurrentBeat ? 14 : 8,
                        height: isCurrentBeat ? 14 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrentBeat
                              ? (index == 0
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.primary)
                              : Colors.grey.withValues(alpha: 0.3),
                          boxShadow: isCurrentBeat
                              ? [
                                  BoxShadow(
                                    color: (index == 0
                                            ? Colors.redAccent
                                            : Theme.of(context).colorScheme.primary)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

