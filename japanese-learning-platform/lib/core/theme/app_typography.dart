/// 设计系统 - 排版规范
/// 
/// 定义字体家族、字号、字重、行高的统一常量
/// 字体优先级：NotoSansJP（日文）> system
/// 禁止使用 Inter 字体
library;

import 'package:flutter/material.dart';

/// 应用字体常量
/// 
/// 统一管理字体家族、字号、字重
class AppTypography {
  AppTypography._();

  // ============================================================
  // 字体家族
  // ============================================================
  
  /// 主字体 - 使用系统默认字体（待字体文件下载后启用 NotoSansJP）
  // TODO: 下载 NotoSansJP 字体文件后取消注释
  // static const String fontFamily = 'NotoSansJP';
  static const String fontFamily = '';  // 空字符串 = 使用系统默认字体
  
  /// 衬线字体 - NotoSerifJP（用于特殊场景如诗词、例句）
  static const String serifFontFamily = 'NotoSerifJP';

  // ============================================================
  // 字重
  // ============================================================
  
  /// 正常字重
  static const FontWeight regular = FontWeight.w400;
  
  /// 中等字重
  static const FontWeight medium = FontWeight.w500;
  
  /// 半粗字重
  static const FontWeight semiBold = FontWeight.w600;
  
  /// 粗字重
  static const FontWeight bold = FontWeight.w700;

  // ============================================================
  // 字号系统（基于 4px 倍数网格）
  // ============================================================
  
  /// 超大号 - 32px（页面大标题）
  static const double displayLarge = 32.0;
  
  /// 大号 - 28px（页面标题）
  static const double displayMedium = 28.0;
  
  /// 中标号 - 24px
  static const double displaySmall = 24.0;
  
  /// 标题1 - 20px（模块标题）
  static const double headlineLarge = 20.0;
  
  /// 标题2 - 18px（卡片标题）
  static const double headlineMedium = 18.0;
  
  /// 标题3 - 16px
  static const double headlineSmall = 16.0;
  
  /// 正文大 - 16px
  static const double bodyLarge = 16.0;
  
  /// 正文 - 14px
  static const double bodyMedium = 14.0;
  
  /// 正文小 - 12px（辅助文字）
  static const double bodySmall = 12.0;
  
  /// 标签 - 10px（徽章、角标）
  static const double labelSmall = 10.0;

  // ============================================================
  // 行高倍数
  // ============================================================
  
  /// 紧凑行高 - 1.2
  static const double lineHeightTight = 1.2;
  
  /// 标准行高 - 1.5
  static const double lineHeightNormal = 1.5;
  
  /// 宽松行高 - 1.75
  static const double lineHeightRelaxed = 1.75;

  // ============================================================
  // 字母间距
  // ============================================================
  
  /// 紧凑字间距
  static const double letterSpacingTight = -0.5;
  
  /// 标准字间距
  static const double letterSpacingNormal = 0.0;
  
  /// 宽松字间距
  static const double letterSpacingWide = 0.5;

  // ============================================================
  // TextStyle 预设（快捷方式）
  // ============================================================
  
  /// 页面大标题（如"今日学习"）
  static TextStyle get displayLargeStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: displayLarge,
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// 页面标题
  static TextStyle get displayMediumStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: displayMedium,
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// 模块标题
  static TextStyle get headlineLargeStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: headlineLarge,
        fontWeight: semiBold,
        height: lineHeightNormal,
      );

  /// 卡片标题
  static TextStyle get headlineMediumStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: headlineMedium,
        fontWeight: semiBold,
        height: lineHeightNormal,
      );

  /// 正文大
  static TextStyle get bodyLargeStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyLarge,
        fontWeight: regular,
        height: lineHeightRelaxed,
      );

  /// 正文标准
  static TextStyle get bodyMediumStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyMedium,
        fontWeight: regular,
        height: lineHeightNormal,
      );

  /// 正文小（辅助说明）
  static TextStyle get bodySmallStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: bodySmall,
        fontWeight: regular,
        height: lineHeightNormal,
      );

  /// 标签（徽章文字）
  static TextStyle get labelSmallStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: labelSmall,
        fontWeight: medium,
        height: lineHeightTight,
      );

  /// 日文示例句（衬线体）
  static TextStyle get serifBodyStyle => const TextStyle(
        fontFamily: serifFontFamily,
        fontSize: bodyLarge,
        fontWeight: regular,
        height: lineHeightRelaxed,
      );
}
