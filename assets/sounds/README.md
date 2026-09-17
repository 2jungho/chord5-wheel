# Sound Assets & Hybrid Audio Architecture 🎵

이 디렉토리는 **Guitar & Theory Explorer**의 단음, 릭(Lick), 코드 및 가상 밴드 연주에 사용되는 오디오 리소스를 관리합니다.

---

## 🎧 오디오 아키텍처 개요 (Audio Engine Architecture)

본 프로젝트는 플랫폼별 최적의 저지연(Low-Latency) 및 고품질 재생을 위해 **하이브리드 오디오 엔진**을 채택하고 있습니다.

1. **Web (Tone.js & Web Audio API DSP 체인)**
   - 브라우저 환경에서 정밀한 타이밍 제어와 실시간 기타 앰프 시뮬레이션(DSP Filter/Overdrive/Reverb/Chorus)을 수행합니다.
   - 5대 기타 톤 프리셋(스틸 통기타, 나일론, 클린 일렉, 튜브 오버드라이브, 하이게인 디스토션)을 실시간 합성 및 렌더링합니다.

2. **Native Platforms (Windows / Android / iOS - `flutter_soloud`)**
   - 고성능 C++ 기반 SoLoud 오디오 엔진을 통해 네이티브 환경에서 즉각적인 단음 피킹, 코드 스트럼 및 사운드 효과를 재생합니다.
   - 단일 샘플 파일(`assets/sounds/*.wav`, `*.mp3`)이 위치하는 표준 경로입니다.

3. **VirtualBandSynth (PCM/WAV Pure Dart Sequencer)**
   - 4인조 가상 밴드(드럼, 베이스, 건반, 기타) 세션을 위한 실시간 PCM 합성 및 녹음된 연주의 무손실 WAV 파일 다운로드를 지원합니다.

---

## 📁 파일 배치 가이드 (File Conventions)

- **기타 현 단음 샘플**: `guitar_E2.wav` ~ `guitar_E6.wav` (표준 조율 6현 ~ 1현 전 프렛 피치)
- **포맷 권장 사항**:
  - Sample Rate: 44.1 kHz 또는 48 kHz
  - Bit Depth: 16-bit PCM WAV 또는 고음질 MP3 (320 kbps)
  - 채널: Stereo / Mono
