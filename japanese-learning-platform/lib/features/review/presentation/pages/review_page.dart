/// 复习页面
///
/// 基于艾宾浩斯遗忘曲线的智能复习系统
/// 展示待复习项目、复习统计和复习进度
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../redux/redux.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/theme/theme.dart';

import '../pages/review_session_page.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 复习页面组件
///
/// 展示复习相关数据：
/// - 今日待复习数量
/// - 连续复习天数
/// - 各 JLPT 等级复习进度
/// - 最近复习记录
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ReviewState>(
      converter: (store) => store.state.review,
      builder: (context, reviewState) {
        final dueItems = reviewState.dueItems;
        final statsState = StoreProvider.of<AppState>(context).state.statistics;
        final stats = statsState.statistics;

        return AppScaffold(
          scrollable: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              _buildHeader(context),

              // 复习统计概览
              _buildStatsOverview(context, stats),

              // 待复习列表
              const SectionHeader(title: '待复习'),
              _buildPendingReviewList(context, dueItems),

              // 底部间距
              const SizedBox(height: AppSpacing.xxxxl),
            ],
          ),
        );
      },
    );
  }

  /// 构建页面头部
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
        '复习',
        style: textTheme.displayLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  /// 构建复习统计概览
  ///
  /// 三列展示：今日待复习、连续天数、总复习次数
  Widget _buildStatsOverview(
    BuildContext context,
    LearningStatistics? stats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ContentCard(
        child: Row(
          children: [
            _buildStatItem(
              context: context,
              value: '${stats?.dueReviewCount ?? 0}',
              label: '待复习',
              color: colorScheme.error,
            ),
            _buildStatDivider(context),
            _buildStatItem(
              context: context,
              value: '${stats?.streakDays ?? 0}',
              label: '连续天数',
              color: colorScheme.primary,
            ),
            _buildStatDivider(context),
            _buildStatItem(
              context: context,
              value: '${stats?.totalReviews ?? 0}',
              label: '总复习',
              color: colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required BuildContext context,
    required String value,
    required String label,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.displayMedium?.copyWith(
              color: color,
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
      ),
    );
  }

  /// 构建统计项之间的分割线
  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outline.withAlphaCompat(0.3),
    );
  }

  /// 导航到复习会话页面
  void _navigateToReviewSession(
    BuildContext context,
    List<ReviewItem> items,
  ) {
    if (items.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionPage(
          items: items,
          mode: ReviewMode.originalOnly,
        ),
      ),
    );
  }

  /// 构建待复习列表（按 JLPT 等级分组）
  Widget _buildPendingReviewList(
    BuildContext context,
    List<ReviewItem> dueItems,
  ) {
    if (dueItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: '暂无待复习项',
          subtitle: '所有复习任务已完成，继续做题保持手感吧',
        ),
      );
    }

    // 按等级分组
    final grouped = <JLPTLevel, List<ReviewItem>>{};
    for (final item in dueItems) {
      grouped.putIfAbsent(item.level, () => <ReviewItem>[]).add(item);
    }
    // 按等级顺序（N5 -> N1）展示
    final levels = grouped.keys.toList()
      ..sort((a, b) => a.numericValue.compareTo(b.numericValue));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (final level in levels)
            _buildLevelGroup(context, level, grouped[level]!),
        ],
      ),
    );
  }

  /// 构建单个等级的待复习分组
  Widget _buildLevelGroup(
    BuildContext context,
    JLPTLevel level,
    List<ReviewItem> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 按题型再细分统计
    final typeCounts = <QuestionType, int>{};
    for (final item in items) {
      typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;
    }
    final typeSummary = typeCounts.entries
        .map((e) => '${e.key.displayNameZh} ${e.value}')
        .join(' · ');

    // 紧急程度：存在 overdue 项则为紧急
    final now = DateTime.now();
    final hasOverdue = items.any((i) {
      final next = i.nextReviewAt;
      if (next == null) return false;
      return now.difference(next).inDays >= 1;
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContentCard(
        onTap: () => _navigateToReviewSession(context, items),
        child: Row(
          children: [
            // 紧急程度指示器
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: hasOverdue ? colorScheme.error : colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${level.displayName} 复习',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${items.length} 项 · $typeSummary',
                    style: textTheme.bodySmall?.copyWith(
                      color: hasOverdue
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 开始按钮
            TextButton(
              onPressed: () => _navigateToReviewSession(context, items),
              child: const Text('开始'),
            ),
          ],
        ),
      ),
    );
  }
}
