/// 空状态组件
/// 
/// Material Design 3 + 日式古典风格：
/// - 大量留白（padding 48px）
/// - 图标使用 tertiary 色（金色点缀）
/// - 标题使用 serif 字体（古典感）
/// - 操作按钮使用 FilledTonalButton（柔和）
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 空状态组件
/// 
/// 使用规范：
/// - 用于列表无数据、搜索无结果等场景
/// - 日式留白：padding 48px，呼吸感强
/// - 提供清晰的视觉指引和可选的操作按钮
/// - 图标使用 tertiary 色（金色点缀）
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
        // 日式大量留白
        padding: const EdgeInsets.all(AppSpacing.xxxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标或图片（日式古典：使用 tertiary 金色点缀）
            if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: colorScheme.tertiary.withAlphaCompat(0.6),
              )
            else if (image != null)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: image,
              ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // 主标题（日式古典：serif 字体，tracking-tight）
            Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: AppTypography.bold,
                letterSpacing: AppTypography.letterSpacingTight,
                fontFamily: AppTypography.serifFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 副标题（可选）
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: AppTypography.letterSpacingWide,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // 操作按钮（可选，Material 3 FilledButton.tonal）
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxxl),
              FilledButton.tonal(
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
