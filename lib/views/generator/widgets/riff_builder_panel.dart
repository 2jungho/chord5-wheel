import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';

class RiffBuilderPanel extends StatelessWidget {
  final String rootNote;
  final String quality;
  final String scaleName;

  const RiffBuilderPanel({
    super.key,
    required this.rootNote,
    required this.quality,
    required this.scaleName,
  });

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              const Text(
                "Interactive Riff Builder (Lyria)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (lyria.isPlaying)
                Text(
                  "Playing Riff...",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Generate a guitar riff based on $rootNote$quality using $scaleName.",
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Style Chips
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRiffChip(context, lyria, "Funky Riff",
                        "Create a funky guitar riff in $rootNote$quality. Syncopated rhythm."),
                    _buildRiffChip(context, lyria, "Heavy Metal",
                        "Create a heavy metal riff in $rootNote$quality using power chords and palm muting."),
                    _buildRiffChip(context, lyria, "Neo Soul",
                        "Create a neo-soul guitar riff in $rootNote$quality. Smooth and chordal."),
                    _buildRiffChip(context, lyria, "Blues Lick",
                        "Play a blues lick over $rootNote$quality using the pentatonic scale."),
                    _buildRiffChip(context, lyria, "Solo Line",
                        "Play a melodic solo line over $rootNote$quality using the $scaleName."),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: lyria.isConnected
                ? OutlinedButton.icon(
                    onPressed: lyria.disconnect,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop Playback"),
                  )
                : FilledButton.icon(
                    onPressed: lyria.connect,
                    icon: const Icon(Icons.link),
                    label: const Text("Ready to Riff"),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRiffChip(
      BuildContext context, LyriaState lyria, String label, String prompt) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.play_circle_outline, size: 16),
      onPressed: () {
        if (!lyria.isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Connecting to Lyria... Press again when ready.")));
          lyria.connect();
          return;
        }
        // Send Riff Prompt
        final fullPrompt =
            "Context: Guitar Riff Generator.\n$prompt\nTempo: 110 BPM. Length: 2 bars loop.";
        lyria.startJam(fullPrompt);
      },
    );
  }
}
