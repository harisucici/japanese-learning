/// 应用导航栏组件
///
/// 响应式导航：
/// - 移动端（<600px）：底部导航栏
/// - 平板（600-1024px）：底部导航栏
/// - 桌面（>1024px）：侧边栏导航
///
/// 使用 GoRouter 的 StatefulNavigationShell 保持各 Tab 状态独立
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 响应式断点
class _NavBreakpoints {
  static const double desktopMin = 1024;
  static bool isDesktop(double width) => width >= desktopMin;
}

/// 应用导航栏组件
///
/// 响应式导航：根据屏幕宽度自动切换底部导航栏或侧边栏
class AppNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = _NavBreakpoints.isDesktop(constraints.maxWidth);
        if (isDesktop) {
          return _DesktopNav(navigationShell: navigationShell);
        }
        return _MobileNav(navigationShell: navigationShell);
      },
    );
  }
}

/// 移动端底部导航
class _MobileNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        );
      },
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withAlphaCompat(0.1),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_outlined),
          selectedIcon: Icon(Icons.edit),
          label: '练习',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: '复习',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }
}

/// 桌面端侧边栏导航
class _DesktopNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _DesktopNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        );
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withAlphaCompat(0.1),
      leading: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('首页'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.edit_outlined),
          selectedIcon: Icon(Icons.edit),
          label: Text('练习'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('复习'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('我的'),
        ),
      ],
    );
  }
}
