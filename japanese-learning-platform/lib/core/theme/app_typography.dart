/// 设计系统 - 排版规范 (design-taste-frontend 升级)
/// 
/// 高端排版原则：
/// - 主字体 NotoSansJP（日文专业字体）
/// - tracking-tight（紧凑字间距）用于标题
/// - 基于 4px 网格的字号系统
/// - 严格的行高和字重层级
library;

import 'package:flutter/material.dart';

/// 应用字体常量
class AppTypography {
  AppTypography._();

  // ============================================================
  // 字体家族
  // ============================================================
  
  /// 主字体 - NotoSansJP（日文专业字体）
  static const String fontFamily = 'NotoSansJP';
  
  /// 衬线字体 - NotoSerifJP（用于古典内容、诗词）
  static const String serifFontFamily = 'NotoSerifJP';

  // ============================================================
  // 字重系统
  // ============================================================
  
  /// 正常 - 400
  static const FontWeight regular = FontWeight.w400;
  
  /// 中等 - 500（用于次要文字）
  static const FontWeight medium = FontWeight.w500;
  
  /// 半粗 - 600（用于标题）
  static const FontWeight semiBold = FontWeight.w600;
  
  /// 粗体 - 700（用于主标题）
  static const FontWeight bold = FontWeight.w700;

  // ============================================================
  // 字号系统（基于 4px 网格，设计方差 8/10）
  // ============================================================
  
  /// Display Large - 36px（页面大标题，tracking-tighter）
  static const double displayLarge = 36.0;
  
  /// Display Medium - 32px（页面标题）
  static const double displayMedium = 32.0;
  
  /// Display Small - 28px（区块标题）
  static const double displaySmall = 28.0;
  
  /// Headline Large - 24px（模块标题）
  static const double headlineLarge = 24.0;
  
  /// Headline Medium - 20px（卡片标题）
  static const double headlineMedium = 20.0;
  
  /// Headline Small - 18px（子标题）
  static const double headlineSmall = 18.0;
  
  /// Title Large - 16px（列表项标题）
  static const double titleLarge = 16.0;
  
  /// Title Medium - 14px（卡片副标题）
  static const double titleMedium = 14.0;
  
  /// Body Large - 16px（正文大）
  static const double bodyLarge = 16.0;
  
  /// Body Medium - 14px（正文）
  static const double bodyMedium = 14.0;
  
  /// Body Small - 12px（辅助文字）
  static const double bodySmall = 12.0;
  
  /// Label Large - 14px（按钮文字）
  static const double labelLarge = 14.0;
  
  /// Label Medium - 12px（标签）
  static const double labelMedium = 12.0;
  
  /// Label Small - 10px（徽章、角标）
  static const double labelSmall = 10.0;

  // ============================================================
  // 行高倍数
  // ============================================================
  
  /// 紧凑行高 - 1.2（用于标题）
  static const double lineHeightTight = 1.2;
  
  /// 标准行高 - 1.5（用于正文）
  static const double lineHeightNormal = 1.5;
  
  /// 宽松行高 - 1.75（用于长段落）
  static const double lineHeightRelaxed = 1.75;

  // ============================================================
  // 字间距（design-taste-frontend 关键）
  // ============================================================
  
  /// 极紧凑 - 用于 Display 标题（tracking-tighter）
  static const double letterSpacingTighter = -1.0;
  
  /// 紧凑 - 用于 Headline 标题
  static const double letterSpacingTight = -0.5;
  
  /// 标准 - 用于正文
  static const double letterSpacingNormal = 0.0;
  
  /// 宽松 - 用于标签（tracking-wide）
  static const double letterSpacingWide = 0.5;

  // ============================================================
  // TextStyle 预设
  // ============================================================
  
  /// Display Large - 页面大标题
  static TextStyle get displayLargeStyle => const TextStyle(
    fontSize: displayLarge,
    fontWeight: bold,
    letterSpacing: letterSpacingTighter,
    height: lineHeightTight,
  );
  
  /// Display Medium - 页面标题
  static TextStyle get displayMediumStyle => const TextStyle(
    fontSize: displayMedium,
    fontWeight: bold,
    letterSpacing: letterSpacingTighter,
    height: lineHeightTight,
  );
  
  /// Headline Large - 模块标题
  static TextStyle get headlineLargeStyle => const TextStyle(
    fontSize: headlineLarge,
    fontWeight: semiBold,
    letterSpacing: letterSpacingTight,
    height: lineHeightTight,
  );
  
  /// Body Large - 正文大
  static TextStyle get bodyLargeStyle => const TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  /// Body Medium - 正文
  static TextStyle get bodyMediumStyle => const TextStyle(
    fontSize: bodyMedium,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  /// Body Small - 辅助文字
  static TextStyle get bodySmallStyle => const TextStyle(
    fontSize: bodySmall,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  /// Label Large - 按钮文字
  static TextStyle get labelLargeStyle => const TextStyle(
    fontSize: labelLarge,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
}
