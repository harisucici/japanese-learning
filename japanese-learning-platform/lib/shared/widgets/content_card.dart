/// 内容卡片组件
/// 
/// 通用卡片容器，统一卡片视觉规范
/// 遵循设计规范：无阴影（通过边框区分），16px 圆角
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

/// 内容卡片组件
/// 
/// 使用规范：
/// - 使用 Theme 中的 cardColor 作为背景
/// - 使用 Theme 中的 cardTheme 统一样式
/// - 可选的 onTap 回调（有则显示涟漪效果）
/// - 内边距统一为 16px
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
  
  /// 边框色覆盖
  final Color? borderColor;

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
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final hasInteraction = onTap != null || onLongPress != null;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final effectiveMargin = margin ?? EdgeInsets.zero;

    // 构建卡片形状
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(
        color: borderColor ?? Theme.of(context).colorScheme.outline,
        width: 1,
      ),
    );

    // 构建卡片内容
    Widget cardContent = Padding(
      padding: effectivePadding,
      child: child,
    );

    // 如果有交互，使用 InkWell 包裹
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

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: color ?? cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: cardContent,
    );
  }
}
