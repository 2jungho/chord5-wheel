# Theme System Migration Plan

## 1. 개요 (Overview)
* **목표**: 하드코딩된 색상 상수(`AppColors`)를 제거하고, Flutter의 `ThemeData`를 기반으로 한 동적 테마 시스템을 도입하여 라이트/다크 모드 및 커스텀 테마 확장을 가능하게 함.
* **대상**: `lib/widgets/common/app_colors.dart` 및 색상을 직접 사용하는 모든 위젯 파일.

## 2. 작업 절차 (Workflow)

### Step 1: AppTheme 클래스 정의 (Define Theme)
* `lib/providers/theme_provider.dart` (또는 `settings_state.dart` 확장) 생성.
* `ThemeData`를 반환하는 정적 메서드 정의:
    * `static ThemeData get lightTheme`
    * `static ThemeData get darkTheme`
* 기존 `AppColors`의 색상을 `ColorScheme` (primary, secondary, surface, background 등)에 매핑.

### Step 2: 상태 관리 연동 (State Management)
* `SettingsState` (또는 `ThemeState`)에 `ThemeMode` 변수 추가 (`system`, `light`, `dark`).
* `MaterialApp` 위젯(보통 `main.dart`)에 `theme`, `darkTheme`, `themeMode` 속성 연결.
    ```dart
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode, // Provider 값 연결
      ...
    )
    ```

### Step 3: 위젯 마이그레이션 (Migrate Widgets) - 가장 큰 작업
* 프로젝트 전체에서 `AppColors.xxxx` 참조를 검색.
* 하드코딩된 색상을 `Theme.of(context)` 또는 `context.read<Theme...>()` 형식으로 변경.
    * **Before**: `color: AppColors.bgPrimary`
    * **After**: `color: Theme.of(context).colorScheme.background`
    * **Before**: `style: TextStyle(color: Colors.white)`
    * **After**: `style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)`

### Step 4: 설정 UI 추가 (Update Settings Dialog)
* `SettingsDialog.dart`에 "테마 설정" 섹션 추가.
* 라디오 버튼 또는 토글 스위치로 "라이트 모드 / 다크 모드 / 시스템 설정" 선택 기능 구현.

## 3. 파일 구조 변경 (Structure)
```
lib/
  utils/
    app_theme.dart       ← (New) 라이트/다크 테마 정의
  providers/
    settings_state.dart  ← (Update) ThemeMode 상태 추가
  widgets/
    common/
      app_colors.dart    ← (Deprecate) 점진적 제거 또는 Palette로 용도 변경
```

## 4. 검증 (Validation)
* 설정에서 테마 변경 시 즉시 앱 전체 색상이 반전되는지 확인.
* 앱 재실행 시 설정된 테마가 유지되는지 확인 (Shared Preferences 확인).
