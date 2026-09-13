import 'package:flutter/material.dart';
import '../../../models/instrument_model.dart';

/// Dropdown selector for instrument tuning presets.
class TuningDropdown extends StatelessWidget {
  final TuningPreset tuningPreset;
  final ValueChanged<TuningPreset>? onSelectTuning;

  const TuningDropdown({
    super.key,
    required this.tuningPreset,
    this.onSelectTuning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TuningPreset>(
          value: tuningPreset,
          dropdownColor: isDark ? const Color(0xFF1E2433) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          onChanged: (TuningPreset? newPreset) {
            if (newPreset != null) {
              onSelectTuning?.call(newPreset);
            }
          },
          items: TuningPreset.values.map((preset) {
            final isSelected = preset == tuningPreset;
            return DropdownMenuItem<TuningPreset>(
              value: preset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                  ] else ...[
                    const SizedBox(width: 20),
                  ],
                  Text(
                    preset.shortName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${preset.notes.join(' ')})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
