/// 练习页面
/// 
/// 按 JLPT 等级和题型浏览练习内容
/// 支持等级筛选和分类展示
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../shared/widgets/jlpt_level_selector.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_router.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 练习页面组件
/// 
/// 按 JLPT 等级分类展示练习内容：
/// - 顶部：等级选择器
/// - 中部：题型分类（词汇、语法、阅读、听力）
/// - 下部：推荐练习列表
class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  /// 当前选中的 JLPT 等级
  String _selectedLevel = 'N5';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          _buildHeader(context),
          
          // 等级选择器
          JlptLevelSelector(
            selectedLevel: _selectedLevel,
            onLevelChanged: (level) {
              setState(() => _selectedLevel = level);
            },
          ),
          
          // 题型分类
          const SectionHeader(title: '题型分类'),
          _buildCategoryGrid(context),
          
          // 推荐练习
          const SectionHeader(title: '推荐练习'),
          _buildRecommendedList(context),
          
          // 底部间距
          const SizedBox(height: AppSpacing.xxxxl),
        ],
      ),
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
        '练习',
        style: textTheme.displayLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  /// 构建题型分类网格
  /// 
  /// 展示四种题型：词汇、语法、阅读理解、听力
  Widget _buildCategoryGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final categories = [
      ('词汇', '2,340 题', Icons.text_fields, colorScheme.primary),
      ('语法', '1,560 题', Icons.book, colorScheme.secondary),
      ('阅读理解', '890 题', Icons.article, colorScheme.tertiary),
      ('听力', '650 题', Icons.headphones, colorScheme.error),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.4,
        children: categories.map((cat) {
          return ContentCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            onTap: () {
              // 导航到对应题型练习
              AppRouter.goToQuiz(context, _selectedLevel);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: cat.$4.withAlphaCompat(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    cat.$3,
                    size: 20,
                    color: cat.$4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  cat.$1,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  cat.$2,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建推荐练习列表
  Widget _buildRecommendedList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final items = [
      ('N5 基础词汇 01', '50 题', '约 10 分钟'),
      ('N5 语法入门', '30 题', '约 15 分钟'),
      ('N5 阅读练习', '10 篇', '约 20 分钟'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ContentCard(
              onTap: () {
                AppRouter.goToQuiz(context, _selectedLevel);
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${item.$2} · ${item.$3}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
