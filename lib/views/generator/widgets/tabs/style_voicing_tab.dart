import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../services/ai_service.dart';
import '../../../../../services/prompt_templates.dart';
import '../../../../../providers/settings_state.dart';
import '../../../../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

class StyleVoicingTab extends StatefulWidget {
  final String root;
  final String quality;
  final String? selectedScaleName;

  const StyleVoicingTab({
    super.key,
    required this.root,
    required this.quality,
    this.selectedScaleName,
  });

  @override
  State<StyleVoicingTab> createState() => _StyleVoicingTabState();
}

class _StyleVoicingTabState extends State<StyleVoicingTab>
    with AutomaticKeepAliveClientMixin {
  final List<String> _styles = [
    'Neo-Soul',
    'Funk',
    'Jazz Ballad',
    'Rock',
    'R&B'
  ];
  String _selectedStyle = 'Neo-Soul';

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  Future<void> _analyzeStyle() async {
    final settings = context.read<SettingsState>();
    if (!settings.hasApiKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('API Key is missing. Please check settings.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chordName = '${widget.root}${widget.quality}';

      final aiService = AIService(
        apiKey: settings.currentApiKey,
        provider: settings.aiProvider,
        modelName: settings.geminiModel.id,
        systemPrompt:
            PromptTemplates.getStyleVoicingSystemPrompt(settings.systemPrompt),
      );

      final prompt =
          PromptTemplates.getStyleVoicingUserPrompt(chordName, _selectedStyle);

      String fullResponse = '';
      await for (final chunk in aiService.sendMessageStream(prompt)) {
        fullResponse += chunk;
      }

      final jsonResult = AIService.extractJson(fullResponse);
      if (mounted) {
        setState(() {
          _result = jsonResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Analysis failed: $e';
        if (e.toString().contains('Quota exceeded') ||
            e.toString().contains('429')) {
          msg =
              '⚠️ API 사용량이 초과되었습니다.\n잠시 후(약 1분) 다시 시도해주세요.\n(Free Tier Limit)';
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls - Stacked vertically for narrow 2-column layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStyle,
                  isDense: true,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: _styles.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStyle = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _analyzeStyle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Analyze AI'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Content
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: QuotaErrorWidget(
              errorMessage: _errorMessage!,
              onRetry: _analyzeStyle,
            ),
          )
        else if (_result != null)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoicingsSection(),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildSongsSection(),
                ],
              ),
            ),
          )
        else if (!_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Select a style and click Analyze\nto see voicings & context.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoicingsSection() {
    final voicings = _result!['voicings'] as List<dynamic>? ?? [];
    if (voicings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Voicings',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: voicings.map((v) {
            return Container(
              width: 140, // Fixed width card
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['name'] ?? 'Voicing',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      v['tab'] ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v['desc'] ?? '',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSongsSection() {
    final songs = _result!['songs'] as List<dynamic>? ?? [];
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In Context (Famous Songs)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...songs.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.music_note, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: s['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            TextSpan(
                                text: ' by ${s['artist'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text(s['desc'] ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
