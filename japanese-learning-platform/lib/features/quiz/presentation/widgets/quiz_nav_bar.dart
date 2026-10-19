/// 底部导航栏
///
/// 上一题/下一题/提交
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 答题页底部导航
class QuizNavBar extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isSubmitted;
  final bool hasAnswer;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuizNavBar({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isSubmitted,
    required this.hasAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 上一题
          Expanded(
            child: _NavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: '上一题',
              enabled: !isFirst,
              onTap: onPrevious,
              style: _NavButtonStyle.secondary,
            ),
          ),
          const SizedBox(width: 10),
          // 提交 / 下一题
          Expanded(
            flex: 1,
            child: isSubmitted || isLast
                ? _NavButton(
                    icon: Icons.check_rounded,
                    label: isLast ? '提交' : '下一题',
                    enabled: hasAnswer,
                    onTap: onSubmit,
                    style: _NavButtonStyle.primary,
                  )
                : _NavButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    label: '下一题',
                    enabled: hasAnswer,
                    onTap: onNext,
                    style: _NavButtonStyle.primary,
                  ),
          ),
        ],
      ),
    );
  }
}

enum _NavButtonStyle { primary, secondary }

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final _NavButtonStyle style;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == _NavButtonStyle.primary;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? (isPrimary ? AppColors.primary : AppColors.surface)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled
                  ? (isPrimary ? Colors.white : AppColors.textPrimary)
                  : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? (isPrimary ? Colors.white : AppColors.textPrimary)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
