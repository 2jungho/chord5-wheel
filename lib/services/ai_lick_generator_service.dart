import 'dart:convert';
import '../models/lick/artist_lick_model.dart';
import '../providers/settings_state.dart';
import 'ai_service.dart';
import 'prompt_templates.dart';

/// Gemini 및 멀티 AI 기반 자연어 즉석 기타 릭(Lick) 생성 서비스
class AILickGeneratorService {
  /// 자연어 프롬프트와 화성 컨텍스트(Key, Target Chord)를 바탕으로
  /// 실제 연주 가능한 기타 시그니처 릭(ArtistLick)을 생성합니다.
  static Future<ArtistLick> generateLick({
    required SettingsState settings,
    required String prompt,
    required String currentKey,
    required String targetChord,
    String? artistStyle,
    AIService? customAiService,
    void Function(String chunk)? onStreamChunk,
  }) async {
    final apiKey = settings.currentApiKey;
    if (apiKey.isEmpty && customAiService == null) {
      throw StateError(
          'API 키가 설정되지 않았습니다. 설정 화면에서 API 키를 입력하거나 프로바이더를 확인해주세요.');
    }

    final systemPrompt =
        PromptTemplates.getLickGeneratorSystemPrompt(settings.systemPrompt);
    final userPrompt = PromptTemplates.getLickGeneratorUserPrompt(
      prompt: prompt,
      currentKey: currentKey,
      targetChord: targetChord,
      artistStyle: artistStyle,
    );

    final ai = customAiService ??
        AIService(
          apiKey: apiKey,
          provider: settings.aiProvider,
          modelName: settings.currentModelId,
          systemPrompt: systemPrompt,
          thinkingLevel: settings.thinkingLevel,
          customBaseUrl: settings.customBaseUrl,
        );

    final buffer = StringBuffer();
    await for (final chunk in ai.sendMessageStream(userPrompt)) {
      buffer.write(chunk);
      if (onStreamChunk != null) {
        onStreamChunk(chunk);
      }
    }

    final responseText = buffer.toString();
    if (responseText.trim().isEmpty) {
      throw const FormatException('AI로부터 응답을 수신하지 못했습니다.');
    }

    // JSON 추출 및 파싱
    final rawJson = AIService.extractJson(responseText);
    return sanitizeAndBuildLick(
      rawJson,
      fallbackKey: currentKey,
      fallbackTargetChord: targetChord,
      userPrompt: prompt,
    );
  }

  /// AI가 반환한 JSON 맵을 견고하게 정제하고 ArtistLick 모델로 변환
  static ArtistLick sanitizeAndBuildLick(
    Map<String, dynamic> json, {
    required String fallbackKey,
    required String fallbackTargetChord,
    String? userPrompt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = json['id'] as String? ?? 'ai_lick_$now';
    final artistId = json['artistId'] as String? ?? 'custom_ai';
    final artist = json['artist'] as String? ?? 'AI Guitar Master';
    final genre = json['genre'] as String? ?? 'Blues & Rock';
    final title = json['title'] as String? ??
        (userPrompt != null && userPrompt.isNotEmpty
            ? '$userPrompt 스타일 릭'
            : 'AI 즉석 생성 릭');
    final difficulty = json['difficulty'] as String? ?? 'Intermediate';
    final defaultKey = json['defaultKey'] as String? ?? fallbackKey;
    final targetChord = json['targetChord'] as String? ?? fallbackTargetChord;

    final rawDegrees = json['applicableDegrees'];
    final List<String> applicableDegrees = (rawDegrees is List)
        ? rawDegrees.map((e) => e.toString()).toList()
        : ['I', 'IV', 'V'];

    final scaleUsed = json['scaleUsed'] as String? ?? 'Pentatonic & Blues Scale';
    final cagedForm = json['cagedForm'] as String? ?? 'E Form';
    final pentatonicBox = ((json['pentatonicBox'] as num?)?.toInt() ?? 1).clamp(1, 5);
    final description = json['description'] as String? ??
        'AI가 생성한 $targetChord 타겟 화성학적 시그니처 릭입니다.';
    final theoryTips = json['theoryTips'] as String? ??
        '타겟 코드톤 및 주요 인터벌 연결을 의식하며 연주해보세요.';

    // 태그 정제
    final rawTags = json['tags'];
    final List<String> tags = (rawTags is List)
        ? rawTags.map((e) => e.toString()).toList()
        : [];
    if (!tags.contains('AI Generated')) {
      tags.insert(0, 'AI Generated');
    }

    // 노트 리스트 정제
    final rawNotes = json['notes'];
    if (rawNotes is! List || rawNotes.isEmpty) {
      throw const FormatException('릭에 유효한 음표 데이터(notes)가 포함되어 있지 않습니다.');
    }

    final List<LickNote> notes = [];
    for (final n in rawNotes) {
      if (n is Map<String, dynamic>) {
        notes.add(_sanitizeNote(n));
      } else if (n is Map) {
        notes.add(_sanitizeNote(Map<String, dynamic>.from(n)));
      }
    }

    if (notes.isEmpty) {
      throw const FormatException('음표 데이터 정제 후 유효한 음표가 없습니다.');
    }

    return ArtistLick(
      id: id,
      artistId: artistId,
      artist: artist,
      genre: genre,
      title: title,
      difficulty: difficulty,
      defaultKey: defaultKey,
      targetChord: targetChord,
      applicableDegrees: applicableDegrees,
      scaleUsed: scaleUsed,
      cagedForm: cagedForm,
      pentatonicBox: pentatonicBox,
      description: description,
      theoryTips: theoryTips,
      tags: tags,
      notes: notes,
    );
  }

  static LickNote _sanitizeNote(Map<String, dynamic> map) {
    final string = ((map['string'] as num?)?.toInt() ?? 1).clamp(1, 6);
    final fret = ((map['fret'] as num?)?.toInt() ?? 0).clamp(0, 24);
    final duration = (map['duration'] as num?)?.toDouble() ?? 0.5;
    final interval = (map['interval'] as String?) ?? 'R';
    final noteName = (map['noteName'] as String?) ?? 'C';
    final technique = NoteTechnique.fromString(map['technique'] as String?);
    final isTargetNote = (map['isTargetNote'] as bool?) ?? false;

    return LickNote(
      string: string,
      fret: fret,
      duration: duration,
      interval: interval,
      noteName: noteName,
      technique: technique,
      isTargetNote: isTargetNote,
    );
  }

  /// 릭 데이터를 licks_*.json 형식으로 손쉽게 추가할 수 있도록
  /// 정돈된 들여쓰기의 JSON 문자열로 변환합니다.
  static String formatLickAsJson(ArtistLick lick) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(lick.toJson());
  }
}
