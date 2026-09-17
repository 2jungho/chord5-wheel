import 'package:flutter/material.dart';
import '../../models/chord_model.dart';
import '../../models/instrument_model.dart';
import '../../utils/theory_utils.dart';
import 'chords/adaptive_chord_diagram.dart';

class ChordInfoSection extends StatelessWidget {
  final String root;
  final String quality;
  final String intervals;
  final List<String> notes;
  final VoidCallback onPlay;
  final VoidCallback? onRestore;
  final ChordVoicing? voicing;
  final String? characterNote;
  final String? degree;
  final Instrument instrument;

  const ChordInfoSection({
    super.key,
    required this.root,
    required this.quality,
    required this.intervals,
    required this.notes,
    required this.onPlay,
    this.onRestore,
    this.voicing,
    this.characterNote,
    this.degree,
    required this.instrument,
  });

  @override
  Widget build(BuildContext context) {
    // 퀄리티 표시용 문자열 변환
    final displayQuality = TheoryUtils.formatDisplayQuality(quality);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('CHORD SYMBOL',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 1.0)),
            if (degree != null && degree!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(degree!,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(root,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 42,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(displayQuality,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w300)),
              ),
            ),
            const SizedBox(width: 16),
            if (onRestore != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: onRestore,
                  icon: Icon(Icons.restore,
                      size: 32, color: Theme.of(context).colorScheme.tertiary),
                  tooltip: 'Restore initial chord',
                ),
              ),
            IconButton(
              onPressed: onPlay,
              icon: Icon(Icons.play_circle_fill,
                  size: 40, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (voicing != null || notes.isNotEmpty)
          Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              AdaptiveChordDiagram(
                voicing: voicing,
                notes: notes,
                width: 170,
                height: 130,
                isMain: true,
                root: root,
                quality: quality,
                characterNote: characterNote,
                onPlay: onPlay,
                enableDetailDialog: true,
                instrument: instrument,
              ),
              _buildDetails(context, instrument),
            ],
          ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, Instrument instrument) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoItem(
            context, 'Intervals', intervals.isEmpty ? '-' : intervals,
            isCode: true),
        const SizedBox(height: 6),
        _buildInfoItem(context, 'Notes', notes.join(', '), isCode: true),
        // Shape Info는 프렛보드 악기일 때만 의미가 있음
        if (voicing != null && instrument.isFretted) ...[
          const SizedBox(height: 6),
          _buildInfoItem(
            context,
            'Shape Info',
            voicing!.frets
                .take(instrument.stringCount)
                .map((f) => f == -1 ? 'x' : f.toString())
                .join(' '),
            isCode: true,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value,
      {bool isBold = false, bool isCode = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight:
                    isBold || isCode ? FontWeight.bold : FontWeight.normal,
                fontFamily: isCode ? 'monospace' : null)),
      ],
    );
  }
}
