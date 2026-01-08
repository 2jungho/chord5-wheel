import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_state.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

class AIArrangeDialog extends StatefulWidget {
  final List<ChordBlock> currentProgression;
  final Function(List<ChordBlock> blocks, String style) onApply;

  const AIArrangeDialog({
    super.key,
    required this.currentProgression,
    required this.onApply,
  });

  @override
  State<AIArrangeDialog> createState() => _AIArrangeDialogState();
}

class _AIArrangeDialogState extends State<AIArrangeDialog> {
  final List<Map<String, String>> _styles = [
    {'name': 'Jazz Re-harm', 'desc': '텐션과 대리 코드를 활용한 재즈 스타일'},
    {'name': 'Neo-Soul', 'desc': 'R&B/Hip-hop 감성의 세련된 보이싱'},
    {'name': 'Pop Ballad', 'desc': '서정적이고 안정적인 팝 발라드'},
    {'name': 'Cinematic', 'desc': '영화음악 같은 웅장하고 몽환적인 분위기'},
    {'name': 'Lo-Fi', 'desc': '편안하고 따뜻한 느낌의 로파이 감성'},
    {'name': 'Bluesy', 'desc': '블루스 스케일과 도미넌트 7th 강조'},
  ];

  String _selectedStyle = 'Jazz Re-harm';
  bool _isGenerating = false;
  String? _errorMessage;
  List<ChordBlock>? _generatedProgression;
  String? _explanation;

  Future<void> _generateArrangement() async {
    final settings = context.read<SettingsState>();
    final apiKey = settings.currentApiKey;
    if (apiKey.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedProgression = null;
    });

    try {
      final progressionStr =
          widget.currentProgression.map((b) => b.chordSymbol).join('-');
      // 총 마디 수 계산 (기본 duration 4 = 1마디 가정)
      final totalDuration =
          widget.currentProgression.fold(0, (sum, b) => sum + b.duration);
      final totalBars = (totalDuration / 4).ceil();

      final systemPrompt =
          PromptTemplates.getVariatorSystemPrompt(settings.systemPrompt);
      final userPrompt = PromptTemplates.getVariatorUserPrompt(
          progressionStr, _selectedStyle, totalBars);

      final aiService = AIService(
        apiKey: apiKey,
        provider: settings.aiProvider,
        modelName: settings.geminiModel.id,
        systemPrompt: systemPrompt,
      );

      final buffer = StringBuffer();
      await for (final chunk in aiService.sendMessageStream(userPrompt)) {
        buffer.write(chunk);
      }

      final responseText = buffer.toString();
      final jsonList = AIService.extractJsonList(responseText);

      final List<ChordBlock> newBlocks = [];
      final List<String> comments = [];

      for (var item in jsonList) {
        if (item is Map) {
          final chord = item['chord'] ?? 'C';
          // int or double handling
          final durationRaw = item['duration'] ?? 4;
          final int duration = (durationRaw is num) ? durationRaw.toInt() : 4;
          final comment = item['comment'] ?? '';

          newBlocks.add(ChordBlock(
            chordSymbol: chord,
            duration: duration,
          ));
          if (comment.isNotEmpty) {
            comments.add('$chord: $comment');
          }
        }
      }

      if (newBlocks.isEmpty) {
        throw Exception('생성된 코드가 없습니다.');
      }

      setState(() {
        _generatedProgression = newBlocks;
        _explanation = comments.take(3).join('\n'); // 상위 3개 코멘트만 표시
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // API Key Check (Prerequisite)
    final hasApiKey = context.read<SettingsState>().currentApiKey.isNotEmpty;
    if (!hasApiKey) {
      return AlertDialog(
        title: const Text('API 키 필요'),
        content:
            const Text('이 기능을 사용하려면 설정에서 AI API 키(Gemini/OpenAI)를 등록해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_fix_high,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('AI 편곡 (Arrangement)'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재 코드 진행을 원하는 스타일로 재해석합니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Style Selector
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _styles.map((style) {
                  final isSelected = _selectedStyle == style['name'];
                  return ChoiceChip(
                    label: Text(style['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStyle = style['name']!;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (_selectedStyle.isNotEmpty)
                Text(
                  _styles
                      .firstWhere((s) => s['name'] == _selectedStyle)['desc']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const Divider(height: 32),

              // Result Area
              if (_isGenerating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                QuotaErrorWidget.isQuotaErrorDetected(_errorMessage!)
                    ? QuotaErrorWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _generateArrangement,
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      )
              else if (_generatedProgression != null) ...[
                Text('제안된 진행:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _generatedProgression!
                        .map((b) => b.chordSymbol)
                        .join(' - '),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_explanation != null && _explanation!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('특이사항:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(
                    _explanation!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ]
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('스타일을 선택하고 생성 버튼을 누르세요.'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (_generatedProgression == null || _errorMessage != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),

        // Generate Button (if not generated yet)
        if (_generatedProgression == null && !_isGenerating)
          FilledButton.icon(
            onPressed: _generateArrangement,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('생성하기'),
          ),

        // Apply Button (if generated)
        if (_generatedProgression != null) ...[
          TextButton(
            onPressed: _generateArrangement, // Retry with same settings
            child: const Text('다시 생성'),
          ),
          FilledButton(
            onPressed: () {
              widget.onApply(_generatedProgression!, _selectedStyle);
              Navigator.of(context).pop();
            },
            child: const Text('적용하기'),
          ),
        ],
      ],
    );
  }
}
