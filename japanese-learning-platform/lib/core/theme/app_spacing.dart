/// 设计系统 - 间距规范
/// 
/// 基于 4px 倍数网格的间距系统
/// VISUAL_DENSITY: 4 → 日常应用密度，适中留白
library;

import 'package:flutter/material.dart';

/// 应用间距常量
/// 
/// 所有间距均为 4px 的倍数，保证视觉一致性
class AppSpacing {
  AppSpacing._();

  // ============================================================
  // 基础间距单位（4px 倍数）
  // ============================================================
  
  /// 2px - 极小间距（紧凑图标与文字）
  static const double xs2 = 2.0;
  
  /// 4px - 超小间距（标签内边距、徽章）
  static const double xs = 4.0;
  
  /// 8px - 小间距（列表项内元素）
  static const double sm = 8.0;
  
  /// 12px - 中小间距
  static const double md = 12.0;
  
  /// 16px - 中间距（卡片内边距、列表间距）
  static const double lg = 16.0;
  
  /// 20px - 中大间距
  static const double xl = 20.0;
  
  /// 24px - 大间距（区块间距）
  static const double xxl = 24.0;
  
  /// 32px - 超大间距（页面区块）
  static const double xxxl = 32.0;
  
  /// 48px - 特大间距（页面顶部/底部）
  static const double xxxxl = 48.0;
  
  /// 64px - 极大间距（特殊场景）
  static const double xxxxxl = 64.0;

  // ============================================================
  // 页面级间距
  // ============================================================
  
  /// 页面水平内边距（左右）
  static const double pageHorizontal = 16.0;
  
  /// 页面垂直内边距（顶部）
  static const double pageTop = 24.0;
  
  /// 页面垂直内边距（底部）
  static const double pageBottom = 24.0;

  // ============================================================
  // 卡片级间距
  // ============================================================
  
  /// 卡片内边距 - 24px（design-taste-frontend 规范）
  static const double cardPadding = 24.0;
  
  /// 卡片间距（卡片之间的距离）
  static const double cardGap = 16.0;

  // ============================================================
  // 列表项间距
  // ============================================================
  
  /// 列表项垂直内边距
  static const double listItemVertical = 12.0;
  
  /// 列表项之间的间距
  static const double listGap = 4.0;

  // ============================================================
  // EdgeInsets 快捷方式
  // ============================================================
  
  /// 页面水平内边距
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );

  /// 页面完整内边距
  static const EdgeInsets pageAllPadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    pageBottom,
  );

  /// 卡片内边距
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  /// 卡片内边距（左右）
  static const EdgeInsets cardPaddingH = EdgeInsets.symmetric(
    horizontal: cardPadding,
  );

  /// 安全区域顶部（避免与状态栏重叠）
  static EdgeInsets safeTop(BuildContext context) {
    return EdgeInsets.only(top: MediaQuery.of(context).padding.top);
  }

  /// 安全区域底部（避免与导航栏重叠）
  static EdgeInsets safeBottom(BuildContext context) {
    return EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom);
  }
}
