# Guitar & Theory Explorer 🎸

[![GitHub Repository](https://img.shields.io/badge/GitHub-2jungho%2Fchord5--wheel-181717?style=flat-square&logo=github)](https://github.com/2jungho/chord5-wheel)
[![Live Demo](https://img.shields.io/badge/Live_Demo-chord5--wheel.web.app-4285F4?style=flat-square&logo=googlechrome&logoColor=white)](https://chord5-wheel.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Gemini-3.7_Flash-8E75B2?style=flat-square&logo=google)](https://deepmind.google/technologies/gemini/)

**[👉 웹 데모 실행하기 (Live Demo)](https://chord5-wheel.web.app)** | **[📦 GitHub 저장소 바로가기](https://github.com/2jungho/chord5-wheel)**

화성학 이론과 기타 연주 정보를 시각적으로 탐험하고, 생성형 AI 및 4인조 가상 밴드(드럼, 베이스, 건반, 기타) 세션과 함께 음악적 영감을 얻는 멀티 플랫폼 Flutter 애플리케이션입니다. 5도권(Circle of Fifths) 기반의 키 탐색부터, 고도화된 코드 보이싱 알고리즘, 실시간 타임라인 코드 진행 스튜디오, 스마트 카포 전조기, 화성학적 경과 화음 삽입기, 5트랙 DAW MIDI 익스포터, CAGED 펜타토닉 솔로 박스 내비게이터, 5가지 고품질 테마 팔레트, 그리고 AI 잼 세션까지 음악인 및 작곡 입문자를 위한 올인원 환경을 제공합니다.

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

## 🎨 5대 테마 팔레트 (Theme Preset System)

상단 헤더의 테마 뱃지 또는 환경설정에서 원클릭으로 변경할 수 있으며, 선택한 테마는 로컬 스토리지에 영구 저장됩니다.

| 테마 프리셋 | 주요 색상 & 톤 | 설명 |
| :--- | :--- | :--- |
| **🌌 Slate Dark (기본)** | Slate 900 (`#0F172A`), Indigo Accent (`#6366F1`) | 가장 친숙하고 가독성이 뛰어난 클래식 딥 다크 테마 |
| **✨ Obsidian Cyber** | Obsidian Black (`#070B14`), Neon Cyan (`#06B6D4`), Neon Violet | 미래지향적인 사이버 펑크 & 네온 글로우 테마 |
| **🎸 Vintage Amber** | Dark Mahogany (`#1A120B`), Warm Amber Gold (`#F59E0B`) | 클래식 펜더/깁슨 앰프와 우드 기타 느낌의 따뜻한 레트로 락 테마 |
| **🌿 Midnight Forest** | Midnight Pine (`#061A14`), Vivid Emerald Mint (`#10B981`) | 차분하고 눈의 피로를 덜어주는 에메랄드 포레스트 테마 |
| **☀️ Studio Clean Light** | Crisp Slate 50 (`#F8FAFC`), Pure White, Deep Indigo | 밝고 화사하며 선명한 화이트 스튜디오 라이트 테마 |

---

## 🚀 주요 기능 (Key Features)

### 1. 5도권 탐색기 (Circle of Fifths Explorer)
*   **Interactive Wheel**: 5도권 휠을 통해 직관적으로 Root Key를 탐색하고 변경합니다.
*   **Mode & Scale Visualizer**: Ionian, Dorian, Phrygian, Lydian, Mixolydian, Aeolian, Locrian 등 7가지 모드와 캐릭터 노트를 실시간으로 확인합니다.
*   **AI Modulation Navigator**: 현재 키에서 목표 키로 자연스럽게 이동할 수 있는 **Pivot Chord Modulation** 경로를 AI가 실시간으로 분석/추천합니다. (휠 영역 길게 누르기)
*   **Diatonic Dashboard & 카포 추천**: 선택된 키의 다이아토닉 코드를 한눈에 파악하고, 카포 추천 버튼을 통해 쉬운 오픈 코드 폼을 즉시 탐색합니다.

### 2. 🎸 스마트 카포 전조기 (Smart Capo Transposer)
*   어려운 하이코드(바레코드)가 많은 곡(예: `Eb - Bb - Cm - Ab`)을 기타리스트가 연주하기 쉬운 **오픈 코드(Open Chord: C, G, D, Em, Am 폼)**로 변환하는 카포 위치(Capo 1~11)를 실시간 분석합니다.
*   **난이도 점수(Playability Score)**와 추천 뱃지(👑 최고 추천, ⭐ 추천)를 제공하며, 원클릭으로 타임라인 코드 진행에 즉시 적용할 수 있습니다.

### 3. ✨ 화성학적 경과 화음 삽입기 (Harmonic Passing Chord Inserter)
*   타임라인의 각 코드 블록 좌측 상단 `+` 버튼을 누르면, 해당 코드로 자연스럽게 연결되는 경과 화음을 추천받고 1클릭으로 삽입할 수 있습니다:
    *   **세컨더리 도미넌트 ($V7/X$)**: 목표 코드로 강한 해결감을 유도하는 5도 세븐스 코드.
    *   **얼터드 세컨더리 ($V7\flat9/X$)**: 마이너 코드로 진입할 때 매력적인 텐션을 부여하는 네오소울/재즈 코드.
    *   **트라이톤 대리 코드 ($SubV7/X$)**: 베이스가 반음 하행하며 부드럽고 세련되게 연결되는 대리 코드.
    *   **상행 디미니시 경과음 ($\sharp\text{Idim7}$)**: 반음 상행으로 클래식/보사노바 풍의 우아한 텐션 유도.
    *   **백도어 도미넌트 ($\flat\text{VII7}$)**: 서브도미넌트 마이너 종지감 생성.

### 4. 📥 5트랙 DAW 멀티트랙 MIDI 내보내기 (Multi-Track MIDI Exporter)
*   타임라인에 구성된 코드 진행을 **표준 MIDI 파일(SMF Format 1, `.mid`)**로 즉시 인코딩하여 다운로드합니다.
*   **5개 독립 트랙 구조**:
    1. `Track 0: Conductor` (BPM 템포 & 4/4 박자 메타데이터)
    2. `Track 1: Drums` (General MIDI Channel 10 킥/스네어/하이햇)
    3. `Track 2: Bass` (그루브 8비트 베이스라인)
    4. `Track 3: Keys` (Rhodes 건반 서스테인 화음)
    5. `Track 4: Guitar` (스트럼 딜레이가 적용된 리얼 기타 트랙)
*   Logic Pro, Ableton Live, Cubase, FL Studio, GarageBand 등 모든 DAW에서 드래그 앤 드롭으로 즉시 작업 가능합니다.

### 5. 🔥 CAGED 펜타토닉 솔로 박스 & 블루 노트 내비게이터 (Solo Box Navigator)
*   지판(Fretboard) 하단 뷰 컨트롤에서 **Box 1 ~ Box 5**를 선택하면, 해당 폼의 운지 영역만 스포트라이트로 격리 표시됩니다.
*   **블루스 노트($\flat5$)** 및 루트(Root) 마커가 시각적으로 강조되어 기타 솔로 즉흥 연주(Improvisation) 학습에 최적화되어 있습니다.

### 6. 🥁 4인조 가상 밴드 & AI 잼 세션 (4-Piece Virtual Band & AI Jam)
*   **Multi-Instrument Realtime Accompaniment**: 드럼, 베이스, 건반(Rhodes), 기타가 어우러진 4인조 가상 밴드 사운드.
*   **Dynamic Controls**: 60 ~ 180 BPM 템포 슬라이더, 볼륨 조절 및 원클릭 음소거/복원 토글.
*   **7가지 음악 스타일**: Neo-Soul, Jazz Funk, Lofi Chill, Rock, Blues, City Pop, Acoustic Ballad.

### 7. 🧠 최신 Gemini 3.x 모델 및 추론 강도(Thinking Level) 지원
*   `gemini-3.7-flash` (기본 추천), `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-pro-preview`, `gemma-4-31b-it` 지원.
*   모델별 추론 강도(`ThinkingLevel`: Off, Low, Medium, High)를 설정에서 자유롭게 커스터마이징 가능.

---

## 🛠 기술 스택 (Tech Stack)

| Category | Technology | Description |
|---|---|---|
| **Framework** | Flutter 3.x (Dart 3) | 반응형 크로스 플랫폼 프레임워크 |
| **State Management** | Provider | 상태 관리 및 모듈별 State 분리 (`StudioState`, `LyriaState`, `SettingsState`, `MusicState`) |
| **MIDI Engine** | Pure Dart SMF Type 1 Writer | 5트랙 표준 MIDI 바이너리 파일 생성 및 크로스 플랫폼 다운로드 |
| **Audio Engine** | Tone.js (Web) / VirtualBandSynth (PCM/WAV) / flutter_soloud | 플랫폼별 최적화된 하이브리드 오디오 엔진 |
| **AI (LLM / Audio)** | Google Gemini 3.7 Flash / Lyria Protocol | 음악 이론 분석, 편곡 추천 및 실시간 잼 세션 |
| **Hosting & Deploy** | Firebase Hosting | 프로덕션 웹 릴리즈 배포 (`chord5-wheel.web.app`) |
| **Repository** | GitHub (`2jungho/chord5-wheel`) | 버전 관리 및 협업 |
| **Code Quality** | Effective Dart / 0-Lint Architecture | `dart analyze lib test` 0개 이슈 달성 |

---

## 📂 프로젝트 구조 (Structure)

```
lib/
├── audio/                 # 하이브리드 오디오 브릿지 (VirtualBandSynth, Tone.js, Native SoLoud)
├── models/                # 데이터 모델 (Chord, Voicing, Scale, MusicConstants, GeminiModel, FretboardMarker)
├── providers/             # 상태 관리자 (SettingsState, StudioState, LyriaState, MusicState, ViewControlStateMixin)
├── services/              # 핵심 엔진 및 서비스
│   ├── ai_service.dart          # Gemini 3.x LLM API 및 프롬프트 처리
│   ├── capo_service.dart        # 스마트 카포 오픈코드 난이도 계산 엔진
│   ├── harmonic_suggestion_service.dart # 세컨더리 도미넌트/트라이톤/디미니시 경과음 계산기
│   ├── midi/                    # Pure Dart SMF Type 1 멀티트랙 MIDI 파일 작성 및 다운로더
│   ├── lyria/                   # 4인조 가상 밴드 시퀀서 및 Lyria 실시간 스트리밍
│   └── music_theory_service.dart # 핵심 화성학 연산
├── utils/                 # 기타/피아노 지판 연산, CAGED 펜타토닉 박스 계산기, 테마 프리셋(AppTheme)
├── views/                 # 메인 화면
│   ├── explorer/                # 5도권 탐색기 대시보드
│   ├── generator/               # 코드 분석기 및 보이싱 다이어그램
│   └── studio/                  # 타임라인 코드 진행 작업실
│       └── widgets/
│           ├── timeline/                # 타임라인 코드 카드, 경과음 삽입 모달(ChordInsertDialog)
│           ├── famous_songs/            # 모듈화된 유명곡 카드 및 모델 뱃지
│           ├── lyria_jam_panel.dart     # 4인조 가상 밴드 & AI 잼 세션 컨트롤 패널
│           └── insight_report_widget.dart # AI 코드 진행 분석 리포트
└── widgets/               # 공통 위젯
    ├── capo/                    # 스마트 카포 다이얼로그(CapoModal)
    ├── common/                  # 앱 헤더, 5도권 휠, 프렛보드 맵, 뷰 컨트롤 패널, 테마 설정
    └── ...
```

---

## 💻 로컬 개발 환경 설정 (Getting Started)

### 1. 전제 조건
*   Flutter SDK (3.24.x 이상 권장)
*   Dart SDK 3.x

### 2. 의존성 설치
```bash
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

# 전체 단위 및 위젯 테스트 실행 (30 tests)
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

### v2.2.0 (2026-08-28 - Guitar Hobbyist & Songwriting Suite)
* **🎸 스마트 카포 전조기 (Smart Capo Transposer)**:
  * 오픈 코드(C, G, D, Em, Am 폼) 운지 난이도 분석 점수 계산 엔진 구현 (`CapoService`).
  * 타임라인 및 5도권 다이아토닉 리스트에서 원클릭으로 카포 위치 추천 및 전조 적용 (`CapoModal`).
* **✨ 화성학적 경과 화음 삽입기 (Harmonic Passing Chord Inserter)**:
  * 세컨더리 도미넌트($V7$), 얼터드 세컨더리($V7\flat9$), 트라이톤 대리($SubV7$), 상행 디미니시($\sharp\text{Idim7}$), 백도어 도미넌트($\flat\text{VII7}$) 자동 계산 엔진 구현 (`HarmonicSuggestionService`).
  * 타임라인 카드 간 `+` 버튼으로 프리뷰 청음 및 즉시 삽입 지원 (`ChordInsertDialog`).
* **📥 5트랙 DAW 멀티트랙 MIDI 내보내기 (Multi-Track MIDI Exporter)**:
  * 외부 패키지 없는 Pure Dart SMF Type 1 바이너리 인코더 구현 (`MidiFileWriter`).
  * 드럼, 베이스, 건반(Rhodes), 기타, 메타데이터 트랙이 포함된 멀티트랙 `.mid` 파일 브라우저 다운로드 연동 (`MidiExportService`).
* **🔥 CAGED 펜타토닉 솔로 박스 & 블루 노트 내비게이터**:
  * 1~5번 CAGED 펜타토닉 솔로 박스 프렛 계산 및 블루스 노트($\flat5$) 가이드 지원 (`PentatonicBoxCalculator`).
  * 뷰 컨트롤 패널 및 프렛보드 맵과 완전 연동.
* **품질 보증**: 30개 전체 단위/위젯 테스트 통과 및 정적 분석 0이슈 달성.

### v2.1.0 (2026-08-28 - 4-Piece Virtual Band & 5-Theme Preset System)
* **4-Piece Virtual Band Sound Engine**:
  * 드럼(Drums), 베이스(Bass), 건반(Keys/Rhodes), 기타(Guitar) 4인조 가상 밴드 신디사이저 및 시퀀서 구현.
  * 장르별 고유 리듬 패턴 및 베이스라인 자동 연동.
* **5가지 고품질 테마 프리셋 (Theme Palette)**:
  * 🌌 **Slate Dark**, ✨ **Obsidian Cyber**, 🎸 **Vintage Amber**, 🌿 **Midnight Forest**, ☀️ **Studio Clean Light** 지원.
  * 상단 헤더 원클릭 테마 팝업 메뉴 및 설정 서랍 연동.

### v2.0.0 (2026-08-27 - Lyria Realtime Jam, Gemini 3.x Suite & Clean Architecture Refactor)
* **AI Jam Session & Backing Band**:
  * Gemini 실시간 스트리밍 & Tone.js 가상 밴드 하이브리드 엔진 구축.
  * 0~100% 정밀 볼륨 조절 슬라이더 및 원클릭 음소거/복원 토글 기능 추가.
  * 60~180 BPM 템포 슬라이더 및 7가지 음악 스타일 프리셋 지원.
* **Gemini 3.x Model Suite & Thinking Intensity**:
  * `gemini-3.7-flash`, `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-pro-preview`, `gemma-4-31b-it` 지원.
  * 모델별 추론 강도(`ThinkingLevel`: Off, Low, Medium, High) 설정 기능 추가.

---

## 👤 Developer / Maintainer

* **이정호 (Lee Jungho)**
  * **GitHub**: [@2jungho](https://github.com/2jungho)
  * **Email**: `jungho.lee@maius.co.kr` / `2jungho@gmail.com`
