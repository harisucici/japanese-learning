/// 应用脚手架组件
/// 
/// 统一页面基础布局，处理安全区域和背景色
/// 所有页面均应使用此组件而非 Scaffold
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 应用脚手架组件
/// 
/// 统一页面布局规范：
/// - 背景色使用 AppColors.background
/// - 自动处理安全区域
/// - 支持可选的 AppBar
/// - 支持底部导航栏遮挡
class AppScaffold extends StatelessWidget {
  /// 页面标题（可选，传入则显示 AppBar）
  final String? title;
  
  /// 自定义 AppBar（优先级高于 title）
  final PreferredSizeWidget? appBar;
  
  /// 页面主体内容
  final Widget body;
  
  /// 底部操作栏（如按钮、标签栏）
  final Widget? bottomBar;
  
  /// 悬浮按钮
  final Widget? floatingActionButton;
  
  /// 是否显示安全区域顶部（默认 true）
  final bool safeAreaTop;
  
  /// 是否显示安全区域底部（默认 true）
  final bool safeAreaBottom;
  
  /// 是否使用滚动视图包裹（默认 true）
  final bool scrollable;
  
  /// 背景色
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.scrollable = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 确定 AppBar：优先使用自定义 appBar，否则根据 title 构建
    final effectiveAppBar = appBar ?? 
        (title != null 
            ? AppBar(title: Text(title!)) 
            : null);

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: effectiveAppBar,
      body: _buildBody(context),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 构建主体内容
  Widget _buildBody(BuildContext context) {
    Widget content = body;

    // 如果需要滚动，用 SingleChildScrollView 包裹
    if (scrollable) {
      content = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }

    // 安全区域处理
    if (safeAreaTop || safeAreaBottom) {
      content = SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: content,
      );
    }

    return content;
  }
}
