# AI 기반 기능 확장을 위한 작업 절차 (AI_적용_작업절차.md)

이 문서는 사용자의 요청에 따라 다음 3가지 AI 기반 기능을 **Studio** 탭에 통합 구현하기 위한 절차를 기술합니다.

1.  **AI 코드 진행 편곡 (Progression Variator)**: 현재 진행을 다양한 스타일로 변형.
2.  **AI 화성학 분석 (Theory Insight)**: 코드의 화성학적 기능 및 연결 설명.
3.  **AI 솔로잉 가이드 (Soloing Guide)**: 코드별 추천 스케일 제공.

---

## ✅ 전제 조건 (Prerequisites)

이 문서에서 정의하는 모든 AI 기능은 다음 조건이 충족될 때만 사용할 수 있습니다.

1.  **API Key 설정 필수**: 
    *   사용자 설정(`SettingsState`)에 유효한 API 키(Gemini 또는 OpenAI)가 저장되어 있어야 합니다.
    *   키가 없는 경우, AI와 관련된 모든 UI(버튼 등)는 **비활성화**되거나 **숨김 처리**되어야 합니다.
2.  **조건부 동작 수행**: 
    *   생성되는 모든 기능은 API 키가 존재하는지 확인(`hasApiKey`) 후 실행됩니다.
    *   사용자가 기능을 요청하더라도 키가 없다면 적절한 안내 메시지(SnackBar 또는 Dialog)를 표시하고 API 호출을 차단해야 합니다.

---

## 📅 작업 단계 요약

| 단계 | 작업 내용 | 비고 |
| :--- | :--- | :--- |
| **Step 0** | **AI Service 확장** | 공통 프롬프트 관리 및 JSON 파싱 구조 강화 |
| **Step 1** | **변형(Variator) 기능 구현** | 스타일 선택 UI 및 코드 교체 로직 |
| **Step 2** | **분석(Insight) 기능 구현** | 화성학적 해석 텍스트 표시 패널 |
| **Step 3** | **솔로잉(Soloing) 기능 구현** | 코드별 추천 스케일 매핑 및 UI 시각화 |
| **Step 4** | **전조(Modulation) 네비게이터** | 5도권: 타겟 키로의 자연스러운 전조 경로 생성 |
| **Step 5** | **스타일 보이싱(Voicing) 및 분석** | 코드분석: 장르별 보이싱 및 실전 사용 예제 검색 |
| **Step 6** | **AI 곡 진행 검색 (Song Searcher)** | 타이틀/가수로 특정 곡의 코드 진행 분석 및 채우기 |

---

## 🚀 상세 작업 절차

### Step 0: AI Service 및 모델 강화

가장 먼저 다양한 형태의 AI 요청을 처리할 수 있도록 `AIService`와 데이터 모델을 정비합니다.

1.  **Prompt Manager 도입**:
    *   기능별 시스템 프롬프트를 전담 관리하는 정적 클래스 또는 메서드 생성.
    *   `PromptTemplates.variator`, `PromptTemplates.insight` 등.
2.  **Robust JSON Parser**:
    *   AI 응답에서 JSON만 정확히 추출하는 유틸리티 함수(Markdown 코드 블록 제거 등)를 공통화하여 `AIService`에 내장.

### Step 1: AI 코드 진행 편곡 (Progression Variator)

사용자가 입력한 단순한 코드를 세련된 진행으로 바꿔주는 기능입니다.

1.  **UI 구성**:
    *   `StudioView` 상단(또는 Quick Add 옆)에 `✨ AI 편곡` 버튼 추가.
    *   클릭 시 **스타일 선택 팝업** (`AIArrangeDialog`) 표시.
        *   옵션 예: *Jazz Re-harm*, *Neo-Soul*, *Pop Ballad*, *Cinematic*.
    *   *전제 조건*: API 키가 없으면 버튼 숨김 또는 '키 설정 필요' 툴팁 표시.
2.  **Logic 구현**:
    *   현재 타임라인의 코드 리스트를 문자열로 변환하여 프롬프트에 포함.
    *   **Prompt**: "다음 코드 진행을 [스타일] 느낌으로 편곡해줘. 각 코드의 길이(duration)는 유지하거나 합리적으로 나눠줘."
    *   **Response Format**:
        ```json
        [
          {"chord": "CMaj9", "duration": 4.0, "comment": "Tension 9 added for richness"},
          {"chord": "A7b13", "duration": 4.0, "comment": "Secondary Dominant with tension"}
        ]
        ```
    *   `ProgressionModel`과의 호환성 검증 (duration parsing).
