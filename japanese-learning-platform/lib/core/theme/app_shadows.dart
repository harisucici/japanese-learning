/// 设计系统 - 阴影规范
/// 
/// 定义分层阴影系统，使用色调匹配背景色
/// 避免纯黑阴影，保持干净、高级的视觉效果
library;

import 'package:flutter/material.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 应用阴影常量
/// 
/// 遵循设计规范：
/// - 阴影颜色匹配背景色调（不用纯黑）
/// - 多层阴影叠加，创造深度感
/// - VISUAL_DENSITY: 4 → 适度阴影，不过度堆叠
class AppShadows {
  AppShadows._();

  // ============================================================
  // 阴影颜色 - 浅色主题
  // ============================================================
  
  /// 浅色主题阴影色（柔和灰蓝）
  static const Color _lightShadow = Color(0xFF1E293B);
  
  /// 深色主题阴影色（更深的灰蓝）
  static const Color _darkShadow = Color(0xFF000000);

  // ============================================================
  // 分层阴影 - 浅色主题
  // ============================================================
  
  /// 无阴影
  static const List<BoxShadow> none = [];

  /// 极轻阴影（静态小元素，如标签）
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x081E293B),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// 轻阴影（小按钮、标签）
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A1E293B),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// 中等阴影（卡片）
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0D1E293B),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x081E293B),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// 大阴影（浮动按钮、下拉菜单）
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x141E293B),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A1E293B),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// 超大阴影（模态框、底部弹窗）
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1F1E293B),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0D1E293B),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================================
  // 扩散阴影（Bento 风格）
  // ============================================================
  
  /// 扩散阴影 - 用于高级卡片（Bento 风格）
  /// 非常轻、非常宽的阴影，创造悬浮感
  static List<BoxShadow> diffusion({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? _lightShadow).withAlphaCompat(0.05),
        blurRadius: 40,
        spreadRadius: 0,
        offset: const Offset(0, 20),
      ),
    ];
  }

  // ============================================================
  // 内阴影（输入框聚焦、按压效果）
  // ============================================================
  
  /// 内阴影 - 输入框
  static const List<BoxShadow> inset = [
    BoxShadow(
      color: Color(0x0D1E293B),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ============================================================
  // 按钮按压阴影
  // ============================================================
  
  /// 按钮默认阴影
  static const List<BoxShadow> buttonDefault = [
    BoxShadow(
      color: Color(0x142563EB),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// 按钮按下阴影（按压时缩小）
  static const List<BoxShadow> buttonPressed = [
    BoxShadow(
      color: Color(0x0A2563EB),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}
