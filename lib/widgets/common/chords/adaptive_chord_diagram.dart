import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/chord_model.dart';
import '../../../models/instrument_model.dart';
import '../../../providers/settings_state.dart';
import '../../../utils/theory_utils.dart';
import '../chord_detail_dialog.dart';
import '../guitar/guitar_chord_widget.dart';
import '../piano/piano_chord_widget.dart';

/// 선택된 악기(기타/피아노 등)에 맞춰 자동으로 적절한 코드 다이어그램을 렌더링하는 다형성 위젯
class AdaptiveChordDiagram extends StatelessWidget {
  final ChordVoicing? voicing;
  final List<String> notes;
  final double width;
  final double height;
  final bool showLabels;
  final bool isMain;
  final String? root;
  final String? quality;
  final String? characterNote;
  final VoidCallback? onPlay;
  final VoidCallback? onTap;
  final bool enableDetailDialog;
  final Instrument? instrument;

  const AdaptiveChordDiagram({
    super.key,
    this.voicing,
    this.notes = const [],
    this.width = 160,
    this.height = 120,
    this.showLabels = true,
    this.isMain = false,
    this.root,
    this.quality,
    this.characterNote,
    this.onPlay,
    this.onTap,
    this.enableDetailDialog = false,
    this.instrument,
  });

  @override
  Widget build(BuildContext context) {
    final selectedInstrument =
        instrument ?? context.watch<SettingsState>().selectedInstrument;
    final isPiano = selectedInstrument.type == InstrumentType.piano;

    if (isPiano) {
      // 피아노 다이어그램: 노트 목록 우선 사용, 없을 경우 voicing+root로부터 계산
      List<String> effectiveNotes = notes;
      if (effectiveNotes.isEmpty && voicing != null && root != null) {
        effectiveNotes = TheoryUtils.getNotesFromVoicing(voicing!, root!);
      }

      if (effectiveNotes.isEmpty) {
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.music_off, size: 24, color: Colors.grey),
          ),
        );
      }

      return PianoChordWidget(
        notes: effectiveNotes,
        width: width,
        height: height,
        showLabels: showLabels,
      );
    }

    // 기타 및 현악기 다이어그램
    if (voicing == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.music_off, size: 24, color: Colors.grey),
        ),
      );
    }

    final guitarWidget = GuitarChordWidget(
      voicing: voicing!,
      width: width,
      height: height,
      isMain: isMain,
      stringCount: selectedInstrument.stringCount,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: guitarWidget,
      );
    }

    if (enableDetailDialog && root != null && quality != null) {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ChordDetailDialog(
              root: root!,
              quality: quality!,
              voicing: voicing!,
              notes: notes,
              onPlay: onPlay,
              characterNote: characterNote,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: guitarWidget,
      );
    }

    return guitarWidget;
  }
}
