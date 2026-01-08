import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import '../../../models/progression/progression_models.dart';
import '../../../utils/theory_utils.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_state.dart';
import '../../../services/ai_service.dart';
import '../../../services/prompt_templates.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

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

    // 코드 진행이 변경되었는지 확인
    final oldProgression =
        oldWidget.session.progression.map((e) => e.chordSymbol).join('-');
    final newProgression =
        widget.session.progression.map((e) => e.chordSymbol).join('-');

    if (oldProgression != newProgression) {
      // 진행이 바뀌면 AI 결과 초기화
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
          modelName: settings.geminiModel.id,
          systemPrompt: systemPrompt);

      // 스트림 응답 수신 및 누적
      final stream = aiService.sendMessageStream(userPrompt);
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
      }

      String responseText = buffer.toString().trim();

      // AIService의 견고한 JSON 추출 로직 사용 (Markdown 블록 처리 및 에러 상세 제공)
      final Map<String, dynamic> jsonResult =
          AIService.extractJson(responseText);

      // Map<String, List<String>> 형태로 변환
      final Map<String, List<String>> songs = {};
      jsonResult.forEach((genre, list) {
        if (list is List) {
          songs[genre] = list.map((e) => e.toString()).toList();
        }
      });

      setState(() {
        _aiGeneratedSongs = songs;
        if (songs.isNotEmpty) {
          // 기존에 선택된 장르가 새로 받은 결과에도 있다면 유지, 없으면 첫 번째 장르 선택
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

  Future<void> _launchYoutubeSearch(String query) async {
    final urlString =
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    final Uri url = Uri.parse(urlString);

    // 웹 환경(또는 지원하는 플랫폼)에서 팝업 창으로 열기 위한 시도
    // webOnlyWindowName에 window features(크기 등)를 전달하면
    // Flutter Web에서는 window.open의 3번째 인자로 사용될 수 있음.
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName:
          'width=1000,height=600,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes',
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch YouTube')),
        );
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
      return _buildAiSearchPanel(context);
    }

    // 1. 매칭되는 프리셋 찾기
    final matchedPreset =
        TheoryUtils.matchProgressionToPreset(widget.session.progression);

    // 2. 프리셋이 없거나 유명곡 데이터가 없으면 "AI로 찾기" 패널 표시
    if (matchedPreset == null || matchedPreset.famousSongs.isEmpty) {
      return _buildAiSearchPanel(context);
    }

    // 3. 장르 데이터 준비
    final genres = matchedPreset.famousSongs.keys.toList();

    // 현재 선택된 장르가 유효하지 않으면 첫 번째 장르로 초기화
    if (_selectedGenre == null || !genres.contains(_selectedGenre)) {
      _selectedGenre = genres.first;
    }

    final currentSongs =
        (matchedPreset.famousSongs[_selectedGenre] ?? []).take(5).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Genre Dropdown
          Row(
            children: [
              Icon(Icons.queue_music,
                  size: 20, color: Theme.of(context).colorScheme.primary),
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
              // AI Search Button (New)
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
                          size: 14),
                      label: Text(
                          (_aiGeneratedSongs != null &&
                                  _aiGeneratedSongs!.isNotEmpty)
                              ? 'AI 결과 보기'
                              : 'AI로 더 찾아보기',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5)),
                      ),
                    ),
                  ),
                ),
              // Folding Toggle Button
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
              // Genre Dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
                            Icon(Icons.library_music,
                                size: 14,
                                color: Theme.of(context).colorScheme.tertiary),
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
          // Main Content: Songs + Detailed Info
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Mobile Breakpoint: 850px (adjusted to fit content)
                        final isMobile = constraints.maxWidth < 850;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSongList(currentSongs, context),
                              const SizedBox(height: 16),
                              _buildDetailedInfoPanel(
                                  context, matchedPreset, widget.session,
                                  isMobile: true),
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left side: Song List
                              Expanded(
                                child: _buildSongList(currentSongs, context),
                              ),
                              const SizedBox(width: 24),
                              // Right side: Detailed Description
                              _buildDetailedInfoPanel(
                                  context, matchedPreset, widget.session,
                                  isMobile: false),
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

  Widget _buildIconButton(BuildContext context,
      {required String tooltip,
      required IconData icon,
      required VoidCallback onTap,
      required bool isPrimary}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPrimary
                  ? colorScheme.primary // 솔리드 컬러로 변경하여 선명하게
                  : colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent // 테두리 제거
                    : colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? colorScheme.onPrimary // 배경 대비 선명한 아이콘 색상 (보통 흰색)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongList(List<String> songs, BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: songs.map((songTitle) {
        return Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Song Title & Artist
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.music_note_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        String title = songTitle;
                        String artist = '';
                        final separatorIndex = songTitle.lastIndexOf(' - ');
                        if (separatorIndex != -1) {
                          title = songTitle.substring(0, separatorIndex).trim();
                          artist =
                              songTitle.substring(separatorIndex + 3).trim();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: title,
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (artist.isNotEmpty)
                              Tooltip(
                                message: artist,
                                child: Text(
                                  '($artist)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(
                    context,
                    tooltip: '원곡 듣기',
                    icon: Icons.play_circle_fill,
                    onTap: () => _launchYoutubeSearch(songTitle),
                    isPrimary: true,
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    context,
                    tooltip: '배킹 트랙',
                    icon: Icons.graphic_eq,
                    onTap: () =>
                        _launchYoutubeSearch('$songTitle backing track'),
                    isPrimary: false,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedInfoPanel(
      BuildContext context, dynamic matchedPreset, ProgressionSession session,
      {required bool isMobile}) {
    return SelectionArea(
      child: Container(
        width:
            isMobile ? double.infinity : 450, // Removed fixed width for mobile
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Info (Left)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    matchedPreset.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    matchedPreset.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Badges (Right) - Widths matched via IntrinsicWidth & stretch
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session.progression
                            .map((b) => b.chordSymbol)
                            .join('  -  '),
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // Distinct color for Roman Numerals
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        TheoryUtils.parseProgressionText(
                                matchedPreset.progression, 'C Major')
                            .map((b) => b.functionTag ?? b.chordSymbol)
                            .join('   -   '),
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSearchPanel(BuildContext context) {
    // 1. 결과가 있는 경우: 기존 UI와 유사하게 표시
    if (_aiGeneratedSongs != null && _aiGeneratedSongs!.isNotEmpty) {
      // AI 결과가 있으면 해당 데이터로 UI 구성
      // 현재 선택된 장르가 유효하지 않으면 첫 번째 장르로 초기화
      final genres = _aiGeneratedSongs!.keys.toList();
      if (_selectedGenre == null || !genres.contains(_selectedGenre)) {
        _selectedGenre = genres.first;
      }

      final currentSongs =
          (_aiGeneratedSongs![_selectedGenre] ?? []).take(5).toList();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.3), // AI 결과임을 강조하기 위해 테두리 색상 변경
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Responsive Title + Controls
            LayoutBuilder(builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI가 찾은 유명 곡',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAiBadge(context),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        tooltip: _isExpanded ? '접기' : '펴기',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isNarrow) ...[
                        _buildModelSelector(context),
                        const SizedBox(width: 8),
                      ],
                      // Back to DB Results
                      if (TheoryUtils.matchProgressionToPreset(
                              widget.session.progression) !=
                          null)
                        _buildBackToDbButton(context),
                      const Spacer(),
                      _buildGenreDropdown(context, genres),
                      const SizedBox(width: 8),
                      _buildRegenerateButton(context),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Content: Songs + AI Info (Responsive)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_isExpanded
                  ? const SizedBox.shrink()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 850;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSongList(currentSongs, context),
                              const SizedBox(height: 16),
                              _buildAiInfoBox(context),
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: _buildSongList(currentSongs, context)),
                              const SizedBox(width: 24),
                              _buildAiInfoBox(context, isMobile: false),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // AI 안내 문구
            if (_aiErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: QuotaErrorWidget.isQuotaErrorDetected(_aiErrorMessage!)
                    ? QuotaErrorWidget(
                        errorMessage: _aiErrorMessage!,
                        onRetry: () => _fetchFamousSongsFromAI(context),
                      )
                    : Text(_aiErrorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12)),
              ),
          ],
        ),
      );
    }

    final settings = context.watch<SettingsState>();
    final bool hasApiKey = settings.currentApiKey.isNotEmpty;
    final bool hasProgression = widget.session.progression.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.queue_music,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 코드 진행이 쓰인 유명 곡 (Famous Songs)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildModelSelector(context),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          // Content - Compact Horizontal Layout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(builder: (context, promoConstraints) {
              final isPromoNarrow = promoConstraints.maxWidth < 450;
              return Row(
                children: [
                  if (!isPromoNarrow) ...[
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 32,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알려진 프리셋 진행이 아닙니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !hasProgression
                              ? '먼저 코드 진행을 입력해주세요.'
                              : hasApiKey
                                  ? 'AI를 통해 이 진행이 사용된 곡을 찾아볼까?'
                                  : 'AI 기능을 사용하려면 설정에서 API 키를 입력해주세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_aiErrorMessage != null &&
                      QuotaErrorWidget.isQuotaErrorDetected(_aiErrorMessage!))
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: QuotaErrorWidget(
                        errorMessage: _aiErrorMessage!,
                        onRetry: () => _fetchFamousSongsFromAI(context),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: (_isGenerating)
                            ? null
                            : (hasApiKey && hasProgression
                                ? () => _fetchFamousSongsFromAI(context)
                                : null),
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(
                            isPromoNarrow
                                ? (_isGenerating ? '찾는 중...' : 'AI 찾기')
                                : (_isGenerating ? '곡 찾는 중...' : 'AI로 유명곡 찾기'),
                            style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ]
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInfoBox(BuildContext context, {bool isMobile = true}) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI 생성 결과',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '이 목록은 생성형 AI가 추천한 결과로, 실제 곡의 코드 진행과 다를 수 있습니다.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Current Progression Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.session.progression
                  .map((b) => b.chordSymbol)
                  .join('  -  '),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology,
              size: 14, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            settings.geminiModel.label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
    );
  }

  Widget _buildBackToDbButton(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: () => setState(() => _showAiIfAvailable = false),
        icon: const Icon(Icons.storage_rounded, size: 14),
        label: const Text('기본 유명곡 보기', style: TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown(BuildContext context, List<String> genres) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
                  Icon(Icons.library_music,
                      size: 14, color: Theme.of(context).colorScheme.tertiary),
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
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context) {
    return IconButton(
      onPressed: _isGenerating ? null : () => _fetchFamousSongsFromAI(context),
      icon: _isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh, size: 20),
      tooltip: '다시 찾기',
    );
  }
}
