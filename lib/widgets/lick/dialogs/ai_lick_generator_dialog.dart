import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/lick/artist_lick_model.dart';
import '../../../models/gemini_model.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/lick_vault_state.dart';
import '../../../providers/studio_state.dart';
import '../../../services/ai_lick_generator_service.dart';
import '../../../services/lick_audio_player.dart';
import '../../common/dialogs/app_dialog_frame.dart';

/// Gemini 3.8 Flash 연동 "자연어 즉석 릭 생성기" 대화형 모달 다이얼로그
class AILickGeneratorDialog extends StatefulWidget {
  final String? initialKey;
  final String? initialTargetChord;

  const AILickGeneratorDialog({
    super.key,
    this.initialKey,
    this.initialTargetChord,
  });

  static void show(
    BuildContext context, {
    String? initialKey,
    String? initialTargetChord,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AILickGeneratorDialog(
        initialKey: initialKey,
        initialTargetChord: initialTargetChord,
      ),
    );
  }

  @override
  State<AILickGeneratorDialog> createState() => _AILickGeneratorDialogState();
}

class _AILickGeneratorDialogState extends State<AILickGeneratorDialog> {
  final TextEditingController _promptController = TextEditingController();
  final LickAudioPlayer _player = LickAudioPlayer();

  late String _currentKey;
  late String _targetChord;
  String _selectedStyle = 'Blues & Rock';

  bool _isGenerating = false;
  String? _errorMessage;
  String _streamingChunk = '';

  ArtistLick? _generatedLick;
  bool _isPlaying = false;
  int _activeNoteIndex = -1;

