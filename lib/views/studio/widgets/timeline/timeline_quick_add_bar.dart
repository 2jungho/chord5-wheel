import 'package:flutter/material.dart';
import '../../../../providers/studio_state.dart';
import '../preset_selector_dialog.dart';

class TimelineQuickAddBar extends StatefulWidget {
  final TextEditingController controller;
  final StudioState studio;

  const TimelineQuickAddBar({
    super.key,
    required this.controller,
    required this.studio,
  });

  @override
  State<TimelineQuickAddBar> createState() => _TimelineQuickAddBarState();
}

class _TimelineQuickAddBarState extends State<TimelineQuickAddBar> {
  @override
  Widget build(BuildContext context) {
    final currentChordsText =
        widget.studio.session.progression.map((c) => c.chordSymbol).join(' - ');
    if (widget.controller.text.isEmpty && currentChordsText.isNotEmpty) {
      widget.controller.text = currentChordsText;
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.bolt, size: 20, color: Colors.amber),
              tooltip: '코드 진행 프리셋 탐색기',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => PresetSelectorDialog(
                    onSelected: (progression) {
                      widget.controller.text = progression;
                      setState(() {});
                    },
                    onApply: (progression, title) {
                      widget.studio.addProgressionFromText(progression,
                          replace: true, title: title);
                      widget.controller.text = progression;
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: (val) => setState(() {}),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.studio.addProgressionFromText(value.trim(),
                      replace: true, title: value.trim());
                  widget.controller.text = value.trim();
                  setState(() {});
                }
              },
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Quick Add (영문/숫자 입력 e.g. C-Am-Dm-G7)',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]').hasMatch(widget.controller.text))
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Icon(Icons.g_translate_rounded,
                      color: Theme.of(context).colorScheme.error, size: 12),
                  const SizedBox(width: 4),
                  Text('한/영 키를 눌러 영문으로 변경하세요',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          if (widget.controller.text.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '입력한 진행으로 전체 교체 (신규 생성)',
              child: InkWell(
                onTap: () {
                  widget.studio.addProgressionFromText(
                      widget.controller.text.trim(),
                      replace: true,
                      title: widget.controller.text.trim());
                  setState(() {});
                },
                child: Text('신규',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '기존 진행 뒤에 추가',
              child: InkWell(
                onTap: () {
                  widget.studio.addProgressionFromText(
                      widget.controller.text.trim(),
                      replace: false);
                  widget.controller.text = widget.studio.session.progression
                      .map((c) => c.chordSymbol)
                      .join(' - ');
                  setState(() {});
                },
                child: Text('추가',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary)),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                widget.controller.clear();
                setState(() {});
              },
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
