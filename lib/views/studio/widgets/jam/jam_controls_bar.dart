import 'package:flutter/material.dart';
import '../../../../providers/lyria_state.dart';
import '../../../../providers/studio_state.dart';

class JamControlsBar extends StatelessWidget {
  final LyriaState lyria;
  final StudioState studio;
  final bool isRecording;
  final bool hasRecorded;
  final VoidCallback onToggleRecording;
  final VoidCallback onDownloadRecording;
  final VoidCallback? onTogglePlayback;
  final List<String> styles;

  const JamControlsBar({
    super.key,
    required this.lyria,
    required this.studio,
    required this.isRecording,
    required this.hasRecorded,
    required this.onToggleRecording,
    required this.onDownloadRecording,
    this.onTogglePlayback,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 820;

        final startButton = FilledButton.icon(
          onPressed: lyria.isConnecting
              ? null
              : (onTogglePlayback ??
                  () {
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

                      lyria.startJamSession(
                        chordProgression: chords,
                        blocks: session.progression,
                        key: session.key.isNotEmpty ? session.key : 'C Major',
                      );
                    }
                  }),
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
          onPressed: onToggleRecording,
          icon: Icon(
            isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
            size: 15,
            color: isRecording ? Colors.red : Colors.redAccent,
          ),
          label: Text(
            isRecording ? "녹음 중지" : "REC",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isRecording ? Colors.red : null,
            ),
          ),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(
              color: isRecording
                  ? Colors.red
                  : Theme.of(context).dividerColor,
            ),
          ),
        );

        final downloadRecordButton = IconButton(
          tooltip: '녹음된 연주 파일 다운로드 (WAV)',
          onPressed: onDownloadRecording,
          icon: const Icon(Icons.download, size: 18, color: Colors.green),
          visualDensity: VisualDensity.compact,
        );

        final tempoSlider = Row(
          children: [
            Text(
              "Tempo: ${lyria.tempo.toInt()} BPM",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: lyria.tempo,
                  min: 60.0,
                  max: 180.0,
                  divisions: 120,
                  onChanged: (val) => lyria.updateTempo(val),
                ),
              ),
            ),
          ],
        );

        final volumeSlider = Row(
          children: [
            IconButton(
              icon: Icon(
                lyria.isMuted
                    ? Icons.volume_off
                    : (lyria.volume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up),
                size: 16,
                color: lyria.isMuted
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => lyria.toggleMute(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              "Vol: ${(lyria.volume * 100).toInt()}%",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
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
            value:
                styles.contains(lyria.style) ? lyria.style : styles.first,
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
                  if (hasRecorded) ...[
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
            if (hasRecorded) ...[
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
    );
  }
}
