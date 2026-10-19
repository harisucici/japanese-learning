/// 日语等级选择器组件
/// 
/// Material 3 + 日式古典风格：
/// - 使用 FilledTonalButton 风格的柔和按钮
/// - 大量留白（horizontal padding 24px）
/// - 宽松的字间距
/// - 无硬边框，使用圆角和背景色区分层级
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: levels.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
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
      ),
    );
  }
}

/// 等级标签（私有组件）
/// 
/// Material 3 FilledTonalButton 风格：
/// - 选中：primaryContainer 背景 + primary 文字
/// - 未选中：surface 背景 + outline 边框（1px）
/// - 日式古典：大量留白，宽松字间距
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
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            level,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.bodyMedium,
              fontWeight: AppTypography.semiBold,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              letterSpacing: AppTypography.letterSpacingWide,
            ),
          ),
        ),
      ),
    );
  }
}
