import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.1 解析总览页
/// 显示：正确答案、核心考点、关键判断依据
class AnalysisOverviewCard extends StatelessWidget {
  final QuestionAnalysis analysis;

  const AnalysisOverviewCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 正确答案
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                Text(
                  '正确答案：${analysis.options[analysis.correctIndex].label}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 核心考点
            _buildInfoRow(
              icon: Icons.star,
              iconColor: AppColors.primary,
              title: '核心考点',
              content: analysis.overview.corePoint,
            ),
            const SizedBox(height: 12),
            // 关键判断依据
            _buildInfoRow(
              icon: Icons.lightbulb_outline,
              iconColor: AppColors.primary,
              title: '判断依据',
              content: analysis.overview.keyJudgment,
            ),
            const SizedBox(height: 16),
            // 难度
            Row(
              children: [
                const Text('难度：'),
                ...List.generate(5, (i) {
                  return Icon(
                    i < analysis.overview.difficulty
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            // 关键词标签
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.overview.keywords
                  .map((k) => Chip(
                        label: Text(k),
                        backgroundColor: AppColors.primary.withAlphaCompat(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(content),
            ],
          ),
        ),
      ],
    );
  }
}
