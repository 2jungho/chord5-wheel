import 'package:flutter/material.dart';
import '../../../providers/settings_state.dart';
import '../../../utils/app_theme.dart';
import 'settings_section_title.dart';

/// 일반 설정 (앱 테마 프리셋, 마스터 볼륨)
class GeneralSettingsSection extends StatelessWidget {
  final SettingsState settings;

  const GeneralSettingsSection({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('일반 (GENERAL)',
            icon: Icons.dashboard_customize),
        const SizedBox(height: 8),

        // Theme Preset Selection
        Text('앱 테마 (Theme Palette)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppThemePreset.values.map((preset) {
            final isSelected = settings.themePreset == preset;
            return InkWell(
              onTap: () => settings.setThemePreset(preset),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 190,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: preset.primaryAccent,
                        border:
                            Border.all(color: Colors.white70, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Master Volume
        Row(
          children: [
            Text('마스터 볼륨',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(width: 12),
            Icon(Icons.volume_down,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            Expanded(
              child: Slider(
                value: settings.masterVolume,
                min: 0.0,
                max: 1.0,
                onChanged: settings.setMasterVolume,
              ),
            ),
            Icon(Icons.volume_up,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${(settings.masterVolume * 100).toInt()}%',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
