import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../audio/audio_recorder_service.dart';
import '../../../models/progression/progression_models.dart';
import '../../../providers/lyria_state.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/studio_state.dart';
import '../../../services/ai_service.dart';
import '../../../services/prompt_templates.dart';
import '../../../widgets/common/dialogs/settings_dialog.dart';
import 'jam/jam_band_mixer.dart';
import 'jam/jam_controls_bar.dart';
import 'jam/jam_mood_prompt_card.dart';

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

  static const List<String> _styles = [
    "Neo-Soul",
    "Jazz Funk",
    "Lofi Chill",
    "Rock",
    "Blues",
    "City Pop",
    "Acoustic Ballad",
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

  void _togglePlayback() {
    final lyria = context.read<LyriaState>();
    final studio = context.read<StudioState>();

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
  }

  Future<void> _toggleRecording() async {
    final messenger = ScaffoldMessenger.of(context);
    final lyria = context.read<LyriaState>();
    final studio = context.read<StudioState>();

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
  }

  void _downloadRecording() {
    AudioRecorderService.downloadRecording();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('녹음된 오디오가 다운로드되었습니다.')),
    );
  }

  Widget _buildHeader(BuildContext context, LyriaState lyria) {
    return Row(
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
    );
  }

  Widget _buildApiKeyWarning(BuildContext context) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyria = context.watch<LyriaState>();
    final studio = context.read<StudioState>();
    final settings = context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          _buildHeader(context, lyria),
          const SizedBox(height: 12),
          if (!settings.hasApiKey) ...[
            _buildApiKeyWarning(context),
            const SizedBox(height: 12),
          ],
          JamControlsBar(
            lyria: lyria,
            studio: studio,
            isRecording: _isRecording,
            hasRecorded: _hasRecorded,
            onToggleRecording: _toggleRecording,
            onDownloadRecording: _downloadRecording,
            onTogglePlayback: _togglePlayback,
            styles: _styles,
          ),
          const SizedBox(height: 14),
          JamBandMixer(lyria: lyria),
          const SizedBox(height: 14),
          JamMoodPromptCard(
            promptController: _promptController,
            isGeneratingJam: _isGeneratingJam,
            aiJamTitle: _aiJamTitle,
            aiJamExplanation: _aiJamExplanation,
            aiJamPromptError: _aiJamPromptError,
            onGenerate: _generateJamFromPrompt,
            onClearExplanation: () {
              setState(() {
                _aiJamTitle = null;
                _aiJamExplanation = null;
                _aiJamPromptError = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
