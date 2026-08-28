import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyria_state.dart';
import '../../../providers/studio_state.dart';
import '../../../providers/settings_state.dart';
import '../../../widgets/common/dialogs/settings_dialog.dart';
import '../../../audio/audio_recorder_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/prompt_templates.dart';
import '../../../models/progression/progression_models.dart';
import '../../../models/audio/band_sound_profile.dart';
import '../../../widgets/common/ai/quota_error_widget.dart';


class LyriaJamPanel extends StatefulWidget {
  const LyriaJamPanel({super.key});

  @override
  State<LyriaJamPanel> createState() => _LyriaJamPanelState();
}

class _LyriaJamPanelState extends State<LyriaJamPanel> {
  bool _isRecording = false;
  bool _hasRecorded = false;

  // AI Mood Prompt State
  final TextEditingController _promptController = TextEditingController();
  bool _isGeneratingJam = false;
  String? _aiJamPromptError;
  String? _aiJamTitle;
  String? _aiJamExplanation;

  final List<({String label, String prompt, IconData icon})> _moodPresets = const [
    (
      label: '🌧️ 비 오는 로파이',
      prompt: '비 오는 날 새벽 창밖을 보며 연주하는 감성적인 칠 로파이 비트',
      icon: Icons.water_drop_outlined,
    ),
    (
      label: '🌆 시티팝 드라이브',
      prompt: '80년대 레트로 시티팝 느낌의 세련되고 경쾌한 드라이브 그루브',
      icon: Icons.location_city_outlined,
    ),
    (
      label: '🎸 슬로우 블루스',
      prompt: '존 메이어 스타일의 따뜻하고 그루비한 슬로우 템포 블루스 잼',
      icon: Icons.electric_bolt_outlined,
    ),
    (
      label: '☕ 감성 어쿠스틱',
      prompt: '따뜻한 통기타와 부드러운 건반이 어우러진 잔잔한 카페 발라드',
      icon: Icons.coffee_outlined,
    ),
    (
      label: '✨ 네오소울 그루브',
      prompt: '세련된 텐션 코드와 펑키한 드럼 스윙이 돋보이는 네오소울 잼',
      icon: Icons.auto_awesome,
    ),
    (
      label: '⚡ 80s 펑키 록',
      prompt: '강렬한 베이스 리프와 직선적인 드럼 비트의 신나는 펑크 록',
      icon: Icons.flash_on,
    ),
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateJamFromPrompt(String promptText) async {
    final trimmed = promptText.trim();
    if (trimmed.isEmpty) return;

    final settings = context.read<SettingsState>();
    if (!settings.hasApiKey) {
      showDialog(
        context: context,
        builder: (_) => const SettingsDialog(),
      );
      return;
    }

    final studio = context.read<StudioState>();
    final lyria = context.read<LyriaState>();
    final currentKey = studio.session.key.isNotEmpty ? studio.session.key : 'C Major';

    setState(() {
      _isGeneratingJam = true;
      _aiJamPromptError = null;
      _aiJamTitle = null;
      _aiJamExplanation = null;
    });

    try {
      final systemPrompt = PromptTemplates.getJamPromptSystemPrompt(settings.systemPrompt);
      final userPrompt = PromptTemplates.getJamPromptUserPrompt(trimmed, currentKey);

      final aiService = AIService(
        apiKey: settings.currentApiKey,
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

      final style = result['style'] as String? ?? 'Neo-Soul';
      final tempoRaw = result['tempo'] ?? 100;
      final double tempo = (tempoRaw is num) ? tempoRaw.toDouble() : 100.0;
      final key = result['key'] as String? ?? currentKey;
      final title = result['title'] as String? ?? trimmed;
      final explanation = result['explanation'] as String? ?? '';
      final audioPrompt = result['audio_prompt'] as String?;
      final progressionList = result['progression'] as List<dynamic>? ?? [];

      final List<ChordBlock> blocks = [];
      for (var item in progressionList) {
        if (item is Map) {
          final chord = item['chord'] ?? 'C';
          final durationRaw = item['duration'] ?? 4;
          final int duration = (durationRaw is num) ? durationRaw.toInt() : 4;
          blocks.add(ChordBlock(chordSymbol: chord, duration: duration));
        }
      }

      if (blocks.isEmpty) {
        blocks.add(ChordBlock(chordSymbol: 'C', duration: 4));
        blocks.add(ChordBlock(chordSymbol: 'Am', duration: 4));
        blocks.add(ChordBlock(chordSymbol: 'Dm', duration: 4));
        blocks.add(ChordBlock(chordSymbol: 'G7', duration: 4));
      }

      // Update Studio Progression & Key
      studio.updateKey(key);
      studio.applyTransposedChords(blocks.map((b) => b.chordSymbol).toList());

      // Parse instrument toggles if returned
      Map<String, bool>? instMap;
      if (result['instruments'] is Map) {
        final rawInst = result['instruments'] as Map;
        instMap = {
          'drums': rawInst['drums'] == true,
          'bass': rawInst['bass'] == true,
          'keys': rawInst['keys'] == true,
          'guitar': rawInst['guitar'] == true,
        };
      }

      // Start Jam Session with AI parameters
      lyria.applyAiJamConfig(
        style: style,
        tempo: tempo,
        key: key,
        blocks: blocks,
        instruments: instMap,
        audioPrompt: audioPrompt,
      );

      if (mounted) {
        setState(() {
          _aiJamTitle = '$title ($style • ${tempo.toInt()} BPM)';
          _aiJamExplanation = explanation;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiJamPromptError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingJam = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();
    final studio = context.read<StudioState>();
    final settings = context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> styles = [
      "Neo-Soul",
      "Jazz Funk",
      "Lofi Chill",
      "Rock",
      "Blues",
      "City Pop",
      "Acoustic Ballad",
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lyria.isPlaying
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: lyria.isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: lyria.isPlaying
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Jam Session & Backing Band",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Full 4-Piece Band: Drums • Bass • Keys • Guitar",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lyria.isPlaying
                      ? Colors.green.withValues(alpha: 0.2)
                      : (lyria.isConnecting
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lyria.isPlaying
                            ? Colors.green
                            : (lyria.isConnecting ? Colors.amber : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lyria.isPlaying
                          ? "Playing"
                          : (lyria.isConnecting ? "Connecting" : "Ready"),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: lyria.isPlaying
                            ? Colors.green
                            : (lyria.isConnecting
                                ? Colors.amber.shade800
                                : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Missing API Key Notification
          if (!settings.hasApiKey) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "내장 가상 밴드(드럼/베이스/건반/기타)로 즉시 연주됩니다. (AI 프롬프트 생성은 설정에서 API 키 등록)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("설정 열기", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Controls Bar (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final startButton = FilledButton.icon(
                onPressed: lyria.isConnecting
                    ? null
                    : () {
                        if (lyria.isPlaying) {
                          lyria.stopPlayback();
                          if (_isRecording) {
                            AudioRecorderService.stopRecording();
                            setState(() {
                              _isRecording = false;
                              _hasRecorded = true;
                            });
                          }
                        } else {
                          final session = studio.session;
                          String chords = "Key: ${session.key}\n";
                          if (session.progression.isEmpty) {
                            chords += "Progression: C - Am - F - G";
                          } else {
                            chords +=
                                "Progression: ${session.progression.map((b) => b.chordSymbol).join(" - ")}";
                          }

                          lyria.startJamSession(
                            chordProgression: chords,
                            blocks: session.progression,
                            key: session.key.isNotEmpty ? session.key : 'C Major',
                          );
                        }
                      },
                icon: lyria.isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        lyria.isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                label: Text(
                  lyria.isConnecting
                      ? "연결 중..."
                      : (lyria.isPlaying ? "잼 중지" : "잼 시작"),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: lyria.isPlaying
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              final recordButton = OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (_isRecording) {
                    AudioRecorderService.stopRecording();
                    setState(() {
                      _isRecording = false;
                      _hasRecorded = true;
                    });
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('마이크 녹음이 완료되었습니다. [다운로드] 버튼을 눌러 저장하세요.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    final success = await AudioRecorderService.startRecording();
                    if (!mounted) return;
                    if (success) {
                      setState(() {
                        _isRecording = true;
                      });
                      if (!lyria.isPlaying) {
                        final session = studio.session;
                        String chords = "Key: ${session.key}\n";
                        if (session.progression.isEmpty) {
                          chords += "Progression: C - Am - F - G";
                        } else {
                          chords +=
                              "Progression: ${session.progression.map((b) => b.chordSymbol).join(" - ")}";
                        }
                        lyria.startJamSession(
                          chordProgression: chords,
                          blocks: session.progression,
                          key: session.key.isNotEmpty ? session.key : 'C Major',
                        );
                      }
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('마이크 권한을 확인해주세요.'),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                  size: 15,
                  color: _isRecording ? Colors.red : Colors.redAccent,
                ),
                label: Text(
                  _isRecording ? "녹음 중지" : "REC",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.red : null,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: _isRecording
                        ? Colors.red
                        : Theme.of(context).dividerColor,
                  ),
                ),
              );

              final downloadRecordButton = IconButton(
                tooltip: '녹음된 연주 파일 다운로드 (WAV)',
                onPressed: () {
                  AudioRecorderService.downloadRecording();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('녹음된 오디오가 다운로드되었습니다.')),
                  );
                },
                icon: const Icon(Icons.download, size: 18, color: Colors.green),
                visualDensity: VisualDensity.compact,
              );

              final tempoSlider = Row(
                children: [
                  Text(
                    "Tempo: ${lyria.tempo.toInt()} BPM",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: lyria.tempo,
                        min: 60.0,
                        max: 180.0,
                        divisions: 120,
                        onChanged: (val) => lyria.updateTempo(val),
                      ),
                    ),
                  ),
                ],
              );

              final volumeSlider = Row(
                children: [
                  IconButton(
                    icon: Icon(
                      lyria.isMuted
                          ? Icons.volume_off
                          : (lyria.volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                      size: 16,
                      color: lyria.isMuted ? Colors.grey : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => lyria.toggleMute(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    "Vol: ${(lyria.volume * 100).toInt()}%",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: lyria.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        activeColor: lyria.isMuted
                            ? Colors.grey
                            : Theme.of(context).colorScheme.secondary,
                        onChanged: (val) => lyria.updateVolume(val),
                      ),
                    ),
                  ),
                ],
              );

              final styleDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: styles.contains(lyria.style)
                      ? lyria.style
                      : styles.first,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: styles
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) lyria.updateStyle(val);
                  },
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        startButton,
                        const SizedBox(width: 8),
                        recordButton,
                        if (_hasRecorded) ...[
                          const SizedBox(width: 4),
                          downloadRecordButton,
                        ],
                        const Spacer(),
                        styleDropdown,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: tempoSlider),
                        const SizedBox(width: 12),
                        Expanded(child: volumeSlider),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  startButton,
                  const SizedBox(width: 8),
                  recordButton,
                  if (_hasRecorded) ...[
                    const SizedBox(width: 4),
                    downloadRecordButton,
                  ],
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: tempoSlider),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: volumeSlider),
                  const SizedBox(width: 16),
                  styleDropdown,
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Instrument Mixer & Tone Profile Selectors
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Band Tone:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // 4 Instrument Sound Profile Selectors & Mute Toggles
                _buildInstrumentToneSelector(
                  context: context,
                  category: BandInstrumentCategory.drums,
                  currentProfile: lyria.selectedDrums,
                  isActive: lyria.drumsEnabled,
                  onToggle: () => lyria.toggleInstrument("drums"),
                  onProfileSelected: (p) => lyria.setSoundProfile(BandInstrumentCategory.drums, p),
                ),
                _buildInstrumentToneSelector(
                  context: context,
                  category: BandInstrumentCategory.bass,
                  currentProfile: lyria.selectedBass,
                  isActive: lyria.bassEnabled,
                  onToggle: () => lyria.toggleInstrument("bass"),
                  onProfileSelected: (p) => lyria.setSoundProfile(BandInstrumentCategory.bass, p),
                ),
                _buildInstrumentToneSelector(
                  context: context,
                  category: BandInstrumentCategory.keys,
                  currentProfile: lyria.selectedKeys,
                  isActive: lyria.keysEnabled,
                  onToggle: () => lyria.toggleInstrument("keys"),
                  onProfileSelected: (p) => lyria.setSoundProfile(BandInstrumentCategory.keys, p),
                ),
                _buildInstrumentToneSelector(
                  context: context,
                  category: BandInstrumentCategory.guitar,
                  currentProfile: lyria.selectedGuitar,
                  isActive: lyria.guitarEnabled,
                  onToggle: () => lyria.toggleInstrument("guitar"),
                  onProfileSelected: (p) => lyria.setSoundProfile(BandInstrumentCategory.guitar, p),
                ),

                // Beat Metronome / Pulse Indicator
                if (lyria.isPlaying) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (index) {
                      final isCurrentBeat = lyria.activeBeat == (index + 1);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isCurrentBeat ? 14 : 8,
                        height: isCurrentBeat ? 14 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrentBeat
                              ? (index == 0
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.primary)
                              : Colors.grey.withValues(alpha: 0.3),
                          boxShadow: isCurrentBeat
                              ? [
                                  BoxShadow(
                                    color: (index == 0
                                            ? Colors.redAccent
                                            : Theme.of(context).colorScheme.primary)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),


          const SizedBox(height: 14),

          // --- AI Jam Mood Prompt Section ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "AI 분위기 & 사운드 프롬프트 (Mood Prompt)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (_aiJamTitle != null)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _aiJamTitle = null;
                            _aiJamExplanation = null;
                            _aiJamPromptError = null;
                          });
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.close, size: 14, color: Colors.grey),
                            SizedBox(width: 2),
                            Text("해설 닫기", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Prompt Input Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "원하는 곡 분위기나 스타일을 입력하세요 (예: 비 오는 새벽 로파이, 존 메이어 블루스)",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(Icons.music_note, size: 16),
                          suffixIcon: _promptController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _promptController.clear()),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        onSubmitted: (val) => _generateJamFromPrompt(val),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isGeneratingJam || _promptController.text.trim().isEmpty
                          ? null
                          : () => _generateJamFromPrompt(_promptController.text),
                      icon: _isGeneratingJam
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 15),
                      label: const Text("잼 생성", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Quick Mood Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _moodPresets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: _isGeneratingJam
                              ? null
                              : () {
                                  _promptController.text = preset.prompt;
                                  _generateJamFromPrompt(preset.prompt);
                                },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              preset.label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // AI Generation Loading State
                if (_isGeneratingJam) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "AI가 분위기를 분석하여 맞춤형 잼트랙과 코드 진행을 조율 중입니다...",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Error Message
                if (_aiJamPromptError != null) ...[
                  const SizedBox(height: 10),
                  QuotaErrorWidget.isQuotaErrorDetected(_aiJamPromptError!)
                      ? QuotaErrorWidget(
                          errorMessage: _aiJamPromptError!,
                          onRetry: () => _generateJamFromPrompt(_promptController.text),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _aiJamPromptError!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                ],

                // AI Insight & Explanation Card
                if (_aiJamTitle != null && _aiJamExplanation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.library_music, size: 15, color: Colors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _aiJamTitle!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "타임라인 자동 적용됨",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_aiJamExplanation!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _aiJamExplanation!,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentToneSelector({
    required BuildContext context,
    required BandInstrumentCategory category,
    required SoundProfile currentProfile,
    required bool isActive,
    required VoidCallback onToggle,
    required Function(SoundProfile) onProfileSelected,
  }) {
    final theme = Theme.of(context);
    final profiles = BandSoundProfiles.getProfilesForCategory(category);

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle Mute/Unmute
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentProfile.icon,
                    size: 13,
                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tone Dropdown Selector
          PopupMenuButton<SoundProfile>(
            tooltip: '${category.displayName} 사운드 프로파일 변경',
            padding: EdgeInsets.zero,
            initialValue: currentProfile,
            onSelected: onProfileSelected,
            itemBuilder: (context) => profiles.map((p) {
              final isSel = p.id == currentProfile.id;
              return PopupMenuItem<SoundProfile>(
                value: p,
                child: Row(
                  children: [
                    Icon(p.icon, size: 16, color: isSel ? theme.colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? theme.colorScheme.primary : null,
                            ),
                          ),
                          Text(
                            p.description,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (isSel)
                      Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentProfile.shortName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