3.  **State 적용**:
    *   사용자가 변형된 결과를 미리보기(Preview) 할 수 있도록 임시 상태에 저장.
    *   "적용하기" 클릭 시 `MusicState`/`SettingsState`를 통해 `ProgressionSession` 업데이트.

### Step 2: AI 화성학 분석 리포트 (Theory Insight)

현재 코드 진행이 "왜 좋은지" 알려주는 교육적 기능입니다.

1.  **UI 구성**:
    *   `FamousSongsPanel` 아래 또는 `Studio` 좌측 패널에 `AnalysisPanel` 추가.
    *   "🔍 심층 분석(Deep Dive)" 버튼 제공.
    *   분석 결과는 채팅 형태가 아닌, 잘 정돈된 **리포트 카드** 형태로 표시.
    *   *전제 조건*: API 키가 없으면 패널 자체를 숨기거나 'AI 분석 사용 불가' 표시.
2.  **Logic 구현**:
    *   **Prompt**: "각 코드의 기능(Function)과 진행의 특징(Feature)을 분석해줘. Key Center, Secondary Dominant, Modal Interchange 등을 식별해."
    *   **Response Format**:
        ```json
        {
          "estimated_key": "C Major",
          "analysis": [
            {"chord": "Dm7", "function": "ii", "description": "Sub-dominant role, setting up the V chord."},
            {"chord": "G7", "function": "V", "description": "Dominant chord resolving to C."}
          ],
          "summary": "전형적인 Two-Five-One 진행에 텐션을 가미한 스타일입니다."
        }
        ```

### Step 3: AI 솔로잉 가이드 (Soloing Guide)

각 코드 위에서 연주하면 좋은 스케일을 추천합니다.

1.  **UI 구성**:
    *   `StudioTimeline`의 각 코드 블록 표시 영역 확장.
    *   코드 텍스트 하단에 작은 칩(Chip) 형태로 추천 스케일 표시 (예: *G Mixolydian*, *C Ionian*).
    *   칩 클릭 시 해당 스케일 정보(구성음)를 툴팁이나 `ChordDetailDialog`로 표시.
    *   *전제 조건*: API 키가 없으면 스케일 추천 칩 기능을 비활성화.
2.  **Logic 구현**:
    *   **Prompt**: "이 진행의 각 코드 구간에서 솔로 연주하기 좋은 스케일을 1순위, 2순위로 추천해줘."
    *   **Response Format**:
        ```json
        [
          {"chord_index": 0, "scales": ["C Ionian", "C Lydian"]},
          {"chord_index": 1, "scales": ["A Altered", "A Phrygian Dominant"]}
        ]
        ```
    *   결과 매핑: 타임라인의 각 `ProgressionModel` 인덱스와 AI 응답을 매칭하여 UI 갱신.

### Step 4: AI 전조 네비게이터 (Modulation Navigator)

5도권 탐색기의 핵심인 '조(Key)의 관계'를 확장하여, 두 조 사이를 연결하는 전조 과정을 제안합니다.

1.  **UI 구성**:
    *   `CircleOfFifthsWheel`에서 현재 선택되지 않은 다른 키를 **길게 누르기(Long Press)** 또는 **우클릭** 시 컨텍스트 메뉴 표시.
    *   메뉴 옵션: `🔀 AI 전조 경로 생성 (Modulate Here)`.
    *   결과는 다이얼로그나 하단 패널에 "Start Key -> Pivot Chords -> Target Key" 흐름으로 시각화.
    *   옵션: *재생 버튼*을 통해 전조 과정을 들어볼 수 있도록 함.
2.  **Logic 구현**:
    *   **Prompt**: "[Start Key]에서 [Target Key]로 자연스럽게 전조하는 4~8마디 코드 진행을 만들어줘. Pivot Chord를 명시해."
    *   **Response Format**:
        ```json
        {
          "from": "C Major",
          "to": "E Major",
          "progression": [
            {"chord": "Cmaj7", "function": "I (Original)"},
            {"chord": "Bm7b5", "function": "ii/III (Pivot)"},
            {"chord": "E7alt", "function": "V/III"},
            {"chord": "Emaj7", "function": "I (Target)"}
          ],
          "explanation": "3도 상행 전조를 위해 평행단조의 2-5-1을 활용했습니다."
        }
        ```

