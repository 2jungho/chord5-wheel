import 'package:flutter/material.dart';
import '../../../providers/settings_state.dart';
import '../../../models/instrument_model.dart';
import 'settings_section_title.dart';

/// 악기 및 튜닝 설정 섹션
class InstrumentSettingsSection extends StatelessWidget {
  final SettingsState settings;

  const InstrumentSettingsSection({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('악기 (INSTRUMENT)', icon: Icons.music_note),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.selectedInstrumentId,
              isExpanded: true,
              icon: const Icon(Icons.expand_more),
              items: settings.availableInstruments
                  .map((Instrument inst) => DropdownMenuItem<String>(
                        value: inst.id,
                        child: Row(
                          children: [
                            Icon(
                              inst.type == InstrumentType.piano
                                  ? Icons.piano
                                  : Icons.grid_view,
                              size: 18,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Text(inst.name, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) settings.setInstrument(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
