/// 章节标题组件
/// 
/// 日式古典留白风格：
/// - 大量顶部间距（32px+）
/// - 宽松的字间距
/// - 细线分隔（1px border）
/// - 操作按钮使用 TextButton
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
/// 章节标题组件
/// 
/// 使用规范：
/// - 主标题使用 headlineLarge 字重
/// - 日式留白：topPadding 默认 32px
/// - 副标题使用 bodySmall 颜色
/// - 操作按钮可选（如"查看全部"）
class SectionHeader extends StatelessWidget {
  /// 主标题
  final String title;
  
  /// 副标题（可选）
  final String? subtitle;
  
  /// 操作按钮文字（可选，如"查看全部"）
  final String? actionText;
  
  /// 操作按钮点击回调
  final VoidCallback? onAction;
  
  /// 水平内边距（默认 24，日式大方留白）
  final double horizontalPadding;
  
  /// 顶部间距（默认 32，日式大量留白）
  final double topPadding;
  
  /// 底部间距（默认 16）
  final double bottomPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.horizontalPadding = AppSpacing.xxl,
    this.topPadding = AppSpacing.xxxl,
    this.bottomPadding = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 左侧：标题 + 副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 主标题（日式古典：tracking-tight）
                    Text(
                      title,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: AppTypography.letterSpacingTight,
                      ),
                    ),
                    
                    // 副标题（可选）
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: AppTypography.letterSpacingWide,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 右侧：操作按钮（可选）
              if (actionText != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: AppTypography.medium,
                          letterSpacing: AppTypography.letterSpacingWide,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs2),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // 日式细线分隔（1px border，非粗阴影）
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 1,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}
