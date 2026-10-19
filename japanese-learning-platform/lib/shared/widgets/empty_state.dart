/// 空状态组件
/// 
/// 在列表无数据时显示友好的空状态提示
/// 引导用户进行下一步操作
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 空状态组件
/// 
/// 使用规范：
/// - 用于列表无数据、搜索无结果等场景
/// - 提供清晰的视觉指引和可选的操作按钮
/// - 图标/插图居中，文字说明清晰
class EmptyState extends StatelessWidget {
  /// 图标（与 image 二选一）
  final IconData? icon;
  
  /// 图片/插图 Widget（与 icon 二选一）
  final Widget? image;
  
  /// 主标题
  final String title;
  
  /// 副标题/说明文字
  final String? subtitle;
  
  /// 操作按钮文字（可选）
  final String? actionText;
  
  /// 操作按钮回调
  final VoidCallback? onAction;
  
  /// 图标大小（默认 80）
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon,
    this.image,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconSize = 80,
  }) : assert(icon != null || image != null, '必须提供 icon 或 image');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标或图片
            if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: colorScheme.onSurfaceVariant.withAlphaCompat(0.5),
              )
            else if (image != null)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: image,
              ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // 主标题
            Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: AppTypography.semiBold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题（可选）
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // 操作按钮（可选）
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
