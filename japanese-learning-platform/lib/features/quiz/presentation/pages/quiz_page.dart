/// 练习详情页
/// 
/// 展示具体等级的练习内容，包含练习列表和开始练习入口
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/content_card.dart';
import '../../../../core/theme/theme.dart';

/// 练习详情页组件
/// 
/// 根据传入的 JLPT 等级展示对应的练习列表
/// 参数 [level] 表示 JLPT 等级（N5-N1）
class QuizPage extends StatelessWidget {
  /// JLPT 等级
  final String level;

  const QuizPage({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('$level 练习'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 练习概览
          _buildOverview(context),
          
          // 练习列表
          const SectionHeader(title: '练习内容'),
          _buildPracticeList(context),
          
          // 底部间距
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// 构建练习概览
  Widget _buildOverview(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$level 等级练习',
              style: textTheme.headlineLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '包含词汇、语法、阅读、听力四大板块，全面覆盖 $level 考试要求',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _buildOverviewStat('234', '总题数'),
                const SizedBox(width: AppSpacing.xxl),
                _buildOverviewStat('85%', '通过率'),
                const SizedBox(width: AppSpacing.xxl),
                _buildOverviewStat('4.2', '平均分'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建概览统计项
  Widget _buildOverviewStat(String value, String label) {
    return Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建练习列表
  Widget _buildPracticeList(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    final practices = [
      ('词汇练习 01', '50 题', '约 10 分钟', true),
      ('词汇练习 02', '50 题', '约 10 分钟', false),
      ('语法练习 01', '30 题', '约 15 分钟', true),
      ('语法练习 02', '30 题', '约 15 分钟', false),
      ('阅读理解 01', '10 篇', '约 20 分钟', false),
      ('听力练习 01', '20 题', '约 25 分钟', false),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: practices.map((practice) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ContentCard(
              onTap: () {
                context.push('/quiz/${level.toLowerCase()}/answer');
              },
              child: Row(
                children: [
                  // 状态指示器
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: practice.$4
                          ? colorScheme.secondary
                          : colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  
                  // 练习信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          practice.$1,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${practice.$2} · ${practice.$3}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 完成状态
                  if (practice.$4)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: colorScheme.secondary,
                    )
                  else
                    Icon(
                      Icons.play_arrow,
                      color: colorScheme.primary,
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
