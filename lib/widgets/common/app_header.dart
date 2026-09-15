import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/navigation/app_tab.dart';
import '../../providers/generator_state.dart';
import '../../providers/settings_state.dart';
import '../../utils/app_theme.dart';
import '../../utils/changelog_parser.dart';
import '../lick/artist_lick_vault_sheet.dart';

export '../../models/navigation/app_tab.dart';

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
  Size get preferredSize => const Size.fromHeight(60);

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

  Future<void> _loadVersion() async {
    try {
      final items = await ChangelogParser.loadFromReadme();
      if (items.isNotEmpty && mounted) {
        setState(() {
          _latestVersion = items.first.version;
        });
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
      text = text[0].toUpperCase() + text.substring(1);
      context.read<GeneratorState>().analyzeChord(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final isUltraMobile = constraints.maxWidth < 400;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLogoSection(context, isMobile, isUltraMobile),
                if (widget.currentTab == AppTab.generator)
                  _buildSearchBar(context, isMobile, isUltraMobile)
                else
                  const Spacer(),
                _buildThemeSelector(context, isUltraMobile),
                const SizedBox(width: 8),
                _buildTabButtons(context, isMobile, isUltraMobile),
                SizedBox(width: isUltraMobile ? 4 : (isMobile ? 8 : 16)),
                _buildActionButtons(context, isMobile, isUltraMobile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoSection(
      BuildContext context, bool isMobile, bool isUltraMobile) {
    return Row(
      children: [
        Container(
          width: isUltraMobile ? 30 : 36,
          height: isUltraMobile ? 30 : 36,
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
            padding: EdgeInsets.all(isUltraMobile ? 3.0 : 5.0),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 10),
          if (widget.currentTab != AppTab.generator)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.currentTab == AppTab.explorer
                      ? 'Guitar & Theory'
                      : 'Music Studio',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.currentTab == AppTab.explorer ? 'Circle of Fifths' : 'Chord Flow & Rhythm'}${_latestVersion.isNotEmpty ? '  ${_latestVersion.startsWith('v') ? _latestVersion : 'v$_latestVersion'}' : ''}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(
      BuildContext context, bool isMobile, bool isUltraMobile) {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  margin:
                      EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isUltraMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      hintText: isUltraMobile
                          ? 'Chord...'
                          : (isMobile
                              ? 'Chord (영문)...'
                              : 'Enter chord (영문 입력 e.g. Cmaj7)...'),
                      hintStyle:
                          TextStyle(color: Theme.of(context).hintColor),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      prefixIcon: isUltraMobile
                          ? null
                          : Icon(Icons.search,
                              color: Theme.of(context).hintColor),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.primary),
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
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
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
                          color: Theme.of(context).colorScheme.error,
                          size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '한/영 키를 눌러 영문으로 변경하세요',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
    );
  }

  Widget _buildThemeSelector(BuildContext context, bool isUltraMobile) {
    return Builder(builder: (context) {
      final settings = context.watch<SettingsState>();
      final currentTheme = settings.themePreset;

      return PopupMenuButton<AppThemePreset>(
        initialValue: currentTheme,
        tooltip: '테마 선택 (Theme Palette)',
        onSelected: (preset) {
          settings.setThemePreset(preset);
        },
        offset: const Offset(0, 40),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        itemBuilder: (context) {
          return AppThemePreset.values.map((preset) {
            final isSelected = preset == currentTheme;
            return PopupMenuItem<AppThemePreset>(
              value: preset,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.primaryAccent,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isUltraMobile ? 6 : 10,
            vertical: isUltraMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentTheme.primaryAccent,
                ),
              ),
              if (!isUltraMobile) ...[
                const SizedBox(width: 6),
                Text(
                  currentTheme.shortName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabButtons(
      BuildContext context, bool isMobile, bool isUltraMobile) {
    return Container(
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
    );
  }

  Widget _buildActionButtons(
      BuildContext context, bool isMobile, bool isUltraMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Artist Lick Vault Button
        SizedBox(
          width: isUltraMobile ? 32 : 44,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.electric_bolt,
              size: isUltraMobile ? 20 : 22,
              color: Colors.amber,
            ),
            tooltip: '아티스트 릭 보관함 (Hendrix, Clapton, SRV, Moore)',
            onPressed: () => ArtistLickVaultSheet.show(context),
          ),
        ),

        // AI Chat Button
        if (widget.hasApiKey)
          SizedBox(
            width: isUltraMobile ? 32 : 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                widget.isChatOpen ? Icons.chat_bubble : Icons.auto_awesome,
                size: isUltraMobile ? 20 : 24,
                color: widget.isChatOpen
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).iconTheme.color,
              ),
              tooltip: 'AI Theory Tutor',
              onPressed: widget.onToggleChat,
            ),
          ),

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
            EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? const [
                  BoxShadow(
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
