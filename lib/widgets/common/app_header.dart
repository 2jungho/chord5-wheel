import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../../providers/generator_state.dart';
import 'dialogs/changelog_dialog.dart';
import '../../utils/changelog_parser.dart';

/// 첫 글자를 영문 대문자로 강제 변환하는 포매터
class FirstLetterUppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      // 텍스트가 비어있을 때 시스템의 조합 영역(composing)이 남아있으면 에러가 발생할 수 있음
      if (newValue.composing.isValid) {
        return newValue.copyWith(composing: TextRange.empty);
      }
      return newValue;
    }

    final text = newValue.text;
    final uppercaseText = text[0].toUpperCase() + text.substring(1);

    // 텍스트가 이미 대문자로 시작하고 범위가 유효하다면 그대로 반환
    if (text == uppercaseText &&
        newValue.selection.end <= text.length &&
        newValue.composing.end <= text.length) {
      return newValue;
    }

    // 텍스트를 수정할 때는 조합 영역을 초기화하는 것이 안전함 (특히 웹/IME 환경)
    return newValue.copyWith(
      text: uppercaseText,
      selection: newValue.selection.copyWith(
        baseOffset:
            newValue.selection.baseOffset.clamp(0, uppercaseText.length),
        extentOffset:
            newValue.selection.extentOffset.clamp(0, uppercaseText.length),
      ),
      composing: TextRange.empty,
    );
  }
}

enum AppTab { explorer, generator, studio }

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final Function(AppTab) onTabChanged;
  final AppTab currentTab;
  final VoidCallback? onToggleChat;
  final VoidCallback? onOpenSettings;
  final bool isChatOpen;
  final bool hasApiKey;

  const AppHeader({
    super.key,
    required this.onTabChanged,
    required this.currentTab,
    this.onToggleChat,
    this.onOpenSettings,
    this.isChatOpen = false,
    this.hasApiKey = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(85);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late TextEditingController _searchController;
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadVersion();
  }

  // _handleRiffGenerator removed (Legacy)

  Future<void> _loadVersion() async {
    try {
      final items = await ChangelogParser.loadFromReadme();
      if (items.isNotEmpty) {
        if (mounted) {
          setState(() {
            _latestVersion = items.first.version;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load version: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    var text = _searchController.text;
    if (text.isNotEmpty) {
      // Auto-capitalize first letter for processing
      text = text[0].toUpperCase() + text.substring(1);
      context.read<GeneratorState>().analyzeChord(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final isUltraMobile = constraints.maxWidth < 400;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Section
              Row(
                children: [
                  Container(
                    width: isUltraMobile ? 32 : 40,
                    height: isUltraMobile ? 32 : 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isUltraMobile ? 4.0 : 6.0),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    if (widget.currentTab != AppTab.generator)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.currentTab == AppTab.explorer
                                ? 'Guitar & Theory'
                                : 'Music Studio',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            widget.currentTab == AppTab.explorer
                                ? 'Circle of Fifths'
                                : 'Chord Flow & Rhythm',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),

              // Search Bar (Visible only when Generator is active)
              if (widget.currentTab == AppTab.generator)
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              margin: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 24),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: isUltraMobile ? 14 : 16),
                                decoration: InputDecoration(
                                  hintText: isUltraMobile
                                      ? 'Chord...'
                                      : (isMobile
                                          ? 'Chord (영문)...'
                                          : 'Enter chord (영문 입력 e.g. Cmaj7)...'),
                                  hintStyle: TextStyle(
                                      color: Theme.of(context).hintColor),
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 0),
                                  prefixIcon: isUltraMobile
                                      ? null
                                      : Icon(Icons.search,
                                          color: Theme.of(context).hintColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.arrow_forward,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: _handleAnalyze,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(
                                        color: Theme.of(context).dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 1.5),
                                  ),
                                ),
                                onSubmitted: (_) => _handleAnalyze(),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                          ),
                          if (RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]')
                                  .hasMatch(_searchController.text) &&
                              !isMobile)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.g_translate_rounded,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '한/영 키를 눌러 영문으로 변경하세요',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Spacer(), // Spacer to push Tab Buttons to right

              // Tab Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: isMobile ? '탐색' : '5도권 탐색기',
                      isActive: widget.currentTab == AppTab.explorer,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onTap: () => widget.onTabChanged(AppTab.explorer),
                      compact: isUltraMobile,
                    ),
                    const SizedBox(width: 4),
                    _TabButton(
                      label: isMobile ? '분석' : '코드 분석',
                      isActive: widget.currentTab == AppTab.generator,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      onTap: () => widget.onTabChanged(AppTab.generator),
                      compact: isUltraMobile,
                    ),
                    const SizedBox(width: 4),
                    _TabButton(
                      label: isMobile ? '진행' : '코드진행',
                      isActive: widget.currentTab == AppTab.studio,
                      activeColor: Theme.of(context).colorScheme.tertiary,
                      onTap: () => widget.onTabChanged(AppTab.studio),
                      compact: isUltraMobile,
                    ),
                  ],
                ),
              ),

              SizedBox(width: isUltraMobile ? 4 : (isMobile ? 8 : 16)),

              // AI Chat Button
              if (widget.hasApiKey) ...[
                SizedBox(
                  width: isUltraMobile ? 32 : 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.isChatOpen
                          ? Icons.chat_bubble
                          : Icons.auto_awesome,
                      size: isUltraMobile ? 20 : 24,
                      color: widget.isChatOpen
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).iconTheme.color,
                    ),
                    tooltip: 'AI Theory Tutor',
                    onPressed: widget.onToggleChat,
                  ),
                ),
              ],

              // Settings Menu (Drawer Trigger)
              SizedBox(
                width: isUltraMobile ? 32 : 48,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.menu,
                      size: isUltraMobile ? 20 : 24,
                      color: Theme.of(context).iconTheme.color),
                  tooltip: '설정 및 메뉴',
                  onPressed: widget.onOpenSettings,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool compact;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
