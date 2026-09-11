# Guitar & Theory Explorer 🎸

[![GitHub Repository](https://img.shields.io/badge/GitHub-2jungho%2Fchord5--wheel-181717?style=flat-square&logo=github)](https://github.com/2jungho/chord5-wheel)
[![Live Demo](https://img.shields.io/badge/Live_Demo-chord5--wheel.web.app-4285F4?style=flat-square&logo=googlechrome&logoColor=white)](https://chord5-wheel.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Gemini-3.7_Flash-8E75B2?style=flat-square&logo=google)](https://deepmind.google/technologies/gemini/)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o_/_o3--mini-412991?style=flat-square&logo=openai&logoColor=white)](https://openai.com/)
[![Claude](https://img.shields.io/badge/Claude-3.7_Sonnet-D97706?style=flat-square&logo=anthropic&logoColor=white)](https://claude.ai/)

**[👉 웹 데모 실행하기 (Live Demo)](https://chord5-wheel.web.app)** | **[📦 GitHub 저장소 바로가기](https://github.com/2jungho/chord5-wheel)**

화성학 이론과 기타 연주 정보를 시각적으로 탐험하고, 다양한 최신 생성형 AI 모델(Gemini, ChatGPT, Claude, Ollama) 및 4인조 가상 밴드(드럼, 베이스, 건반, 기타) 세션과 함께 음악적 영감을 얻는 멀티 플랫폼 Flutter 애플리케이션입니다. 5도권(Circle of Fifths) 기반의 키 탐색부터, 18대 전설적 기타 거장의 시그니처 릭 보관함(Artist Lick Vault), 5대 기타 사운드(통기타, 나일론, 클린, 오버드라이브, 디스토션) 톤 프리셋 엔진, 고도화된 코드 보이싱 알고리즘, 실시간 타임라인 코드 진행 스튜디오, 스마트 카포 전조기, 화성학적 경과 화음 삽입기, 5트랙 DAW MIDI 익스포터, CAGED 펜타토닉 솔로 박스 내비게이터, 5가지 고품질 테마 팔레트, 그리고 통합 AI 음악 비서까지 음악인 및 작곡 입문자를 위한 올인원 환경을 제공합니다.

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

## 🤖 멀티 AI 모델 지원 (Multi-AI Provider Architecture)

환경설정(⚙️)의 **AI 서비스 제공자 셀렉트 박스**에서 원하는 AI 프로바이더와 모델을 원클릭으로 선택하여 앱 내 모든 AI 분석 및 음악 추천 기능에 사용할 수 있습니다.

| AI 프로바이더 | 지원 모델 프리셋 | 특징 및 강점 |
| :--- | :--- | :--- |
| **Google Gemini** | `gemini-3.7-flash` (기본), `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-pro`, `gemini-2.5-flash` | 초고속 실시간 스트리밍, 단계별 추론 강도(Thinking Level) 지원 |
| **OpenAI ChatGPT** | `gpt-4o`, `gpt-4o-mini`, `o3-mini` (추론형), `o1` (고성능 추론) | 탁월한 작곡/화성학 지식, 강력한 음악적 추론 역량 |
| **Anthropic Claude** | `claude-3-7-sonnet-20250219` (Hybrid Thinking), `claude-3-5-sonnet`, `claude-3-5-haiku` | 뛰어난 이론적 서술력, 자연스러운 한국어 설명, 심층 사고 지원 |
| **Custom / Local AI** | `Ollama` (`http://localhost:11434/v1`), `Groq`, `OpenRouter` 등 | 개인 PC 로컬 LLM(Llama 3 등) 또는 호환 엔드포인트 연동 |

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
*   **AI Modulation Navigator**: 현재 키에서 목표 키로 자연스럽게 이동할 수 있는 **Pivot Chord Modulation** 경로를 멀티 AI 모델이 실시간으로 분석/추천합니다. (휠 영역 길게 누르기)
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

### 6. 🎸 아티스트 릭 보관함 & 18대 거장 라이브러리 (Artist Lick Vault)
*   **18대 전설적 기타 거장 & 40여 개 시그니처 릭**:
    *   **Blues & Blues Rock**: 지미 헨드릭스(Jimi Hendrix), 에릭 클랩튼(Eric Clapton), 스티비 레이 본(Stevie Ray Vaughan), 게리 무어(Gary Moore)
    *   **Classic & Hard Rock**: 지미 페이지(Jimmy Page), 에디 반 헤일런(Eddie Van Halen), 슬래시(Slash)
    *   **Tone & Expressive**: 데이비드 길모어(David Gilmour), 제프 벡(Jeff Beck)
    *   **Instrumental Rock**: 스티브 바이(Steve Vai), 조 사트리아니(Joe Satriani)
    *   **Shred & Neo-Classical**: 잉베이 말름스틴(Yngwie Malmsteen), 폴 길버트(Paul Gilbert)
    *   **Jazz & Fusion**: 웨스 몽고메리(Wes Montgomery), 조 패스(Joe Pass)
    *   **Neo-Soul & Modern**: 존 메이어(John Mayer), 마테우스 아사토(Mateus Asato), 팀 헨슨(Tim Henson)
*   **확장형 Repository 패턴 & 지연 로딩 (Lazy Loading)**: 장르별 분할 JSON 에셋(`assets/data/licks/*.json`)을 선택 시점에만 비동기 로드하고 인메모리 캐싱하여 가벼운 메모리 점유율과 제로 렉(0-lag) 보장.
*   **인터랙티브 Guitar TAB 뷰어 & 실시간 단음 미리듣기**: 벤딩(Full, Half), 해머링 온, 풀링 오프, 슬라이드, 비브라토, 태핑('T'), 내추럴 하모닉스('NH') 기호 시각화 및 타브 악보 음표 클릭 시 즉시 톤 프리뷰 재생.
*   **코드 & 코드 진행 맞춤 릭 자동 추천 (Contextual Lick Recommendation Engine)**:
    *   **5도권 탐색기 & 코드 분석기 연동**: 현재 선택된 코드(예: `Am`, `C7`, `D7`, `Em` 등)의 루트음과 코드 성향(Major, Minor, Dominant 7th 등)을 실시간 분석하여 가장 잘 어울리는 18대 거장의 시그니처 릭을 자동 추천하고 타겟 코드 키로 자동 조옮김(Transpose)하여 카드 형태로 제공 (`ChordLickRecommendationCard`).
    *   **코드 진행 스튜디오 타임라인 연동**: 스튜디오 타임라인에 등록된 코드 진행 패턴(2-5-1 진행, 1-6-2-5 진행, 1-4-5 진행 등) 및 현재 선택된 코드 블록에 적합한 아티스트 릭을 탐색·추천하고, 클릭 한 번으로 미리듣기 및 5대 Box 전체 보기 지원 (`ProgressionLickPanel`).
*   **기타 연주 기법(아티큘레이션) 오디오 & 시각화 엔진 (Guitar Technique Audio Engine)**:
    *   릭 재생 시 단순한 평면 피치가 아닌 기타 특유의 연주 테크닉을 오디오 DSP 및 시각적 애니메이션으로 리얼하게 표현:
        *   **벤딩 (Bending `Full`, `½`)**: 기준 음을 피킹한 후 실시간 주파수 굴절(Pitch Glide)로 음정이 휘어 올라가는 초크 업 사운드 구현 및 오렌지색 벤딩 뱃지/글로우 점등.
        *   **슬라이드 (Slide `/`, `\`)**: 시작 프렛에서 목표 프렛까지 미세 반음 글리산도(Glissando) 연결 및 시안색 슬라이드 뱃지 표시.
        *   **해머링 온 (Hammer-on `h`)**: 부드러운 어택의 레가토 슬러(Legato Slur) 타현음 및 그린색 해머링 뱃지 표시.
        *   **풀링 오프 (Pull-off `p`)**: 경쾌한 하향 릴리즈 핑거링 연주음 및 퍼플색 풀링 뱃지 표시.
        *   **비브라토 (Vibrato `~`)**: 지속음에서 음높이가 미세하게 떨리는 비브라토 모듈레이션 표현.
*   **5대 CAGED 폼 (Box 1 ~ Box 5) 실시간 운지 변환기**: 릭의 고유 포지션에 머무르지 않고, **Box 1 (E Form), Box 2 (D Form), Box 3 (C Form), Box 4 (A Form), Box 5 (G Form)** 중 원하는 포지션 탭을 선택하면 Viterbi 기반 최소 손이동 최적화 알고리즘을 통해 해당 지판 박스로 릭의 모든 운지와 TAB 악보가 실시간 재매핑됩니다.
*   **5대 폼 전체 펼쳐보기 (All 5 Boxes Stack View)**: '5대 폼 전체 펼치기' 토글 버튼을 통해 5개 박스의 TAB 악보를 한 화면에서 수직으로 펼쳐 포지션별 핑거링 차이를 한눈에 대조 및 선택 가능.
*   **실시간 화성학 분석 & 연주 가이드**: 릭별 권장 연주 폼(CAGED 폼 및 펜타토닉 박스), 타겟 코드톤, 연주 팁, 그리고 각 음표의 화성적 역할(3도, 7도, 텐션, $\flat5$ 블루노트 등)을 자동 분석/표시.
*   **키 자동 조옮김 (Auto Transposition)**: 5도권 휠의 현재 Key나 타임라인 선택 코드에 맞춰 릭의 음정과 기타 지판 운지를 실시간으로 조옮김.

### 7. 🔊 5대 기타 사운드 & 톤 프리셋 시스템 (5 Guitar Tone Presets)
*   하단 액션 바의 톤 선택 팝업 버튼을 통해 원하는 기타 사운드를 원클릭으로 변경할 수 있으며, 릭 재생 및 TAB 악보 단음 클릭 시 Web Audio(Tone.js) DSP 체인을 통해 실시간으로 사운드가 변환됩니다:
    *   **🎸 스틸 통기타 (Acoustic Steel)**: 찰랑거리는 스틸현의 찰현음과 선명한 고음, 풍성한 어쿠스틱 바디 공명감 (Folk / Pop / Fingerstyle).
    *   **🎸 나일론 기타 (Classical Nylon)**: 핑거링에 최적화된 부드러운 어택, 따뜻한 중저음과 부드러운 하이컷 롤오프 (Bossa Nova / Flamenco / Latin).
    *   **🎸 클린 일렉 (Electric Clean)**: Fender Twin Reverb의 맑고 투명한 싱글 코일 차임 & 아날로그 코러스 공간감 (Neo-Soul / Funk / R&B / Pop).
    *   **🎸 오버드라이브 (Tube Overdrive)**: 진공관 앰프를 크런치 시킨 끈적하고 펀치력 있는 블루스/록 질감 (Blues / Classic Rock / Funky Rock).
    *   **🎸 디스토션 (High-Gain Lead)**: 헤비 록 & 메탈 리드 솔로용 강력한 하이게인, 배음 증폭 및 긴 서스테인 (Hard Rock / Heavy Metal / Shred).
*   **스마트 사운드 추천**: 아티스트 선택 시 해당 아티스트의 음악 스타일과 장르에 가장 잘 어울리는 기타 사운드가 자동으로 기본 매핑됩니다.

### 8. 🥁 4인조 가상 밴드 & AI 잼 세션 (4-Piece Virtual Band & AI Jam)
*   **Multi-Instrument Realtime Accompaniment**: 드럼, 베이스, 건반(Rhodes), 기타가 어우러진 4인조 가상 밴드 사운드.
*   **Dynamic Controls**: 60 ~ 180 BPM 템포 슬라이더, 볼륨 조절 및 원클릭 음소거/복원 토글.
*   **7가지 음악 스타일**: Neo-Soul, Jazz Funk, Lofi Chill, Rock, Blues, City Pop, Acoustic Ballad.

### 9. 🤖 대화형 AI 튜터 챗봇 & 앱 상태 제어
*   우측 패널에서 실시간 스트리밍으로 화성학 질문 답변 및 코드 진행 분석을 제공합니다.
*   **LaTeX 수식 및 화살표 렌더러 탑재**: 답변 내 `$\rightarrow$`, `$\to$`, `$\Rightarrow$` 등의 화살표 문법 및 수식(`$$...$$`)이 깨짐 없이 시각적 기호로 깔끔하게 렌더링됩니다.
*   사용자의 자연어 요청에 따라 앱의 5도권 키 및 모드를 실시간으로 변경(App State Command Execution)합니다.
*   헤더에 최적화된 단일 라인 축약 뱃지(`3.7F`, `4o`, `3.7S`, `R1` 등)와 외부 사이트 바로가기 제공.

---

## 🛠 기술 스택 (Tech Stack)

| Category | Technology | Description |
|---|---|---|
| **Framework** | Flutter 3.x (Dart 3) | 반응형 크로스 플랫폼 프레임워크 |
| **State Management** | Provider | 상태 관리 및 모듈별 State 분리 (`StudioState`, `ChatState`, `SettingsState`, `MusicState`) |
| **MIDI Engine** | Pure Dart SMF Type 1 Writer | 5트랙 표준 MIDI 바이너리 파일 생성 및 크로스 플랫폼 다운로드 |
| **Audio Engine** | Tone.js (Web) / VirtualBandSynth (PCM/WAV) / flutter_soloud | 플랫폼별 최적화된 하이브리드 오디오 엔진 |
| **Multi-AI Engine** | Gemini / OpenAI / Claude / DeepSeek / Ollama | 멀티 LLM SSE 스트리밍 및 공통 JSON 파서 연동 |
| **Markdown & LaTeX** | flutter_markdown_plus / flutter_markdown_plus_latex | GFM 지원 및 KaTeX/LaTeX 수식·화살표 기호 미려 렌더링 |
| **Hosting & Deploy** | Firebase Hosting | 프로덕션 웹 릴리즈 배포 (`chord5-wheel.web.app`) |
| **Repository** | GitHub (`2jungho/chord5-wheel`) | 버전 관리 및 협업 |
| **Code Quality** | Effective Dart / 0-Lint Architecture | `dart analyze lib test` 0개 이슈 달성 |

---

## 📂 프로젝트 구조 (Structure)

```
lib/
├── audio/                 # 하이브리드 오디오 브릿지 (VirtualBandSynth, Tone.js, Native SoLoud)
├── models/                # 데이터 모델 (Chord, Voicing, Scale, MusicConstants, AIProviderConfig, FretboardMarker)
│   ├── audio/                 # 오디오 및 사운드 프로필 모델 (BandSoundProfile, SoundProfile)
│   └── lick/                  # 릭 및 아티스트 모델 (ArtistLick, GuitarArtist, ArtistLickPresets)
├── providers/             # 상태 관리자 (SettingsState, StudioState, ChatState, MusicState, LickVaultState)
├── services/              # 핵심 엔진 및 서비스
│   ├── ai_service.dart          # 멀티 AI 프로바이더 팩토리 및 라우터
│   ├── providers/               # 프로바이더별 SSE 스트리밍 구현체 (Gemini, Claude, OpenAI, DeepSeek, Ollama)
│   ├── capo_service.dart        # 스마트 카포 오픈코드 난이도 계산 엔진
│   ├── harmonic_suggestion_service.dart # 세컨더리 도미넌트/트라이톤/디미니시 경과음 계산기
│   ├── lick/                    # 릭 저장소 레이어 (LickRepository, AssetLickRepository)
│   ├── lick_analyzer_service.dart # 릭 화성학 분석 및 조옮김(Transpose) 엔진
│   ├── lick_audio_player.dart   # 릭 및 TAB 단음 실시간 오디오 플레이어
│   ├── midi/                    # Pure Dart SMF Type 1 멀티트랙 MIDI 파일 작성 및 다운로더
│   ├── lyria/                   # 4인조 가상 밴드 시퀀서 및 오디오 브릿지
│   └── music_theory_service.dart # 핵심 화성학 연산
├── utils/                 # 기타/피아노 지판 연산, CAGED 펜타토닉 박스 계산기, 테마 프리셋(AppTheme)
├── views/                 # 메인 화면
│   ├── explorer/                # 5도권 탐색기 대시보드 및 변조 다이얼로그
│   ├── generator/               # 코드 분석기 및 스타일별 보이싱 탭
│   └── studio/                  # 타임라인 코드 진행 작업실
│       └── widgets/
│           ├── timeline/                # 타임라인 코드 카드, 경과음 삽입 모달(ChordInsertDialog)
│           ├── famous_songs/            # 모듈화된 유명곡 카드 및 AI 곡 탐색
│           ├── jam/                     # 4인조 가상 밴드 세션 컨트롤 패널 (LyriaJamPanel 모듈)
│           └── insight_report_widget.dart # AI 코드 진행 분석 리포트
└── widgets/               # 공통 위젯
    ├── ai_chat/                 # AI 채팅 패널(AIChatPanel), 메시지 버블(ChatMessageBubble)
    ├── capo/                    # 스마트 카포 다이얼로그(CapoModal)
    ├── lick/                    # 아티스트 릭 보관함(ArtistLickVaultSheet) 및 분해된 컴포넌트(components/)
    ├── common/                  # 앱 헤더, 5도권 휠, 프렛보드 맵, 뷰 컨트롤 패널, 테마/AI 설정 다이얼로그
    └── ...

assets/
└── data/
    ├── artists/                 # 18대 기타 거장 메타데이터 (artists.json)
    └── licks/                   # 장르별 분할 릭 데이터셋 (licks_blues, licks_rock, licks_tone 등)
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

# 전체 단위 및 위젯 테스트 실행 (92 tests)
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

### v2.9.1 (2026-09-11 - Comprehensive Clean Architecture Refactoring & Stability Hardening)
* **🏛️ 대규모 코드베이스 리팩토링 및 클린 아키텍처 고도화 (Behavior-Preserving Refactoring)**:
  * **1단계: 화성학 서비스 연동 및 데드코드 해소 (`MusicTheoryService`)**:
    * `MusicTheoryService.calculateKeyContext(..., {bool isSeventh = true})` 파라미터 확장 및 `MusicState._calculateState()`와의 직접 연동으로 중복 연산 제거 및 데드코드 상태 완전 해소.
    * CAGED 폼 명칭 정규화 메서드 `NoteUtils.normalizeCagedForm` 구현 및 전역 호출 일원화.
  * **2단계: 핵심 State Provider 헬퍼 통합 & 정규화 (`MusicState`, `StudioState`)**:
    * `MusicState`: 산재된 하드코딩 문자열 슬라이싱(`replaceAll`, `substring`)을 `normalizeCagedForm`으로 치환하고 Key/Mode 리셋 시퀀스를 `_resetSelectionAndRecalculate()`로 통합.
    * `StudioState`: `addProgressionFromText`, `convertProgressionDensity`, `setProgression` 등에 중복 작성되어 있던 블록 생성 루프를 단일 헬퍼 `_buildProgressionBlocks(...)`로 일원화.
  * **3단계: 1,090줄 God-Widget 분해 (`ArtistLickVaultSheet` → 5개 서브 컴포넌트)**:
    * `lib/widgets/lick/components/` 산하에 5개 단일 책임 위젯으로 전면 분리:
      1. `LickFilterBar`: 장르 칩, 아티스트 선택 필터, 거장 프로필 배너, 태그 필터 바.
      2. `LickCardList`: 릭 카드 목록 및 난이도 배지.
      3. `InteractiveTabViewer`: 6현 TAB 악보 렌더러, 5-Box 펜타토닉 뷰 스위처, 연주 테크닉 배지, 단음 미리듣기.
      4. `LickTheoryPanel`: 화성학 분석 및 코드 톤 타겟팅, 음표별 역할 분석.
      5. `LickActionBar`: 재생 템포, 5대 기타 사운드 프리셋 팝업, 재생/일시정지, 타임라인 삽입.
    * 메인 시트 위젯 라인 수: **1,089줄 → 160줄 (`-85.3%` 경량화)**.
  * **4단계: UI 빌더 내부 도메인 연산 로직 추출 및 성능 최적화**:
    * `GuitarUtils.generateStudioFretboardMap`: `StudioView` 빌드 메서드 내에 있던 75줄의 복잡한 펜타토닉 박스 및 고스트 노트 계산 로직을 순수 유틸 함수로 추출하여 UI 재렌더링 부하 최소화.
    * `GeneratorView`: 모바일/데스크톱 공통 상단 코드 결과 카드를 `_ChordResultCard`로 분리 및 `Consumer`를 타입 안전한 `Selector`로 전환하여 불필요한 전체 리빌드 방지.
    * `ExplorerView`: `context.watch<MusicState>()`를 `context.select<MusicState, bool>((s) => s.isSeventhMode)`로 최적화.
  * **5단계: 공통 헤더/타임라인/설정 상태 정리**:
    * `AppHeader`: `FirstLetterUppercaseFormatter`를 `lib/utils/text_formatters.dart`로 분리, 네비게이션 탭 `AppTab` enum을 `lib/models/navigation/app_tab.dart`로 모듈화, 대형 `build()` 함수를 5대 전용 빌더 메서드로 구조화.
    * `StudioTimeline`: 너비 조절 핸들의 불필요한 `dynamic` 캐스팅 및 `try/catch` 예외 처리를 `_analysisPanelWidth.clamp(250.0, 800.0)`로 간결하고 안전하게 교체.
    * `SettingsState`: 중간에 삽입되어 있던 `_huggingFaceToken` 필드를 최상단 필드 및 게터 영역으로 재배치하여 코드 일관성 확보.
* **품질 보증**: 92개 전체 단위/위젯 테스트 100% 통과, `dart analyze` 0개 이슈, 웹 릴리즈 빌드 및 Firebase Hosting 프로덕션 배포 완료.

### v2.9.0 (2026-09-11 - Artist Lick Vault 18 Masters Suite & 5 Guitar Tone Presets)
* **🎸 아티스트 릭 보관함(Artist Lick Vault) 아키텍처 개편 & 18대 기타 거장 라이브러리 구축**:
  * **확장형 Repository 패턴 전환**:
    * `GuitarArtist` 엔티티 분리 및 정규화, `LickRepository` 인터페이스 및 `AssetLickRepository` 지연 로딩(Lazy Loading) & 인메모리 캐싱 도입.
    * 하드코딩 구조를 탈피하여 `assets/data/artists/` 및 장르별 분할 JSON(`assets/data/licks/*.json`)으로 완전 외부화하여 무제한 확장성 확보.
  * **18대 전설적 기타리스트 & 40여 개 시그니처 릭 탑재**:
    * **Blues & Blues Rock**: 지미 헨드릭스, 에릭 클랩튼, 스티비 레이 본, 게리 무어
    * **Classic & Hard Rock**: 지미 페이지, 에디 반 헤일런, 슬래시
    * **Tone & Expressive**: 데이비드 길모어, 제프 벡
    * **Instrumental Rock**: 스티브 바이, 조 사트리아니
    * **Shred & Neo-Classical**: 잉베이 말름스틴, 폴 길버트
    * **Jazz & Fusion**: 웨스 몽고메리, 조 패스
    * **Neo-Soul & Modern**: 존 메이어, 마테우스 아사토, 팀 헨슨
  * **인터랙티브 Guitar TAB 뷰어 & 화성학 분석 엔진**:
    * 벤딩(Full/Half), 해머링온, 풀링오프, 슬라이드, 비브라토, 오른손 태핑('T'), 내추럴 하모닉스('NH') 테크닉 기호 렌더링.
    * 탭 악보 음표 클릭 시 실시간 단음 미리듣기, CAGED 폼/펜타토닉 박스 가이드, 음표별 화성학 역할(3도, 7도, 텐션, $\flat5$ 블루노트 등) 분석 제공.
    * 5도권 휠의 현재 Key 및 타임라인 선택 코드에 맞춘 실시간 자동 조옮김(Auto Transpose).
* **🔊 5대 기타 사운드 & 톤 프리셋 시스템 (Web Audio / Tone.js DSP Chain Modeling)**:
  * **5대 시그니처 톤 탑재**: 스틸 통기타(Acoustic Steel), 나일론 기타(Classical Nylon), 클린 일렉(Electric Clean), 튜브 오버드라이브(Tube Overdrive), 하이게인 디스토션(High-Gain Lead).
  * **Tone.js DSP 체인 정밀 튜닝**: `guitarHighpass`, `guitarAmpEQ`, `guitarDrive` (Distortion), `guitarChorus`, `guitarCabFilter` (4x12 / 12" Jensen / Flat 롤오프) 파라미터 제어.
  * **UI & 편의 기능**: 하단 액션 바에 사운드 프리셋 드롭다운 팝업 버튼 배치, 아티스트별 추천 톤 자동 매핑, TAB 단음 프리뷰 실시간 톤 연동.
* **품질 보증**: 83개 전체 단위/위젯 테스트 100% 통과, `dart analyze` 0개 이슈, 웹 프로덕션 빌드 및 Firebase 호스팅 배포 완료.

### v2.8.0 (2026-09-11 - Full Clean Architecture Modularization & Codebase Refactoring)
* **🏗️ 대규모 비대 소스 및 God Widget 전면 분리 & 모듈화 (Clean Architecture)**:
  * **Settings UI 통합 단일화 (`lib/widgets/settings/`)**:
    * `SettingsDialog`와 `SettingsDrawer`에 95% 중복 분산되어 있던 1,500여 줄의 설정을 단일 컴포넌트 `SettingsContent`로 통합 (`-89.6%` 라인 감소 및 동기화 무결성 확보).
  * **프렛보드 렌더러 분리 (`fretboard_painter.dart`)**:
    * 510줄의 캔버스 그래픽 렌더링 로직(`FretboardPainter`, `ZoneDef`)을 순수 페인터로 추출하여 UI 재렌더링 성능 및 가독성 향상.
  * **순수 화성학/보이스 리딩 계산 엔진 분리 (`voice_leading_calculator.dart`)**:
    * `StudioState` 거대 상태 클래스로부터 순수 연산 로직(`calculateVoiceLeading`, `calculateAnchorFret`)을 분리하고 독립 단위 테스트 구축.
  * **스튜디오 타임라인 모듈화 (`lib/views/studio/widgets/timeline/`)**:
    * 1,636줄의 God Widget을 5개 특화 서브패널(`TimelineHeaderToolbar`, `TimelineSectionsBar`, `TimelineQuickAddBar`, `TimelineKeyPanel`, `TimelineAnalysisPanel`)로 분해.
  * **가상 밴드 잼 세션 모듈화 (`lib/views/studio/widgets/jam/`)**:
    * 1,283줄의 `LyriaJamPanel`을 4개 독립 컴포넌트(`JamControlsBar`, `JamBandMixer`, `JamToneSelector`, `JamMoodPromptCard`)로 구조화.
  * **AI 채팅 패널 모듈화 (`lib/widgets/ai_chat/`)**:
    * 992줄의 `AIChatPanel`을 `ChatPanelHeader`, `ChatInputBar`, `ChatQuickPromptsBar`, `ChatDialogs`로 분리.
  * **유명곡 탐색기 모듈화 (`lib/views/studio/widgets/famous_songs/`)**:
    * 852줄의 `FamousSongsPanel`을 `FamousSongsAiSearchView` 및 `FamousSongsDetailInfoPanel`로 분리.
* **품질 보증**: 58개 전체 단위/위젯 테스트 100% 통과, `dart analyze` 0개 이슈, 웹 프로덕션 빌드 및 Firebase 호스팅 배포 완료.

### v2.7.0 (2026-09-10 - AI Chat LaTeX Math & Arrow Renderer Enhancement)
* **✨ AI 채팅 LaTeX 수식 및 화살표 렌더러 플러그인 탑재 (`flutter_markdown_plus_latex`)**:
  * AI 튜터 응답 내 `$\rightarrow$`, `$\to$`, `$\Rightarrow$` 등 LaTeX 화살표 표기 및 수학 공식(`$...$`, `$$...$$`)이 원문 텍스트 깨짐 없이 미려한 그래픽 기호로 렌더링되도록 개선.
  * `flutter_markdown_plus` 및 `flutter_markdown_plus_latex` 기반 커스텀 빌더(`LatexElementBuilder`) 연동으로 앱 테마 색상(onSurface) 및 사용자 지정 폰트 크기 자동 동기화.
  * GitHub Flavored Markdown(표, 체크박스 등) 문법 확장과 결합하여 풍부한 마크다운 표현력 확보.
* **품질 보증**: 48개 전체 단위/위젯 테스트 100% 통과 및 정적 분석 0개 이슈 달성.

### v2.6.0 (2026-08-28 - AI Prompt Jam Track Generator & Mood Vibe Suite)
* **✨ AI 잼트랙 분위기 프롬프트 주입기 (AI Mood-Driven Jam Generator)**:
  * 잼트랙 패널에 자연어 무드 프롬프트 입력창 탑재 ("비 오는 새벽 로파이", "시티팝 드라이브", "존 메이어 블루스" 등).
  * 멀티 AI(Gemini, GPT-4o, Claude)를 통해 자연어 분위기를 7가지 밴드 스타일, BPM 템포, 4~8마디 맞춤형 코드 진행, 악기 믹서 밸런스로 실시간 변환.
  * AI가 도출한 코드 진행이 스튜디오 타임라인에 자동 배치되고 4인조 가상 밴드(드럼, 베이스, 건반, 기타)가 즉시 연주 시작.
  * 6가지 대표 추천 무드 칩(`🌧️ 비 오는 로파이`, `🌆 시티팝`, `🎸 슬로우 블루스`, `☕ 감성 어쿠스틱`, `✨ 네오소울`, `⚡ 펑키 록`) 및 AI 음악 해설 배지 제공.
* **품질 보증**: 44개 전체 단위/위젯 테스트 100% 통과 및 정적 분석 0개 이슈 달성.

### v2.5.0 (2026-08-28 - YouTube Link Chord Extractor & 5th Wheel Density Suite)
* **📺 YouTube 링크 기반 코드 진행 자동 추출기 (YouTube Chord Extractor)**:
  * YouTube oEmbed 비동기 파싱 엔진(`YouTubeMetadataService`) 구현 (`youtu.be`, `watch?v=`, `shorts` 지원).
  * 유튜브 URL 입력 시 썸네일, 영상 제목, 채널명 실시간 감지 및 멀티 AI(Gemini, GPT-4o, Claude)를 통한 정밀 화성학 코드 진행 분석.
  * `AI 곡 진행 검색` 다이얼로그에 `[유튜브 링크 입력 | 곡명/가수 검색]` 탭 탑재 및 타임라인 원클릭 동기화.
* **🎹 3화음(Triad) / 7화음(7th) 전 영역 통일 스위치**:
  * 5도권 휠 탐색기(Explorer), 스튜디오 Key Center 패널, 타임라인 툴바 전 영역에 `[3화음 | 7화음]` 스위치 통일 배치.
  * 타임라인 코드 진행 일괄 확장(`CMaj7 - Am7 - Dm7 - G7`) 및 단순화(`C - Am - Dm - G`) 실시간 지원.
* **품질 보증**: 43개 전체 단위/위젯 테스트 100% 통과 및 정적 분석 0개 이슈 달성.

### v2.4.0 (2026-08-28 - Diatonic Triads vs 7th Chords Suite & Harmonic Density Converter)
* **🎹 다이아토닉 3화음(Triad) / 7화음(7th) 원클릭 전환**:
  * 5도권 탐색기 `Diatonic Chords` 헤더에 `[3화음 | 7화음]` 캡슐형 세그먼트 스위치 탑재.
  * **3화음 모드**: 기본 3성부(1-3-5, e.g. `C, Dm, Em, F, G, Am, Bdim`) 및 프렛보드 트라이어드 마커/보이싱 실시간 연동.
  * **7화음 모드**: 4성부(1-3-5-7, e.g. `Cmaj7, Dm7, Em7, Fmaj7, G7, Am7, Bm7b5`) 및 확장 텐션 보이싱 지원.
  * 사용자의 선택 모드를 `SharedPreferences` 로컬 스토리지에 자동 저장하여 앱 재실행 시에도 유지.
* **⚡ 타임라인 스튜디오 `3화음 ↔ 7화음 일괄 변환기` (Harmonic Density Converter)**:
  * 타임라인 툴바에 **`화음 변환`** 팝업 메뉴 추가 (`7화음으로 확장(Enrich)` / `3화음으로 단순화(Simplify)`).
  * 기존 타임라인 진행의 모든 코드를 원클릭으로 일괄 변환하고 음성 리딩 및 보이싱을 즉시 재계산.
* **🎨 솔로 박스(Solo Box) 및 뷰 컨트롤 패널 시인성 최적화**:
  * `[전체], [Box 1], [Box 2], [Box 3], [Box 4], [Box 5]` 버튼을 단일 행(Single Row) 가로 스크롤 레이아웃으로 개선하여 줄바꿈 끊김 현상 해소.

### v2.3.0 (2026-08-28 - Multi-AI Provider Architecture & Precision UI)
* **🤖 Multi-AI Provider 통합 지원**:
  * **Google Gemini** (Gemini 3.7 Flash, 3.6 Flash, 3.5 Flash, 3.5 Flash Lite, 3.1 Pro, 2.5 Flash)
  * **OpenAI ChatGPT** (GPT-4o, GPT-4o mini, o3-mini, o1)
  * **Anthropic Claude** (Claude 3.7 Sonnet, Claude 3.5 Sonnet, Claude 3.5 Haiku)
  * **Custom / Local AI** (Ollama, Groq, OpenRouter 등 OpenAI 호환 엔드포인트)
* **📡 고성능 스트리밍 & 라우팅 아키텍처**:
  * Server-Sent Events(SSE) 스트리밍 프로바이더 레이어 구축 (`ClaudeProvider`, `OpenAICompatibleProvider`, `OpenAIProvider`, `GeminiProvider`).
  * `AIService` 팩토리 패턴을 통한 동적 라우팅 및 전 기능(변조 탐색기, 스타일 보이싱, AI 편곡, AI 곡 검색, 유명곡 추천, 솔로잉 가이드) 연동.
* **⚙️ 직관적인 드롭다운 셀렉트 박스 UI & 모델 배지 최적화**:
  * AI 서비스 제공자 전용 셀렉트 박스로 한눈에 직관적 선택 지원.
  * 채팅창 헤더에 축약형 모델 뱃지(`3.7F`, `4o`, `3.7S` 등) 적용으로 줄바꿈/텍스트 밀림 완벽 해소.
* **품질 보증**: 38개 전체 단위/위젯 테스트 100% 통과 및 정적 분석 0개 이슈 달성.

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

### v2.1.0 (2026-08-28 - 4-Piece Virtual Band & 5-Theme Preset System)
* **4-Piece Virtual Band Sound Engine**: 드럼, 베이스, 건반, 기타 4인조 가상 밴드 신디사이저 및 시퀀서 구현.
* **5가지 고품질 테마 프리셋 (Theme Palette)**: Slate Dark, Obsidian Cyber, Vintage Amber, Midnight Forest, Studio Clean Light 지원.

### v2.0.0 (2026-08-27 - Lyria Realtime Jam, Gemini 3.x Suite & Clean Architecture Refactor)
* **AI Jam Session & Backing Band**: Gemini 실시간 스트리밍 & 가상 밴드 하이브리드 엔진 구축.
* **Gemini 3.x Model Suite & Thinking Intensity**: `gemini-3.7-flash`, `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-pro-preview` 지원.

---

## 👤 Developer / Maintainer

* **이정호 (Lee Jungho)**
  * **GitHub**: [@2jungho](https://github.com/2jungho)
  * **Email**: `jungho.lee@maius.co.kr` / `2jungho@gmail.com`

