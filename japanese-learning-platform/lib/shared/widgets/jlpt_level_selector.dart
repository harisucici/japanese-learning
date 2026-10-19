/// 日语等级选择器组件
/// 
/// 用于选择 JLPT 等级（N5-N1）
/// 支持水平滚动和选中状态高亮
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';

/// 日语等级选择器
/// 
/// 水平滚动的 JLPT 等级选择条
/// 选中项高亮，支持动画过渡
class JlptLevelSelector extends StatelessWidget {
  /// 当前选中的等级
  final String selectedLevel;
  
  /// 等级变化回调
  final ValueChanged<String> onLevelChanged;
  
  /// 可选等级列表（默认 N5-N1）
  final List<String> levels;

  const JlptLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.levels = AppConstants.jlptLevels,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = level == selectedLevel;
          
          return _LevelChip(
            level: level,
            isSelected: isSelected,
            colorScheme: colorScheme,
            onTap: () => onLevelChanged(level),
          );
        },
      ),
    );
  }
}

/// 等级标签（私有组件）
/// 
/// 单个 JLPT 等级标签，使用 AnimatedContainer 实现平滑过渡
class _LevelChip extends StatelessWidget {
  final String level;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _LevelChip({
    required this.level,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
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
            level,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.bodyMedium,
              fontWeight: AppTypography.semiBold,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
