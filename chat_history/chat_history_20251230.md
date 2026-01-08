# 2025-12-30 작업 요약

## 주요 작업 내용
1. **AI 모델 및 설정 중앙화**
   - `SettingsState`가 Gemini 모델(flash/pro) 설정의 단일 소스가 되도록 수정.
   - 각 패널(AI Chat, Famous Songs, Insight 등)에서 개별 드롭다운 제거 및 `SettingsState` 값 참조하도록 변경.

2. **StudioTimeline UI 개선**
   - 헤더 영역 오버플로우 문제 해결 (`Flexible`, `SizedBox` 조정).
   - CAGED Selector를 헤더에서 분리하여 타임라인 그리드 상단 툴바(Voicing Shape)로 이동.
   - 키 변경 시 5도권(Circle of Fifths)과의 동기화 로직 추가.

3. **Fretboard 반응형 개선**
   - `FretboardSection`의 최소 너비 제한을 완화하여(850 -> 600) 화면 너비에 맞춰 줄어들도록 수정.

4. **기획 및 취소된 작업**
   - **Spotlight Focus UI**: 선택된 CAGED 폼만 밝게 표시하고 나머지는 Dim 처리하는 기능.
   - 구현 계획 수립 단계에서 작업 취소 요청으로 중단.

## 변경된 파일 목록
- `lib/views/studio/widgets/studio_timeline.dart`
- `lib/widgets/common/fretboard/fretboard_section.dart`
- `lib/views/studio/widgets/famous_songs_panel.dart`
- `lib/widgets/ai_chat/ai_chat_panel.dart`

## 특이사항
- "Spotlight Focus" 기능은 추후 재진행 가능하도록 `md/작업절차.md`에 계획이 작성되어 있음.
