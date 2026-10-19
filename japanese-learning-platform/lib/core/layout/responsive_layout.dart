/// 响应式布局工具
///
/// 定义断点、布局类型、以及响应式布局辅助组件
library;

import 'package:flutter/material.dart';

/// 响应式断点
class Breakpoints {
  /// 移动端/Web 分界点：768px
  static const double mobile = 768;

  /// 平板最大宽度（保持向后兼容）
  static const double tablet = 1024;

  /// 桌面最小宽度
  static const double desktop = 1024;

  /// 根据宽度判断布局类型
  /// - < 768px: mobile
  /// - >= 768px: desktop (web)
  static LayoutType getLayoutType(double width) {
    if (width < mobile) {
      return LayoutType.mobile;
    } else {
      return LayoutType.desktop;
    }
  }

  /// 是否为移动端 (< 768px)
  static bool isMobile(double width) => width < mobile;

  /// 是否为平板（保持向后兼容，归入 desktop）
  static bool isTablet(double width) => width >= mobile && width < tablet;

  /// 是否为桌面/Web (>= 768px)
  static bool isDesktop(double width) => width >= mobile;

  /// 是否为 Web 布局 (>= 768px)
  static bool isWeb(double width) => width >= mobile;
}

/// 布局类型
enum LayoutType {
  mobile,
  tablet,
  desktop,
}

/// 响应式布局构建器
///
/// 根据屏幕宽度自动切换布局：
/// - 移动端（<600px）：单列布局
/// - 平板（600-1024px）：双列布局
/// - 桌面（>1024px）：侧边栏 + 主内容
class ResponsiveLayout extends StatelessWidget {
  /// 移动端布局
  final Widget mobile;

  /// 平板布局
  final Widget? tablet;

  /// 桌面布局（包含侧边栏和主内容）
  final Widget? desktop;

  /// 桌面侧边栏内容
  final Widget? sidebar;

  /// 主内容
  final Widget child;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.sidebar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutType = Breakpoints.getLayoutType(width);

        switch (layoutType) {
          case LayoutType.mobile:
            return mobile;
          case LayoutType.tablet:
            return tablet ?? mobile;
          case LayoutType.desktop:
            if (desktop != null) {
              return desktop!;
            }
            if (sidebar != null) {
              return Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: sidebar!,
                  ),
                  Expanded(child: child),
                ],
              );
            }
            return child;
        }
      },
    );
  }
}

/// 响应式网格布局
///
/// 根据屏幕宽度自动调整列数
class ResponsiveGrid extends StatelessWidget {
  /// 子组件列表
  final List<Widget> children;

  /// 间距
  final double spacing;

  /// 行间距
  final double runSpacing;

  /// 最小卡片宽度
  final double minCardWidth;

  /// 最大列数
  final int maxColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minCardWidth = 300,
    this.maxColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutType = Breakpoints.getLayoutType(width);

        int columnCount;
        switch (layoutType) {
          case LayoutType.mobile:
            columnCount = 1;
            break;
          case LayoutType.tablet:
            columnCount = 2;
            break;
          case LayoutType.desktop:
            columnCount = maxColumns;
            break;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: (width - spacing * (columnCount - 1)) / columnCount,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// 响应式间距
///
/// 根据屏幕宽度自动调整间距
class ResponsiveSpacing extends StatelessWidget {
  final Widget child;

  const ResponsiveSpacing({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutType = Breakpoints.getLayoutType(width);

        double padding;
        switch (layoutType) {
          case LayoutType.mobile:
            padding = 16;
            break;
          case LayoutType.tablet:
            padding = 24;
            break;
          case LayoutType.desktop:
            padding = 32;
            break;
        }

        return Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        );
      },
    );
  }
}
