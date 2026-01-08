# 피아노 모드 UI 개선 제안

## 1. 개요
현재 기타 중심으로 설계된 "CAGED System" 및 "코드 다이어그램"을 피아노 악기 선택 시 피아노 특성에 맞는 UI로 자동 전환하기 위한 제안입니다.

## 2. 주요 변경 사항

### A. "CAGED System" 섹션 → "Chord Inversions (코드 전위)" 섹션으로 대체
*   **문제점:** CAGED 시스템은 기타 지판의 운지 패턴이므로 피아노 연주자에게는 의미가 없습니다.
*   **해결방안:** 피아노 모드에서는 이 영역을 **"Chord Inversions (코드 전위)"** 영역으로 변경하여 코드의 다양한 쌓기 방식을 보여줍니다.
*   **UI 구성:**
    *   **탭/아이템:** 기존 `C Form`, `A Form`... 대신 `Root Pos`, `1st Inv`, `2nd Inv`, `3rd Inv` 버튼으로 구성.
    *   **시각화:** 기타 줄 그리드 대신 **미니 피아노 건반**을 표시하고, 해당 전위에서 눌러야 할 건반을 색칠하여 표시.

### B. 코드 다이어그램 (Timeline, Recommended Voicings) 변경
*   **문제점:** 코드 정보를 보여주는 작은 박스들이 여전히 기타 줄(6현 그리드)로 표시됩니다.
*   **해결방안:** `StringCount`에 의존하는 대신, 악기 타입이 피아노일 경우 **건반형 다이어그램 위젯**으로 교체합니다.
    *   작은 직사각형 안에 약 1.5~2옥타브 정도의 건반을 그리고 구성음을 표시합니다.

### C. 프렛보드 맵 (Fretboard Map) 개선
*   **현황:** 이미 하단 패널은 피아노 건반으로 전환되도록 구현되어 있습니다.
*   **추가 개선:** 상단 헤더의 칩 정보(예: "튜닝: EADGBE")가 피아노일 때는 불필요하므로 숨기거나 "Standard Tuning (440Hz)" 등으로 변경합니다.

## 3. 구현 단계 (Action Plan)

1.  **`PianoChordWidget` 제작:**
    *   작은 크기의 피아노 건반 위에 특정 노트들을 표시할 수 있는 경량 위젯 구현. (기존 `PianoKeysWidget`은 풀 사이즈용이므로 별도 제작 또는 옵션 조정)
2.  **`TheoryUtils` 확장:**
    *   코드 구성음의 전위(Inversion)를 계산하는 로직 추가 (`getChordInversions(root, quality)`).
3.  **UI 분기 처리:**
    *   `CagedList` 위젯 내부: `if (instrument == piano) return PianoInversionList();`
    *   `StudioTimeline`, `ChordInfoSection`: `GuitarChordWidget` 대신 `PianoChordWidget` 호출.

---
**의견:** 이 방향으로 진행하면 피아노 사용자에게 훨씬 직관적인 경험을 제공할 수 있습니다. 승인하시면 바로 전용 위젯 구현부터 시작하겠습니다.
