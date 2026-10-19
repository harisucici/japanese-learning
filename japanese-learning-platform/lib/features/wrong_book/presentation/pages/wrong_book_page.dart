/// 错题本页面
///
/// 展示所有答错的题目，支持按等级/题型筛选、按错误次数排序
/// 点击题目可进入重新答题模式
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../redux/redux.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/jlpt_level_selector.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_constants.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 错题本页面
class WrongBookPage extends StatelessWidget {
  const WrongBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, WrongBookState>(
      converter: (store) => store.state.wrongBook,
      builder: (context, wrongBookState) {
        return AppScaffold(
          appBar: AppBar(
            title: const Text('错题本'),
            actions: [
              PopupMenuButton<WrongBookSort>(
                icon: const Icon(Icons.sort),
                onSelected: (sort) {
                  StoreProvider.of<AppState>(context)
                      .dispatch(WrongBookSortChanged(sort));
                },
                itemBuilder: (context) => WrongBookSort.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ))
                    .toList(),
              ),
            ],
          ),
          scrollable: false,
          body: Column(
            children: [
              // 等级筛选
              _buildLevelFilter(context, wrongBookState),

              // 题型筛选
              _buildTypeFilter(context, wrongBookState),

              // 统计摘要
              _buildStatsSummary(context, wrongBookState.filteredItems),

              // 错题列表
              Expanded(
                child: _buildWrongList(context, wrongBookState.filteredItems),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 等级筛选器
  Widget _buildLevelFilter(BuildContext context, WrongBookState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: JlptLevelSelector(
        selectedLevel: state.levelFilter?.displayName ?? '全部',
        onLevelChanged: (level) {
          final store = StoreProvider.of<AppState>(context);
          if (level == '全部') {
            store.dispatch(WrongBookLevelFilterChanged(null));
          } else {
            store.dispatch(WrongBookLevelFilterChanged(JLPTLevel.fromString(level)));
          }
        },
        levels: ['全部', ...AppConstants.jlptLevels],
      ),
    );
  }

  /// 题型筛选器
  Widget _buildTypeFilter(BuildContext context, WrongBookState state) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: QuestionType.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final store = StoreProvider.of<AppState>(context);
          if (index == 0) {
            return _TypeChip(
              label: '全部题型',
              isSelected: state.typeFilter == null,
              onTap: () => store.dispatch(WrongBookTypeFilterChanged(null)),
            );
          }
          final type = QuestionType.values[index - 1];
          return _TypeChip(
            label: type.displayNameZh,
            isSelected: state.typeFilter == type,
            onTap: () => store.dispatch(WrongBookTypeFilterChanged(type)),
          );
        },
      ),
    );
  }

  /// 统计摘要
  Widget _buildStatsSummary(BuildContext context, List<ReviewItem> items) {
    final totalWrong = items.fold<int>(0, (s, i) => s + i.wrongCount);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ContentCard(
        child: Row(
          children: [
            _StatItem(
              label: '错题数',
              value: '${items.length}',
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.lg),
            _StatItem(
              label: '总错误次数',
              value: '$totalWrong',
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.lg),
            _StatItem(
              label: '待复习',
              value: '${items.where((i) => i.isDue).length}',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 错题列表
  Widget _buildWrongList(BuildContext context, List<ReviewItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: '暂无错题',
        subtitle: '继续做题，错题会自动收录到这里',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _WrongItemCard(
          item: item,
          onTap: () {
            // 导航到答题页面，进入重新答题模式
            context.push('/quiz/${item.level.name.toUpperCase()}');
          },
        );
      },
    );
  }
}

/// 题型筛选标签
class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.medium,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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

/// 错题卡片
class _WrongItemCard extends StatelessWidget {
  final ReviewItem item;
  final VoidCallback onTap;

  const _WrongItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuestionsState>(
      converter: (store) => store.state.questions,
      builder: (context, questionsState) {
        final question = questionsState.questionsById[item.questionId];

        return ContentCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：等级 + 题型 + 错误次数
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlphaCompat(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '${item.level.displayName} · ${item.type.displayNameZh}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppTypography.labelSmall,
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '错${item.wrongCount}次',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppTypography.bodySmall,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 题目内容
              if (question == null)
                const Text('题目未找到')
              else
                Text(
                  question.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),

              // 底部：复习状态 + 操作提示
              Row(
                children: [
                  Icon(
                    item.isDue ? Icons.schedule : Icons.check_circle_outline,
                    size: 14,
                    color: item.isDue ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    item.isDue ? '待复习' : '已复习',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppTypography.labelSmall,
                      color: item.isDue ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '点击重新答题',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppTypography.labelSmall,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