  // 추천 즉석 프롬프트 프리셋
  static const List<({String label, String prompt, String chord, String style})>
      _recommendationChips = [
    (
      label: '🎸 헨드릭스 블루스 더블스탑',
      prompt: '지미 헨드릭스 스타일의 펜타토닉 박스 1번 중심 소울풀한 더블스탑과 해머링-온 필인',
      chord: 'E7',
      style: 'Jimi Hendrix Blues',
    ),
    (
      label: '✨ 존 메이어 네오소울',
      prompt: '존 메이어 특유의 세련된 트라이어드 슬라이드와 코드 멜로디 장식음 릭',
      chord: 'Gmaj7',
      style: 'Neo-Soul & Acoustic Groove',
    ),
    (
      label: '⚡ 길모어 서스테인 벤딩',
      prompt: '데이비드 길모어 스타일의 깊은 1번줄 풀 벤딩과 긴 비브라토 서스테인 솔로 릭',
      chord: 'Bm',
      style: 'Pink Floyd Progressive Rock',
    ),
    (
      label: '🚀 에디 밴 헤일런 양손 태핑',
      prompt: '에디 밴 헤일런 스타일의 화려하고 경쾌한 양손 태핑(Right-hand Tap) 아르페지오 릭',
      chord: 'A5',
      style: 'Hard Rock & Shred',
    ),
    (
      label: '🎻 잉베이 하모닉 스윕',
      prompt: '잉베이 맘스틴 스타일의 디미니쉬드 7th 스윕 피킹 및 네오클래시컬 하모닉 마이너 런',
      chord: 'B7',
      style: 'Neoclassical Metal',
    ),
    (
      label: '🎷 조 패스 비밥 2-5-1',
      prompt: '조 패스 스타일의 재즈 II-V-I 진행 위에서 부드럽게 크로매틱 어프로치로 감싸는 비밥 라인',
      chord: 'Dm7',
      style: 'Jazz & Bebop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentKey = widget.initialKey ?? 'G Major';
    _targetChord = widget.initialTargetChord ?? 'G';
  }

  @override
  void dispose() {
    _promptController.dispose();
    _player.stop();
    super.dispose();
  }

  void _applyRecommendation(
      ({String label, String prompt, String chord, String style}) chip) {
    setState(() {
      _promptController.text = chip.prompt;
      _targetChord = chip.chord;
      _selectedStyle = chip.style;
      _errorMessage = null;
    });
  }

  Future<void> _generateLick() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage = '원하는 릭의 스타일이나 느낌을 입력해주세요.';
      });
      return;
    }

    final settings = context.read<SettingsState>();
    if (!settings.hasApiKey) {
      setState(() {
        _errorMessage =
            'API 키가 등록되어 있지 않습니다. 상단 [설정] 메뉴에서 ${settings.aiProviderType.label} API 키를 등록해주세요.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _streamingChunk = '';
      _generatedLick = null;
      _isPlaying = false;
      _activeNoteIndex = -1;
    });
    _player.stop();

    try {
      final lick = await AILickGeneratorService.generateLick(
        settings: settings,
        prompt: prompt,
        currentKey: _currentKey,
        targetChord: _targetChord,
        artistStyle: _selectedStyle,
        onStreamChunk: (chunk) {
          if (mounted) {
            setState(() {
              _streamingChunk += chunk;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _generatedLick = lick;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '릭 생성 실패: $e';
          _isGenerating = false;
        });
      }
    }
  }

  void _togglePlay() async {
    if (_generatedLick == null) return;

    if (_isPlaying) {
      _player.stop();
      setState(() {
        _isPlaying = false;
        _activeNoteIndex = -1;
      });
    } else {
      final vault = context.read<LickVaultState>();
      setState(() {
        _isPlaying = true;
        _activeNoteIndex = 0;
      });

      await _player.playLick(
        _generatedLick!,
        soundProfileId: vault.selectedGuitarSound.id,
        onNoteStep: (index) {
          if (mounted) {
            setState(() {
              _activeNoteIndex = index;
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _activeNoteIndex = -1;
            });
          }
        },
      );
    }
  }

  void _copyJsonToClipboard() {
    if (_generatedLick == null) return;
    final jsonStr = AILickGeneratorService.formatLickAsJson(_generatedLick!);
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '릭 JSON이 클립보드에 복사되었습니다! assets/data/licks/ 파일에 바로 추가할 수 있습니다.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _addToVaultAndSelect() {
    if (_generatedLick == null) return;
    final vault = context.read<LickVaultState>();
    vault.addCustomLick(_generatedLick!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_added, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              '\'${_generatedLick!.title}\'이(가) 보관함 최상단에 등록되었습니다.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  void _insertChordToStudio() {
    if (_generatedLick == null) return;
    final studio = context.read<StudioState>();
    studio.addProgressionFromText(_generatedLick!.targetChord);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '타임라인에 ${_generatedLick!.targetChord} 코드가 추가되었습니다.',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsState>();

    return AppDialogFrame(
      title: '자연어 즉석 릭 생성기',
      subtitle: '대화형 AI(Gemini 3.8 Flash)로 나만의 시그니처 기타 솔로 릭을 즉석 작곡합니다',
      width: 740,
      height: 780,
      headerLeading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. AI 모델 및 컨텍스트 바
            _buildContextStatusBar(context, settings),
            const SizedBox(height: 14),

            // 2. 추천 퀵 칩 모음
            const Text(
              '추천 즉석 프리셋 (클릭 시 자동 설정):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _recommendationChips.map((chip) {
                final isSelected = _promptController.text == chip.prompt;
                return ActionChip(
                  label: Text(chip.label, style: const TextStyle(fontSize: 11)),
                  backgroundColor: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _applyRecommendation(chip),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 3. 사용자 프롬프트 입력창
            TextField(
              controller: _promptController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    '원하는 릭 느낌을 자유롭게 적어보세요 (예: 5번줄 루트 락 발라드 솔로, 2번줄 풀 벤딩으로 끝나는 애절한 릭)',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _promptController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. 생성 실행 버튼 & 에러 메시지
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateLick,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.psychology, size: 18),
                    label: Text(
                      _isGenerating ? 'Gemini가 릭을 작곡하는 중...' : '즉석 릭 생성하기',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            // 5. 생성 결과 영역
            if (_generatedLick != null)
              _buildGeneratedLickCard(context, _generatedLick!)
            else if (_isGenerating)
              _buildGeneratingProgressCard(context)
            else
              _buildEmptyPlaceholder(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContextStatusBar(BuildContext context, SettingsState settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final modelBadge = settings.currentModelId == GeminiModel.flash38.id
        ? 'Gemini 3.8 Flash (최신)'
        : settings.currentModelId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_outlined, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Key: $_currentKey',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            'Target: $_targetChord',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  modelBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.music_note,
              size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          const Text(
            '원하는 스타일을 선택하거나 입력한 뒤 [즉석 릭 생성하기]를 눌러보세요.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '생성된 릭은 즉시 오디오로 들어보고 지판 TAB 확인, 보관함 등록 및 JSON 복사가 가능합니다.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingProgressCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Gemini 3.8 Flash 연산 중...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _streamingChunk.isEmpty
                ? '기타 물리적 연주성(Playability), CAGED 박스 운지 및 화성학적 코드톤 해결음을 분석 중입니다.'
                : '수신된 데이터 파싱 중...',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedLickCard(BuildContext context, ArtistLick lick) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더: 릭 타이틀, 아티스트/장르 정보 및 메타 뱃지
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lick.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lick.artist} · ${lick.genre} (${lick.difficulty})',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: _togglePlay,
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                tooltip: _isPlaying ? '정지' : '미리듣기',
                style: IconButton.styleFrom(
                  backgroundColor: _isPlaying ? Colors.redAccent : colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. CAGED Form, Box, Target Chord 뱃지 행
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildBadge('Box ${lick.pentatonicBox} (${lick.cagedForm})',
                  colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
              _buildBadge('Target: ${lick.targetChord}', colorScheme.tertiaryContainer,
                  colorScheme.onTertiaryContainer),
              _buildBadge(lick.scaleUsed, colorScheme.surfaceContainerHighest,
                  colorScheme.onSurfaceVariant),
              ...lick.tags.take(3).map((tag) => _buildBadge(
                  tag, colorScheme.surface, colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 14),

          // 3. 미니 기타 TAB 및 음표 시퀀스 뷰
          _buildMiniTabStaff(context, lick),
          const SizedBox(height: 12),

          // 4. 화성학적 팁 및 설명
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: Colors.amberAccent[200]),
                    const SizedBox(width: 4),
                    const Text(
                      '화성학적 분석 & 연주 팁',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lick.theoryTips,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (lick.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    lick.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. 액션 버튼 모음 (보관함 추가, JSON 복사, 타임라인 추가)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _addToVaultAndSelect,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('보관함에 즉시 추가', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _copyJsonToClipboard,
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('JSON 복사', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _insertChordToStudio,
                icon: const Icon(Icons.queue_music, size: 18),
                tooltip: '스튜디오 타임라인에 코드 추가',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTabStaff(BuildContext context, ArtistLick lick) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAB Preview (${lick.notes.length} notes):',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: lick.notes.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                final isPlayingNote = _activeNoteIndex == index;

                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPlayingNote
                        ? colorScheme.primary
                        : (note.isTargetNote
                            ? Colors.amber.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPlayingNote
                          ? colorScheme.primary
                          : (note.isTargetNote
                              ? Colors.amber
                              : colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${note.string}줄 ${note.fret}F',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPlayingNote
                              ? colorScheme.onPrimary
                              : (note.isTargetNote
                                  ? Colors.amberAccent
                                  : colorScheme.onSurface),
                        ),
                      ),
                      Text(
                        '${note.noteName} (${note.interval})',
                        style: TextStyle(
                          fontSize: 8,
                          color: isPlayingNote
                              ? colorScheme.onPrimary.withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (note.technique != NoteTechnique.none)
                        Text(
                          note.technique.symbol,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isPlayingNote
                                ? colorScheme.onPrimary
                                : Colors.cyanAccent,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