### Step 5: AI 스타일 보이싱 및 실전 분석 (Generator Tab)

이론적 코드 분석을 넘어, 실제 연주와 곡에서의 쓰임새를 알려줍니다.

1.  **UI 구성**:
    *   `ExtendedAnalysisSection`에 새로운 탭 `🎸 Style & Context` 추가.
    *   **스타일 선택**: 드롭다운 (Neo-Soul, Funk, Rock, Jazz Ballad).
    *   **결과 표시**:
        *   선택한 스타일의 추천 보이싱 (TAB 형식 텍스트).
        *   해당 코드가 사용된 유명 곡 리스트 및 설명.
2.  **Logic 구현**:
    *   **Prompt**: `[Chord]` 코드를 `[Style]` 스타일로 연주할 때의 기타 보이싱(TAB)과, 이 코드가 중요하게 쓰인 유명 곡 예시를 알려줘.
    *   **Response Format**:
        ```json
        {
          "voicings": [
            {"name": "Shell Voicing", "tab": "x-3-2-4-x-x", "desc": "Clean sound suitable for rapid changes"}
          ],
          "songs": [
            {"title": "Just the Two of Us", "artist": "Grover Washington Jr.", "desc": "Uses this chord as a passing diminished..."}
          ]
        }
        ```

### Step 6: AI 곡 진행 검색 (AI Song Searcher)

사용자가 입력한 곡 제목과 가수를 기반으로 해당 곡의 코드 진행을 분석하여 가져오는 기능입니다.

1.  **UI 구성**:
    *   `StudioView`의 코드 진행 입력 영역(또는 Quick Add 옆)에 `🔍 AI 곡 검색` 버튼 추가.
    *   클릭 시 **곡 정보 입력 다이얼로그** (`AISongSearchDialog`) 표시.
    *   사용자 입력 필드: `곡 제목`, `가수(선택)`.
    *   섹션 선택 옵션: `전체(Full)`, `후렴구(Chorus)`, `인트로(Intro)`.
2.  **Logic 구현**:
    *   **Prompt**: "[곡 제목] - [가수]의 [섹션] 부분 코드 진행을 분석해줘. 결과는 반드시 마디(Bar) 단위의 duration을 포함해야 해."
    *   **Response Format**:
        ```json
        {
          "title": "Song Title",
          "artist": "Artist Name",
          "key": "G Major",
          "progression": [
            {"chord": "Gmaj7", "duration": 4, "description": "1st degree tonic"},
            {"chord": "Em7", "duration": 4, "description": "6th degree minor"}
          ],
          "comment": "이 곡은 전형적인 VI-II-V-I 진행을 사용합니다."
        }
        ```
    *   **AI의 지식 컷오프(Knowledge Cutoff)**: 최신곡이나 비주류 곡의 경우 환각 현상(Hallucination)이 발생할 수 있음을 UI에 명시.
3.  **Preview & Apply**:
    *   가져온 결과를 즉시 타임라인에 반영하지 않고, 다이얼로그 내에서 리스트 형태로 **미리보기** 제공.
    *   사용자가 "타임라인에 채우기" 클릭 시 `StudioState.setProgression()`을 통해 반영.

---

## ⚠️ 제약 사항 및 고려사항 (Constraints)

1.  **API Cost & Latency**:
    *   모든 기능은 **On-demand(사용자 클릭 시)** 로만 동작해야 함. 타임라인 변경 시마다 자동 호출 금지.
2.  **Error Handling**:
    *   AI가 `Hmaj7` 같은 존재하지 않는 코드를 반환하거나 파싱 실패 시, "분석 불가" 또는 원본 코드 유지.
    *   응답 대기 중에는 적절한 로딩 인디케이터(`CircularProgressIndicator`) 표시 필수.
3.  **Context Preservation**:
    *   이전 대화 맥락(History)을 유지할 필요 없음. 매 요청마다 **현재의 전체 코드 진행 문자열**을 새롭게 전송하여 독립적인(Stateless) 결과를 받는 것이 정확도에 유리.
