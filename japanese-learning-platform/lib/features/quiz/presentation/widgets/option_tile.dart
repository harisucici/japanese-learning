/// 选项卡片组件
///
/// 移动端大点击区域，选中/对错状态通过文字+图标+颜色共同表达
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 选项卡片
class OptionTile extends StatelessWidget {
  final QuestionOption option;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSubmitted = isCorrect != null;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;

    if (isSubmitted && isSelected) {
      // 提交后：用户选择的选项
      if (isCorrect == true) {
        bgColor = AppColors.success.withAlphaCompat(0.08);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        iconColor = AppColors.success;
      } else {
        bgColor = AppColors.error.withAlphaCompat(0.08);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        iconColor = AppColors.error;
      }
    } else if (isSubmitted && isCorrect == true) {
      // 提交后：显示正确答案
      bgColor = AppColors.success.withAlphaCompat(0.08);
      borderColor = AppColors.success;
      textColor = AppColors.success;
      iconColor = AppColors.success;
    } else if (isSelected) {
      // 选中未提交
      bgColor = AppColors.primary.withAlphaCompat(0.08);
      borderColor = AppColors.primary;
      textColor = AppColors.textPrimary;
      iconColor = AppColors.primary;
    } else {
      // 默认
      bgColor = AppColors.surface;
      borderColor = AppColors.border;
      textColor = AppColors.textPrimary;
      iconColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected || (isSubmitted && isCorrect == true) ? 2 : 1),
        ),
        child: Row(
          children: [
            _buildIndexBox(iconColor, isSubmitted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.content,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight:
                      isSelected || (isSubmitted && isCorrect == true) ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSubmitted && isSelected)
              Icon(
                isCorrect == true ? Icons.check_circle : Icons.cancel,
                color: iconColor,
                size: 22,
              ),
            if (isSubmitted && !isSelected && isCorrect == true)
              Icon(Icons.check_circle, color: AppColors.success, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexBox(Color color, bool isSubmitted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlphaCompat(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        _indexToLetter(option.index),
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _indexToLetter(int index) {
    if (index < 0 || index > 25) return '${index + 1}';
    return String.fromCharCode(65 + index);
  }
}
