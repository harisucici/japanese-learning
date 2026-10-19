/// 动画基础设施 - Material Design 动效系统
///
/// 提供统一的动画常量、过渡效果、卡片入场、按钮交互等
/// 所有动画基于 transform/opacity（硬件加速）
library;

import 'package:flutter/material.dart';

/// 动画时长常量
class AnimationDurations {
  AnimationDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// 动画曲线常量
class AnimationCurves {
  AnimationCurves._();

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve spring = Cubic(0.175, 0.885, 0.32, 1.275);
}

/// 页面过渡动画构建器
class PageTransitions {
  /// FadeThrough 过渡 - Material Design 3 标准（自定义实现）
  static Widget fadeThrough(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  /// SharedAxisTransition - 共享轴过渡（自定义实现）
  static Widget sharedAxisX(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SharedAxisXTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  static Widget sharedAxisY(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SharedAxisYTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  /// SlideTransition - 滑动进入
  static Widget slideRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AnimationCurves.decelerate,
      )),
      child: child,
    );
  }

  static Widget slideLeft(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AnimationCurves.decelerate,
      )),
      child: child,
    );
  }
}

/// 卡片入场动画 - Staggered Animation（逐个出现）
class StaggeredCardAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final int totalItems;
  final Duration baseDelay;

  const StaggeredCardAnimation({
    super.key,
    required this.child,
    required this.index,
    required this.totalItems,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  @override
  State<StaggeredCardAnimation> createState() => _StaggeredCardAnimationState();
}

class _StaggeredCardAnimationState extends State<StaggeredCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.normal,
    );

    final delay = widget.baseDelay * widget.index;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.0,
        1.0,
        curve: AnimationCurves.decelerate,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 列表项入场动画 - fadeIn + slideUp
class ListItemAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const ListItemAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 30),
  });

  @override
  State<ListItemAnimation> createState() => _ListItemAnimationState();
}

class _ListItemAnimationState extends State<ListItemAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.fast,
    );

    final delay = widget.delay * widget.index;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.decelerate,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 按钮交互反馈 - ripple effect + scale
class InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleDown;
  final Color? rippleColor;

  const InteractiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDown = 0.96,
    this.rippleColor,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.fast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.spring,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                splashColor: widget.rippleColor ??
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                highlightColor: widget.rippleColor ??
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// 答案选择弹簧动画
class AnswerSelectionAnimation extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const AnswerSelectionAnimation({
    super.key,
    required this.child,
    required this.isSelected,
  });

  @override
  State<AnswerSelectionAnimation> createState() =>
      _AnswerSelectionAnimationState();
}

class _AnswerSelectionAnimationState extends State<AnswerSelectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationDurations.fast,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.spring,
    ));
  }

  @override
  void didUpdateWidget(AnswerSelectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 正确/错误反馈动画 - scale + color transition
class FeedbackAnimation extends StatefulWidget {
  final Widget child;
  final bool isCorrect;
  final bool showFeedback;

  const FeedbackAnimation({
    super.key,
    required this.child,
    required this.isCorrect,
    required this.showFeedback,
  });

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackAnimationState extends State<FeedbackAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AnimationDurations.fast,
    );
    _colorController = AnimationController(
      vsync: this,
      duration: AnimationDurations.normal,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 70,
      ),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AnimationCurves.spring,
    ));

    final targetColor = widget.isCorrect
        ? const Color(0xFF4CAF50).withOpacity(0.1)
        : const Color(0xFFF44336).withOpacity(0.1);

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: targetColor,
    ).animate(_colorController);
  }

  @override
  void didUpdateWidget(FeedbackAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFeedback && !oldWidget.showFeedback) {
      _scaleController.forward(from: 0.0);
      _colorController.forward();
    } else if (!widget.showFeedback && oldWidget.showFeedback) {
      _colorController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child,
              );
            },
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 滚动淡入动画 - FadeInOnScroll
class FadeInOnScroll extends StatefulWidget {
  final Widget child;
  final double startOpacity;
  final double endOpacity;
  final double startOffset;
  final double endOffset;

  const FadeInOnScroll({
    super.key,
    required this.child,
    this.startOpacity = 0.0,
    this.endOpacity = 1.0,
    this.startOffset = 50.0,
    this.endOffset = 0.0,
  });

  @override
  State<FadeInOnScroll> createState() => _FadeInOnScrollState();
}

class _FadeInOnScrollState extends State<FadeInOnScroll> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_scrollOffset / 200).clamp(0.0, 1.0);
    final opacity = widget.startOpacity +
        (widget.endOpacity - widget.startOpacity) * progress;
    final offset = widget.startOffset +
        (widget.endOffset - widget.startOffset) * progress;

    return Transform.translate(
      offset: Offset(0, offset),
      child: Opacity(
        opacity: opacity,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer 骨架屏动画
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    )..addListener(() {
        setState(() {});
      });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

/// AnimatedSwitcher 包装器 - 用于状态切换
class AnimatedStateSwitch extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedStateSwitch({
    super.key,
    required this.child,
    this.duration = AnimationDurations.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// FadeThrough Transition - Material Design 3 风格
/// 新页面淡入，旧页面淡出，中间有短暂重叠
class _FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _FadeThroughTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 前 50% 淡出旧页面，后 50% 淡入新页面
        final opacity = animation.value;
        final scale = 0.95 + (0.05 * opacity); // 轻微缩放
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// SharedAxisX Transition - 水平轴共享过渡
class _SharedAxisXTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SharedAxisXTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 新页面从右侧滑入
        final translateX = (1.0 - animation.value) * 100;
        final opacity = animation.value;
        
        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// SharedAxisY Transition - 垂直轴共享过渡
class _SharedAxisYTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SharedAxisYTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 新页面从下方滑入
        final translateY = (1.0 - animation.value) * 50;
        final opacity = animation.value;
        
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
