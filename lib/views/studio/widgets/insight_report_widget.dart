import 'package:flutter/material.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../providers/settings_state.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

class InsightReportWidget extends StatefulWidget {
  final List<ChordBlock> progression;

  const InsightReportWidget({
    super.key,
    required this.progression,
  });

  @override
  State<InsightReportWidget> createState() => _InsightReportWidgetState();
}

class _InsightReportWidgetState extends State<InsightReportWidget> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  String? _lastProgressionStr;

  @override
  void didUpdateWidget(covariant InsightReportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If progression changes significantly, reset analysis
    final newProgressionStr =
        widget.progression.map((b) => b.chordSymbol).join('-');
    if (_lastProgressionStr != newProgressionStr) {
      _lastProgressionStr = newProgressionStr;
      setState(() {
        _analysisResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _runAnalysis() async {
    final settings = context.read<SettingsState>();
    final apiKey = settings.currentApiKey;
    if (apiKey.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final progressionStr =
          widget.progression.map((b) => b.chordSymbol).join(' - ');

      final systemPrompt =
          PromptTemplates.getInsightSystemPrompt(settings.systemPrompt);
      final userPrompt = PromptTemplates.getInsightUserPrompt(progressionStr);

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
      final jsonResult = AIService.extractJson(responseText);

      setState(() {
        _analysisResult = jsonResult;
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
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prerequisite: API Key Check
    final hasApiKey = context.watch<SettingsState>().currentApiKey.isNotEmpty;
    if (!hasApiKey) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person,
                  size: 48,
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'AI 분석을 사용하려면 API 키가 필요합니다.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.progression.isEmpty) {
      return const Center(
        child: Text('분석할 코드 진행이 없습니다.'),
      );
    }

    if (_analysisResult == null) {
      if (_isAnalyzing) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('화성학 분석 중...'),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('코드 진행에 대한 심층 분석을 실행합니다.'),
            const SizedBox(height: 24),
            if (_errorMessage != null &&
                QuotaErrorWidget.isQuotaErrorDetected(_errorMessage!))
              QuotaErrorWidget(
                errorMessage: _errorMessage!,
                onRetry: _runAnalysis,
              )
            else ...[
              FilledButton.icon(
                onPressed: _runAnalysis,
                icon: const Icon(Icons.search),
                label: const Text('AI 심층 분석 실행'),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12)),
                ),
            ],
          ],
        ),
      );
    }

    // Display Result
    final estimatedKey = _analysisResult?['estimated_key'] ?? 'Unknown';
    final summary = _analysisResult?['summary'] ?? '';
    final List<dynamic> analysisList = _analysisResult?['analysis'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.key,
                        size: 20,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated Key: $estimatedKey',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Analysis List
          const Text(
            'Chord Function Analysis',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...analysisList.map((item) {
            final chord = item['chord'] ?? '';
            final function = item['function'] ?? '';
            final desc = item['description'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(chord,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (function.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                function,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('다시 분석하기'),
            ),
          ),
        ],
      ),
    );
  }
}
