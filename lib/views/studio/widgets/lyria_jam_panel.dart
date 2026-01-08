import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';
import '../../../providers/studio_state.dart';

class LyriaJamPanel extends StatelessWidget {
  const LyriaJamPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();
    final studio = context.read<StudioState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              Icon(Icons.spatial_audio_off,
                  size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Lyria Jam Session (Exp)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              // Status Indicator
              Tooltip(
                message: lyria.isConnected
                    ? (lyria.isPlaying ? "Playing" : "Connected")
                    : "Disconnected",
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !lyria.isConnected
                        ? Colors.red
                        : (lyria.isPlaying ? Colors.green : Colors.amber),
                  ),
                ),
              ),
            ],
          ),

          // Status Text
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              lyria.statusMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Controls
          Row(
            children: [
              // Connect Button
              if (!lyria.isConnected)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => lyria.connect(),
                    icon: const Icon(Icons.link),
                    label: const Text("Initialize Session"),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
              else
                // Jam Controls
                Expanded(
                  child: Row(
                    children: [
                      // Play/Stop
                      IconButton.filled(
                        icon: Icon(
                            lyria.isPlaying ? Icons.stop : Icons.play_arrow),
                        tooltip: lyria.isPlaying ? "Stop Jam" : "Start Jam",
                        onPressed: lyria.isReady
                            ? () {
                                if (lyria.isPlaying) {
                                  lyria.disconnect();
                                } else {
                                  final session = studio.session;
                                  String chords = "Key: ${session.key}\n";
                                  if (session.progression.isEmpty) {
                                    chords +=
                                        "Progression: C - Am - F - G"; // Demo
                                  } else {
                                    chords += "Progression: " +
                                        session.progression
                                            .map((b) => b.chordSymbol)
                                            .join(" - ");
                                  }
                                  lyria.startJam(chords);
                                }
                              }
                            : null, // Disable if not ready
                      ),
                      const SizedBox(width: 12),

                      // Tempo
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tempo: ${lyria.tempo.toInt()} BPM",
                                  style: const TextStyle(fontSize: 10)),
                              SizedBox(
                                height: 24,
                                child: Slider(
                                  value: lyria.tempo,
                                  min: 60,
                                  max: 200,
                                  onChanged: (val) => lyria.updateTempo(val),
                                ),
                              ),
                            ]),
                      ),

                      const SizedBox(width: 12),
                      // Style
                      DropdownButton<String>(
                        value: lyria.style,
                        items: ["Rock", "Jazz", "Funk", "Lo-Fi", "Blues"]
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) lyria.updateStyle(val);
                        },
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}
