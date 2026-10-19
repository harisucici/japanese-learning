/// 设计系统 - 颜色规范 (design-taste-frontend 升级)
/// 
/// 遵循高端设计原则：
/// - 主色 #2563EB（深蓝，品牌色）
/// - 背景 #FAFAFA（柔和灰白）
/// - 表面纯白 #FFFFFF
/// - 边框 rgba(slate-200, 0.5)
/// - 文字 #18181B（Zinc-900，非纯黑）
library;

import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  AppColors._();

  // ============================================================
  // 主色调 - 品牌色（保留 #2563EB）
  // ============================================================
  
  /// 主色 - 深蓝色（品牌核心）
  static const Color primary = Color(0xFF2563EB);
  
  /// 主色变体 - 浅色（用于 hover/active）
  static const Color primaryLight = Color(0xFF3B82F6);
  
  /// 主色变体 - 深色（用于 pressed）
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  /// 主色 - 50（最浅背景）
  static const Color primary50 = Color(0xFFEFF6FF);
  
  /// 主色 - 100
  static const Color primary100 = Color(0xFFDBEAFE);
  
  /// 主色 - 200
  static const Color primary200 = Color(0xFFBFDBFE);
  
  /// 主色 - 500
  static const Color primary500 = Color(0xFF3B82F6);
  
  /// 主色 - 600（主色）
  static const Color primary600 = Color(0xFF2563EB);
  
  /// 主色 - 700
  static const Color primary700 = Color(0xFF1D4ED8);
  
  /// 主色 - 900（最深）
  static const Color primary900 = Color(0xFF1E3A8A);

  // ============================================================
  // 辅助色 - Emerald Green（替代原 #10B981）
  // ============================================================
  
  /// 辅色 - 翡翠绿（高端感）
  static const Color success = Color(0xFF10B981);
  
  /// 辅色变体 - 浅色
  static const Color successLight = Color(0xFF34D399);
  
  /// 辅色变体 - 深色
  static const Color successDark = Color(0xFF059669);
  
  /// 辅色 - 50
  static const Color success50 = Color(0xFFECFDF5);
  
  /// 辅色 - 100
  static const Color success100 = Color(0xFFD1FAE5);

  // ============================================================
  // 语义色 - 高级感配色（饱和度 < 80%）
  // ============================================================
  
  /// 警告色 - 琥珀色（温暖高级）
  static const Color warning = Color(0xFFF59E0B);
  
  /// 警告色 - 浅色
  static const Color warningLight = Color(0xFFFDE68A);
  
  /// 错误色 - 玫瑰红（非刺眼红）
  static const Color error = Color(0xFFEF4444);
  
  /// 错误色 - 浅色
  static const Color errorLight = Color(0xFFFEE2E2);
  
  /// 信息色 - 天蓝色
  static const Color info = Color(0xFF0EA5E9);
  
  /// 信息色 - 浅色
  static const Color infoLight = Color(0xFFE0F2FE);

  // ============================================================
  // 中性色 - 浅色主题（design-taste-frontend 规范）
  // ============================================================
  
  /// 背景色 - #FAFAFA（柔和灰白，非纯白）
  static const Color background = Color(0xFFFAFAFA);
  
  /// 表面色 - 纯白 #FFFFFF（卡片、面板）
  static const Color surface = Color(0xFFFFFFFF);
  
  /// 表面色变体 - 次要表面
  static const Color surfaceVariant = Color(0xFFF4F4F5); // Zinc-100
  
  /// 边框色 - slate-200/50（高端透明边框）
  static const Color border = Color(0xFFE5E7EB);
  
  /// 边框色 - 浅色（用于分割）
  static const Color borderLight = Color(0x80E5E7EB); // 50% opacity
  
  /// 分割线色
  static const Color divider = Color(0xFFE5E7EB);

  // ============================================================
  // 文字色 - Zinc 色系（非纯黑）
  // ============================================================
  
  /// 主文字 - Zinc-900（#18181B，非纯黑）
  static const Color textPrimary = Color(0xFF18181B);
  
  /// 次要文字 - Zinc-600
  static const Color textSecondary = Color(0xFF52525B);
  
  /// 辅助文字 - Zinc-500
  static const Color textTertiary = Color(0xFF71717A);
  
  /// 禁用文字 - Zinc-400
  static const Color textDisabled = Color(0xFFA1A1AA);
  
  /// 提示文字 - Zinc-400（输入框 hint）
  static const Color textHint = Color(0xFFA1A1AA);
  
  /// 反色文字（在深色背景上）
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // 深色主题（可选）
  // ============================================================
  
  /// 深色背景 - Zinc-950
  static const Color darkBackground = Color(0xFF09090B);
  
  /// 深色表面 - Zinc-900
  static const Color darkSurface = Color(0xFF18181B);
  
  /// 深色边框
  static const Color darkBorder = Color(0xFF27272A);
  
  /// 深色表面变体
  static const Color darkSurfaceVariant = Color(0xFF27272A);
  
  /// 深色文字
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  
  /// 深色提示文字
  static const Color darkTextHint = Color(0xFF71717A);
}
