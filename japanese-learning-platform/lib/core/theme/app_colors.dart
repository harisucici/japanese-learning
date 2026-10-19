/// 设计系统 - 颜色规范
/// 
/// 定义应用中所有颜色的统一常量
/// 遵循设计规范：主色 #2563EB（深蓝），辅色 #10B981（绿）
/// 背景 #F9FAFB，文字 #111827
library;

import 'package:flutter/material.dart';

/// 应用颜色常量
/// 
/// 统一管理所有颜色值，确保设计一致性
class AppColors {
  AppColors._();

  // ============================================================
  // 主色调 - 品牌色
  // ============================================================
  
  /// 主色 - 深蓝色
  static const Color primary = Color(0xFF2563EB);
  
  /// 主色变体 - 浅色
  static const Color primaryLight = Color(0xFF60A5FA);
  
  /// 主色变体 - 深色
  static const Color primaryDark = Color(0xFF1E40AF);
  
  /// 主色 - 50（最浅）
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
  // 辅助色 - 成功色
  // ============================================================
  
  /// 辅色 - 绿色
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
  // 语义色 - 警告与错误
  // ============================================================
  
  /// 警告色
  static const Color warning = Color(0xFFF59E0B);
  
  /// 警告色 - 浅色
  static const Color warningLight = Color(0xFFFCD34D);
  
  /// 错误色
  static const Color error = Color(0xFFEF4444);
  
  /// 错误色 - 浅色
  static const Color errorLight = Color(0xFFFCA5A5);
  
  /// 信息色
  static const Color info = Color(0xFF0EA5E9);

  // ============================================================
  // 中性色 - 浅色主题
  // ============================================================
  
  /// 背景色
  static const Color background = Color(0xFFF9FAFB);
  
  /// 表面色（卡片、面板）
  static const Color surface = Color(0xFFFFFFFF);
  
  /// 表面色变体 - 次要表面
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  
  /// 边框色
  static const Color border = Color(0xFFE5E7EB);
  
  /// 边框色 - 浅色
  static const Color borderLight = Color(0xFFF3F4F6);
  
  /// 分割线色
  static const Color divider = Color(0xFFE5E7EB);

  // ============================================================
  // 文字色
  // ============================================================
  
  /// 主要文字色
  static const Color textPrimary = Color(0xFF111827);
  
  /// 次要文字色
  static const Color textSecondary = Color(0xFF6B7280);
  
  /// 提示文字色
  static const Color textHint = Color(0xFF9CA3AF);
  
  /// 禁用文字色
  static const Color textDisabled = Color(0xFFD1D5DB);
  
  /// 反色文字（白色）
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // 中性色 - 深色主题
  // ============================================================
  
  /// 深色背景
  static const Color darkBackground = Color(0xFF0F172A);
  
  /// 深色表面
  static const Color darkSurface = Color(0xFF1E293B);
  
  /// 深色表面变体
  static const Color darkSurfaceVariant = Color(0xFF334155);
  
  /// 深色边框
  static const Color darkBorder = Color(0xFF334155);
  
  /// 深色文字 - 主要
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  
  /// 深色文字 - 次要
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  /// 深色文字 - 提示
  static const Color darkTextHint = Color(0xFF64748B);
}
