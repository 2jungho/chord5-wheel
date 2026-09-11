import 'package:flutter/material.dart';
import '../../../../providers/lyria_state.dart';
import '../../../../models/audio/band_sound_profile.dart';
import 'jam_tone_selector.dart';

class JamBandMixer extends StatelessWidget {
  final LyriaState lyria;

  const JamBandMixer({super.key, required this.lyria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                "Band Tone:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // 4 Instrument Sound Profile Selectors & Mute Toggles & Track Volumes
          JamToneSelector(
            category: BandInstrumentCategory.drums,
            currentProfile: lyria.selectedDrums,
            isActive: lyria.drumsEnabled,
            volume: lyria.drumsVolume,
            onToggle: () => lyria.toggleInstrument("drums"),
            onVolumeChanged: (v) => lyria.updateInstrumentVolume("drums", v),
            onProfileSelected: (p) =>
                lyria.setSoundProfile(BandInstrumentCategory.drums, p),
          ),
          JamToneSelector(
            category: BandInstrumentCategory.bass,
            currentProfile: lyria.selectedBass,
            isActive: lyria.bassEnabled,
            volume: lyria.bassVolume,
            onToggle: () => lyria.toggleInstrument("bass"),
            onVolumeChanged: (v) => lyria.updateInstrumentVolume("bass", v),
            onProfileSelected: (p) =>
                lyria.setSoundProfile(BandInstrumentCategory.bass, p),
          ),
          JamToneSelector(
            category: BandInstrumentCategory.keys,
            currentProfile: lyria.selectedKeys,
            isActive: lyria.keysEnabled,
            volume: lyria.keysVolume,
            onToggle: () => lyria.toggleInstrument("keys"),
            onVolumeChanged: (v) => lyria.updateInstrumentVolume("keys", v),
            onProfileSelected: (p) =>
                lyria.setSoundProfile(BandInstrumentCategory.keys, p),
          ),
          JamToneSelector(
            category: BandInstrumentCategory.guitar,
            currentProfile: lyria.selectedGuitar,
            isActive: lyria.guitarEnabled,
            volume: lyria.guitarVolume,
            onToggle: () => lyria.toggleInstrument("guitar"),
            onVolumeChanged: (v) => lyria.updateInstrumentVolume("guitar", v),
            onProfileSelected: (p) =>
                lyria.setSoundProfile(BandInstrumentCategory.guitar, p),
          ),

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
    );
  }
}
