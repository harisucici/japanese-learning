/// 等级选择器 - 横向滚动
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/enums.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// JLPT 等级选择器
class LevelSelector extends StatelessWidget {
  final JLPTLevel selected;
  final ValueChanged<JLPTLevel> onSelected;

  const LevelSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: JLPTLevel.values.length,
        itemBuilder: (context, index) {
          final level = JLPTLevel.values[index];
          final isSelected = level == selected;
          return _LevelChip(
            level: level,
            isSelected: isSelected,
            onTap: () => onSelected(level),
          );
        },
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final JLPTLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlphaCompat(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.displayName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getLevelLabel(level),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white.withAlphaCompat(0.9)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLevelLabel(JLPTLevel level) {
    switch (level) {
      case JLPTLevel.n5:
        return '入门';
      case JLPTLevel.n4:
        return '基础';
      case JLPTLevel.n3:
        return '中级';
      case JLPTLevel.n2:
        return '进阶';
      case JLPTLevel.n1:
        return '高级';
    }
  }
}
