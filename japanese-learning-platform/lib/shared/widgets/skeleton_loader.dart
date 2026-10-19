/// 骨架屏加载组件
/// 
/// 在数据加载时提供视觉占位，避免空白页面
/// 遵循 shimmer 动画规范
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

/// 骨架屏加载组件
/// 
/// 使用规范：
/// - 用于数据加载中的占位显示
/// - 使用 Shimmer 动画创造流动效果
/// - 颜色跟随主题变化
class SkeletonLoader extends StatelessWidget {
  /// 骨架屏宽度
  final double? width;
  
  /// 骨架屏高度
  final double height;
  
  /// 圆角半径（默认 8）
  final double borderRadius;
  
  /// 是否为圆形
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: isCircle
              ? BorderRadius.circular(height / 2)
              : BorderRadius.circular(borderRadius),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// 列表项骨架屏
/// 
/// 模拟列表项的骨架加载效果
class ListItemSkeleton extends StatelessWidget {
  /// 列表项数量（默认 5）
  final int itemCount;
  
  /// 是否显示副标题（默认 true）
  final bool showSubtitle;
  
  /// 是否显示头像（默认 true）
  final bool showAvatar;

  const ListItemSkeleton({
    super.key,
    this.itemCount = 5,
    this.showSubtitle = true,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // 头像占位
              if (showAvatar) ...[
                const SkeletonLoader(
                  width: 40,
                  height: 40,
                  isCircle: true,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              
              // 文字占位
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(width: double.infinity),
                    if (showSubtitle) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 12,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片骨架屏
/// 
/// 模拟卡片的骨架加载效果
class CardSkeleton extends StatelessWidget {
  /// 卡片数量（默认 3）
  final int cardCount;
  
  /// 卡片高度（默认 120）
  final double cardHeight;

  const CardSkeleton({
    super.key,
    this.cardCount = 3,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          cardCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonLoader(
              width: double.infinity,
              height: cardHeight,
              borderRadius: AppRadius.lg,
            ),
          ),
        ),
      ),
    );
  }
}
