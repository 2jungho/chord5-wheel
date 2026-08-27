# Guitar & Theory Explorer 🎸

[![GitHub Repository](https://img.shields.io/badge/GitHub-2jungho%2Fchord5--wheel-181717?style=flat-square&logo=github)](https://github.com/2jungho/chord5-wheel)
[![Live Demo](https://img.shields.io/badge/Live_Demo-chord5--wheel.web.app-4285F4?style=flat-square&logo=googlechrome&logoColor=white)](https://chord5-wheel.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Gemini-3.7_Flash-8E75B2?style=flat-square&logo=google)](https://deepmind.google/technologies/gemini/)

**[👉 웹 데모 실행하기 (Live Demo)](https://chord5-wheel.web.app)** | **[📦 GitHub 저장소 바로가기](https://github.com/2jungho/chord5-wheel)**

화성학 이론과 기타 연주 정보를 시각적으로 탐험하고, 생성형 AI 및 실시간 오디오 반주 세션과 함께 음악적 영감을 얻는 멀티 플랫폼 Flutter 애플리케이션입니다. 5도권(Circle of Fifths) 기반의 키 탐색부터, 고도화된 코드 보이싱 알고리즘, 실시간 타임라인 코드 진행 스튜디오, 그리고 AI 잼 세션(AI Jam Session & Backing Band)까지 음악인을 위한 올인원 환경을 제공합니다.

---

## 🔗 Git & Repository 정보 (Version Control)

| 항목 | 상세 정보 |
|---|---|
| **GitHub Repository** | [https://github.com/2jungho/chord5-wheel](https://github.com/2jungho/chord5-wheel) |
| **Clone URL (HTTPS)** | `https://github.com/2jungho/chord5-wheel.git` |
| **Clone URL (SSH)** | `git@github.com:2jungho/chord5-wheel.git` |
| **Default Branch** | `main` |
| **Author / Maintainer** | `jungho.lee` (`jungho.lee@maius.co.kr` / `2jungho@gmail.com`) |

```bash
# 저장소 복제 (Clone)
git clone https://github.com/2jungho/chord5-wheel.git
cd chord5-wheel

# 로컬 Git 작성자 설정 (선택 사항)
git config user.name "jungho.lee"
git config user.email "jungho.lee@maius.co.kr"
```

---

## 📱 지원 플랫폼 (Platforms)

*   **Web** (Primary Target - Firebase Hosting & WASM 지원)
*   **Windows Desktop** (Native C++ Engine & Inno Setup 패키징 지원)
*   **Android** (모바일 최적화)
*   **macOS / Linux** (실험적 지원)

---

## 🚀 주요 기능 (Key Features)

### 1. 5도권 탐색기 (Circle of Fifths Explorer)
*   **Interactive Wheel**: 5도권 휠을 통해 직관적으로 Root Key를 탐색하고 변경합니다.
*   **Mode & Scale Visualizer**: Ionian, Dorian, Phrygian, Lydian, Mixolydian, Aeolian, Locrian 등 7가지 모드와 캐릭터 노트를 실시간으로 확인합니다.
*   **AI Modulation Navigator**: 현재 키에서 목표 키로 자연스럽게 이동할 수 있는 **Pivot Chord Modulation** 경로를 AI가 실시간으로 분석/추천합니다. (휠 영역 길게 누르기)
*   **Diatonic Dashboard**: 선택된 키의 다이아토닉 코드를 한눈에 파악하고 즉석에서 스트럼/보이싱 사운드를 청음합니다.

### 2. 코드 생성기 & 분석기 (Chord Generator)
*   **Advanced Analysis**: `Cmaj13`, `F#m7b5`, `D7alt` 등 복잡한 텐션 코드 심볼을 인식하여 구성음(Notes)과 인터벌(Intervals)을 정밀 분석합니다.
*   **Algorithmic Voicing**: CAGED 시스템 로직과 Drop 2 / Shell Voicing 알고리즘을 기반으로 연주 가능한 최적의 지판 운지 형태를 자동 생성합니다.
*   **Interactive Fretboard**: 지판 전체에 인터벌 마커를 표시하며, 가이드 톤(3rd, 7th) 강조, 스포트라이트 포커스 및 펜타토닉 컨텍스트 시각화를 지원합니다.

### 3. 멀티 악기 에코시스템 (Multi-Instrument Ecosystem)
*   **Instrument Switching**: Guitar, Bass (4/5현), Ukulele, **Piano** 등 다양한 악기로 즉시 전환할 수 있습니다.
*   **Adaptive UI**: 선택한 악기에 맞춰 프렛보드, 코드 다이어그램, 튜닝 정보가 즉각 최적화됩니다.
*   **Piano Mode**: 피아노 선택 시 CAGED 대신 **Chord Inversion(전위)** 목록과 인터랙티브 건반 시각화를 제공합니다.

### 4. 코드 진행 스튜디오 & 타임라인 (Progression Studio)
*   **Timeline Editor**: 직관적인 블록 추가/삭제 및 순서 편집을 통해 나만의 코드 진행을 설계합니다.
*   **Quick Presets**: "Jazz 2-5-1", "Pop 1-5-6-4", "Blues 12-bar" 등 장르별 필수 코드 진행 프리셋을 제공합니다.
*   **Famous Songs Panel**: 입력된 코드 진행과 연관된 전 세계 유명 곡을 AI가 검색해주며, **YouTube 팝업 플레이어**를 통해 원곡과 배킹 트랙을 즉시 감상할 수 있습니다.
*   **AI Arranger & Reharmonization**: 기본 진행을 Neo-Soul, Jazz Funk, Gospel 등 감각적인 코드로 자동 재화문화(Reharmonization)합니다.

### 5. 🎹 AI 잼 세션 & 실시간 배킹 밴드 (AI Jam Session & Backing Band)
*   **AI Realtime Streaming & Virtual Band**: Google Gemini / Lyria 실시간 오디오 반주 및 내장 가상 밴드 엔진(Tone.js)을 통해 타임라인 진행에 맞춘 즉흥 연주 반주를 제공합니다.
*   **Dynamic Controls**:
    *   **Tempo Slider**: 60 ~ 180 BPM 실시간 템포 조절.
    *   **Volume Slider & Mute Toggle**: 0% ~ 100% 볼륨 조절 및 원클릭 음소거/복원 토글.
    *   **7 Multi-Styles**: Neo-Soul, Jazz Funk, Lofi Chill, Rock, Blues, City Pop, Acoustic Ballad.
*   **Zero-Config Ready**: API 키가 없어도 내장 가상 밴드로 즉시 연주 가능하며, Gemini API 키 등록 시 AI 잼 세션으로 원활하게 확장됩니다.

### 6. 🧠 최신 Gemini 3.x 모델 및 추론 강도(Thinking Level) 지원
*   **Supported Models**:
    *   `gemini-3.7-flash` (기본 추천 - 최신 플래그십 하이브리드 추론 모델)
    *   `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-pro-preview`, `gemini-2.5-flash`
    *   `gemma-4-31b-it` (경량 오픈 모델)
*   **Reasoning Control**: 모델별 추론 강도(`ThinkingLevel`: Off, Low, Medium, High)를 설정 다이얼로그에서 자유롭게 커스터마이징 가능.

### 7. 하이브리드 고음질 오디오 엔진 (Hybrid Audio Engine)
*   **Web Engine (Tone.js + Web Audio API)**: 폴리포닉 신디사이저, 샘플러 매핑(Guitar/Bass 피치 시뮬레이션), 마스터 볼륨 게인 제어.
*   **Native Engine (Windows/Android)**: `flutter_soloud` C++ 오디오 엔진 기반 저지연 사운드 재생.

---

## 🛠 기술 스택 (Tech Stack)

| Category | Technology | Description |
|---|---|---|
| **Framework** | Flutter 3.x (Dart 3) | 반응형 크로스 플랫폼 프레임워크 |
| **State Management** | Provider | 상태 관리 및 모듈별 State 분리 (`StudioState`, `LyriaState`, `SettingsState` 등) |
| **Audio Engine** | Tone.js (Web) / flutter_soloud (Native) / audioplayers | 플랫폼별 최적화된 하이브리드 오디오 엔진 |
| **AI (LLM / Audio)** | Google Gemini 3.7 Flash / Lyria Protocol | 음악 이론 분석, 편곡 추천 및 실시간 잼 세션 |
| **Hosting & Deploy** | Firebase Hosting | 프로덕션 웹 릴리즈 배포 (`chord5-wheel.web.app`) |
| **Repository** | GitHub (`2jungho/chord5-wheel`) | 버전 관리 및 협업 |
| **Code Quality** | Effective Dart / 0-Lint Architecture | `dart analyze lib test` 0개 이슈 달성 |

---

## 📂 프로젝트 구조 (Structure)

```
lib/
├── audio/                 # 하이브리드 오디오 브릿지 (Tone.js JS Interop, Native SoLoud)
├── models/                # 데이터 모델 (Chord, Voicing, Scale, MusicConstants, GeminiModel)
├── providers/             # 상태 관리자 (SettingsState, StudioState, LyriaState, MusicState)
├── services/              # 외부 서비스 연동
│   ├── ai_service.dart          # Gemini 3.x LLM API 및 프롬프트 처리
│   ├── lyria/                   # Gemini/Lyria 실시간 스트리밍 및 AudioQueue
│   └── music_theory_service.dart # 핵심 화성학 연산
├── utils/                 # 기타/피아노 지판 연산, 노멀라이즈된 유틸리티
├── views/                 # 메인 화면
│   ├── explorer/                # 5도권 탐색기 대시보드
│   ├── generator/               # 코드 분석기 및 보이싱 다이어그램
│   └── studio/                  # 타임라인 코드 진행 작업실
│       └── widgets/
│           ├── famous_songs/        # 모듈화된 유명곡 카드 및 모델 뱃지
│           ├── timeline/            # 모듈화된 타임라인 코드 카드
│           ├── lyria_jam_panel.dart # AI 잼 세션 및 볼륨/템포 컨트롤 바
│           └── studio_timeline.dart # 타임라인 컨테이너
└── widgets/               # 공용 UI 위젯 (Fretboard, Piano, Wheel, Dialogs)
```

---

## 🏗 로컬 개발 및 실행 (Setup & Run)

### 1. 사전 요구사항
* Flutter SDK (3.0.0 이상)
* Git (`git --version`)
* Node.js & Firebase CLI (`npm install -g firebase-tools`)

### 2. 저장소 복제 및 의존성 설치
```bash
# 저장소 복제
git clone https://github.com/2jungho/chord5-wheel.git
cd chord5-wheel

# 의존성 설치
flutter clean
flutter pub get
```

### 3. 로컬 실행
```bash
# Web 실행 (Chrome)
flutter run -d chrome

# Windows 실행
flutter run -d windows
```

### 4. 테스트 및 정적 분석 실행
```bash
# 정적 분석 (0 issues)
dart analyze lib test

# 전체 단위 및 위젯 테스트 실행 (21 tests)
flutter test
```

---

## 🚀 빌드 및 배포 가이드 (Build & Deployment)

### Firebase Hosting 배포
```bash
# 1. Web 릴리즈 빌드
flutter build web --release

# 2. Firebase 배포
firebase deploy --only hosting
```
* **라이브 서비스 접속**: **[https://chord5-wheel.web.app](https://chord5-wheel.web.app)**

---

## 📝 변경 이력 (Changelog)

### v2.0.0 (2026-08-27 - Lyria Realtime Jam, Gemini 3.x Suite & Clean Architecture Refactor)
* **AI Jam Session & Backing Band**:
  * Gemini 실시간 스트리밍 & Tone.js 가상 밴드 하이브리드 엔진 구축.
  * 0~100% 정밀 볼륨 조절 슬라이더 및 원클릭 음소거/복원 토글 기능 추가.
  * 60~180 BPM 템포 슬라이더 및 7가지 음악 스타일 프리셋 지원.
  * 모바일 및 좁은 화면을 위한 반응형 레이아웃 적용.
* **Gemini 3.x Model Suite & Thinking Intensity**:
  * `gemini-3.7-flash`, `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-pro-preview`, `gemma-4-31b-it` 완벽 지원.
  * 모델별 추론 강도(`ThinkingLevel`: Off, Low, Medium, High) 설정 기능 추가.
* **코드베이스 리팩토링 & 린트 Zero (0 Issues)**:
  * 미사용 레거시 코드 제거로 웹 번들 최적화.
  * Effective Dart 표준 네이밍(`noteNames`, `keys`, `modes`, `tuningNotes`) 일괄 적용.
  * `FamousSongItem`, `TimelineChordCard` 등 거대 위젯 단일 책임 컴포넌트로 분리.
  * Gemini 모델 파싱 및 추론 강도 검증을 위한 신규 단위 테스트 추가 (21/21 All Passed).

### v1.9.2 (2026-08-27 - Gemini 3.7 & Modern API Upgrade)
* 최신 플래그십 모델 지원 및 레거시 모델 식별자 자동 마이그레이션.
* Firebase Hosting 배포 안정화.

---

## 👤 Developer / Maintainer

* **이정호 (Lee Jungho)**
  * **GitHub**: [@2jungho](https://github.com/2jungho)
  * **Email**: `jungho.lee@maius.co.kr` / `2jungho@gmail.com`
