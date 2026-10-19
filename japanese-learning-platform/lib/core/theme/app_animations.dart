/// 设计系统 - 动画规范
/// 
/// MOTION_INTENSITY: 6 → 流畅动效，使用 spring 物理
/// 统一动画时长、曲线和 spring 参数
library;

import 'package:flutter/material.dart';

/// 应用动画常量
/// 
/// 遵循 MOTION_INTENSITY: 6 规范：
/// - 使用 spring 物理模拟（不用线性动画）
/// - 统一过渡曲线
/// - 所有动画基于 transform 和 opacity（硬件加速）
class AppAnimations {
  AppAnimations._();

  // ============================================================
  // 动画时长
  // ============================================================
  
  /// 极快 - 100ms（微交互、状态切换）
  static const Duration fast = Duration(milliseconds: 100);
  
  /// 快速 - 200ms（按钮状态、hover）
  static const Duration quick = Duration(milliseconds: 200);
  
  /// 标准 - 300ms（页面过渡、卡片展开）
  static const Duration normal = Duration(milliseconds: 300);
  
  /// 慢速 - 500ms（复杂过渡、入场动画）
  static const Duration slow = Duration(milliseconds: 500);
  
  /// 极慢 - 800ms（页面进入、特殊效果）
  static const Duration verySlow = Duration(milliseconds: 800);

  // ============================================================
  // 过渡曲线
  // ============================================================
  
  /// 标准曲线 - Material 默认
  static const Curve easeStandard = Curves.easeInOutCubic;
  
  /// 减速曲线 - 入场动画
  static const Curve easeOut = Curves.easeOutCubic;
  
  /// 加速曲线 - 退场动画
  static const Curve easeIn = Curves.easeInCubic;
  
  /// 弹性曲线 - 轻微回弹
  static const Curve easeElastic = Curves.elasticOut;
  
  /// 流畅曲线 - 自然流畅（iOS 风格）
  static final Curve easeSmooth = const Cubic(0.16, 1, 0.3, 1);
  
  /// 弹簧曲线 - 动感
  static final Curve easeBounce = const Cubic(0.34, 1.56, 0.64, 1);

  // ============================================================
  // Spring 物理参数
  // ============================================================
  
  /// 标准弹簧 - 通用
  static const SpringDescription springStandard = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 20.0,
  );

  /// 轻柔弹簧 - 微交互
  static const SpringDescription springGentle = SpringDescription(
    mass: 1.0,
    stiffness: 80.0,
    damping: 25.0,
  );

  /// 弹性弹簧 - 强调效果
  static const SpringDescription springBouncy = SpringDescription(
    mass: 1.0,
    stiffness: 150.0,
    damping: 15.0,
  );

  /// 僵硬弹簧 - 快速响应
  static const SpringDescription springStiff = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 25.0,
  );

  // ============================================================
  // 页面过渡
  // ============================================================
  
  /// 淡入淡出 - 页面切换
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  
  /// 滑动进入 - 从右侧
  static const Duration slideTransitionDuration = Duration(milliseconds: 250);

  // ============================================================
  // 装饰性动画
  // ============================================================
  
  /// 脉动动画时长（加载指示器）
  static const Duration pulseDuration = Duration(milliseconds: 1500);
  
  /// 微光动画时长（骨架屏）
  static const Duration shimmerDuration = Duration(milliseconds: 1200);
  
  /// 浮动动画时长（装饰元素）
  static const Duration floatDuration = Duration(milliseconds: 3000);
}
