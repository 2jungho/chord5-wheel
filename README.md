# Guitar & Theory Explorer 🎸

**[👉 웹 데모 실행하기 (Live Demo)](https://chord5-wheel.web.app)**

화성학 이론과 기타 연주 정보를 시각적으로 탐험하고, AI의 도움을 받아 음악적 영감을 얻는 멀티 플랫폼 Flutter 애플리케이션입니다. 5도권(Circle of Fifths) 기반의 키 탐색부터, 고도화된 코드 보이싱 알고리즘, 그리고 타임라인 기반의 코드 진행 스튜디오까지 음악인을 위한 통합 환경을 제공합니다.

---

## 📱 지원 플랫폼 (Platforms)

*   **Web** (Primary Target - Firebase Hosting)
*   **Windows Desktop** (Native Support)
*   **Android** (Mobile Optimized)
*   **macOS / Linux** (Experimental)

---

## 🚀 주요 기능 (Key Features)

### 1. 5도권 탐색기 (Circle of Fifths Explorer)
*   **Interactive Wheel**: 5도권 휠을 통해 직관적으로 Root Key를 탐색하고 변경합니다.
*   **Mode & Scale Visualizer**: Ionian, Aeolian 등 7가지 모드와 스케일 구성을 실시간으로 확인합니다.
*   **AI Modulation Navigator**: 현재 키에서 목표 키로 자연스럽게 이동할 수 있는 **Pivot Chord Modulation** 경로를 AI가 추천해줍니다. (Long Press on Wheel)
*   **Diatonic Dashboard**: 선택된 키의 다이아토닉 코드를 한눈에 파악하고 즉석에서 사운드를 들어봅니다.

### 2. 코드 생성기 & 분석기 (Chord Generator)
*   **Advanced Analysis**: `Cmaj13`, `F#m7b5` 등 복잡한 코드 심볼을 인식하여 구성음(Notes)과 인터벌(Intervals)을 분석합니다.
*   **Algorithmic Voicing**: CAGED 시스템 로직을 기반으로 연주 가능한 최적의 기타 보이싱을 자동 생성합니다.
*   **Interactive Fretboard**: 지판 전체에 인터벌 마커를 표시하며, 가이드 톤(3rd, 7th) 강조 및 펜타토닉 컨텍스트 시각화를 지원합니다.

### 3. 멀티 악기 에코시스템 (Multi-Instrument Ecosystem)
*   **Instrument Switching**: Guitar, Bass (4/5현), Ukulele, **Piano** 등 다양한 악기로 전환하여 이론을 학습할 수 있습니다.
*   **Adaptive UI**: 선택한 악기에 맞춰 프렛보드, 코드 다이어그램, 튜닝 정보가 즉시 최적화된 형태로 변경됩니다.
*   **Piano Mode**: 피아노 선택 시 기타 중심의 CAGED 시스템 대신 **Chord Inversion(전위)** 목록과 건반 시각화를 제공합니다.
*   **Web Audio Simulation**: 웹 환경에서는 악기별 사운드(예: Bass 피치 시뮬레이션)를 지원하여 더욱 실감나는 경험을 제공합니다.

### 4. 코드 진행 스튜디오 (Progression Studio)
*   **Timeline Editor**: 드래그 앤 드롭과 간편 입력을 통해 나만의 코드 진행을 설계합니다.
*   **Quick Presets**: "Jazz 2-5-1", "Blues 12-bar" 등 자주 사용되는 코드 진행 프리셋을 제공합니다.
*   **Famous Songs Panel**: 입력한 코드 진행과 연관된 유명 곡을 AI가 검색해주며, **YouTube 팝업 플레이어**를 통해 원곡과 배킹 트랙을 즉시 감상할 수 있습니다.
*   **Rhythm Sequencer**: 다양한 리듬 패턴을 적용하여 실제 반주 느낌의 사운드를 재생합니다.

### 5. AI 음악 비서 (Integrated AI Assistant)
*   **AI Arranger (Reharmonization)**: 기존 진행을 Jazz, Neo-Soul 등 다양한 스타일로 세련되게 편곡합니다.
*   **AI Theory Insight**: 진행의 음악적 의미와 기능(Function)을 심층 분석한 리포트를 생성합니다.
*   **Smart Soloing Guide**: 각 코드마다 어울리는 스케일과 구체적인 연주 팁을 실시간으로 제안합니다.
*   **Multi-Model Support**: Google Gemini 최신 모델(`gemini-3.7-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-pro-preview`, `gemini-2.5-flash`, `gemma-4-31b-it`) 및 OpenAI GPT-4o 지원.

### 6. 하이브리드 오디오 엔진 (Audio Engine)
*   **Native Engine (Windows/Android)**: `flutter_soloud` 기반의 C++ 엔진으로 초저지연 사운드 재생.
*   **Web Engine**: `Tone.js` (Web Audio API)를 브릿지로 연결하여 브라우저 환경에서도 안정적인 사운드 제공(Bass Octave Simulation 포함).
*   **Resource Optimized**: 64개 이상의 기타 샘플링 노트를 사전 로드(Pre-load)하여 반응성을 극대화했습니다.

---

## 🛠 기술 스택 (Tech Stack)
| Category | Technology | Description |
|---|---|---|
| **Framework** | Flutter (Dart) | UI Framework |
| **State Management** | Provider | MVC/MVVM 패턴 기반 상태 관리 |
| **Navigation** | GoRouter | 선언적 라우팅 및 탭 관리 |
| **Audio** | flutter_soloud / Tone.js | 플랫폼별 최적화된 오디오 엔진 |
| **AI (LLM)** | Gemini (3.7 Flash 등) / OpenAI | 생성형 AI 기반 이론 상담 및 음악 생성 |
| **Web Service** | Firebase Hosting | 호스팅 및 배포 관리 (`chord5-wheel`) |
| **UI Rendering** | CustomPainter | 고성능 지판 및 휠 렌더링 |

---

## 📂 프로젝트 구조 (Structure)

```
lib/
├── audio/                 # 플랫폼별 오디오 서비스 (Tone.js Bridge 포함)
├── models/                # 데이터 모델 (Chord, Voicing, Instrument, AI Models)
├── providers/             # 공유 상태 관리 (Settings, Music, Generator, Studio, Chat, Lyria)
├── services/              # 외부 서비스 연동
│   ├── ai_service.dart          # LLM API 통신 및 프롬프트 관리
│   ├── lyria/                   # Google Lyria AI 음악 연동 (Experimental)
│   ├── music_gen/               # Hugging Face 기반 음악 생성
│   └── music_theory_service.dart # 핵심 화성학 로직 처리
├── utils/                 # 화성학 연산, 지판 유틸리티, 앱 테마
├── views/                 # 주요 화면 페이지
│   ├── explorer/                # 5도권 탐색기 대시보드
│   ├── generator/               # 코드 분석 및 보이싱 정보
│   └── studio/                  # 타임라인 기반 코드 진행 작업실
├── widgets/               # 공용 및 도메인별 위젯
│   └── common/
│       ├── ai/                      # AI 관련 공용 위젯 (Chat, Theory)
│       ├── dialogs/                 # 환경 설정 및 팝업
│       ├── fretboard/               # 대화형 프렛보드/건반 맵
│       ├── guitar/                  # 기타 코드 다이어그램
│       ├── piano/                   # 피아노 건반 및 전위 리스트
│       ├── theory/                  # 다이아토닉, CAGED 리스트 등
│       └── wheel/                   # 5도권 휠 UI 컴포넌트
└── main.dart              # 앱 진입점 및 데스크톱 환경 설정
```

---

## 🏗 설치 및 로컬 실행 (Setup & Run)

### 1. 사전 요구사항 (Prerequisites)
* **Flutter SDK**: 3.0.0 이상
* **Node.js & Firebase CLI** (웹 배포 시 필요): `npm install -g firebase-tools`
* **(선택)** Google Gemini API Key 또는 OpenAI API Key

### 2. 의존성 설치
```bash
flutter clean
flutter pub get
```

### 3. 로컬 환경에서 앱 실행 (Development Run)

* **Web (Chrome 브라우저)**:
  ```bash
  flutter run -d chrome
  ```
* **Windows 데스크톱 앱**:
  ```bash
  flutter run -d windows
  ```

---

## 🚀 빌드 및 배포 가이드 (Build & Deployment)

### 1. Firebase Hosting 웹 배포 (Web Target)

현재 프로젝트는 Firebase 프로젝트(`chord5-wheel`)에 연동되어 있습니다.

#### Step 1: Firebase 로그인 (최초 1회)
```bash
firebase login
```

#### Step 2: Flutter Web 릴리즈 빌드
* **표준 릴리즈 빌드 (JavaScript)**:
  ```bash
  flutter build web --release
  ```
* **고성능 WebAssembly(WASM) 빌드 (추천)**:
  ```bash
  flutter build web --wasm --release
  ```
  > WASM 지원 브라우저(Chrome, Edge, Firefox 최신 버전)에서 2배 이상의 렌더링 및 연산 성능을 제공하며, 미지원 브라우저에서는 JS로 자동 폴백됩니다.
  > 빌드 산출물은 `build/web` 폴더에 생성됩니다.

#### Step 3: 로컬 호스팅 미리보기 (선택 사항)
실제 배포 전 로컬 서버에서 배포본을 검증할 수 있습니다.
```bash
firebase serve --only hosting
# 또는
firebase emulators:start --only hosting
```

#### Step 4: Firebase Hosting 배포
```bash
firebase deploy --only hosting
```
* 배포 완료 후 **[https://chord5-wheel.web.app](https://chord5-wheel.web.app)** 에서 즉시 서비스를 이용할 수 있습니다.

---

### 2. Windows 데스크톱 빌드 (Native Target)

1. **Windows 릴리즈 바이너리 빌드**
   ```bash
   flutter build windows --release
   ```
   > 빌드 산출물 위치: `build/windows/x64/runner/Release/`

2. **설치 프로그램(Installer) 패키징**
   * 프로젝트 루트의 `5-Chord-Wheel.iss` 스크립트를 [Inno Setup Compiler](https://jrsoftware.org/isinfo.php)로 컴파일하여 Windows 설치 파일(`Output/Setup.exe`)을 제작할 수 있습니다.

---

## 📝 변경 이력 (Changelog)

### v1.9.2 (2026-08-27 - Gemini 3.7 & Modern API Upgrade)
*   **Gemini 3.7 Upgrade**: 최신 플래그십 모델 `gemini-3.7-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-pro-preview` 및 `gemma-4-31b-it` 지원 추가.
*   **Legacy Auto-Fallback**: 기존에 저장된 구버전 모델 식별자를 최신 대응 모델로 자동 전환.
*   **Documentation Polish**: Firebase Hosting 및 Windows 데스크톱 빌드/배포 가이드 추가.

### v1.9.1 (2025-12-31 - Layout Stability & UI Refinement)
*   **Crash Fixes**: GeneratorView의 레이아웃 충돌(`!_debugDoingThisLayout`) 및 렌더링 오버플로우 문제를 근본적으로 해결하여 앱 안정성 확보.
*   **Compact Fretboard**: 프렛보드 맵 영역의 높이를 20% 축소(270px)하여 모든 디바이스에서 화면 공간 효율성 극대화.
*   **Zero-Scroll Controls**: 뷰 컨트롤 패널(ViewControlPanel)의 레이아웃을 재설계(간격 축소 및 가로 배치)하여 별도의 스크롤 없이 모든 옵션을 즉시 조작 가능하도록 개선.
*   **Mobile Responsiveness**: 모바일 환경에서 프렛보드 섹션의 오버플로우를 방지하기 위한 스크롤 뷰 최적화 적용.
*   **Fixed Fretboard Width**: 모바일 환경에서 프렛보드의 가로 스크롤 영역을 850px로 고정하여 시인성 확보.
*   **Refined Spacing**: 프렛보드 프렛 간격을 약 20% 확장하여(0.72 scale factor) 데스크톱 환경에서의 답답함 해소 및 시각적 안정감 개선.
*   **Control Panel Integration**: 코드 진행 탭(StudioView) 프렛보드 영역에 'View Controls' 기능을 통합하여 CAGED 폼 선택 및 인터벌 필터링 지원.
*   **UI Cleanup**: 중복된 Key Scale 버튼을 제거하고 ViewControlPanel 내의 인터벌 버튼 간격을 재정렬(b3, b5, b7 중앙 정렬)하여 직관성 향상.
*   **Expanded Voicing Library**: `Sus4`, `Sus2`, `Aug`, `Dim7`, `6th` 등 다양한 코드 퀄리티에 대한 CAGED 보이싱 패턴 알고리즘을 추가하여 표현 범위 대폭 확대.

### v1.9.0 (2025-12-30 - UX & Layout Optimization)
*   **Web 1080p Optimized**: 1920x1080 해상도에서 페이지 스크롤 없이 모든 기능을 사용할 수 있도록 전체 레이아웃을 고정형(Fixed)으로 최적화.
*   **Unified Analysis Surface**: 코드 분석 탭의 스크롤 영역을 단일화하여 여러 개의 스크롤바가 생기는 문제를 해결하고 시각적 통합감 강화.
*   **2-Column Theory Board**: 확장 분석(Extended Analysis) 영역을 2단 그리드 형태로 개편하여 조성, 텐션, 대리 코드, 스타일 분석 정보를 한눈에 파악하도록 개선.
*   **Compact View Controls**: 프렛보드 컨트롤 패널의 크기를 줄이고 불필요한 'All' 버튼을 제거하여 스크롤 없이 즉시 조작 가능한 제로 스크롤 UI 구현.

### v1.8.0 (2025-12-30 - Focus & AI Simplification)
*   **Fretboard Spotlight**: 선택한 CAGED 폼 영역만 밝게 표시하고, 해당 위치로 지판이 자동 스크롤되는 집중 모드(Spotlight Focus) 구현.
*   **Gemini Exclusive**: AI 모델 설정을 Google Gemini로 단일화하여 UI/UX 및 안정성 강화.
*   **Chord Diagram Smart Order**: Modulation Navigator에서 코드 다이어그램 배열 시, 첫 코드의 위치를 기준으로 연주 편의성을 고려한 최적의 폼을 추천하도록 개선.

### v1.7.0 (2025-12-29 - Gemini Stability & Chat UX)
*   **Gemma 3 27B Ready**: Google의 최신 경량 모델 `Gemma 3 27B` 지원 추가 및 SDK 포맷 호환성 문제 해결.
*   **Chat Reliability**:
    *   **Data Safety**: 스트림 에러 발생 시 기존 답변 유지 및 에러 메시지 별도 표기 로직 적용.
    *   **Auto-Scroll Fix**: 사용자가 답변을 보고 있을 때(Stick-to-bottom)만 스크롤이 자동으로 따라가도록 UX 개선.
    *   **Rendering Stability**: 동적 리스트에서의 `SelectionArea` 충돌로 인한 텍스트 소실 현상을 해결하고, `SelectableText` 기반으로 안정화.

---
**Developer/Maintainer**: Lee Jungho (2jungho@gmail.com)
