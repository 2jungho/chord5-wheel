import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lick_vault_state.dart';
import '../../providers/studio_state.dart';
import 'components/lick_filter_bar.dart';
import 'components/lick_card_list.dart';
import 'components/interactive_tab_viewer.dart';
import 'components/lick_theory_panel.dart';
import 'components/lick_action_bar.dart';

/// 아티스트 릭 보관함 및 인터랙티브 TAB / 화성 분석 바텀시트
class ArtistLickVaultSheet extends StatelessWidget {
  const ArtistLickVaultSheet({super.key});

  static void show(BuildContext context) {
    // 릭 보관함 초기화 및 스튜디오 세션 키 동기화
    final vault = context.read<LickVaultState>();
    final studioKey = context.read<StudioState>().session.key;
    vault.initialize();
    vault.syncKey(studioKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ArtistLickVaultSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vault = context.watch<LickVaultState>();
    final activeLick = vault.currentTransposedLick;
    final analysis = vault.harmonicAnalysis;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 드래그 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // 헤더 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Artist Lick Vault',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Key: ${vault.activeKey}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 메인 스크롤 콘텐츠
          Expanded(
            child: vault.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('아티스트 및 릭 데이터를 불러오는 중...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 장르 / 아티스트 / 태그 필터 바
                        LickFilterBar(vault: vault),
                        const SizedBox(height: 16),

                        // 2. 릭 카드 가로 스크롤 목록
                        LickCardList(vault: vault),
                        const SizedBox(height: 20),

                        // 3. 대화형 TAB 뷰어 & 5대 Box 스위처
                        InteractiveTabViewer(vault: vault, activeLick: activeLick),
                        const SizedBox(height: 20),

                        // 4. 화성 분석 및 연주 팁 카드
                        LickTheoryPanel(lick: activeLick, analysis: analysis),
                      ],
                    ),
                  ),
          ),

          // 하단 플레이백 & 액션 컨트롤 바
          LickActionBar(vault: vault),
        ],
      ),
    );
  }
}
