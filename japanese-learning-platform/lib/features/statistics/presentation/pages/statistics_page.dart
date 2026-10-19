/// 学习统计页面
///
/// 展示学习数据：总题数、正确率、连续天数、各等级进度、题型掌握情况、学习时长
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../redux/redux.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../core/theme/theme.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 学习统计页面
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StatisticsState>(
      converter: (store) => store.state.statistics,
      builder: (context, statsState) {
        if (statsState.loading) {
          return AppScaffold(
            appBar: AppBar(
              title: const Text('学习统计'),
            ),
            scrollable: true,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final stats = statsState.statistics ?? LearningStatistics.empty;

        return AppScaffold(
          appBar: AppBar(
            title: const Text('学习统计'),
          ),
          scrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 概览卡片
              _buildOverview(context, stats),

              // 学习时长
              _buildDuration(context, stats),

              // 等级进度
              _buildLevelProgress(context, stats),

              // 题型掌握
              _buildTypeMastery(context, stats),

              // 底部间距
              const SizedBox(height: AppSpacing.xxxxl),
            ],
          ),
        );
      },
    );
  }

  /// 概览卡片：总题数、正确率、连续天数
  Widget _buildOverview(BuildContext context, LearningStatistics stats) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ContentCard(
        child: Column(
          children: [
            Row(
              children: [
                _OverviewStat(
                  label: '总答题',
                  value: '${stats.totalAnswers}',
                  icon: Icons.quiz_outlined,
                  color: colorScheme.primary,
                ),
                _OverviewStat(
                  label: '正确率',
                  value: '${(stats.overallAccuracy * 100).toInt()}%',
                  icon: Icons.check_circle_outline,
                  color: colorScheme.secondary,
                ),
                _OverviewStat(
                  label: '连续天数',
                  value: '${stats.streakDays}',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: [
                _OverviewStat(
                  label: '练习次数',
                  value: '${stats.totalSessions}',
                  icon: Icons.library_books_outlined,
                  color: colorScheme.tertiary,
                ),
                _OverviewStat(
                  label: '错题数',
                  value: '${stats.wrongAnswerCount}',
                  icon: Icons.error_outline,
                  color: AppColors.error,
                ),
                _OverviewStat(
                  label: '待复习',
                  value: '${stats.dueReviewCount}',
                  icon: Icons.schedule,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 学习时长统计
  Widget _buildDuration(BuildContext context, LearningStatistics stats) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final totalMinutes = (stats.totalDurationMs / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('学习时长',
              style: TextStyle(
                fontSize: AppTypography.headlineSmall,
                fontWeight: AppTypography.semiBold,
              )),
          const SizedBox(height: AppSpacing.sm),
          ContentCard(
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hours > 0 ? '$hours 小时 $minutes 分钟' : '$minutes 分钟',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '总学习时长',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.favorite_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${stats.favoriteCount} 收藏',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 各等级进度
  Widget _buildLevelProgress(BuildContext context, LearningStatistics stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('各等级进度',
              style: TextStyle(
                fontSize: AppTypography.headlineSmall,
                fontWeight: AppTypography.semiBold,
              )),
          const SizedBox(height: AppSpacing.sm),
          ...stats.levelProgress
              .where((p) => p.totalQuestions > 0)
              .map((p) => _LevelProgressTile(progress: p)),
          if (stats.levelProgress.every((p) => p.totalQuestions == 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('暂无数据', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  /// 各题型掌握情况
  Widget _buildTypeMastery(BuildContext context, LearningStatistics stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('题型掌握',
              style: TextStyle(
                fontSize: AppTypography.headlineSmall,
                fontWeight: AppTypography.semiBold,
              )),
          const SizedBox(height: AppSpacing.sm),
          ...stats.typeMastery
              .where((m) => m.totalQuestions > 0)
              .map((m) => _TypeMasteryTile(mastery: m)),
          if (stats.typeMastery.every((m) => m.totalQuestions == 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('暂无数据', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

/// 概览统计项
class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 等级进度项
class _LevelProgressTile extends StatelessWidget {
  final LevelProgress progress;

  const _LevelProgressTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accuracy = progress.accuracy;
    final percentage = (accuracy * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlphaCompat(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    progress.level.displayName,
                    style: TextStyle(
                      fontSize: AppTypography.labelSmall,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.correctCount}/${progress.totalQuestions} · $percentage%',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 6,
                backgroundColor:
                    colorScheme.outline.withAlphaCompat(0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 题型掌握项
class _TypeMasteryTile extends StatelessWidget {
  final TypeMastery mastery;

  const _TypeMasteryTile({required this.mastery});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accuracy = mastery.accuracy;
    final percentage = (accuracy * 100).toInt();

    // 根据正确率选择颜色
    Color barColor;
    if (accuracy >= 0.8) {
      barColor = AppColors.success;
    } else if (accuracy >= 0.5) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mastery.type.displayNameZh,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const Spacer(),
                if (mastery.masteredCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlphaCompat(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '${mastery.masteredCount} 已掌握',
                      style: TextStyle(
                        fontSize: AppTypography.labelSmall,
                        color: AppColors.success,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$percentage%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 6,
                backgroundColor: colorScheme.outline.withAlphaCompat(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '总 ${mastery.totalQuestions} 题 · 正确 ${mastery.correctCount}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
