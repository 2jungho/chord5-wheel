class ChangelogItem {
  final String version;
  final String date;
  final List<String> changes;

  const ChangelogItem({
    required this.version,
    required this.date,
    required this.changes,
  });
}

const List<ChangelogItem> changelogData = [
  ChangelogItem(
    version: 'v1.0.7',
    date: '2025-12-18',
    changes: [
      '📱 Mobile Optimization: 스마트 레이아웃 적용 (좁은 화면 자동 세로 배치)',
      '📜 Scrollable Fretboard: 프렛보드 가로 스크롤 및 마우스 드래그 지원',
      '🐛 Chord Fix: CMaj7 등의 코드가 Dominant 7으로 잘못 인식되던 오류 수정',
    ],
  ),
  ChangelogItem(
    version: 'v1.0.6',
    date: '2025-12-17',
    changes: [
      '🎸 Fretboard Controls: 인터벌 필터링, CAGED 폼 포커스 기능 추가',
      '🔬 Zone Filtering: 최적의 CAGED 영역 자동 선택 로직 개선',
      '📏 Expanded Range: 프렛보드 표시 범위를 0-17 프렛으로 확장',
    ],
  ),
  ChangelogItem(
    version: 'v1.0.5',
    date: '2025-12-16',
    changes: [
      '🎼 Guide Tones: 코드 핵심음(3th, 7th) 시각적 강조 기능 적용',
      '🎨 Visualization: 코드 다이어그램 시인성 개선 (흰색 테두리 추가)',
      '🐛 Bug Fix: Ionian 모드 특성음 수정 및 긴 코드명 표시 오류 해결',
    ],
  ),
  ChangelogItem(
    version: 'v1.0.2 ~ v1.0.4',
    date: '2025-12-15',
    changes: [
      '🧩 CAGED System: 탐색기 하단 리스트 상호작용 및 하이라이트 추가',
      '🩹 Hotfixes: Lydian #4 인터벌 표기 수정, 모바일 브라우저 호환성 개선',
      '🖥️ Desktop: Windows 종료 시 좀비 프로세스 방지 처리',
    ],
  ),
];
