import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';

class InstantModePanel extends StatelessWidget {
  final String rootNote;
  final String modeName;

  const InstantModePanel({
    super.key,
    required this.rootNote,
    required this.modeName,
  });

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();
    final isPlaying = lyria.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq, // Sound Wave Icon
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Instant Mode Preview (Lyria)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                "$rootNote $modeName Atmosphere",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Play Button
          IconButton.filled(
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 20),
            tooltip:
                isPlaying ? "Stop Preview" : "Listen to $rootNote $modeName",
            onPressed: !lyria.isReady && !lyria.isConnected
                ? () {
                    // Auto-connect if needed?
                    // For now, let's assume global connection or show snackbar
                    lyria.connect();
                  }
                : () {
                    if (isPlaying) {
                      lyria.disconnect(); // Or stop command
                    } else {
                      // Prompt for ambient mode music
                      final prompt =
                          "Create an ambient ${modeName.toLowerCase()} backing track in $rootNote. "
                          "Focus on the characteristic intervals of the ${modeName} mode. "
                          "Style: Ambient, Pad, Slow. Length: loop.";
                      lyria.startJam(prompt);
                    }
                  },
          ),
          // Connection Status Dot
          if (!lyria.isConnected)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: "Lyria API Disconnected",
                child: Icon(Icons.link_off,
                    size: 16, color: Theme.of(context).disabledColor),
              ),
            ),
        ],
      ),
    );
  }
}
