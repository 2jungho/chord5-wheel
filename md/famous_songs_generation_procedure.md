# 유명곡 리스트 AI 생성 기능 작업 절차

## 1. 개요
현재 '코드 진행' 탭의 `FamousSongsPanel`은 하드코딩된 프리셋(`progression_presets.dart`)과 일치하는 경우에만 유명곡 리스트를 보여줍니다.
이를 확장하여, 프리셋에 없는 코드 진행이더라도 AI(Gemini/OpenAI)를 통해 해당 진행이 쓰인 유명곡을 검색/생성하여 보여주는 기능을 구현합니다.

## 2. 사전 조건 및 제약 사항
- **API Key**: 사용자가 설정 탭에서 Gemini 또는 OpenAI API 키를 입력하여 활성화된 상태여야 합니다.
- **UI Visibility**: 기존에는 매칭되는 프리셋이 없으면 패널 자체가 숨겨졌으나(`SizedBox.shrink`), 이제는 "AI로 찾기" 버튼을 제공하기 위해 패널이 항상 보이거나, 적어도 버튼을 위한 영역이 확보되어야 합니다.
- **비용/속도**: AI 호출은 비동기로 이루어지며, 로딩 상태 표시가 필요합니다.

## 3. 작업 단계

### 1단계: FamousSongsPanel UI 구조 변경
- **목표**: 프리셋 매칭 실패 시에도 패널(또는 최소한의 UI)을 표시하도록 변경.
- **수정 파일**: `lib/views/studio/widgets/famous_songs_panel.dart`
- **내용**:
    - `build` 메서드 초입의 `matchedPreset == null` 체크 로직 수정.
    - 매칭된 프리셋이 없을 경우, 빈 상태(Empty State) 대신 "이 코드 진행으로 유명곡 찾기 (AI)" 버튼을 포함한 안내 문구 표시.
    - `SettingsState`를 `Provider`로 접근하여 API Key 유무 확인 -> 버튼 활성화/비활성화 처리.

### 2단계: AI 요청 및 상태 관리 로직 구현
- **목표**: "AI로 찾기" 버튼 클릭 시 `AIService`를 사용하여 유명곡 리스트 요청.
- **수정 파일**: `lib/views/studio/widgets/famous_songs_panel.dart`
- **내용**:
    - `State` 클래스 내에 AI 생성 결과를 담을 변수(`Map<String, List<String>>? _aiGeneratedSongs`)와 로딩 상태 변수(`_isGenerating`) 추가.
    - `_fetchFamousSongsFromAI` 메서드 구현:
        1. 현재 세션의 코드 진행(`widget.session.progression`)을 텍스트로 변환.
        2. `AIService` 인스턴스 생성 (API Key는 `SettingsState`에서 가져옴).
        3. 프롬프트 작성: "다음 코드 진행이 사용된 유명한 곡들을 장르별로 3~5곡 추천해줘. JSON 형식으로 반환해. { 'Genre': ['Title - Artist'] } ..."
        4. 응답 파싱 및 상태 업데이트.

### 3단계: 결과 표시 UI 구현
- **목표**: AI 응답 결과를 기존 프리셋 결과와 동일한 UI 형식으로 렌더링.
- **수정 파일**: `lib/views/studio/widgets/famous_songs_panel.dart`
- **내용**:
    - 기존 `_buildSongList` 등을 재사용하여 AI 결과 표시.
    - AI 결과인 경우, 우측 상세 정보 패널(`_buildDetailedInfoPanel`)의 내용을 "AI가 생성한 추천 목록입니다" 등으로 대체하거나 숨김 처리.

### 4단계: 테스트 및 검증
- **테스트 케이스**:
    1. **프리셋 매칭 케이스**: 기존 Money Chord 등 입력 시 프리셋 데이터가 우선 표시되는지 확인. (또는 AI 재생성 버튼 제공 여부 결정)
    2. **매칭 실패 케이스**: 프리셋에 없는 진행 입력 시 "AI로 찾기" 버튼 표시 확인.
    3. **AI 요청**: 버튼 클릭 시 로딩 인디케이터 표시, 완료 후 리스트 표시 확인.
    4. **권한 없음**: API Key가 없을 때 버튼이 비활성화되거나 안내 메시지 표시 확인.

## 4. 프롬프트 설계 (예시)
```text
System: 당신은 음악 전문가입니다.
User: 다음 코드 진행을 사용하는 유명한 대중음악(Pop, Jazz, K-Pop 등)을 찾아주세요.
코드 진행: [C, G, Am, F]
응답은 반드시 다음 JSON 포맷만 출력하세요. 설명은 필요 없습니다.
{
  "Pop": ["Let It Be - The Beatles", "No Woman No Cry - Bob Marley"],
  "K-Pop": ["벚꽃 엔딩 - 버스커 버스커"]
}
```

## 5. 예상 쟁점
- **환각(Hallucination)**: AI가 실제로 해당 코드 진행을 쓰지 않는 곡을 추천할 수 있음. (사용자에게 AI 결과임을 인지시켜야 함)
- **JSON 파싱**: AI 응답이 완벽한 JSON이 아닐 경우에 대한 예외 처리 필요.
