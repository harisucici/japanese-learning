/// 设计系统 - 颜色规范（深青色 / 蓝绿色配色）
///
/// 配色方案：
/// - 主色：深青色 #268785（RGB 38, 135, 133）
/// - 背景：深青色（深色背景）
/// - 强调色：高饱和度亮色（青色、翠绿、金色）
/// - 文字：白色
library;

import 'package:flutter/material.dart';

/// 应用颜色常量（深青色配色 + Material 3 颜色角色）
class AppColors {
  AppColors._();

  // ============================================================
  // 主色调 - 深青色（品牌核心）#268785
  // ============================================================

  /// 主色 - 深青色 #268785（RGB 38, 135, 133）
  static const Color primary = Color(0xFF268785);

  /// 主色变体 - 浅色（hover/active）
  static const Color primaryLight = Color(0xFF3BA8A5);

  /// 主色变体 - 深色（pressed）
  static const Color primaryDark = Color(0xFF1B6362);

  /// 主色 - 50（最浅背景，青色极淡）
  static const Color primary50 = Color(0xFFE0F5F4);

  /// 主色 - 100
  static const Color primary100 = Color(0xFFB3E6E4);

  /// 主色 - 200
  static const Color primary200 = Color(0xFF80D4D1);

  /// 主色 - 500
  static const Color primary500 = Color(0xFF268785);

  /// 主色 - 600（主色）
  static const Color primary600 = Color(0xFF1F706F);

  /// 主色 - 700
  static const Color primary700 = Color(0xFF175958);

  /// 主色 - 900（最深）
  static const Color primary900 = Color(0xFF0D3D3C);

  // ============================================================
  // 辅助色 - 亮青色（高饱和度强调色）
  // ============================================================

  /// 辅色 - 亮青色（高饱和度，用于强调）
  static const Color secondary = Color(0xFF00BCD4);

  /// 辅色变体 - 浅色
  static const Color secondaryLight = Color(0xFF4DD0E1);

  /// 辅色变体 - 深色
  static const Color secondaryDark = Color(0xFF0097A7);

  /// 辅色 - 50
  static const Color secondary50 = Color(0xFFE0F7FA);

  /// 辅色 - 100
  static const Color secondary100 = Color(0xFFB2EBF2);

  /// 成功色 - 翠绿（高饱和度）
  static const Color success = Color(0xFF00C853);

  /// 成功色 - 浅色
  static const Color successLight = Color(0xFF69F0AE);

  /// 成功色 - 深色
  static const Color successDark = Color(0xFF009624);

  /// 成功色 - 50
  static const Color success50 = Color(0xFFE1F5E7);

  /// 成功色 - 100
  static const Color success100 = Color(0xFFC8E6C9);

  // ============================================================
  // 点缀色 - 金色、珊瑚色
  // ============================================================

  /// 金色（点缀，用于高级标记）
  static const Color gold = Color(0xFFFFD54F);

  /// 金色 - 浅色
  static const Color goldLight = Color(0xFFFFE082);

  /// 金色 - 深色
  static const Color goldDark = Color(0xFFFFC107);

  /// 金色 - 50
  static const Color gold50 = Color(0xFFFFFDE7);

  /// 金色 - 100
  static const Color gold100 = Color(0xFFFFF9C4);

  // ============================================================
  // 语义色 - 高饱和度功能色
  // ============================================================

  /// 警告色 - 琥珀
  static const Color warning = Color(0xFFFFAB00);

  /// 警告色 - 浅色
  static const Color warningLight = Color(0xFFFFE082);

  /// 错误色 - 珊瑚红
  static const Color error = Color(0xFFFF5252);

  /// 错误色 - 浅色
  static const Color errorLight = Color(0xFFFFCDD2);

  /// 信息色 - 亮蓝
  static const Color info = Color(0xFF40C4FF);

  /// 信息色 - 浅色
  static const Color infoLight = Color(0xFFB3E5FC);

  // ============================================================
  // 中性色 - 深色主题（深青色背景）
  // ============================================================

  /// 背景色 - 深青色（主要背景）
  static const Color background = Color(0xFF0D2B2A);

  /// 背景色 - 更深的青色（层级区分）
  static const Color backgroundDeep = Color(0xFF081D1C);

