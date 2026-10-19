import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.6 选项对比表
class OptionCompareTable extends StatelessWidget {
  final List<QuestionOption> options;
  final int correctIndex;

  const OptionCompareTable({
    super.key,
    required this.options,
    required this.correctIndex,
  });

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
            Text(
              '选项逐项讲解',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '不只讲正确项，每个选项都完整解析',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...options.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              return _buildOptionCard(context, opt, i);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, QuestionOption opt, int i) {
    final isCorrect = i == correctIndex;
    final isPlausible = opt.verdict == OptionVerdict.plausible;
    final color = isCorrect
        ? AppColors.success
        : isPlausible
            ? AppColors.warning
            : Colors.grey.shade400;
    final bg = isCorrect
        ? AppColors.success.withAlphaCompat(0.05)
        : isPlausible
            ? AppColors.warning.withAlphaCompat(0.05)
            : Colors.grey.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlphaCompat(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 标签
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    opt.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      opt.reading,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _verdictBadge(opt.verdict),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          // 含义
          _infoRow(Icons.translate, '含义', opt.meaning, AppColors.primary),
          const SizedBox(height: 8),
          // 用法说明
          _infoRow(Icons.build, '用法', opt.usageNote, AppColors.primary),
          const SizedBox(height: 8),
          // 本题判断依据
          _infoRow(Icons.check_circle_outline, '判断依据', opt.reasoning, color),
        ],
      ),
    );
  }

  Widget _verdictBadge(OptionVerdict v) {
    String text;
    Color color;
    IconData icon;
    switch (v) {
      case OptionVerdict.correct:
        text = '正确';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case OptionVerdict.plausible:
        text = '干扰项';
        color = AppColors.warning;
        icon = Icons.warning_amber;
        break;
      case OptionVerdict.wrong:
        text = '错误';
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlphaCompat(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label：',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Built-in List.asMap() is used - no extension needed
