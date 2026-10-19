/// 设计系统 - 圆角规范
/// 
/// 统一管理组件的圆角半径
library;

import 'package:flutter/material.dart';

/// 应用圆角常量
/// 
/// 不同层级使用不同圆角，建立视觉层次
class AppRadius {
  AppRadius._();

  // ============================================================
  // 小圆角 - 按钮、标签、徽章
  // ============================================================
  
  /// 极小圆角 - 4px（小标签、徽章）
  static const double xs = 4.0;
  
  /// 小圆角 - 8px（按钮、输入框）
  static const double sm = 8.0;
  
  /// 中小圆角 - 12px（小型卡片）
  static const double md = 12.0;

  // ============================================================
  // 中圆角 - 卡片、面板
  // ============================================================
  
  /// 中圆角 - 16px（标准卡片）
  static const double lg = 16.0;
  
  /// 中大圆角 - 20px（大卡片、对话框）
  static const double xl = 20.0;
  
  /// 大圆角 - 24px（大型面板）
  static const double xxl = 24.0;

  // ============================================================
  // 超大圆角 - 模态框、底部弹窗
  // ============================================================
  
  /// 超大圆角 - 28px
  static const double xxxl = 28.0;
  
  /// 极大圆角 - 32px（底部弹窗顶部）
  static const double xxxxl = 32.0;

  // ============================================================
  // 全圆角（胶囊形）
  // ============================================================
  
  /// 全圆角 - 999px（胶囊按钮、标签）
  static const double full = 999.0;

  // ============================================================
  // BorderRadius 快捷方式
  // ============================================================
  
  /// 小圆角（按钮）
  static const BorderRadius radiusSm = BorderRadius.all(
    Radius.circular(sm),
  );
  
  /// 中圆角（卡片）
  static const BorderRadius radiusMd = BorderRadius.all(
    Radius.circular(md),
  );
  
  /// 大圆角（大型卡片）
  static const BorderRadius radiusLg = BorderRadius.all(
    Radius.circular(lg),
  );
  
  /// 全圆角（胶囊形）
  static const BorderRadius radiusFull = BorderRadius.all(
    Radius.circular(full),
  );
  
  /// 顶部大圆角（底部弹窗）
  static const BorderRadius radiusTopXl = BorderRadius.only(
    topLeft: Radius.circular(xxxxl),
    topRight: Radius.circular(xxxxl),
  );
}
