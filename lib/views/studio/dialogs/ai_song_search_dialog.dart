import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_state.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import '../../../../services/youtube_metadata_service.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart';
import '../../../widgets/common/dialogs/app_dialog_frame.dart';

class AISongSearchDialog extends StatefulWidget {
  final Function(List<ChordBlock> progression, String key, String title)
      onApply;

  const AISongSearchDialog({super.key, required this.onApply});

  @override
  State<AISongSearchDialog> createState() => _AISongSearchDialogState();
}

class _AISongSearchDialogState extends State<AISongSearchDialog> {
  int _selectedTab = 0; // 0: YouTube URL, 1: Text Search

  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  YouTubeVideoInfo? _youtubeInfo;
  bool _isFetchingYouTube = false;

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
    _youtubeUrlController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeInfo() async {
    final url = _youtubeUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = '유튜브 영상 링크(URL)를 입력해주세요.');
      return;
    }

    if (!YouTubeMetadataService.isValidYouTubeUrl(url)) {
      setState(() => _errorMessage =
          '올바른 YouTube URL 형식이 아닙니다.\n(예: https://youtu.be/... 또는 https://www.youtube.com/watch?v=...)');
      return;
    }

    setState(() {
      _isFetchingYouTube = true;
      _errorMessage = null;
    });

    try {
      final info = await YouTubeMetadataService.fetchMetadata(url);
      if (mounted) {
        setState(() {
          _youtubeInfo = info;
          if (info.guessedTitle.isNotEmpty) {
            _titleController.text = info.guessedTitle;
          } else {
            _titleController.text = info.title;
          }
          if (info.guessedArtist.isNotEmpty) {
            _artistController.text = info.guessedArtist;
          } else if (info.authorName.isNotEmpty) {
            _artistController.text = info.authorName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '유튜브 정보를 가져오지 못했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingYouTube = false;
        });
      }
    }
  }

  Future<void> _searchSong() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (_selectedTab == 0 && _youtubeInfo == null) {
        setState(() => _errorMessage = '유튜브 URL을 입력 후 먼저 영상을 확인해주세요.');
      } else {
        setState(() => _errorMessage = '곡 제목을 입력해주세요.');
      }
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
        modelName: settings.currentModelId,
        systemPrompt: systemPrompt,
        thinkingLevel: settings.thinkingLevel,
        customBaseUrl: settings.customBaseUrl,
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
      return AppDialogFrame(
        title: 'API 키 필요',
        width: 400,
        height: 220,
        body: const Center(
          child: Text('곡 검색 기능을 사용하려면 설정에서 AI API 키를 등록해주세요.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    return AppDialogFrame(
      title: 'AI 곡 코드 진행 추출 및 검색',
      subtitle: '유튜브 링크 또는 곡명을 기반으로 AI가 코드 진행을 분석합니다.',
      width: 600,
      height: 700,
      headerLeading: Icon(
        _selectedTab == 0 ? Icons.smart_display : Icons.search,
        color: _selectedTab == 0 ? Colors.redAccent : Theme.of(context).colorScheme.primary,
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
            label: const Text('코드 분석하기'),
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchResult == null) ...[
              // Tab Selector
              Center(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.play_circle_filled, color: Colors.redAccent, size: 18),
                      label: Text('유튜브 링크 입력'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.music_note, size: 18),
                      label: Text('곡명 / 가수 검색'),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (val) {
                    setState(() {
                      _selectedTab = val.first;
                      _errorMessage = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedTab == 0) ...[
                // YouTube Mode
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _youtubeUrlController,
                        decoration: InputDecoration(
                          labelText: 'YouTube 동영상 URL',
                          hintText: 'https://youtu.be/... 또는 https://www.youtube.com/watch?v=...',
                          prefixIcon: const Icon(Icons.link, color: Colors.redAccent),
                          suffixIcon: _youtubeUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _youtubeUrlController.clear();
                                    setState(() => _youtubeInfo = null);
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _fetchYouTubeInfo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _isFetchingYouTube ? null : _fetchYouTubeInfo,
                      icon: _isFetchingYouTube
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('영상 확인'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Video Preview Card if loaded
                if (_youtubeInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                _youtubeInfo!.thumbnailUrl,
                                width: 120,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 75,
                                  color: Colors.black26,
                                  child: const Icon(Icons.movie, color: Colors.white54),
                                ),
                              ),
                              const Icon(Icons.play_circle_filled,
                                  color: Colors.redAccent, size: 28),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _youtubeInfo!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _youtubeInfo!.authorName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '감지: ${_titleController.text} (${_artistController.text})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Editable parsed fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '곡 제목 (필수)',
                          hintText: '영상 제목에서 자동 추출',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _artistController,
                        decoration: const InputDecoration(
                          labelText: '가수명 (선택)',
                          hintText: '채널/가수명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Manual Text Search Mode
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '곡 제목 (필수)',
                    hintText: '예: Let It Be, 밤편지, Dynamite',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: '가수명 (선택)',
                    hintText: '예: Beatles, 아이유, BTS',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSection,
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
                '💡 유튜브 링크나 곡명을 입력하면 AI가 원곡의 정식 Key와 코드 진행을 자동으로 분석합니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
          ],
        ),
      ),
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
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (_youtubeInfo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _youtubeInfo!.thumbnailUrl,
                    width: 70,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$title - $artist',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Original Key: $key',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
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
                    Text('$dur박자',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('화성학 해설:',
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
