/// 个人中心页面
///
/// 星野京都风格 × Material Design 3
/// 全幅沉浸式布局 + 极端留白 + 轻盈字体
/// 枯山水波纹装饰，简洁信息展示
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_illustrations.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// 个人中心页面
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
          backgroundColor: AppColors.washi,
          scrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 全幅 Hero 区域 - 枯山水
              HeroImageArea(
                height: 360,
                primaryColor: AppColors.primary,
                illustration: KaresansuiPattern(
                  width: 280,
                  height: 140,
                  color: const Color(0xFF9E9E9E),
                ),
                overlayText: '私のページ',
              ),

              // 标题区域
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxxxl,
                  80,
                  AppSpacing.xxxxl,
                  60,
                ),
                child: Text(
                  '我的',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: AppColors.sumi,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // 用户信息 - 简洁展示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
                child: _buildUserInfoSection(user),
              ),

              const SizedBox(height: 80),

              // 学习统计
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习统计',
                      style: TextStyle(
                        fontFamily: AppTypography.serifFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.sumiLighter,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildLearningStats(context, statsState),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // 功能入口
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能',
                      style: TextStyle(
                        fontFamily: AppTypography.serifFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.sumiLighter,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFeatureEntry(
                      title: '错题本',
                      subtitle: '回顾答错的题目',
                      onTap: () => AppRouter.goToWrongBook(context),
                    ),
                    _buildFeatureEntry(
                      title: '学习统计',
                      subtitle: '查看完整学习数据',
                      onTap: () => AppRouter.goToStatistics(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // 设置
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设置',
                      style: TextStyle(
                        fontFamily: AppTypography.serifFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.sumiLighter,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSettingItem(
                      title: '外观',
                      subtitle: _getThemeModeText(themeMode),
                      onTap: () => StoreProvider.of<AppState>(context)
                          .dispatch(toggleThemeMode()),
                    ),
                    _buildSettingItem(
                      title: '语言',
                      subtitle: '简体中文',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      title: '通知',
                      subtitle: '已开启',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      title: '帮助中心',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      title: '关于',
                      subtitle: 'v1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user?.name ?? '学习者',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.sumi,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '当前等级：${user?.currentLevel.displayName ?? 'N5'}',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: AppColors.sumiLighter,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStats(BuildContext context, StatisticsState statsState) {
    if (statsState.loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _renderLearningStats(statsState.statistics);
  }

  Widget _renderLearningStats(LearningStatistics? stats) {
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

    return GestureDetector(
      onTap: () {
        // TODO: 导航到统计详情页
      },
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              value: '$totalQuestions',
              label: '总题数',
              color: AppColors.primary,
            ),
          ),
          Container(width: 0.5, height: 60, color: AppColors.washiBorder),
          Expanded(
            child: _buildStatItem(
              value: '$accuracy%',
              label: '正确率',
              color: AppColors.kincha,
            ),
          ),
          Container(width: 0.5, height: 60, color: AppColors.washiBorder),
          Expanded(
            child: _buildStatItem(
              value: duration,
              label: '学习时长',
              color: AppColors.sumire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.serifFontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: color,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.sumiLighter,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureEntry({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.washiBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.sumi,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.sumiLighter,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.sumiLighter.withOpacity(0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.washiBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.sumi,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.sumiLighter,
                  letterSpacing: 1,
                ),
              ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.sumiLighter.withOpacity(0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }
}
