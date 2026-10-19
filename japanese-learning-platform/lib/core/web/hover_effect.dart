/// 鼠标悬停效果组件
///
/// 为 Web 端提供鼠标悬停交互效果
library;

import 'package:flutter/material.dart';

/// 悬停效果构建器
///
/// 在 Web 端为组件添加鼠标悬停效果（缩放、阴影、颜色变化）
class HoverEffect extends StatefulWidget {
  /// 子组件构建器
  final Widget Function(BuildContext context, bool isHovered) builder;

  /// 悬停时的缩放比例
  final double hoverScale;

  /// 悬停时的阴影半径
  final double hoverElevation;

  /// 悬停动画时长
  final Duration duration;

  const HoverEffect({
    super.key,
    required this.builder,
    this.hoverScale = 1.02,
    this.hoverElevation = 8,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEnter(PointerEvent event) {
    _isHovered = true;
    _controller.forward();
  }

  void _onHoverExit(PointerEvent event) {
    _isHovered = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onHoverEnter,
      onExit: _onHoverExit,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.builder(context, _isHovered),
          );
        },
      ),
    );
  }
}

/// 悬停卡片
///
/// 带有悬停效果的卡片组件
class HoverCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 悬停时的缩放比例
  final double hoverScale;

  /// 圆角
  final double borderRadius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  const HoverCard({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.borderRadius = 12,
    this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return HoverEffect(
      hoverScale: hoverScale,
      builder: (context, isHovered) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          elevation: isHovered ? 8 : 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
