/// 日式风格应用导航组件
///
/// Web：侧边栏导航（京都传统风格）
/// Mobile：顶部导航栏 + 汉堡菜单
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_illustrations.dart';
import '../../../../core/layout/responsive_layout.dart';

/// 应用导航栏组件
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
        final width = constraints.maxWidth;
        final isWeb = Breakpoints.isWeb(width);

        if (isWeb) {
          return _WebSidebarNav(navigationShell: navigationShell);
        }
        return _MobileTopNav(navigationShell: navigationShell);
      },
    );
  }
}

/// Web 侧边栏导航（日式风格）
class _WebSidebarNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _WebSidebarNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo 区域
                _buildSidebarHeader(context),
                const Divider(height: 1, color: AppColors.border),
                // 导航菜单
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    children: [
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.menu_book_rounded,
                        label: '真题库',
                        isSelected: currentIndex == 0,
                        onTap: () => _navigateToIndex(0),
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.edit_rounded,
                        label: '练习',
                        isSelected: currentIndex == 1,
                        onTap: () => _navigateToIndex(1),
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.history_rounded,
                        label: '复习',
                        isSelected: currentIndex == 2,
                        onTap: () => _navigateToIndex(2),
                      ),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.school_rounded,
                        label: '模拟考试',
                        isSelected: currentIndex == 3,
                        onTap: () => _navigateToIndex(3),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        height: 0.5,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSidebarItem(
                        context: context,
                        icon: Icons.person_rounded,
                        label: '个人中心',
                        isSelected: currentIndex == 4,
                        onTap: () => _navigateToIndex(4),
                      ),
                    ],
                  ),
                ),
                // 底部装饰
                _buildSidebarFooter(context),
              ],
            ),
          ),
          // 主内容区
          Expanded(
            child: Scaffold(
              body: navigationShell,
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + 标题
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日本語学習',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'JLPT 真题练习',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // 京都风景插图（简化版）
          KyotoToriiIllustration(
            width: 200,
            height: 60,
            color: AppColors.primary.withOpacity(0.15),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '学問の道',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: AppColors.textHint,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToIndex(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Mobile 顶部导航栏
class _MobileTopNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileTopNav({required this.navigationShell});

  @override
  State<_MobileTopNav> createState() => _MobileTopNavState();
}

class _MobileTopNavState extends State<_MobileTopNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopAppBar(context),
      drawer: _buildDrawer(context),
      body: widget.navigationShell,
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            '日本語',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary),
          onPressed: () {},
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '日本語学習',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'JLPT 真题练习平台',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // 菜单项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    label: '真题库',
                    isSelected: widget.navigationShell.currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToIndex(0);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.edit_rounded,
                    label: '练习',
                    isSelected: widget.navigationShell.currentIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToIndex(1);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.history_rounded,
                    label: '复习',
                    isSelected: widget.navigationShell.currentIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToIndex(2);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.school_rounded,
                    label: '模拟考试',
                    isSelected: widget.navigationShell.currentIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToIndex(3);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    height: 0.5,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_rounded,
                    label: '个人中心',
                    isSelected: widget.navigationShell.currentIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToIndex(4);
                    },
                  ),
                ],
              ),
            ),
            // 底部装饰
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: KyotoToriiIllustration(
                width: 180,
                height: 50,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
