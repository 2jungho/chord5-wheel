import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:url_strategy/url_strategy.dart';

import 'providers/music_state.dart';
import 'providers/generator_state.dart';
import 'providers/settings_state.dart';
import 'providers/chat_state.dart';
import 'providers/studio_state.dart';

import 'views/home_screen.dart';

import 'audio/audio_manager.dart';
import 'utils/app_theme.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// 앱의 진입점입니다.
/// Flutter 바인딩 초기화, 오디오 매니저 초기화 후 앱을 실행합니다.
void main() async {
  // URL에서 '#' 제거 (PathUrlStrategy 사용)
  setPathUrlStrategy();

  // 비동기 초기화를 위한 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크톱 윈도우 설정 (모바일/웹 제외)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1600, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 닫기 버튼 클릭 시 바로 종료되지 않고 이벤트를 받도록 설정
      await windowManager.setPreventClose(true);
    });
  }

  // 오디오 엔진 (SoundFont 등) 로드
  await AudioManager().initialize();

  runApp(const MyApp());
}

// GoRouter 설정
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        // 쿼리 파라미터 `?tab=generator` 처리
        // 예: 웹에서 특정 탭으로 바로 진입할 때 유용함
        final tab = state.uri.queryParameters['tab'];
        return HomeScreen(initialTab: tab);
      },
    ),
  ],
);

/// 최상위 위젯입니다.
/// Provider 설정, 테마 설정, 라우터 설정을 담당합니다.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    // 윈도우 이벤트 리스너 등록
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    // 윈도우 이벤트 리스너 해제
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // 앱 종료 시 리소스 정리
    AudioManager().dispose();

    // 윈도우 리소스 파괴 (앱 종료)
    // 약간의 딜레이를 주어 오디오 엔진이 정리될 시간을 확보하는 것이 안전함
    // await Future.delayed(const Duration(milliseconds: 100)); // 필요 시 주석 해제
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider를 통해 앱 전역에서 사용할 상태(State)를 주입합니다.
    return MultiProvider(
      providers: [
        // MusicState: 화성학적 계산 및 선택 상태 관리
        ChangeNotifierProvider(create: (_) => MusicState()),
        // GeneratorState: 코드 생성기 탭 상태 관리
        ChangeNotifierProvider(create: (_) => GeneratorState()),
        ChangeNotifierProvider(create: (_) => ChatState()),
        // SettingsState: 앱 설정 관리 (볼륨, 왼손잡이 모드 등)
        ChangeNotifierProvider(create: (_) => SettingsState()),
        // StudioState: 코드 스튜디오 상태 관리
        ChangeNotifierProvider(create: (_) => StudioState()),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Guitar & Theory Explorer',
            scrollBehavior: const AppScrollBehavior(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
