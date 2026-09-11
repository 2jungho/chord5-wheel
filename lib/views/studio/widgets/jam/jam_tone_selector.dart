import 'package:flutter/material.dart';
import '../../../../models/audio/band_sound_profile.dart';

class JamToneSelector extends StatelessWidget {
  final BandInstrumentCategory category;
  final SoundProfile currentProfile;
  final bool isActive;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;
  final Function(SoundProfile) onProfileSelected;

  const JamToneSelector({
    super.key,
    required this.category,
    required this.currentProfile,
    required this.isActive,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profiles = BandSoundProfiles.getProfilesForCategory(category);

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle Mute/Unmute
          InkWell(
            onTap: onToggle,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentProfile.icon,
                    size: 13,
                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tone Dropdown Selector
          PopupMenuButton<SoundProfile>(
            tooltip: '${category.displayName} 사운드 프로파일 변경',
            padding: EdgeInsets.zero,
            initialValue: currentProfile,
            onSelected: onProfileSelected,
            itemBuilder: (context) => profiles.map((p) {
              final isSel = p.id == currentProfile.id;
              return PopupMenuItem<SoundProfile>(
                value: p,
                child: Row(
                  children: [
                    Icon(p.icon,
                        size: 16,
                        color: isSel ? theme.colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? theme.colorScheme.primary : null,
                            ),
                          ),
                          Text(
                            p.description,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (isSel)
                      Icon(Icons.check,
                          size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentProfile.shortName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Volume Slider Popup
          PopupMenuButton<void>(
            tooltip: '${category.displayName} 볼륨 조절 (${(volume * 100).toInt()}%)',
            padding: EdgeInsets.zero,
            itemBuilder: (ctx) => [
              PopupMenuItem<void>(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    return SizedBox(
                      width: 140,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${category.displayName} 볼륨: ${(volume * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Slider(
                            value: volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: (v) {
                              setLocalState(() {});
                              onVolumeChanged(v);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(
                volume < 0.05
                    ? Icons.volume_mute
                    : (volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                size: 13,
                color: isActive ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
