import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/prompt_templates.dart';
import '../../../providers/settings_state.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart';
import '../../../../utils/guitar_utils.dart';
import '../../../../utils/theory_utils.dart';
import '../../../../models/chord_model.dart';
import '../../../../widgets/common/guitar/guitar_chord_widget.dart';

class ModulationDialog extends StatefulWidget {
  final String startKey;
  final String targetKey;

  const ModulationDialog({
    super.key,
    required this.startKey,
    required this.targetKey,
  });

  @override
  State<ModulationDialog> createState() => _ModulationDialogState();
}

class _ModulationDialogState extends State<ModulationDialog> {
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;
  String _formFilter = 'Auto'; // 'Auto', 'C', 'A', 'G', 'E', 'D', 'All'

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    final settings = context.read<SettingsState>();
    if (!settings.hasApiKey) {
      setState(() {
        _errorMessage = 'API Key is missing. Please check settings.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final aiService = AIService(
        apiKey: settings.currentApiKey,
        provider: settings.aiProvider,
        modelName: settings.geminiModel.id,
        systemPrompt:
            PromptTemplates.getModulationSystemPrompt(settings.systemPrompt),
      );

      final prompt = PromptTemplates.getModulationUserPrompt(
          widget.startKey, widget.targetKey);

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
        String msg = 'Failed to generate modulation: $e';
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.shuffle, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          const Text('Modulation Navigator'),
        ],
      ),
      content: SizedBox(
        width: 1050, // Wider for CAGED row
        height: 750, // Increased to remove inner scrolling
        child: _buildContent(),
      ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: _startGeneration,
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing harmonic pathways...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return QuotaErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _startGeneration,
      );
    }

    if (_result == null) {
      return const Center(child: Text('No result received.'));
    }

    // Parse result
    final progression = _result!['progression'] as List<dynamic>? ?? [];
    final explanation = _result!['explanation'] as String? ?? '';
    final fromKey = _result!['from'] ?? widget.startKey;
    final toKey = _result!['to'] ?? widget.targetKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Path
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(fromKey,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 20)),
              Text(toKey,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Progression List
        Expanded(
          flex: 5,
          child: ListView.builder(
            itemCount: progression.length,
            itemBuilder: (context, index) {
              final item = progression[index];
              final chord = item['chord'] ?? '';
              final function = item['function'] ?? '';
              final duration = item['duration'] ?? 4;
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                margin: const EdgeInsets.only(bottom: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note,
                          size: 14, color: Colors.purpleAccent),
                      const SizedBox(width: 12),
                      // Chord Name
                      SizedBox(
                        width: 80,
                        child: Text(
                          chord,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Function & Info
                      Expanded(
                        child: Text(function,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ),
                      // Duration badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3)),
                        ),
                        child: Text('${duration} beats',
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Explanation
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 150), // 조금 더 여유있게 조정
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.05), // 부드러운 배경색
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AI Harmonic Insight',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation.replaceAll('. ', '.\n\n'), // 단락 구분 강화
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Progression Diagram Flow
        Row(
          children: [
            Text(
              'Progression Harmony Flow:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildFormFilter(context),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 4,
          child: _buildProgressionDiagramsPanel(progression),
        ),
      ],
    );
  }

  Widget _buildFormFilter(BuildContext context) {
    final forms = ['Auto', 'C', 'A', 'G', 'E', 'D'];
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: forms.map((f) {
          final isSelected = _formFilter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(f, style: const TextStyle(fontSize: 10)),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _formFilter = f);
              },
              side: BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressionDiagramsPanel(List<dynamic> progression) {
    if (progression.isEmpty) return const SizedBox.shrink();

    // 첫 번째 코드의 위치를 기준으로 삼기 위해 첫 번째 코드의 최적 보이싱 fret을 찾음
    int referenceFret = 0;
    try {
      final firstChord = progression[0]['chord'] ?? '';
      final chordObj = TheoryUtils.analyzeChord(firstChord);
      final voicings =
          GuitarUtils.generateCAGEDVoicings(chordObj.root, chordObj.quality);
      if (voicings.isNotEmpty) {
        if (_formFilter == 'Auto') {
          // Auto일 때는 가장 낮은 포지션을 기준으로 함
          voicings.sort((a, b) => _getMinFret(a).compareTo(_getMinFret(b)));
          referenceFret = _getMinFret(voicings.first);
        } else {
          // 특정 폼이 선택된 경우, 첫 번째 코드에서 해당 폼을 찾아 기준 프렛으로 삼음
          try {
            final matching = voicings
                .firstWhere((v) => v.name?.startsWith(_formFilter) ?? false);
            referenceFret = _getMinFret(matching);
          } catch (_) {
            // 해당 폼이 없는 예외 케이스는 가장 낮은 포지션 기준
            voicings.sort((a, b) => _getMinFret(a).compareTo(_getMinFret(b)));
            referenceFret = _getMinFret(voicings.first);
          }
        }
      }
    } catch (_) {}

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: progression.length,
      separatorBuilder: (context, index) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          Icons.arrow_forward_rounded,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          size: 28,
        ),
      ),
      itemBuilder: (context, index) {
        final item = progression[index];
        final chordName = item['chord'] ?? '';
        final function = item['function'] ?? '';

        final toKey = _result!['to'] as String? ?? widget.targetKey;
        final isTargetTonic = chordName.startsWith(toKey.split(' ')[0]) &&
            (index == progression.length - 1);

        // 필터링된 보이싱 리스트 준비
        List<ChordVoicing> displayVoicings = [];
        try {
          final chordObj = TheoryUtils.analyzeChord(chordName);
          final allVoicings = GuitarUtils.generateCAGEDVoicings(
              chordObj.root, chordObj.quality);

          if (index == 0 && _formFilter != 'Auto') {
            // 첫 번째 코드는 사용자가 선택한 필터 폼을 우선 적용
            try {
              final matching = allVoicings.firstWhere(
                (v) => v.name?.startsWith(_formFilter) ?? false,
              );
              displayVoicings = [matching];
            } catch (_) {
              // 해당 폼이 없으면 기준 프렛과 가장 가까운 것
              allVoicings.sort((a, b) {
                final diffA = (_getMinFret(a) - referenceFret).abs();
                final diffB = (_getMinFret(b) - referenceFret).abs();
                return diffA.compareTo(diffB);
              });
              displayVoicings = [allVoicings.first];
            }
          } else {
            // 두 번째 코드부터(또는 Auto일 때)는 무조건 첫 번째 코드 위치와 가장 가까운 포지션 선택
            allVoicings.sort((a, b) {
              final diffA = (_getMinFret(a) - referenceFret).abs();
              final diffB = (_getMinFret(b) - referenceFret).abs();
              return diffA.compareTo(diffB);
            });
            displayVoicings = [allVoicings.first];
          }
        } catch (_) {}

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chord Info Header
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTargetTonic
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isTargetTonic
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    chordName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTargetTonic
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (function.isNotEmpty)
                    Text(
                      function.length > 15
                          ? function.substring(0, 12) + '...'
                          : function,
                      style: TextStyle(
                        fontSize: 8,
                        color: isTargetTonic
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (displayVoicings.isNotEmpty) ...[
              if (_formFilter != 'Auto')
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    displayVoicings.first.name ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GuitarChordWidget(
                  voicing: displayVoicings.first,
                  width: 150,
                  height: 120,
                ),
              ),
            ] else
              const SizedBox(
                width: 150,
                height: 120,
                child: Center(child: Icon(Icons.music_off, color: Colors.grey)),
              ),
          ],
        );
      },
    );
  }

  int _getMinFret(ChordVoicing v) {
    final frets = v.frets.where((f) => f > 0).toList();
    return frets.isEmpty
        ? 0
        : frets.reduce((min, val) => val < min ? val : min);
  }
}
