# 작업절차: SettingsDrawer 레이아웃 및 기능 변경

## 1. 개요
사용자 요청(이미지 피드백)에 따라 `SettingsDrawer`의 구성을 변경합니다. 지판 컨트롤을 제거하고, 악기 설정 및 AI 모델 설정을 사이드바에 직접 통합합니다.

## 2. 작업 상세
### 2.1 SettingsDrawer 구조 변경 (`lib/widgets/common/settings_drawer.dart`)
- `StatelessWidget`에서 `StatefulWidget`으로 변경 (API Key 입력 필드 상태 관리용).
- 기존 `FRETBOARD VIEW` 섹션 제거.
- `악기 설정 (Instrument Setting)` 섹션 추가.
- `AI Model Settings` 섹션을 Drawer 내부에 직접 통합 (기존 팝업 방식에서 변경).

### 2.2 UI 연동 및 로직 이식
- `SettingsDialog`에서 사용하던 악기 선택 드롭다운 로직 이식.
- `SettingsDialog`에서 사용하던 Gemini API Key 입력, 수정, 삭제 로직 이식.

## 3. 검증 계획
- 메뉴 아이콘 클릭 시 Drawer에 악기 설정과 AI 설정이 직접 노출되는지 확인.
- 악기 변경 시 실제 앱의 악기가 변경되는지 확인.
- API Key 입력 및 저장이 정상적으로 동작하고, 저장된 상태가 유지되는지 확인.
