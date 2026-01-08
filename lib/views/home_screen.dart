import 'package:flutter/material.dart';

import '../widgets/common/app_header.dart';
import '../widgets/common/settings_drawer.dart';

import 'explorer/explorer_view.dart';
import 'generator/generator_view.dart';
import 'studio/studio_view.dart';
import '../widgets/ai_chat/ai_chat_panel.dart';
import 'package:provider/provider.dart';
import '../providers/settings_state.dart';

/// 앱의 메인 화면입니다.
/// 상단 헤더(AppHeader)를 통해 탭(Explorer/Generator)을 전환하고,
/// 선택된 탭에 맞는 뷰를 본문에 표시합니다.
class HomeScreen extends StatefulWidget {
  // 초기 탭 설정 (URL 파라미터 등에서 전달받음)
  final String? initialTab;

  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 현재 활성화된 탭
  AppTab _currentTab = AppTab.explorer;

  // AI 채팅 패널 열림 여부
  bool _isAIChatOpen = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // 초기 탭 설정
    if (widget.initialTab == 'generator') {
      _currentTab = AppTab.generator;
    } else if (widget.initialTab == 'studio') {
      _currentTab = AppTab.studio;
    }
  }

  @override
  Widget build(BuildContext context) {
    // API Key가 있는지 확인 (Provider에 맞는 키 확인)
    final settings = context.watch<SettingsState>();
    final hasApiKey = settings.aiProvider == 'gemini'
        ? settings.geminiApiKey.isNotEmpty
        : settings.openAiApiKey.isNotEmpty;

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 900;

      Widget mainContent;
      switch (_currentTab) {
        case AppTab.explorer:
          mainContent = const ExplorerView();
          break;
        case AppTab.generator:
          mainContent = const GeneratorView();
          break;
        case AppTab.studio:
          mainContent = const StudioView();
          break;
      }

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 앱 전체 배경색
        endDrawer: const SettingsDrawer(), // 설정 Drawer 추가
        // 상단 헤더 (네비게이션 바 역할)
        appBar: AppHeader(
          currentTab: _currentTab,
          onTabChanged: (tab) => setState(() => _currentTab = tab),
          onToggleChat: () {
            setState(() {
              _isAIChatOpen = !_isAIChatOpen;
            });
          },
          onOpenSettings: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          isChatOpen: _isAIChatOpen,
          hasApiKey: hasApiKey,
        ),

        // 탭 상태에 따라 ExplorerView 또는 GeneratorView 표시
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0F172A), // Slate 900
                      const Color(0xFF1E1B4B), // Indigo 950
                      const Color(0xFF312E81), // Indigo 900
                    ]
                  : [
                      const Color(0xFFF8FAFC), // Slate 50
                      const Color(0xFFE0E7FF), // Indigo 100
                      const Color(0xFFDBEAFE), // Blue 100
                    ],
            ),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: mainContent),
                    if (_isAIChatOpen)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 16, right: 16, bottom: 16),
                        child: AIChatPanel(
                            onClose: () =>
                                setState(() => _isAIChatOpen = false)),
                      ),
                  ],
                )
              : Stack(
                  children: [
                    mainContent,
                    if (_isAIChatOpen)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: constraints.maxWidth * 0.85 > 400
                            ? 400
                            : constraints.maxWidth * 0.85,
                        child: Material(
                          elevation: 16,
                          shadowColor: Colors.black54,
                          child: AIChatPanel(
                              onClose: () =>
                                  setState(() => _isAIChatOpen = false)),
                        ),
                      ),
                  ],
                ),
        ),
        floatingActionButton: (!_isAIChatOpen && hasApiKey)
            ? FloatingActionButton(
                onPressed: () => setState(() => _isAIChatOpen = true),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Icon(Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.tertiary),
                tooltip: 'AI 튜터 열기',
              )
            : null,
      );
    });
  }
}
