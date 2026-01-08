# Gemini AI 튜터 (하이브리드 UI) 구현 작업 절차

모바일에서는 **Floating Overlay**, 데스크톱에서는 **Side Panel** 형태로 동작하는 문맥 기반 AI 튜터를 구현하기 위한 단계별 가이드입니다.

## 1. 사전 준비 (Prerequisites)
*   **패키지 추가**: Gemini API 호출을 위한 `google_generative_ai` 패키지 추가.
    ```bash
    flutter pub add google_generative_ai
    flutter pub add flutter_markdown # AI 응답 렌더링용
    ```
*   **API Key 확인**: `SettingsState`에 저장된 Key가 있는지 확인하는 로직 준비.

## 2. 데이터 모델 및 서비스 구현 (`lib/services/ai_service.dart`)
AI와의 통신을 전담하는 서비스 클래스를 생성합니다.
*   **기능**:
    *   GenerativeModel 초기화 (API Key 사용).
    *   `sendMessage(String userMessage, Map<String, dynamic> contextData)` 메서드 구현.
    *   Context Data(현재 Key, Scale, Form 등)를 시스템 프롬프트로 변환하여 주입.

## 3. UI 위젯 구현 (`lib/widgets/ai_chat/`)
채팅 인터페이스를 담당하는 위젯들을 생성합니다.

### 3-1. 채팅 메시지 버블 (`chat_message_bubble.dart`)
*   사용자(나)와 AI(Gemini)의 메시지를 구분하여 표시.
*   Markdown 렌더링 지원 (코드 블럭, 강조 등).

### 3-2. 채팅 패널 위젯 (`ai_chat_panel.dart`)
*   **구성**:
    *   상단: 헤더 (타이틀, 닫기 버튼-모바일용).
    *   중단: `ListView` (메시지 목록).
    *   하단: `TextField` + 전송 버튼.
*   **로직**:
    *   전송 버튼 클릭 시 `AIService` 호출.
    *   현재 앱 상태(`GeneratorState` 등)를 `Provider`로 읽어와 컨텍스트로 함께 전달.

## 4. 메인 화면 통합 (`lib/screens/home_screen.dart`)
반응형 레이아웃을 적용하여 UI를 배치합니다.

### 4-1. 상태 관리
*   `isAIChatOpen` 상태 변수 추가 (패널 열림/닫힘 제어).

### 4-2. 반응형 빌더 (Desktop)
*   `LayoutBuilder`를 사용하여 화면 너비가 넓을 경우(예: > 900px):
    *   `Row` 위젯 사용.
    *   `[Left: MainBody, Right: AnimatedSize(child: AIChatPanel)]` 구조 적용.
    *   `isAIChatOpen`에 따라 패널 너비 조절.

### 4-3. 플로팅 버튼 및 오버레이 (Mobile)
*   화면 너비가 좁을 경우:
    *   `Scaffold`의 `floatingActionButton`에 'AI Chat' 버튼 추가.
    *   버튼 클릭 시 `showModalBottomSheet` 또는 `Scaffold`의 `endDrawer`를 사용하여 `AIChatPanel` 표시.

## 5. 컨텍스트 연동 로직
AI가 현재 상황을 이해하도록 데이터를 수집합니다.
*   **수집 데이터**:
    *   **Generator Tab**: Root Note, Scale Type, Selected CAGED Form.
    *   **Explorer Tab**: Selected Key, Chord Progression.
*   **프롬프트 엔지니어링**:
    *   "시스템: 당신은 기타 이론 전문가입니다. 현재 사용자는 {Key} 키의 {Scale} 스케일을 보고 있습니다..." 형태로 메시지 앞단에 주입.

## 6. 테스트 및 최적화
*   API Key가 없을 때의 예외 처리 (설정 유도).
*   로딩 상태(Typing Indicator) 표시.
*   스트림 응답(Stream Response) 처리로 타이핑 효과 구현 검토.
