# Refactoring Plan: AI Service Strategy Pattern

## 1. 개요 (Overview)
* **대상 파일**: `lib/services/ai_service.dart`
* **목표**: `AIService` 내부의 강한 결합(Hard-coded conditions for providers)을 제거하고, **Strategy Pattern**을 도입하여 확장성과 유지보수성을 높입니다.
* **이점**: 새로운 AI 모델(Claude, Mistral 등) 추가 시 기존 코드를 수정하지 않고 새 클래스만 추가하면 됩니다 (OCP 원칙 준수).

## 2. 작업 절차 (Workflow)

### Step 1: 추상 기본 클래스 정의 (Define Interface)
* `AIProvider` 추상 클래스(또는 인터페이스)를 정의합니다.
* 공통 메서드 서명을 정의합니다:
    * `Stream<String> sendMessageStream(String userMessage, String contextStr)`
    * `void clearSession()`

### Step 2: 구체 클래스 구현 (Implement Concrete Classes)
* `lib/services/providers/` 디렉토리를 생성합니다 (선택 사항, 또는 같은 파일 내).
* **`GeminiProvider`**:
    * 기존 `_streamGemini` 로직과 `google_generative_ai` 의존성을 이관합니다.
    * `startChat()` 및 세션 관리 로직을 포함합니다.
* **`OpenAIProvider`**:
    * 기존 `_streamOpenAI` 로직과 `dart_openai` 의존성을 이관합니다.
    * `_openAiHistory` 관리 및 에러 핸들링 로직을 포함합니다.

### Step 3: AIService 리팩토링 (Refactor Context)
* `AIService` 클래스를 수정하여 구체적인 구현 내용을 제거합니다.
* 생성자에서 `apiProvider` 문자열에 따라 적절한 `AIProvider` 구현체를 주입받거나 생성합니다.
* `sendMessageStream` 호출 시 현재 `_provider` 객체에게 위임(Designate)합니다.

## 3. 예상 코드 구조 (Structure)

```dart
// ai_provider.dart
abstract class AIProvider {
  Stream<String> sendMessageStream(String userMessage, String contextStr);
  void clearSession();
}

// gemini_provider.dart
class GeminiProvider implements AIProvider { ... }

// openai_provider.dart
class OpenAIProvider implements AIProvider { ... }

// ai_service.dart (Context)
class AIService {
  late final AIProvider _provider;

  AIService({required String apiKey, required String provider}) {
    if (provider == 'gemini') {
      _provider = GeminiProvider(apiKey);
    } else {
      _provider = OpenAIProvider(apiKey);
    }
  }

  Stream<String> sendMessageStream(...) => _provider.sendMessageStream(...);
}
```

## 4. 검증 (Validation)
* 리팩토링 후 기존 기능(Gemini 채팅, OpenAI 채팅)이 동일하게 동작하는지 테스트합니다.
* 에러 핸들링(429, 401 등)이 유지되는지 확인합니다.
