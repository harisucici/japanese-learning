/// 个人中心页面
/// 
/// 展示用户信息、学习统计和设置入口
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/models.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 个人中心页面组件
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      distinct: true,
      builder: (context, state) {
        final user = state.auth.user;
        final themeMode = state.themeMode;
        final statsState = state.statistics;
        final stats = statsState.statistics;

        return AppScaffold(
          scrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildUserInfoCard(context, user),
              _buildLearningStats(context, statsState),
              const SectionHeader(title: '功能入口'),
              _buildFeatureEntries(context),
              const SectionHeader(title: '设置'),
              _buildSettingsList(context, themeMode),
              const SizedBox(height: AppSpacing.xxxxl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Text(
        '我的',
        style: textTheme.displayLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, User? user) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ContentCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                Icons.person,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? '学习者',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '当前等级：${user?.currentLevel.displayName ?? 'N5'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.edit_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningStats(
      BuildContext context, StatisticsState statsState) {
    if (statsState.loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _renderLearningStats(context, statsState.statistics);
  }

  Widget _renderLearningStats(
      BuildContext context, LearningStatistics? stats) {
    final totalQuestions = stats?.totalAnswers ?? 0;
    final accuracy = ((stats?.overallAccuracy ?? 0.0) * 100).toInt();
    final totalMinutes = (stats?.totalDurationMs ?? 0) ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    String duration;
    if (hours > 0) {
      duration = '${hours}h${minutes}m';
    } else {
      duration = '${minutes}m';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: GestureDetector(
        onTap: () => AppRouter.goToStatistics(context),
        child: ContentCard(
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context: context,
                  value: '$totalQuestions',
                  label: '总题数',
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  value: '$accuracy%',
                  label: '正确率',
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  value: duration,
                  label: '学习时长',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outline.withAlphaCompat(0.3),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String value,
    required String label,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: AppTypography.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureEntries(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final entries = [
      _FeatureEntry(
        icon: Icons.bookmark_outline,
        iconColor: colorScheme.error,
        title: '错题本',
        subtitle: '回顾答错的题目',
        onTap: () => AppRouter.goToWrongBook(context),
      ),
      _FeatureEntry(
        icon: Icons.bar_chart_rounded,
        iconColor: colorScheme.primary,
        title: '学习统计',
        subtitle: '查看完整学习数据',
        onTap: () => AppRouter.goToStatistics(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ContentCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: entries
              .map((entry) => ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: entry.iconColor.withAlphaCompat(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(entry.icon, color: entry.iconColor, size: 20),
                    ),
                    title: Text(
                      entry.title,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    subtitle: Text(
                      entry.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: entry.onTap,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, ThemeMode currentThemeMode) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String themeModeText;
    switch (currentThemeMode) {
      case ThemeMode.system:
        themeModeText = '跟随系统';
        break;
      case ThemeMode.light:
        themeModeText = '浅色';
        break;
      case ThemeMode.dark:
        themeModeText = '深色';
        break;
    }

    final settings = [
      _SettingsItem(
        icon: Icons.palette_outlined,
        title: '外观',
        subtitle: themeModeText,
        onTap: () => StoreProvider.of<AppState>(context).dispatch(toggleThemeMode()),
      ),
      _SettingsItem(
        icon: Icons.language,
        title: '语言',
        subtitle: '简体中文',
        onTap: () {},
      ),
      _SettingsItem(
        icon: Icons.notifications_outlined,
        title: '通知',
        subtitle: '已开启',
        onTap: () {},
      ),
      _SettingsItem(
        icon: Icons.help_outline,
        title: '帮助中心',
        onTap: () {},
      ),
      _SettingsItem(
        icon: Icons.info_outline,
        title: '关于',
        subtitle: 'v1.0.0',
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ContentCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: settings.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    item.title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: item.onTap,
                ),
                if (index < settings.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.xxl + AppSpacing.lg,
                    color: colorScheme.outline.withAlphaCompat(0.2),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}

class _FeatureEntry {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureEntry({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
