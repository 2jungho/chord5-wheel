import 'package:flutter/material.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../providers/settings_state.dart';
import '../../../../providers/studio_state.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

class SoloingGuidePanel extends StatefulWidget {
  const SoloingGuidePanel({super.key});

  @override
  State<SoloingGuidePanel> createState() => _SoloingGuidePanelState();
}

class _SoloingGuidePanelState extends State<SoloingGuidePanel> {
  // AI Recommendation Cache: Map<ChordSymbol, RecommendationData>
  // Simple caching to avoid re-fetching for same chord in same session context is ideal,
  // but for now let's just fetch on demand or button click.
  final Map<int, Map<String, dynamic>> _aiCache = {};
  bool _isFetching = false;
  String? _errorMessage; // Add error message state

  Future<void> _fetchAIRecommendation(
      BuildContext context, ChordBlock block, int index, String key) async {
    final settings = context.read<SettingsState>();
    final apiKey = settings.currentApiKey;
    if (apiKey.isEmpty) return;

    if (_isFetching) return;

    setState(() {
      _isFetching = true;
      _errorMessage = null;
    });

    try {
      final systemPrompt =
          PromptTemplates.getSoloingSystemPrompt(settings.systemPrompt);
      // Context: Current Chord, Key, Function
      // Ideally we send some surrounding context too.
      final userPrompt = PromptTemplates.getSoloingUserPrompt(
          [block]); // Wrap single block in list

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
      Map<String, dynamic> resultData = {};

      try {
        // Try to parse as List first (common for this prompt)
        final jsonList = AIService.extractJsonList(responseText);
        if (jsonList.isNotEmpty) {
          // If list has items, use the first one (assuming it's a Map)
          if (jsonList.first is Map) {
            resultData = Map<String, dynamic>.from(jsonList.first as Map);
          }
        } else {
          // If list extraction yields nothing, try single object
          resultData = AIService.extractJson(responseText);
        }
      } catch (e) {
        // Fallback: try direct object extraction if list logic failed unexpectedly
        try {
          resultData = AIService.extractJson(responseText);
        } catch (_) {
          debugPrint('JSON Parsing failed completely: $e');
          // Retain default empty map or handle error
        }
      }

      if (resultData.isNotEmpty) {
        setState(() {
          _aiCache[index] = resultData;
        });
      } else {
        throw const FormatException('Empty or invalid JSON response from AI');
      }
    } catch (e) {
      debugPrint('Soloing AI Fetch Error: $e');
      setState(() {
        _errorMessage = e.toString();
        // If it's not a quota error, we might still want to show snackbar for generic errors,
        // but QuotaErrorWidget handles generic errors too.
      });
      if (!e.toString().contains('Quota') && !e.toString().contains('429')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 추천 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioState>();
    final session = studio.session;

    if (session.progression.isEmpty) return const SizedBox.shrink();

    final currentIndex = studio.selectedBlockIndex;
    final currentBlock =
        (currentIndex >= 0 && currentIndex < session.progression.length)
            ? session.progression[currentIndex]
            : null;

    if (currentBlock == null) {
      return const SizedBox.shrink();
    }

    final hasApiKey = context.read<SettingsState>().currentApiKey.isNotEmpty;
    final cachedData = _aiCache[currentIndex];

    // Default (Rule-Based) Logic - Fallback
    String scaleRecommendation = '';
    String tip = '';
    final chord = currentBlock.chordSymbol;
    final function = currentBlock.functionTag;
    final keyName = session.key;
    final isMinorKey = keyName.contains('Minor') ||
        (keyName.endsWith('m') && !keyName.contains('Major'));

    // ... (Existing Rule-Based Logic from StudioTimeline) ...
    // To preserve existing behavior as fallback/default
    if (function != null) {
      if (function == 'V' || function == 'V7') {
        if (isMinorKey) {
          scaleRecommendation = 'Phrygian Dominant';
          tip = '하모닉 마이너의 5번째 모드. 이국적/클래식 사운드.';
        } else {
          scaleRecommendation = 'Mixolydian Mode';
          tip = '도미넌트 7th의 텐션을 활용하세요.';
        }
      } else if (function.toLowerCase() == 'i' || function.contains('I')) {
        if (isMinorKey) {
          scaleRecommendation = '$keyName Natural Minor (Aeolian)';
          tip = '기본 마이너 스케일. 슬프고 차분함.';
        } else {
          scaleRecommendation = '$keyName Major Scale (Ionian)';
          tip = '안정적인 토닉 사운드. 코드 톤 집중.';
        }
      } else if (function.toLowerCase().contains('ii')) {
        scaleRecommendation = chord.contains('b5') ? 'Locrian' : 'Dorian';
        tip = chord.contains('b5') ? 'm7b5엔 로크리안.' : '세련된 마이너 느낌.';
      } else if (function.toLowerCase().contains('vi')) {
        scaleRecommendation = 'Aeolian (Natural Minor)';
        tip = '서정적인 전개.';
      }
    }

    // Very basic fallback if logic missed
    if (scaleRecommendation.isEmpty) {
      scaleRecommendation = '$keyName Scale';
      tip = '키 스케일 음을 중심으로 연주하세요.';
    }

    // Override with AI Data if available
    bool isAiResult = false;
    if (cachedData != null) {
      scaleRecommendation = cachedData['scale'] ?? scaleRecommendation;
      tip = cachedData['tips'] ?? tip;
      isAiResult = true;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isAiResult
                      ? Icons.auto_awesome
                      : Icons.library_music_outlined,
                  size: 18,
                  color: isAiResult
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '솔로잉 가이드 (${isAiResult ? "AI 추천" : "Basic"})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAiResult
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (hasApiKey && !isAiResult)
                SizedBox(
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: _isFetching
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_fix_high, size: 16),
                    onPressed: _isFetching
                        ? null
                        : () => _fetchAIRecommendation(
                            context, currentBlock, currentIndex, keyName),
                    tooltip: 'AI 추천 받기',
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAiResult
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                  : Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isAiResult
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.3)),
            ),
            child: _errorMessage != null &&
                    QuotaErrorWidget.isQuotaErrorDetected(_errorMessage!)
                ? QuotaErrorWidget(
                    errorMessage: _errorMessage!,
                    onRetry: () => _fetchAIRecommendation(
                        context, currentBlock, currentIndex, keyName),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('추천 스케일:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 4),
                      Text(scaleRecommendation,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Tip:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(tip,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