  /// 表面色 - 深青色稍浅（卡片、面板）
  static const Color surface = Color(0xFF143D3B);

  /// 表面色变体 - 次级表面
  static const Color surfaceVariant = Color(0xFF1A4A48);

  /// 边框色 - 深青色边框
  static const Color border = Color(0xFF1F5957);

  /// 边框色 - 浅色
  static const Color borderLight = Color(0xFF267069);

  /// 边框色 - 深色
  static const Color borderDark = Color(0xFF0D3D3C);

  /// 分割线色
  static const Color divider = Color(0xFF1F5957);

  // ============================================================
  // 文字色 - 白色系（深色背景上的高对比度）
  // ============================================================

  /// 主文字 - 白色
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// 次要文字 - 浅灰白
  static const Color textSecondary = Color(0xFFB0BEC5);

  /// 辅助文字 - 灰色
  static const Color textTertiary = Color(0xFF78909C);

  /// 禁用文字 - 深灰
  static const Color textDisabled = Color(0xFF546E7A);

  /// 提示文字 - 输入框 hint
  static const Color textHint = Color(0xFF78909C);

  /// 反色文字（在浅色背景上）
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // 浅色主题（可选：浅色模式）
  // ============================================================

  /// 浅色背景 - 纯白（Web 桌面端主题背景）
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// 浅色表面 - 纯白
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// 浅色边框
  static const Color lightBorder = Color(0xFFB2DFDB);

  /// 浅色文字 - 深色
  static const Color lightTextPrimary = Color(0xFF1A3C3B);

  /// 浅色次要文字
  static const Color lightTextSecondary = Color(0xFF4A6564);

  /// 浅色提示文字
  static const Color lightTextHint = Color(0xFF78909C);

  // ============================================================
  // 深色主题兼容（保持 API 一致）
  // ============================================================

  /// 深色背景 - 深青色
  static const Color darkBackground = Color(0xFF0D2B2A);

  /// 深色表面 - 稍浅青色
  static const Color darkSurface = Color(0xFF143D3B);

  /// 深色边框
  static const Color darkBorder = Color(0xFF1F5957);

  /// 深色表面变体
  static const Color darkSurfaceVariant = Color(0xFF1A4A48);

  /// 深色文字 - 白色
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// 深色次要文字
  static const Color darkTextSecondary = Color(0xFFB0BEC5);

  /// 深色提示文字
  static const Color darkTextHint = Color(0xFF78909C);

  // ============================================================
  // 日式传统色（Japanese Classical Colors）
  // ============================================================

  /// 藤紫 - #89729E（辅助装饰，优雅紫色）
  static const Color sumire = Color(0xFF89729E);

  /// 朱色 - #C73E3E（强调/重要按钮，传统朱红）
  static const Color shu = Color(0xFFC73E3E);

  /// 朱色变体 - 浅色（hover）
  static const Color shuLight = Color(0xFFD95555);

  /// 朱色变体 - 深色（pressed）
  static const Color shuDark = Color(0xFFA02E2E);

  /// 金茶色 - #C9A96E（等级/成就，传统金色）
  static const Color kincha = Color(0xFFC9A96E);

  /// 金茶色变体 - 浅色
  static const Color kinchaLight = Color(0xFFD4B87A);

  /// 金茶色变体 - 深色
  static const Color kinchaDark = Color(0xFFB08F5A);

  /// 和纸白 - #FAF8F5（背景色，温暖的米白）
  static const Color washi = Color(0xFFFAF8F5);

  /// 和纸白变体 - 稍深
  static const Color washiDeep = Color(0xFFF5F1EC);

  /// 墨色 - #1C1C1C（正文文字，深沉的墨黑）
  static const Color sumi = Color(0xFF1C1C1C);

  /// 墨色变体 - 次要文字
  static const Color sumiLight = Color(0xFF4A4A4A);

  /// 墨色变体 - 辅助文字
  static const Color sumiLighter = Color(0xFF7A7A7A);

  /// 和纸边框色 - #E5E0D8（温暖的浅灰边框，日式风格）
  static const Color washiBorder = Color(0xFFE5E0D8);

  /// 和纸边框色 - 深色
  static const Color washiBorderDark = Color(0xFFB8B0A3);
}
