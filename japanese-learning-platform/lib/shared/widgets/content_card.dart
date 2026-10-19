/// 内容卡片组件
/// 
/// Material Design 3 Card 风格：
/// - elevation 0-2，无硬边框
/// - 使用 surface tint 而非边框
/// - 16px 圆角（Material 3 标准）
/// - 日式留白美学
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_colors.dart';

/// 内容卡片组件
/// 
/// 使用规范：
/// - Material 3 Card 风格（elevation 0-1）
/// - 可选的 onTap 回调（有则显示涟漪效果）
/// - 内边距统一为 16px
/// - 日式古典：大量留白，呼吸感强
class ContentCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;
  
  /// 点击回调（可选）
  final VoidCallback? onTap;
  
  /// 长按回调（可选）
  final VoidCallback? onLongPress;
  
  /// 内边距（默认 16）
  final EdgeInsetsGeometry? padding;
  
  /// 外边距（默认 EdgeInsets.zero）
  final EdgeInsetsGeometry? margin;
  
  /// 是否启用点击效果（默认根据 onTap 自动判断）
  final bool? enableTapEffect;
  
  /// 背景色覆盖（默认使用 Theme cardColor）
  final Color? color;
  
  /// 边框色覆盖（默认无硬边框）
  final Color? borderColor;
  
  /// 阴影高度（默认 0，日式扁平）
  final double? elevation;

  const ContentCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.enableTapEffect,
    this.color,
    this.borderColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInteraction = onTap != null || onLongPress != null;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final effectiveMargin = margin ?? EdgeInsets.zero;
    final effectiveElevation = elevation ?? 0;

    // 构建卡片形状（Material 3：无硬边框，使用圆角）
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: borderColor != null
          ? BorderSide(color: borderColor!, width: 1)
          : BorderSide.none,
    );

    // 构建卡片内容
    Widget cardContent = Padding(
      padding: effectivePadding,
      child: child,
    );

    // 如果有交互，使用 InkWell 包裹（Material 3 涟漪效果）
    if (hasInteraction && (enableTapEffect ?? true)) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: cardContent,
        ),
      );
    }

    // Material 3 Card（日式扁平风格）
    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: AppColors.border.withAlpha(26), // 0.1 * 255 ≈ 26
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: cardContent,
    );
  }
}
