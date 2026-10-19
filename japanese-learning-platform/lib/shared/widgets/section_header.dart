/// 章节标题组件
/// 
/// 用于页面中各区块的标题展示
/// 支持可选的副标题和操作按钮
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
/// 章节标题组件
/// 
/// 使用规范：
/// - 主标题使用 headlineLarge 字重
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
  
  /// 水平内边距（默认 16）
  final double horizontalPadding;
  
  /// 顶部间距（默认 24）
  final double topPadding;
  
  /// 底部间距（默认 12）
  final double bottomPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.horizontalPadding = AppSpacing.lg,
    this.topPadding = AppSpacing.xxl,
    this.bottomPadding = AppSpacing.md,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 左侧：标题 + 副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 主标题
                Text(
                  title,
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: AppTypography.semiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                
                // 副标题（可选）
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
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
    );
  }
}
