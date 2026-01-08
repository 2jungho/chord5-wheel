import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_state.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart';

class AISongSearchDialog extends StatefulWidget {
  final Function(List<ChordBlock> blocks, String key, String title) onApply;

  const AISongSearchDialog({
    super.key,
    required this.onApply,
  });

  @override
  State<AISongSearchDialog> createState() => _AISongSearchDialogState();
}

class _AISongSearchDialogState extends State<AISongSearchDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  String _selectedSection = '후렴(Chorus)';

  final List<String> _sections = [
    '인트로(Intro)',
    '브릿지(Bridge)',
    '후렴(Chorus)',
    '전체(Full)',
  ];

  bool _isSearching = false;
  String? _errorMessage;
  Map<String, dynamic>?
      _searchResult; // title, artist, key, progression, comment

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _searchSong() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = '곡 제목을 입력해주세요.');
      return;
    }

    final settings = context.read<SettingsState>();
    final apiKey = settings.currentApiKey;
    if (apiKey.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final systemPrompt =
          PromptTemplates.getSongSearchSystemPrompt(settings.systemPrompt);
      final userPrompt = PromptTemplates.getSongSearchUserPrompt(
          title, _artistController.text.trim(), _selectedSection);

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
      final result = AIService.extractJson(responseText);

      if (result['progression'] == null) {
        throw Exception('곡의 코드 진행을 찾을 수 없습니다.');
      }

      setState(() {
        _searchResult = result;
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
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsState>();
    final hasApiKey = settings.currentApiKey.isNotEmpty;

    if (!hasApiKey) {
      return AlertDialog(
        title: const Text('API 키 필요'),
        content: const Text('곡 검색 기능을 사용하려면 설정에서 AI API 키를 등록해주세요.'),
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
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('AI 곡 진행 검색'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searchResult == null) ...[
                const Text('곡 제목과 가수명을 입력하면 AI가 코드 진행을 분석합니다.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '곡 제목 (필수)',
                    hintText: '예: Let It Be, Dynamite',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: '가수명 (선택)',
                    hintText: '예: Beatles, BTS',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: '요청 구간',
                    border: OutlineInputBorder(),
                  ),
                  items: _sections
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSection = val!),
                ),
                const SizedBox(height: 8),
                Text(
                  '⚠️ 최신곡이나 비주류 곡은 분석 결과가 부정확할 수 있습니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ] else ...[
                // Search Result Preview
                _buildSearchResultPreview(),
              ],
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('곡의 화성을 분석 중입니다...'),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                QuotaErrorWidget.isQuotaErrorDetected(_errorMessage!)
                    ? QuotaErrorWidget(
                        errorMessage: _errorMessage!, onRetry: _searchSong)
                    : Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        if (_searchResult == null && !_isSearching)
          FilledButton.icon(
            onPressed: _searchSong,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('분석하기'),
          ),
        if (_searchResult != null) ...[
          TextButton(
            onPressed: () => setState(() => _searchResult = null),
            child: const Text('다시 검색'),
          ),
          FilledButton(
            onPressed: _applyResult,
            child: const Text('타임라인에 채우기'),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultPreview() {
    final title = _searchResult!['title'] ?? 'Unknown';
    final artist = _searchResult!['artist'] ?? 'Unknown';
    final key = _searchResult!['key'] ?? 'Unknown Key';
    final comment = _searchResult!['comment'] ?? '';
    final progression = _searchResult!['progression'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title - $artist',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Original Key: $key',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('분석된 코드 진행:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: progression.length,
            separatorBuilder: (_, __) =>
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            itemBuilder: (context, index) {
              final item = progression[index];
              final chord = item['chord'] ?? '';
              final dur = item['duration'] ?? 4;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(chord,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${dur}박자',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('해설:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ],
    );
  }

  void _applyResult() {
    final progression = _searchResult!['progression'] as List<dynamic>? ?? [];
    final key = _searchResult!['key'] ?? '';

    final List<ChordBlock> blocks = [];
    for (var item in progression) {
      if (item is Map) {
        final chord = item['chord'] ?? 'C';
        final durationRaw = item['duration'] ?? 4;
        final int duration = (durationRaw is num) ? durationRaw.toInt() : 4;
        blocks.add(ChordBlock(chordSymbol: chord, duration: duration));
      }
    }

    if (blocks.isNotEmpty) {
      final songTitle = _searchResult!['title'] ?? 'Unknown';
      final artist = _searchResult!['artist'] ?? 'Unknown';
      widget.onApply(blocks, key, '$songTitle ($artist)');
      Navigator.of(context).pop();
    }
  }
}
