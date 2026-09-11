import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/progression/progression_models.dart';
import '../../../providers/settings_state.dart';
import '../../../services/ai_service.dart';
import '../../../services/prompt_templates.dart';
import '../../../utils/theory_utils.dart';
import 'famous_songs/famous_song_item.dart';
import 'famous_songs/famous_songs_ai_search_view.dart';
import 'famous_songs/famous_songs_detail_info_panel.dart';

class FamousSongsPanel extends StatefulWidget {
  final ProgressionSession session;

  const FamousSongsPanel({
    super.key,
    required this.session,
  });

  @override
  State<FamousSongsPanel> createState() => _FamousSongsPanelState();
}

class _FamousSongsPanelState extends State<FamousSongsPanel> {
  String? _selectedGenre;

  @override
  void didUpdateWidget(covariant FamousSongsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldProgression =
        oldWidget.session.progression.map((e) => e.chordSymbol).join('-');
    final newProgression =
        widget.session.progression.map((e) => e.chordSymbol).join('-');

    if (oldProgression != newProgression) {
      setState(() {
        _aiGeneratedSongs = null;
        _isGenerating = false;
        _aiErrorMessage = null;
        _selectedGenre = null;
        _showAiIfAvailable = true;
      });
    }
  }

  // AI State
  bool _isGenerating = false;
  Map<String, List<String>>? _aiGeneratedSongs;
  String? _aiErrorMessage;
  bool _showAiIfAvailable = true;

  // Folding State
  bool _isExpanded = true;

  Future<void> _fetchFamousSongsFromAI(BuildContext context) async {
    final settings = context.read<SettingsState>();
    final apiKey = settings.currentApiKey;
    final provider = settings.aiProvider;

    if (apiKey.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _aiErrorMessage = null;
    });

    try {
      final progressionText =
          widget.session.progression.map((b) => b.chordSymbol).join('-');

      final systemPrompt =
          PromptTemplates.getFamousSongsSystemPrompt(settings.systemPrompt);
      final userPrompt =
          PromptTemplates.getFamousSongsUserPrompt(progressionText);

      final aiService = AIService(
        apiKey: apiKey,
        provider: provider,
        modelName: settings.currentModelId,
        systemPrompt: systemPrompt,
        thinkingLevel: settings.thinkingLevel,
        customBaseUrl: settings.customBaseUrl,
      );

      final stream = aiService.sendMessageStream(userPrompt);
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
      }

      String responseText = buffer.toString().trim();
      final Map<String, dynamic> jsonResult =
          AIService.extractJson(responseText);

      final Map<String, List<String>> songs = {};
      jsonResult.forEach((genre, list) {
        if (list is List) {
          songs[genre] = list.map((e) => e.toString()).toList();
        }
      });

      setState(() {
        _aiGeneratedSongs = songs;
        if (songs.isNotEmpty) {
          if (_selectedGenre == null || !songs.containsKey(_selectedGenre)) {
            _selectedGenre = songs.keys.first;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiErrorMessage = e.toString();
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
    // 0. AI 결과가 있거나 생성 중이면 AI 패널 우선 표시
    if (_showAiIfAvailable &&
        (_isGenerating ||
            (_aiGeneratedSongs != null && _aiGeneratedSongs!.isNotEmpty) ||
            _aiErrorMessage != null)) {
      return _buildAiView(context);
    }

    // 1. 매칭되는 프리셋 찾기
    final matchedPreset =
        TheoryUtils.matchProgressionToPreset(widget.session.progression);

    // 2. 프리셋이 없거나 유명곡 데이터가 없으면 "AI로 찾기" 패널 표시
    if (matchedPreset == null || matchedPreset.famousSongs.isEmpty) {
      return _buildAiView(context);
    }

    // 3. 장르 데이터 준비
    final genres = matchedPreset.famousSongs.keys.toList();
    if (_selectedGenre == null || !genres.contains(_selectedGenre)) {
      _selectedGenre = genres.first;
    }

    final currentSongs =
        (matchedPreset.famousSongs[_selectedGenre] ?? []).take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.queue_music,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '이 코드 진행이 쓰인 유명 곡 (Famous Songs)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (context.watch<SettingsState>().currentApiKey.isNotEmpty &&
                  widget.session.progression.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_aiGeneratedSongs != null &&
                            _aiGeneratedSongs!.isNotEmpty) {
                          setState(() => _showAiIfAvailable = true);
                        } else {
                          _fetchFamousSongsFromAI(context);
                        }
                      },
                      icon: Icon(
                        (_aiGeneratedSongs != null &&
                                _aiGeneratedSongs!.isNotEmpty)
                            ? Icons.visibility
                            : Icons.auto_awesome,
                        size: 14,
                      ),
                      label: Text(
                        (_aiGeneratedSongs != null &&
                                _aiGeneratedSongs!.isNotEmpty)
                            ? 'AI 결과 보기'
                            : 'AI로 더 찾아보기',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                tooltip: _isExpanded ? '접기' : '펴기',
                visualDensity: VisualDensity.compact,
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGenre,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    items: genres.map((String genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Row(
                          children: [
                            Icon(
                              Icons.library_music,
                              size: 14,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(genre),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedGenre = newValue;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 850;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: currentSongs
                                    .map((songTitle) =>
                                        FamousSongItem(songTitle: songTitle))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              FamousSongsDetailInfoPanel(
                                matchedPreset: matchedPreset,
                                session: widget.session,
                                isMobile: true,
                              ),
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: currentSongs
                                      .map((songTitle) => FamousSongItem(
                                          songTitle: songTitle))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 24),
                              FamousSongsDetailInfoPanel(
                                matchedPreset: matchedPreset,
                                session: widget.session,
                                isMobile: false,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiView(BuildContext context) {
    return FamousSongsAiSearchView(
      session: widget.session,
      aiGeneratedSongs: _aiGeneratedSongs,
      isGenerating: _isGenerating,
      aiErrorMessage: _aiErrorMessage,
      selectedGenre: _selectedGenre,
      isExpanded: _isExpanded,
      hasMatchedPreset:
          TheoryUtils.matchProgressionToPreset(widget.session.progression) !=
              null,
      onGenreSelected: (genre) => setState(() => _selectedGenre = genre),
      onToggleExpanded: () => setState(() => _isExpanded = !_isExpanded),
      onBackToDb: () => setState(() => _showAiIfAvailable = false),
      onFetchFromAi: () => _fetchFamousSongsFromAI(context),
    );
  }
}
