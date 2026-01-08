import 'package:flutter/material.dart';
import '../../models/chord_model.dart';
import '../../models/instrument_model.dart';
import 'guitar/guitar_chord_widget.dart';
import 'chord_detail_dialog.dart';
import 'piano/piano_chord_widget.dart';

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
    String displayQuality = quality;
    if (quality == 'm')
      displayQuality = 'minor';
    else if (quality == 'maj7') displayQuality = 'major 7';

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
        const SizedBox(height: 12),
        Row(
          children: [
            Text(root,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(displayQuality,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 32,
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
        const SizedBox(height: 24),
        if (voicing != null || notes.isNotEmpty)
          LayoutBuilder(builder: (context, constraints) {
            // Use side-by-side layout if there's enough width
            // 180 (Diagram) + 16 (Gap) + 130 (Min Text width) = 326
            final bool useRow = constraints.maxWidth > 330;

            Widget diagramWidget;
            if (instrument.type == InstrumentType.piano) {
              diagramWidget = PianoChordWidget(
                notes: notes,
                width: 180,
                height: 120,
              );
            } else {
              diagramWidget = InkWell(
                onTap: () {
                  if (instrument.type == InstrumentType.piano) return;
                  if (voicing == null) return;

                  showDialog(
                    context: context,
                    builder: (context) => ChordDetailDialog(
                      root: root,
                      quality: quality,
                      voicing: voicing!,
                      notes: notes,
                      onPlay: onPlay,
                      characterNote: characterNote,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: GuitarChordWidget(
                  voicing: voicing ??
                      ChordVoicing(
                          frets: [-1, -1, -1, -1, -1, -1],
                          startFret: 0,
                          rootString: 6),
                  width: 180,
                  height: 140,
                  isMain: true,
                  stringCount: instrument.stringCount,
                ),
              );
            }

            if (useRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  diagramWidget,
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetails(context, instrument),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  diagramWidget,
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: _buildDetails(context, instrument),
                  ),
                ],
              );
            }
          }),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, Instrument instrument) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInfoItem(
            context, 'Intervals', intervals.isEmpty ? '-' : intervals,
            isCode: true),
        const SizedBox(height: 8),
        _buildInfoItem(context, 'Notes', notes.join(', '), isCode: true),
        // Shape Info는 프렛보드 악기일 때만 의미가 있음
        if (voicing != null && instrument.isFretted) ...[
          const SizedBox(height: 8),
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
