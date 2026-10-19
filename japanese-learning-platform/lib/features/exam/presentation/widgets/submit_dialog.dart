/// 交卷确认对话框
///
/// 显示未答题数量、已答题数、剩余时间，确认后交卷
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../redux/app_state.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 交卷确认对话框
class SubmitDialog extends StatelessWidget {
  final ExamSession session;

  const SubmitDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final remaining = session.remainingSeconds;
    final h = remaining ~/ 3600;
    final m = (remaining % 3600) ~/ 60;
    final s = remaining % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final answered = session.answeredCount;
    final unanswered = session.unansweredCount;
    final total = session.questions.length;
    final marked = session.markedQuestions.length;
    final allAnswered = unanswered == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部图标
            Container(
              margin: const EdgeInsets.only(top: 24),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: allAnswered
                    ? AppColors.success.withAlphaCompat(0.12)
                    : AppColors.warning.withAlphaCompat(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allAnswered
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: allAnswered ? AppColors.success : AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              allAnswered ? '确认交卷？' : '还有未完成的题目',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              allAnswered ? '你已完成所有题目' : '交卷后将无法继续作答',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            // 统计卡片
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.check_circle,
                    value: '$answered',
                    label: '已答',
                    color: AppColors.success,
                  ),
                  const _Divider(),
                  _StatChip(
                    icon: Icons.radio_button_unchecked,
                    value: '$unanswered',
                    label: '未答',
                    color: unanswered > 0 ? AppColors.error : AppColors.textHint,
                  ),
                  const _Divider(),
                  _StatChip(
                    icon: Icons.flag_rounded,
                    value: '$marked',
                    label: '标记',
                    color: marked > 0 ? AppColors.warning : AppColors.textHint,
                  ),
                  const _Divider(),
                  _StatChip(
                    icon: Icons.timer_rounded,
                    value: timeStr,
                    label: '剩余',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '完成进度',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${total > 0 ? (answered * 100 / total).round() : 0}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? answered / total : 0,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(
                        allAnswered ? AppColors.success : AppColors.warning,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            '继续作答',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.success, AppColors.successDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withAlphaCompat(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '确认交卷',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}
