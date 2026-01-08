# 작업절차: Gemini API 설정 진입점 추가

## 1. 개요
현재 Gemini API Key를 입력하는 `SettingsDialog`로 이동하는 버튼이 UI 리팩토링 과정에서 노출되지 않는 문제를 해결합니다. `SettingsDrawer`에 상시 접근 가능한 설정 버튼을 추가합니다.

## 2. 작업 상세
### 2.1 SettingsDrawer 수정 (`lib/widgets/common/settings_drawer.dart`)
- `SettingsDialog`를 임포트합니다.
- 'General' 섹션 하단에 'AI Model Settings' 항목을 추가하여 팝업을 띄울 수 있도록 합니다.

## 3. 검증 계획
- 우측 상단의 메뉴 아이콘 클릭 -> Drawer 열기.
- 'AI Model Settings' 버튼 확인.
- 클릭 시 `SettingsDialog` 팝업이 정상적으로 뜨는지 확인.
- API Key 입력 및 저장 후 상단바에 AI 아이콘이 나타나는지 확인.
